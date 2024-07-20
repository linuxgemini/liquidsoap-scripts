#!/usr/bin/liquidsoap -v

def video.testsrc.smptehdbars_ebustereo(
  ~id=null(),
  ~max_buffer=0.5,
  ~duration=null()
) =
  duration_audio = duration
  duration_audio = if null.defined(duration_audio) then ",atrim=end=#{duration_audio}" else "" end
  src_audio = "sine=frequency=1000:duration=2.75,apad=pad_dur=0.25,aloop=loop=-1:size=3*#{settings.frame.audio.samplerate()}[l]; \
               sine=frequency=1000[r]; \
               [l][r]amerge#{duration_audio}"


  v = video.testsrc.ffmpeg(max_buffer=max_buffer, duration=duration, pattern="smptehdbars")

  a = (input.ffmpeg(max_buffer=max_buffer, format="lavfi", src_audio) :
    source(audio=pcm(stereo))
  )

  (source.mux.video(id=id, video=v, a) :
    source(video=canvas, audio=pcm(stereo))
  )
end
