# Full Stalwart config.toml + DKIM private key, rendered on the node so
# no secret ever lands in git. The initContainer in helm.nix copies these
# into /opt/stalwart/etc on every pod start.
#
# Schema targets Stalwart 0.13.x. Verify against
# https://stalw.art/docs/install/configure on upgrade.
{config, ...}: let
  mailHostname = config.sops.placeholder."mail/server_hostname";

  brevoUser = config.sops.placeholder."mail/brevo/smtp_user";
  brevoKey = config.sops.placeholder."mail/brevo/smtp_key";

  # Fallback admin — Stalwart 0.13 doesn't authenticate against
  # `[[principal]]` blocks in local config (those only seed "local
  # config" overrides, not the auth DB). Real principals are created
  # via the admin UI on first login. The fallback-admin bypasses the
  # DB so we always have a way in.
  adminPwd = config.sops.placeholder."mail/stalwart/admin_password";

  # Single-line base64 of the PEM. Stored that way in sops because YAML
  # block-scalar substitution doesn't re-indent multi-line placeholders,
  # and breaking the | block kills the whole Secret manifest.
  dkimKeyB64 = config.sops.placeholder."mail/stalwart/dkim_private_key_b64";
in {
  sops.templates."mail/stalwart-config.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: stalwart-config
        namespace: mail
      type: Opaque
      stringData:
        config.toml: |
          # These settings are intentionally Nix/SOPS-owned. Stalwart 0.13
          # warns when DB-managed keys are present in the local config unless
          # they are listed here. Keep operationally-sensitive outbound relay,
          # auth policy, DKIM signature, and MTA-STS policy declarative.
          config.local-keys.0 = "remote.*"
          config.local-keys.1 = "remote.*.*"
          config.local-keys.2 = "remote.*.*.*"
          config.local-keys.3 = "queue.outbound.*"
          config.local-keys.4 = "queue.outbound.*.*"
          config.local-keys.5 = "queue.outbound.*.*.*"
          config.local-keys.6 = "signature.*"
          config.local-keys.7 = "signature.*.*"
          config.local-keys.8 = "signature.*.*.*"
          config.local-keys.9 = "auth.*"
          config.local-keys.10 = "auth.*.*"
          config.local-keys.11 = "auth.*.*.*"
          config.local-keys.12 = "session.mta-sts.*"

          [server]
          hostname = "${mailHostname}"

          [server.listener.smtp]
          bind = ["[::]:25"]
          protocol = "smtp"

          [server.listener.submission]
          bind = ["[::]:587"]
          protocol = "smtp"
          tls.implicit = false

          [server.listener.submissions]
          bind = ["[::]:465"]
          protocol = "smtp"
          tls.implicit = true

          [server.listener.imaps]
          bind = ["[::]:993"]
          protocol = "imap"
          tls.implicit = true

          [server.listener.https]
          bind = ["[::]:8083"]
          protocol = "http"
          tls.implicit = false

          [certificate.default]
          cert = "%{file:/etc/stalwart/certs/tls.crt}%"
          private-key = "%{file:/etc/stalwart/certs/tls.key}%"
          default = true

          [storage]
          data = "rocksdb"
          fts = "rocksdb"
          blob = "rocksdb"
          lookup = "rocksdb"
          directory = "internal"

          [store.rocksdb]
          type = "rocksdb"
          path = "/opt/stalwart/data"
          compression = "lz4"

          [directory.internal]
          type = "internal"
          store = "rocksdb"

          # Outbound: route every recipient through Brevo. Stalwart still
          # signs with our DKIM key before handing off — Brevo re-signs
          # with its own selector too (set up in the Brevo dashboard).
          [queue.outbound.next-hop]
          relay = "'brevo'"

          [queue.outbound.tls]
          mta-sts = "optional"
          dane = "optional"
          starttls = "require"

          [remote.brevo]
          type = "smtp"
          address = "smtp-relay.brevo.com"
          port = 587
          protocol = "smtp"
          tls.implicit = false
          tls.allow-invalid-certs = false
          auth.username = "${brevoUser}"
          auth.secret = "${brevoKey}"

          # Bootstrap admin login. Bypasses the DB so we can always log
          # in even before any real principal exists. Real users get
          # created in the admin UI after first login.
          [authentication.fallback-admin]
          user = "admin"
          secret = "${adminPwd}"

          # DKIM signer definition. The signing *rule* (when to sign,
          # for which domains) is configured via the admin UI — its
          # schema is conditional-rules in 0.13 and doesn't fit cleanly
          # in declarative bootstrap config.
          [signature.default]
          private-key = "%{file:/opt/stalwart/etc/dkim.key}%"
          domain = "dobryops.com"
          selector = "default"
          headers = ["From", "To", "Date", "Subject", "Message-ID"]
          algorithm = "rsa-sha256"
          canonicalization = "relaxed/relaxed"
          expire = "10d"
          set-body-length = false
          report = false

          [auth.dkim]
          verify = "relaxed"

          [auth.spf]
          verify.ehlo = "relaxed"
          verify.mail-from = "relaxed"

          [auth.dmarc]
          verify = "relaxed"

          [auth.arc]
          verify = "relaxed"

          [tracer.stdout]
          type = "stdout"
          level = "info"
          ansi = false
          enable = true

          # MTA-STS strict mode for our own outbound — opt-in protection
          # against on-path MX downgrade. Inbound MTA-STS policy lives in
          # DNS (TXT _mta-sts.dobryops.com) and is served by an extra
          # Pangolin HTTP resource if we add one later.
          [session.mta-sts]
          mode = "enforce"
      data:
        dkim.key: ${dkimKeyB64}
    '';
    path = "/var/lib/rancher/k3s/server/manifests/stalwart-config.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
