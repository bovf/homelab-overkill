# Restore ALSA capture state on every boot so the surveillance webcam mic
# stays live. Realtek ALC289 on this laptop comes up with `Capture` muted
# at 0% and `Internal Mic Boost` at 0 — go2rtc + ffmpeg then dutifully
# capture silence and the WebRTC audio track is mute even though the SDP
# negotiated OPUS just fine.
#
# We don't depend on alsactl/alsa-restore.service because that requires a
# previously-saved state file under /var/lib/alsa, which is itself ephemeral
# on a fresh install. Setting the levels explicitly is one fewer state file
# to chase.
{ pkgs, ... }:

{
  systemd.services.alsa-capture-init = {
    description = "Set ALSA capture levels for the surveillance webcam mic";
    wantedBy = [ "multi-user.target" ];
    after    = [ "systemd-modules-load.service" "sound.target" ];
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.alsa-utils ];
    script = ''
      # snd_hda_intel may register a few seconds after the boot target —
      # poll briefly so we don't race the module load.
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        [ -e /proc/asound/card0 ] && break
        sleep 1
      done

      amixer -c 0 sset 'Capture' 60% cap
      amixer -c 0 sset 'Internal Mic Boost' 2
    '';
  };
}
