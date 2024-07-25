#!/usr/bin/liquidsoap

# 2ch @ 48 kHz
settings.frame.audio.channels := 2
settings.frame.audio.samplerate := 48000

# 1080p25
settings.frame.video.width := 1920
settings.frame.video.height := 1080
settings.frame.video.framerate := 25

# include video.testsrc.smptehdbars_ebustereo
%include "testsrc.liq"

testcard_item = mksafe(id="safe_testcard", video.testsrc.smptehdbars_ebustereo(id="testcard"))
testcard_item = video.add_text.sdl(
  id="testcard_item-add_text",
  font="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
  size=32, x=380, y=160,
  "linuxgemini media-streamer ops\
   \nV: #{settings.frame.video.width()}x#{settings.frame.video.height()} @ #{settings.frame.video.framerate()}fps\
   \nA: #{settings.frame.audio.channels()}ch @ #{settings.frame.audio.samplerate()}Hz\
  ",
  testcard_item
)

# Spawn an ffmpeg encoder instance
e = %ffmpeg(
  # not sure if -r is correct here, maybe it is -vframes?
  # -c:v libx264 -r 25 -s 1920x1080 -b:v 2800k -preset fast -g 50 -flags:v +global_header
  %video(
    codec="libx264",
    framerate=25,
    width=1920,
    height=1080,
    b="2800k",
    g=50,
    preset="fast",
    flags="+global_header"
  ),

  # make sure `ac` matches `settings.frame.audio.channels`!
  # make sure `ar` matches `settings.frame.audio.samplerate`!
  # -c:a aac -ac 2 -ar 48000 -b:a 192k -flags:a +global_header
  %audio(
    codec="aac",
    ac=2,
    ar=48000,
    b="192k",
    flags="+global_header"
  ),

  # -f flv
  format="flv",
  # -flvflags no_duration_filesize
  flvflags="no_duration_filesize"
)
