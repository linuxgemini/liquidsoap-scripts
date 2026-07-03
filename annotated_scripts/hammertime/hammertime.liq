#!/usr/bin/env liquidsoap
#
# The Hammer Time Speaking Clock -- Liquidsoap port for Icecast
# =============================================================
# A live "Music on Hold" recreation of Tom Scott's Hammer Time Speaking Clock
# (https://www.tomscott.com/hammer/). All the visual bits of the original
# index.html are dropped; this is audio only.
#
# It is driven entirely from the two original audio assets:
#
#   beat.flac      ~8.46s MC Hammer instrumental. It is NOT a seamless loop:
#                  it deliberately leaves a gap each cycle, which is where the
#                  a-cappella "Stop. Hammer time." sits.
#   voice-net.flac 177s "sprite sheet" holding every spoken fragment. We cue
#                  into it per fragment, so nothing has to be pre-sliced.
#
# NB: FLAC, not the original MP3. MP3 has no seek index, so cueing ~170 s into
# voice-net.mp3 cost ~0.6 s per clip -- that was the lateness. FLAC seeks
# instantly. Create the copies once with (`-map_metadata -1` drops the stray
# 4 KB XMP tag in the original MP3 that Liquidsoap otherwise warns it cannot
# recode -- harmless, but noisy):
#   ffmpeg -i voice-net.mp3 -map_metadata -1 voice-net.flac
#   ffmpeg -i beat.mp3      -map_metadata -1 beat.flac
#
# The original JavaScript polls `new Date()` every 50 ms and fires clips on
# fixed positions inside each real-world 10 second block (wall-clock seconds
# ending in 0). We reproduce that exactly:
#
#   seconds % 10 == 0 : "Stop. Hammer time."                  (voice)
#   seconds % 10 == 2 : (re)start the instrumental beat        (beat)
#   seconds % 10 == 3 : "At the stop, Hammer Time will be"     (voice)
#   seconds % 10 == 6 : <hour>    of the upcoming stop         (voice)
#   seconds % 10 == 7 : <minutes> of the upcoming stop         (voice)
#   seconds % 10 == 8 : <seconds> of the upcoming stop         (voice)
#
# The clock announces the time as it WILL be at the next stop (10 s ahead),
# matching the original's `inTen` logic.
#
# The five voice fragments nearly tile the 10 s cycle (3 + 3 + 1 + 1 + 2 = 10),
# and the beat overlaps them, so the voice (a request.player) and the beat
# (a request.queue) are mixed together with `add`.

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Folder holding beat.flac and voice-net.flac (use forward slashes, even on
# Windows). "." means: run liquidsoap from the folder that contains them.
base = "."

voice_file = "#{base}/voice-net.flac"
beat_file  = "#{base}/beat.flac"

# Fire every clip this many seconds early, to offset the residual decoder +
# output-buffer latency so the speech lands on the wall-clock second. ~0.45 s
# fits here; lower it if the clock sounds early, raise it if it is still late.
lead = 0.45

# Output gain multiplier. 1.0 = unchanged, 2.0 = +6 dB, 0.5 = -6 dB. The
# beat+voice mix already peaks near 0 dBFS, so values >1 will clip loud spots
# unless you also enable the limiter next to the audio graph below.
volume = 1.0

# Icecast target -- adjust to match your server.
icecast_host     = "localhost"
icecast_port     = 8000
icecast_password = "hackme"
icecast_mount    = "hammertime.mp3"

# ---------------------------------------------------------------------------
# Voice sprite fragments (all positions are seconds inside the voice sprite)
# ---------------------------------------------------------------------------

# Build a request that plays the voice sprite cued to the window [cin, cout].
# Cue points are honoured by the decoder because we declare which metadata
# carry them and set those metadata through the `annotate:` protocol.
def vclip(cin, cout) =
  request.create(
    cue_in_metadata="liq_cue_in",
    cue_out_metadata="liq_cue_out",
    "annotate:liq_cue_in=\"#{cin}\",liq_cue_out=\"#{cout}\":#{voice_file}"
  )
end

# "Stop. Hammer time."                     sprite 174.000 .. 177.000
def clip_stop() = vclip(174.0, 177.0) end

# "At the stop, Hammer Time will be"        sprite 0 .. 3.225, trimmed to 3.0
# (speech ends at ~2.46 s, so the trim only drops trailing silence and makes
#  the fragments tile the cycle perfectly).
def clip_intro() = vclip(0.0, 3.0) end

# Hour in 12h form: 0 -> "twelve", 1 -> "one" .. 11 -> "eleven"
# sprite: 4.0 + 2.0 * h, one second each.
def clip_hours(h) =
  c = 4.0 + 2.0 * float_of_int(h)
  vclip(c, c + 1.0)
end

# Minute 0 .. 59            sprite: 30.0 + 2.0 * m, one second each.
def clip_minutes(m) =
  c = 30.0 + 2.0 * float_of_int(m)
  vclip(c, c + 1.0)
end

# Ten-seconds 0,10,20,30,40,50   sprite: 150.0 + 0.4 * s, two seconds each.
def clip_seconds(s) =
  c = 150.0 + 0.4 * float_of_int(s)
  vclip(c, c + 2.0)
end

# ---------------------------------------------------------------------------
# Audio graph: voice player + beat queue, mixed together
# ---------------------------------------------------------------------------

# The five voice fragments nearly fill each 10 s cycle, which would saturate a
# plain request.queue (clips chain back-to-back and drift off the schedule).
# request.player plays each clip the instant it is triggered and just mixes any
# overlap, so every fragment lands on its own wall-clock second.
voice  = request.player(simultaneous=true)
beat_q = request.queue(id="hammer_beat")

# mksafe() plays silence whenever a source is idle, so the mix never stalls.
# normalize=false keeps the original full-level sum of speech over music.
radio = add(normalize=false, [mksafe(beat_q), mksafe(voice)])

# Output gain. Because the mix peaks near 0 dBFS, uncomment the limiter for a
# loud boost without hard clipping (it catches peaks instead of squaring them).
radio = amplify(volume, radio)
#radio = limit(radio)

# ---------------------------------------------------------------------------
# Wall-clock scheduler (mirrors the original setInterval(playCheck, 50))
# ---------------------------------------------------------------------------

# Last cycle position we acted on, so each fragment fires once per second.
prev = ref(-1)

def tick() =
  sec  = int_of_float(time() + lead)   # look ahead by `lead`s so clips fire
  frac = sec mod 10                    # early enough to land on the second

  if frac != prev() then
    prev := frac

    # Local time of the *upcoming* stop (end of this cycle); this is what the
    # hour / minute / second fragments announce.
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

# ---------------------------------------------------------------------------
# Stream to Icecast
# ---------------------------------------------------------------------------
# %mp3 needs a liquidsoap built with LAME. If yours lacks it, swap the encoder
# for: %ffmpeg(format="mp3", %audio(codec="libmp3lame", b="128k"))

output.icecast(
  %mp3(bitrate=128),
  host=icecast_host,
  port=icecast_port,
  password=icecast_password,
  mount=icecast_mount,
  name="The Hammer Time Speaking Clock",
  description="At the stop, Hammer Time will be...",
  genre="Novelty",
  mksafe(radio)
)
