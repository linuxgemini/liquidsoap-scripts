#!/usr/bin/liquidsoap -v

log.stdout.set(true)
log.file.set(false)

# Stereo at 48 kHz
settings.frame.audio.channels := 2
settings.frame.audio.samplerate := 48000

settings.audio.converter.samplerate.libsamplerate.quality := "best"

# 1080{p,i} 29.97 fps
settings.frame.video.width := 1920
settings.frame.video.height := 1080
settings.frame.video.framerate := 30

# stingray naturescape
u = string.trim(file.contents("consts/naturescape-lotus-link"))
i = input.http(
  self_sync=true,
  u
)

e = %ffmpeg(
  %video.copy(ignore_keyframe),
  %audio.copy(ignore_keyframe),

  format="flv",

  flvflags="no_duration_filesize"
)

st_key = string.trim(file.contents("secrets/bloo-stream-key"))
st_url = "rtmp://stream.whatthe.blue/ingress/#{st_key}"

output.url(
  fallible=true,
  self_sync=true,
  url=st_url,
  e,
  i
)
