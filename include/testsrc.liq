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
  src_audio = "sine=frequency=1000:duration=2.75,apad=pad_dur=0.25,aloop=loop=-1:size=3*#{settings.frame.audio.samplerate()},channelmap=channel_layout=mono[l]; \
               sine=frequency=1000,channelmap=channel_layout=mono[r]; \
               [l][r]join=inputs=2:channel_layout=stereo:map=0.0-FL|1.0-FR#{duration_audio}"


  v = video.testsrc.ffmpeg(id="video.testsrc.smptehdbars_ebustereo", max_buffer=max_buffer, duration=duration, pattern="smptehdbars")

  # Generally, one would use `-filter_complex` so that ffmpeg would directly use lavfi. Liquidsoap didn't like that.
  # No harm not using that, I think.
  a = (input.ffmpeg(id="video.testsrc.smptehdbars_ebustereo", max_buffer=max_buffer, format="lavfi", src_audio) :
    source(audio=pcm(stereo))
  )

  (source.mux.video(id=id, video=v, a) :
    source(video=canvas, audio=pcm(stereo))
  )
end
