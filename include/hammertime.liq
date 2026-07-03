#!/usr/bin/env liquidsoap

# An Expensive Word Predictor (Claude Opus 4.8) has produced this script,
# see annotated_scripts/hammertime.liq for detailed explanation

base = "./sounds"

voice_file = "#{base}/voice-net.flac"
beat_file  = "#{base}/beat.flac"

lead = 0.45

# 1.0 = unchanged, 2.0 = +6 dB, 1.4 ≈ +3 dB, 0.5 = -6 dB
volume = 1.0

def vclip(cin, cout) =
  request.create(
    cue_in_metadata="liq_cue_in",
    cue_out_metadata="liq_cue_out",
    "annotate:liq_cue_in=\"#{cin}\",liq_cue_out=\"#{cout}\":#{voice_file}"
  )
end

def clip_stop() = vclip(174.0, 177.0) end

def clip_intro() = vclip(0.0, 3.0) end

def clip_hours(h) =
  c = 4.0 + 2.0 * float_of_int(h)
  vclip(c, c + 1.0)
end

def clip_minutes(m) =
  c = 30.0 + 2.0 * float_of_int(m)
  vclip(c, c + 1.0)
end

def clip_seconds(s) =
  c = 150.0 + 0.4 * float_of_int(s)
  vclip(c, c + 2.0)
end

voice  = request.player(simultaneous=true)
beat_q = request.queue(id="hammer_beat")

speaking_clock = add(normalize=false, [mksafe(beat_q), mksafe(voice)])
speaking_clock = amplify(volume, speaking_clock)
#speaking_clock = limit(speaking_clock)

prev = ref(-1)

def tick() =
  sec  = int_of_float(time() + lead)   # look ahead by `lead`s so clips fire
  frac = sec mod 10                    # early enough to land on the second

  if frac != prev() then
    prev := frac

    stop = time.local(float_of_int(sec - frac + 10))

    if frac == 0 then
      voice.play(clip_stop())
    elsif frac == 2 then
      beat_q.push.uri(beat_file)
    elsif frac == 3 then
      voice.play(clip_intro())
    elsif frac == 6 then
      voice.play(clip_hours(stop.hour mod 12))
    elsif frac == 7 then
      voice.play(clip_minutes(stop.min))
    elsif frac == 8 then
      voice.play(clip_seconds(stop.sec))
    end
  end

  0.05  # re-check in 50 ms
end

thread.run.recurrent(delay=0., tick)
