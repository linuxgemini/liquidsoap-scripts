#!/usr/bin/liquidsoap -v

# Generate an EBU Tech 3304/R49-1999 Stereo ident tone.
# @category Source / Audio processing
# @param ~id Force the value of the source ID.
# @param ~max_buffer Maximum data buffer in seconds
def audio.testsrc_ebustereo(
  ~id=null(),
  ~max_buffer=0.5
) =
  #TODO figure out why this doesnt work and loop over
  #duration = if null.defined(duration) then ",atrim=end=#{duration}" else "" end

  samplerate = settings.frame.audio.samplerate()

  # EBU Tech 3304 spec for Stereo identification tone inherits the R49-1999 spec:
  #   - 1 kHz tone in 2.75 second intervals with a gap of 250 milliseconds (totaling the interval to 3 seconds) on the left channel
  #   - Constant 1 kHz tone on right channel
  src_audio = "sine=frequency=1000:sample_rate=#{samplerate}:duration=2.75,apad=pad_dur=0.25,aloop=loop=-1:size=3*#{samplerate},channelmap=channel_layout=mono[l]; \
               sine=frequency=1000:sample_rate=#{samplerate},channelmap=channel_layout=mono[r]; \
               [l][r]join=inputs=2:channel_layout=stereo:map=0.0-FL|1.0-FR"

  # Generally, one would use `-filter_complex` so that ffmpeg would directly use lavfi. Liquidsoap didn't like that.
  # No harm not using that, I think.
  (input.ffmpeg(id=id, max_buffer=max_buffer, format="lavfi", src_audio) :
    source(audio=pcm(stereo))
  )
end


# Generate a SMPTE HD Testcard with EBU Tech 3304/R49-1999 Stereo ident tone.
# @category Source / Video processing
# @param ~id Force the value of the source ID.
# @param ~max_buffer Maximum data buffer in seconds
def video.testsrc.smptehdbars_ebustereo(
  ~id=null(),
  ~max_buffer=0.5
) =
  v = video.testsrc.ffmpeg(id="video.testsrc.smptehdbars_ebustereo", max_buffer=max_buffer, pattern="smptehdbars")
  a = audio.testsrc_ebustereo(id="video.testsrc.smptehdbars_ebustereo", max_buffer=max_buffer)

  (source.mux.video(id=id, video=v, a) :
    source(video=canvas, audio=pcm(stereo))
  )
end


# Generate an EBU 3373 Testcard with EBU Tech 3304/R49-1999 Stereo ident tone.
# @category Source / Video processing
# @param ~id Force the value of the source ID.
# @param ~max_buffer Maximum data buffer in seconds
def video.testsrc.ebu3373_ebustereo(
  ~id=null(),
  ~max_buffer=0.5
) =
  a = audio.testsrc_ebustereo(id="video.testsrc.ebu3373_ebustereo", max_buffer=max_buffer)

  v_width = settings.frame.video.width()
  v_height = settings.frame.video.height()
  v = image(id="video.testsrc.ebu3373_ebustereo", width=v_width, height=v_height, "images/ebu_hdr-hlg_colour_bars_1920_1080_rgb444p16be_lzw.tif")

  (source.mux.audio(id=id, audio=a, v) :
    source(video=canvas, audio=pcm(stereo))
  )
end
