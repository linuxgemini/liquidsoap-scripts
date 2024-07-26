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

u = string.trim(file.contents("consts/naturescape-lotus-link"))
i = fallback(id="safe_stingray", track_sensitive=false, [
  input.ffmpeg(
    id="stingray_lotus",
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
  self_sync=true,
  e,
  i
)
