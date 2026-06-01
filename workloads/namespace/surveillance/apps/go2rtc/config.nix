# go2rtc.yaml — combined video+audio of the laptop's built-in webcam + mic.
#
# Two producers, merged into one stream. We can't use a single `device:`
# source because go2rtc 1.9.x's Linux device template silently drops the
# `audio=` param — the rendered ffmpeg cmd then has no `-f alsa -i` input,
# so the SDP advertises video only and WebRTC consumers get a muted audio
# slot. Splitting fixes it: device template handles v4l2+transcode to H264,
# exec runs a second ffmpeg that publishes Opus into go2rtc over RTSP.
#
# Camera : /dev/video0  (UVC, MJPG 1280x720@30 confirmed via v4l2-ctl)
# Mic    : ALSA hw:0,0  (ALC289 capture device, confirmed via arecord -l)
{ ... }:

{
  services.k3s.manifests.go2rtc-config.content = {
    apiVersion = "v1";
    kind       = "ConfigMap";
    metadata = {
      name      = "go2rtc-config";
      namespace = "surveillance";
    };
    data."go2rtc.yaml" = ''
      api:
        listen: ":1984"
        origin: "*"

      # No external WebRTC listener — clients reach the stream through the
      # same HTTPS path as the UI (traefik → go2rtc :1984), which negotiates
      # WebRTC over WebSocket. Saves us from punching extra UDP/TCP.
      webrtc:
        candidates: []

      log:
        level: info

      # One ffmpeg, three output tracks into a single RTSP stream:
      #   v:0 = H264   (transcoded for WebRTC/MSE — yuv420p, zerolatency)
      #   v:1 = MJPEG  (copy — camera already emits MJPG so zero re-encode CPU;
      #                 unlocks /api/stream.mjpeg and /api/frame.jpeg fan-out)
      #   a:0 = OPUS   (transcoded from ALSA S16 capture)
      # /dev/video0 is single-open on V4L2 so we can't split the camera
      # across two ffmpeg processes — has to be one.
      streams:
        cam:
          - exec:ffmpeg -hide_banner -loglevel error -f v4l2 -input_format mjpeg -video_size 1280x720 -framerate 30 -i /dev/video0 -f alsa -ac 2 -ar 48000 -i hw:0,0 -map 0:v:0 -c:v:0 libx264 -g 50 -profile:v:0 high -level:v:0 4.1 -preset:v:0 superfast -tune:v:0 zerolatency -pix_fmt:v:0 yuv420p -map 0:v:0 -c:v:1 copy -map 1:a:0 -c:a:0 libopus -application:a:0 lowdelay -ar:a:0 48000 -ac:a:0 2 -user_agent ffmpeg/go2rtc -f rtsp -rtsp_transport tcp {output}
    '';
  };
}
