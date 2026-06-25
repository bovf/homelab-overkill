{config, ...}: let
  matrixDomain = config.sops.placeholder."pangolin/resources/matrix/domain";
  lkJwtDomain = config.sops.placeholder."pangolin/resources/livekit_jwt/domain";
in {
  # Element's config.json. No credentials, but rendered via sops.templates
  # so the homeserver domain never lands in git. `disable_custom_urls` locks
  # the client to our homeserver — a private, friends-only server.
  sops.templates."matrix/element-config.yaml" = {
    content = ''
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: element-config
        namespace: matrix
      data:
        config.json: |
          {
            "default_server_config": {
              "m.homeserver": {
                "base_url": "https://${matrixDomain}",
                "server_name": "${matrixDomain}"
              },
              "org.matrix.msc4143.rtc_foci": [
                {
                  "type": "livekit",
                  "livekit_service_url": "https://${lkJwtDomain}"
                }
              ]
            },
            "brand": "Matrix",
            "disable_custom_urls": true,
            "disable_guests": true,
            "disable_3pid_login": true,
            "show_labs_settings": false,
            "features": {
              "feature_group_calls": true,
              "feature_video_rooms": true,
              "feature_element_call_video_rooms": true
            },
            "room_directory": {
              "servers": ["${matrixDomain}"]
            },
            "element_call": {
              "use_exclusively": true
            }
          }
    '';
    path = "/var/lib/rancher/k3s/server/manifests/element-config.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
