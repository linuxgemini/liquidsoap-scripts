#!/usr/bin/liquidsoap

log.stdout.set(true)
log.file.set(false)

%include "include/stream_base.liq"

# NASA Media satellite uplink received from K03IM-D
# Provided by Anton Kapela (tkapela11)
# See https://www.reddit.com/r/nasa/comments/s2x175/nasa_uhd_returns_to_the_internet/
u = string.trim(file.contents("consts/nasa-media-satellite"))

# stacked mksafe
i = fallback(id="safe_nasa-media", track_sensitive=false, [
  input.ffmpeg(
    id="nasa-media",
    self_sync=false,
    max_buffer=30.,
    int_args=[("icy", 0)],
    u
  ),
  testcard_item()
])

st_key = string.trim(file.contents("secrets/bloo-stream-key"))
st_url = "rtmp://stream.whatthe.blue/ingress/#{st_key}"

# Stream to bloo's shite instance; clock is _sort of_ unstable so its gonna self_sync
output.url(
  self_sync=true,
  url=st_url,
  e,
  i
)
