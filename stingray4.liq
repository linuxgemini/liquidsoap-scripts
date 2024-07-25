#!/usr/bin/liquidsoap

log.stdout.set(true)
log.file.set(false)

############### highest verbosity setup ###############
### set shebang to below
#!/usr/bin/liquidsoap --debug --debug-errors --debug-levels

#log.stdout.set(false)
#log.file.set(true)

#log.level.set(99)

#settings.log.file.path := "/opt/liquidsoap/logs/st4_script.log"

#settings.ffmpeg.log.verbosity := "debug"
############### highest verbosity setup ###############

%include "include/stream_base.liq"

# Stingray Naturescape; although I consider it quite stable,
# they do cue points for ad injection so it gets messy at times
# hence why I let it self_sync.
u = string.trim(file.contents("consts/naturescape-lotus-link"))

# stacked mksafe
i = fallback(id="safe_stingray", track_sensitive=false, [
  input.ffmpeg(
    id="stingray_lotus",
    self_sync=true,
    max_buffer=30.,
    int_args=[("icy", 0)],
    u
  ),
  testcard_item
])

st_key = string.trim(file.contents("secrets/bloo-stream-key"))
st_url = "rtmp://stream.whatthe.blue/ingress/#{st_key}"

# Stream to bloo's service
output.url(
  url=st_url,
  e,
  i
)
