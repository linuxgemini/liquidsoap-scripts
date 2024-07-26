#!/usr/bin/liquidsoap

log.stdout.set(true)
log.file.set(false)

#settings.ffmpeg.log.verbosity := "debug"

%include "include/stream_base.liq"

st_key = string.trim(file.contents("secrets/bloo-stream-key"))
st_url = "rtmp://stream.whatthe.blue/ingress/#{st_key}"

output.url(
  url=st_url,
  e,
  testcard_item
)
