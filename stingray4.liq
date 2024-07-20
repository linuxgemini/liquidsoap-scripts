#!/usr/bin/liquidsoap

log.stdout.set(true)
log.file.set(false)

# //// highest verbosity
### set shebang to below
#!/usr/bin/liquidsoap --debug --debug-errors --debug-levels

#log.stdout.set(false)
#log.file.set(true)

#log.level.set(99)

#settings.log.file.path := "/opt/liquidsoap/logs/st4_script.log"

#settings.ffmpeg.log.verbosity := "debug"
# end block \\\\

# use locally compiled ffmpeg (hopefully)
settings.protocol.ffmpeg.path := "/usr/local/bin/ffmpeg"

# 2ch @ 44.1 kHz
settings.frame.audio.channels := 2
settings.frame.audio.samplerate := 44100

# 720p25
settings.frame.video.width := 1280
settings.frame.video.height := 720
settings.frame.video.framerate := 25

# include video.testsrc.smptehdbars_ebustereo
%include "include/testsrc.liq"

tcard = mksafe(id="safe_testcard", video.testsrc.smptehdbars_ebustereo(id="testcard"))

# Stingray Naturescape; although I consider it quite stable,
# their intervals do get messy at times so I let it self_sync.
u = string.trim(file.contents("consts/naturescape-lotus-link"))

# stacked mksafe
i = fallback(id="safe_stingray", track_sensitive=false, [
  input.ffmpeg(
    id="stingray_lotus",
    self_sync=true,
    int_args=[("icy", 0)],
    u
  ),
  tcard
])

# Spawn an ffmpeg encoder instance
e = %ffmpeg(
  # -c:v libx264 -b:v 2800k -preset fast -g:v 50 -flags:v +global_header
  %video(
    codec="libx264",
    framerate=25,
    width=1280,
    height=720,
    b="2800k",
    g=50,
    preset="fast"
    flags="+global_header"
  ),

  # make sure `ac` matches `settings.frame.audio.channels`!
  # make sure `ar` matches `settings.frame.audio.samplerate`!
  # -c:a aac -ac 2 -ar 44100 -b:a 192k -flags:a +global_header
  %audio(
    codec="aac",
    ac=2,
    ar=44100,
    b="192k"
    flags="+global_header"
  ),

  # -f flv
  format="flv"
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
