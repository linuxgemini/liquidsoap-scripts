#!/usr/bin/liquidsoap

def get_rickroll_uri() = "process:png,qrencode -s 4 -l H -o $(output) 'https$(colon)//youtu.be/dQw4w9WgXcQ?gen_time=#{int_of_float(time())}'" end

def create_qr_request() =
  request.create(
    temporary=true,
    get_rickroll_uri()
  )
end

qr_request = ref(create_qr_request())

# Add an image from a request.
# @category Source / Video processing
# @param ~id Force the value of the source ID.
# @param ~fallible Whether we are allowed to fail (in case the file is non-existent or invalid).
# @param ~width Scale to width
# @param ~height Scale to height
# @param ~x x position.
# @param ~y y position.
def resolve_and_add_request(
  ~id=null("resolve_and_add_request"),
  ~fallible=false,
  ~width=null(),
  ~height=null(),
  ~x=getter(0),
  ~y=getter(0),
  ~r,
  (s:source)
) =

  image = request.image(
    id=id, fallible=fallible, x=x, y=y, width=width, height=height, r
  )

  # destructure just the video portion of the
  # source created by request.image
  # (and rename it as `image`)
  let {video = image} = source.tracks(image)

  # destructure video and everything else of the
  # original source
  let {video, ...tracks} = source.tracks(s)

  # combine original video and the image
  video = track.video.add([video, image])

  # create a "new" source with the new video track
  # and rest of the original source
  source(id=id, tracks.{video=video})
end

def call_generate_qr(s) =
  resolve_and_add_request(
    id="call_generate_qr",
    r=qr_request,
    x=284,
    y=720,
    s
  )
end