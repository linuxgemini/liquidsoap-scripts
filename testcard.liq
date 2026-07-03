#!/usr/bin/liquidsoap

log.stdout.set(true)
log.file.set(false)

#settings.ffmpeg.log.verbosity := "debug"

%include "include/stream_base.liq"

st_key = string.trim(file.contents("secrets/twitch-key"))
st_url = "rtmp://ingest.global-contribute.live-video.net/app/#{st_key}"

output.url(
  url=st_url,
  e,
  testcard_item()
)
