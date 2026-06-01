# Minimal settings.yml for SearXNG. Image ships its own default; this
# ConfigMap overrides the bits we care about. Anything we don't set
# falls back to the upstream settings.yml inside the container.
{ config, ... }:

{
  sops.templates."searxng/settings.yaml" = {
    content = ''
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: searxng-settings
        namespace: dashboard
      data:
        settings.yml: |
          use_default_settings: true

          general:
            instance_name: "DobryOps Search"
            privacypolicy_url: false
            donation_url: false
            contact_url: false

          server:
            base_url: "https://${config.sops.placeholder."pangolin/resources/search/domain"}"
            secret_key: "$SEARXNG_SECRET"
            limiter: false
            image_proxy: true
            method: "GET"
            default_http_headers:
              X-Content-Type-Options: nosniff
              X-Download-Options: noopen
              X-Robots-Tag: noindex, nofollow
              Referrer-Policy: no-referrer

          ui:
            static_use_hash: true
            default_theme: simple
            theme_args:
              simple_style: dark
            infinite_scroll: true
            search_on_category_select: true

          # Glance hits us via the cluster-internal Service for the
          # homepage search bar; allow JSON output for that.
          search:
            safe_search: 0
            autocomplete: "duckduckgo"
            default_lang: "en"
            formats:
              - html
              - json
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/searxng-settings.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
