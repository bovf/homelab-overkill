{config, ...}: {
  sops.templates."helm/ms-researcher-kb.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: ms-researcher-kb
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "4.6.2"
        targetNamespace: knowledgebase
        createNamespace: false
        valuesContent: |
          defaultPodOptions:
            annotations:
              configmap.reloader.stakater.com/reload: "ms-researcher-kb-nginx"

          controllers:
            main:
              containers:
                main:
                  image:
                    repository: nginx
                    tag: "1.31.2@sha256:424939d458e28153a78d9a4a8d60e8fae5eae35e84a2d92a43d153d1f92c171c"
                    pullPolicy: IfNotPresent
                  probes:
                    liveness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 80
                        initialDelaySeconds: 30
                        periodSeconds: 30
                        timeoutSeconds: 5
                        failureThreshold: 3
                    readiness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 80
                        initialDelaySeconds: 30
                        periodSeconds: 10
                        timeoutSeconds: 5
                        failureThreshold: 6
                  resources:
                    requests:
                      cpu: 20m
                      memory: 64Mi
                    limits:
                      cpu: 250m
                      memory: 256Mi
                publisher:
                  image:
                    repository: ghcr.io/gissehel/logseq-publish-spa
                    tag: "latest"
                    pullPolicy: IfNotPresent
                  env:
                    TZ: "Europe/Sofia"
                    REPO_URL: "git@gitlab.dobryops.com:knowledge-base/ms-researcher-kb.git"
                    REPO_BRANCH: "main"
                    POLL_SECONDS: "300"
                    PUBLISH_UID_GID: "101:101"
                  command:
                    - /usr/bin/env
                    - bash
                    - -ceu
                    - |
                      shopt -s dotglob nullglob
                      if ! command -v ssh >/dev/null 2>&1; then
                        apk add --no-cache openssh-client
                      fi
                      mkdir -p /repo /export /tmp/ssh
                      cp /ssh-secret/id_ed25519 /tmp/ssh/id_ed25519
                      chmod 600 /tmp/ssh/id_ed25519
                      export GIT_SSH_COMMAND="ssh -i /tmp/ssh/id_ed25519 -p 2222 -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/tmp/ssh/known_hosts"
                      write_placeholder() {
                        cat > /export/index.html <<'HTML'
                      <!doctype html>
                      <html><head><meta charset="utf-8"><title>MS Researcher KB</title></head>
                      <body><h1>MS Researcher KB</h1><p>The knowledgebase is publishing. Refresh in a minute.</p></body></html>
                      HTML
                      }
                      [ -f /export/index.html ] || write_placeholder
                      while true; do
                        changed=0
                        if [ ! -d /repo/.git ]; then
                          rm -rf /repo/*
                          git clone --depth=1 --branch "''${REPO_BRANCH}" "''${REPO_URL}" /repo
                          changed=1
                        else
                          cd /repo
                          git remote set-url origin "''${REPO_URL}"
                          git fetch --depth=1 origin "''${REPO_BRANCH}"
                          old="$(git rev-parse HEAD)"
                          new="$(git rev-parse "origin/''${REPO_BRANCH}")"
                          if [ "''${old}" != "''${new}" ]; then
                            git reset --hard "origin/''${REPO_BRANCH}"
                            changed=1
                          fi
                        fi

                        publisher_version="2026-06-08-index-v3"
                        current_publisher_version="$(cat /export/.publisher-version 2>/dev/null || true)"
                        if [ "''${changed}" = "1" ] || [ ! -f /export/.published-head ] || [ "''${current_publisher_version}" != "''${publisher_version}" ]; then
                          cd /repo
                          mkdir -p assets journals logseq pages
                          # The viewer is read-only and should expose the full KB.
                          # This edits only the disposable clone, never the GitLab repo.
                          printf '{:publishing/all-pages-public? true}\n' > logseq/config.edn

                          rm -rf /tmp/logseq-export
                          mkdir -p /tmp/logseq-export
                          logseq-publish-spa /tmp/logseq-export
                          test -f /tmp/logseq-export/index.html
                          rm -rf /export/*
                          cp -a /tmp/logseq-export/. /export/
                          node -e 'const fs = require("fs"); const p = "/export/index.html"; const marker = "ms-kb-entrypoint"; const script = String.raw`<script id="ms-kb-entrypoint">(function () { var startHash = "#/page/Start%20Here"; var initialHash = window.location.hash || ""; var forceStartUntil = (initialHash === "" || initialHash === "#" || initialHash === "#/") ? Date.now() + 30000 : 0; function goStart(){ if (forceStartUntil && Date.now() < forceStartUntil && window.location.hash !== startHash) window.location.replace(window.location.pathname + window.location.search + startHash); } function fixBrowseLinks(){ document.querySelectorAll("a").forEach(function(a){ var t=(a.textContent||"").trim(); var h=a.getAttribute("href")||""; if (t === "[[/kb/]]" || t === "/kb/" || h.indexOf("%2Fkb%2F") !== -1 || h.indexOf("#/page//kb/") !== -1 || h === "#/page/kb") { a.href = "#/page/Index"; a.textContent = "KB Index"; a.target = "_self"; } }); } function addNav(){ var nav=document.querySelector(".cp__menubar-repos .nav-header"); if (!nav || document.getElementById("ms-kb-index-nav")) return; var d=document.createElement("div"); d.id="ms-kb-index-nav"; d.innerHTML="<a href=\"#/page/Index\" class=\"item group flex items-center text-sm font-medium rounded-md\"><span class=\"ui__icon ti ti-list-search\"></span><span class=\"flex-1\">KB Index</span></a><a href=\"/kb/\" class=\"item group flex items-center text-sm font-medium rounded-md\"><span class=\"ui__icon ti ti-folder\"></span><span class=\"flex-1\">Raw files</span></a>"; nav.appendChild(d); } function tick(){ goStart(); fixBrowseLinks(); addNav(); } tick(); document.addEventListener("DOMContentLoaded", tick); setInterval(tick, 250); }());</script>`; const html = fs.readFileSync(p, "utf8"); fs.writeFileSync(p, html.includes(marker) ? html.replace(/<script id="ms-kb-entrypoint">[\s\S]*?<\/script>/, script) : html.replace("</head>", script + "\n</head>"));'
                          git rev-parse HEAD > /export/.published-head
                          printf '%s\n' "''${publisher_version}" > /export/.publisher-version
                          date -Is > /export/.published-at
                          chown -R "''${PUBLISH_UID_GID}" /export || true
                          echo "Published MS Researcher KB at $(cat /export/.published-head)"
                        else
                          echo "MS Researcher KB unchanged at $(cat /export/.published-head)"
                        fi
                        sleep "''${POLL_SECONDS}"
                      done
                  resources:
                    requests:
                      cpu: 100m
                      memory: 512Mi
                    limits:
                      cpu: 2000m
                      memory: 2Gi

          service:
            main:
              controller: main
              type: ClusterIP
              externalIPs:
                - "100.89.128.16"
              ports:
                http:
                  # 8101 = MS Researcher KB. 8097/8098/8099/8100 are taken.
                  port: 8101
                  targetPort: 80
                  protocol: TCP

          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: knowledgebase-ms-researcher-kb-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/ms_kb/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: http

          persistence:
            export:
              type: emptyDir
              advancedMounts:
                main:
                  main:
                    - path: /usr/share/nginx/html
                  publisher:
                    - path: /export
            repo:
              accessMode: ReadWriteOnce
              size: 2Gi
              storageClass: local-path
              advancedMounts:
                main:
                  main:
                    - path: /repo
                      readOnly: true
                  publisher:
                    - path: /repo
            git-ssh-key:
              type: hostPath
              hostPath: ${config.sops.secrets."hermes/ms_researcher_kb_git_ssh_key".path}
              hostPathType: File
              advancedMounts:
                main:
                  publisher:
                    - path: /ssh-secret/id_ed25519
                      readOnly: true
            nginx-conf:
              type: configMap
              name: ms-researcher-kb-nginx
              advancedMounts:
                main:
                  main:
                    - path: /etc/nginx/conf.d/default.conf
                      subPath: default.conf
                      readOnly: true
    '';
    path = "/var/lib/rancher/k3s/server/manifests/ms-researcher-kb.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };

  services.k3s.manifests.ms-researcher-kb-nginx.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "ms-researcher-kb-nginx";
      namespace = "knowledgebase";
    };
    data."default.conf" = ''
      server {
        listen 80;
        server_name _;
        root /usr/share/nginx/html;
        index index.html;

        location ~ (^|/)\.git(/|$) {
          return 404;
        }

        location /kb/ {
          alias /repo/;
          autoindex on;
          autoindex_exact_size off;
          autoindex_localtime on;
          types {
            text/markdown md markdown;
            text/plain txt log json jsonl yaml yml edn;
          }
          default_type text/plain;
          add_header Content-Disposition inline always;
        }

        location / {
          try_files $uri $uri/ /index.html;
        }
      }
    '';
  };
}
