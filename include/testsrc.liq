#!/usr/bin/liquidsoap -v

# Generate a SMPTE HD Testcard with EBU Tech 3304/R49-1999 Stereo ident tone.
# @category Source / Video processing
# @param ~id Force the value of the source ID.
# @param ~max_buffer Maximum data buffer in seconds
# @param ~duration Duration of the source.
def video.testsrc.smptehdbars_ebustereo(
  ~id=null(),
  ~max_buffer=0.5,
  ~duration=null()
) =
  duration_audio = duration
  duration_audio = if null.defined(duration_audio) then ",atrim=end=#{duration_audio}" else "" end

  # EBU Tech 3304 spec for Stereo identification tone inherits the R49-1999 spec:
  #   - Constant 1 kHz tone on right channel
  #   - 1 kHz tone in 2.75 second intervals with a gap of 250 milliseconds (totaling the interval to 3 seconds) on the left channel
  #
  # Normally, one could enforce the channel setup to 2 mono to 1 stereo using  `channelmap=channel_layout=` filter on every output 
  # but liquidsoap doesn't like that, so we just let it run without those as `amerge` uses the amount of channels it gets to map
  # the output if you don't map them yourself.
  src_audio = "sine=frequency=1000:duration=2.75,apad=pad_dur=0.25,aloop=loop=-1:size=3*#{settings.frame.audio.samplerate()}[l]; \
               sine=frequency=1000[r]; \
               [l][r]amerge#{duration_audio}"


  v = video.testsrc.ffmpeg(max_buffer=max_buffer, duration=duration, pattern="smptehdbars")

  # Normally (again), one would use `-filter_complex` so that ffmpeg would directly use lavfi. Liquidsoap didn't like that either.
  # No harm in not using that, I think.
  a = (input.ffmpeg(max_buffer=max_buffer, format="lavfi", src_audio) :
    source(audio=pcm(stereo))
  )

  (source.mux.video(id=id, video=v, a) :
    source(video=canvas, audio=pcm(stereo))
  )
end
