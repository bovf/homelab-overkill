# Minimal settings.yml for SearXNG. Image ships its own default; this
# ConfigMap overrides the bits we care about. Anything we don't set
# falls back to the upstream settings.yml inside the container.
{config, ...}: {
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

          # Override by name so other categories keep their upstream engines.
          # Verified from engineer with the pinned image on 2026-09-08:
          # Brave/DDG/Bing return web results; Google is empty and Startpage fails.
          engines:
            - name: brave
              disabled: false
            - name: duckduckgo
              disabled: false
            - name: bing
              disabled: false
            - name: google
              disabled: true
            - name: startpage
              disabled: true

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

          # Glance opens the HTML search page; JSON also supports API clients
          # and the README's functional smoke check.
          search:
            safe_search: 0
            autocomplete: "duckduckgo"
            default_lang: "en"
            formats:
              - html
              - json
    '';
    path = "/var/lib/rancher/k3s/server/manifests/searxng-settings.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
