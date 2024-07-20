#!/usr/bin/liquidsoap -v

log.stdout.set(true)
log.file.set(false)

# 2ch @ 44.1 kHz
settings.frame.audio.channels := 2
settings.frame.audio.samplerate := 44100

# 720p30
settings.frame.video.width := 1280
settings.frame.video.height := 720
settings.frame.video.framerate := 30

# Stingray Naturescape; although I consider it quite stable,
# their intervals do get messy at times so I let it self_sync.
u = string.trim(file.contents("consts/naturescape-lotus-link"))

# Mandatory mksafe() to allow encoding
i = mksafe(
  input.http(
    self_sync=true,
    u
  )
)

# Spawn an ffmpeg encoder instance
e = %ffmpeg(
  # -c:v libx264 -b:v 2500k -preset veryfast -x264-params keyint=300:min-keyint=150 -flags:v +global_header
  %video(
    codec="libx264",
    b="2500k",
    preset="veryfast",
    x264opts="keyint=300:min-keyint=150",
    flags="+global_header"
  ),

  # make sure `ac` matches `settings.frame.audio.channels`!
  # make sure `ar` matches `settings.frame.audio.samplerate`!
  # -c:a aac -ac 2 -ar 44100 -b:a 192k -flags:a +global_header
  %audio(
    codec="aac",
    ac=2,
    ar=44100,
    b="192k",
    flags="+global_header"
  ),

  # -f flv
  format="flv",
  # -flvflags no_duration_filesize
  flvflags="no_duration_filesize"
)

st_key = string.trim(file.contents("secrets/bloo-stream-key"))
st_url = "rtmp://stream.whatthe.blue/ingress/#{st_key}"

# Stream to bloo's shite instance; clock is _sort of_ unstable so its gonna self_sync
output.url(
  self_sync=true,
  url=st_url,
  e,
  i
)
