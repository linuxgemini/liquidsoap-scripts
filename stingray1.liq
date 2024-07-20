#!/usr/bin/liquidsoap -v

log.stdout.set(true)
log.file.set(false)

# Stereo at 44.1 kHz
settings.frame.audio.channels := 2
settings.frame.audio.samplerate := 44100

settings.audio.converter.samplerate.libsamplerate.quality := "best"

# 1080{p,i} 25 fps
settings.frame.video.width := 1920
settings.frame.video.height := 1080
settings.frame.video.framerate := 25

# stingray naturescape
u = string.trim(file.contents("consts/naturescape-lotus-link"))
i = input.http(
  clock_safe=true,
  self_sync=true,
  u
)
#i = mksafe(
#  input.http(
#    clock_safe=true,
#    self_sync=true,
#    u
#  )
#)

e = %ffmpeg(
  format="flv",
  %audio.copy,
  %video.copy
)

st_key = string.trim(file.contents("secrets/bloo-stream-key"))
st_url = "rtmp://stream.whatthe.blue/ingress/#{st_key}"

output.url(
  fallible=true,
  export_cover_metadata=false,
  url=st_url,
  e,
  i
)
