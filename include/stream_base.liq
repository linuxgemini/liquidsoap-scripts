#!/usr/bin/liquidsoap

# 2ch @ 48 kHz
settings.frame.audio.channels := 2
settings.frame.audio.samplerate := 48000

# 1080p25
let {px, vw, vh, rem, width, height} = video.canvas.virtual_10k.actual_1080p
settings.frame.video.width := width
settings.frame.video.height := height
settings.frame.video.framerate := 25

# include custom test sources
%include "testsrc.liq"
%include "utils.liq"

testcard_item = mksafe(
  id="safe_testcard",
  video.testsrc.ebu3373_ebustereo(id="base_testcard")
)

testcard_item = video.add_text(
  id="testcard_item-add_text",
  font="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
  size=32,
  x=300,
  y=650,
  "linuxgemini media-streamer ops; \
   V: #{settings.frame.video.width()}x#{settings.frame.video.height()} @ #{settings.frame.video.framerate()}fps (SDR); \
   A: #{settings.frame.audio.channels()}ch @ #{settings.frame.audio.samplerate()}Hz\
  ",
  testcard_item
)
testcard_item = ref(call_generate_qr(testcard_item))

thread.run(delay=10., every=30., {
  request.destroy(qr_request())
  qr_request := create_qr_request()

  testcard_item := call_generate_qr(testcard_item())
})

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

server.harbor()