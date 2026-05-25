# Declarative bootstrap of Stalwart principals + DKIM signing rule via
# the admin REST API. Runs once on first deploy; idempotent.
#
# Why a Job, not config.toml: Stalwart 0.13 only authenticates against
# principals stored in its runtime DB, not [[principal]] blocks in
# config.toml. The DKIM `auth.dkim.sign` rule is also DB-only in 0.13
# (conditional-rules schema). The Job uses the API to populate both,
# fulfilling our declarative-everything preference.
#
# Bootstrap login is via [authentication.fallback-admin] (in
# secret.nix) which bypasses the DB and always accepts the admin
# password from sops.
{ config, ... }:

let
  adminPwd   = config.sops.placeholder."mail/stalwart/admin_password";
  dobryPwd   = config.sops.placeholder."mail/stalwart/users/dobry/password";
  dkimKeyB64 = config.sops.placeholder."mail/stalwart/dkim_private_key_b64";
  brevoUser  = config.sops.placeholder."mail/brevo/smtp_user";
  brevoKey   = config.sops.placeholder."mail/brevo/smtp_key";
in
{
  # Bootstrap creds for the Job. Separate Secret from stalwart-config
  # so the Job only mounts what it needs.
  sops.templates."mail/stalwart-bootstrap-secret.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: stalwart-bootstrap-creds
        namespace: mail
      type: Opaque
      stringData:
        admin_password: "${adminPwd}"
        dobry_password: "${dobryPwd}"
        dkim_private_key_b64: "${dkimKeyB64}"
        brevo_smtp_user: "${brevoUser}"
        brevo_smtp_key: "${brevoKey}"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/stalwart-bootstrap-secret.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };

  services.k3s.manifests.stalwart-bootstrap-job.content = {
    apiVersion = "batch/v1";
    kind       = "Job";
    metadata = {
      name      = "stalwart-bootstrap";
      namespace = "mail";
      annotations = {
        # Bump on script changes to force re-run (delete old Job + apply new).
        "homelab.dobryops.com/bootstrap-version" = "7";
      };
    };
    spec = {
      backoffLimit            = 5;
      ttlSecondsAfterFinished = 86400;   # auto-clean 24h after success
      template.spec = {
        restartPolicy = "OnFailure";
        containers = [{
          name    = "bootstrap";
          image   = "alpine:3.20";
          command = [ "sh" ];
          args = [
            "-ec"
            ''
              apk add --no-cache --quiet curl jq >/dev/null

              API="http://stalwart.mail.svc.cluster.local:8083/api"

              echo "Waiting for Stalwart API to accept admin auth..."
              until curl -fsS -u "admin:$ADMIN_PASSWORD" "$API/principal" >/dev/null 2>&1; do
                sleep 5
              done
              echo "Stalwart API ready."

              # Stalwart 0.13 returns 200 OK for missing principals with a
              # body like {"error":"notFound","item":"..."}, and 200 OK on
              # successful creation with {"data": <id>}. For idempotent
              # POST, treat fieldAlreadyExists as success.
              ensure() {
                local label=$1 body=$2
                echo "Ensuring $label..."
                local resp
                resp=$(echo "$body" | curl -sS -u "admin:$ADMIN_PASSWORD" \
                       -H "Content-Type: application/json" \
                       -X POST "$API/principal" -d @-)
                if echo "$resp" | grep -q '"data":'; then
                  echo "  created."
                elif echo "$resp" | grep -q '"fieldAlreadyExists"'; then
                  echo "  already exists, skipping."
                else
                  echo "  ERROR: $resp"
                  return 1
                fi
              }

              # Bootstrap order: domain first, then principals that have
              # emails in that domain.
              ensure 'domain dobryops.com' '{"type":"domain","name":"dobryops.com","description":"Primary mail domain"}'

              ensure 'principal dobry' "{
                \"type\": \"individual\",
                \"name\": \"dobry\",
                \"description\": \"Primary mailbox\",
                \"secrets\": [\"$DOBRY_PASSWORD\"],
                \"emails\": [\"dobry@dobryops.com\"],
                \"roles\": [\"user\"]
              }"

              ensure 'list postmaster' '{
                "type": "list",
                "name": "postmaster",
                "description": "Postmaster (RFC-required)",
                "emails": ["postmaster@dobryops.com"],
                "members": ["dobry"]
              }'

              ensure 'list abuse' '{
                "type": "list",
                "name": "abuse",
                "description": "Abuse (RFC-required)",
                "emails": ["abuse@dobryops.com"],
                "members": ["dobry"]
              }'

              # DKIM signer config — captured from the admin UI's
              # network tab. Posts to /api/settings as an "insert"
              # operation over the `signature.default` prefix. The
              # PEM is decoded from the b64 env var at runtime and
              # jq does proper JSON escaping (newlines → \n).
              echo "Ensuring DKIM signature 'default'..."
              PEM=$(echo "$DKIM_KEY_B64" | base64 -d)
              SIG_BODY=$(jq -nc --arg pem "$PEM" '[{
                type: "insert",
                prefix: "signature.default",
                values: [
                  ["report", "true"],
                  ["headers.0", "From"],
                  ["headers.1", "To"],
                  ["headers.2", "Date"],
                  ["headers.3", "Subject"],
                  ["headers.4", "Message-ID"],
                  ["canonicalization", "relaxed/relaxed"],
                  ["selector", "default"],
                  ["algorithm", "rsa-sha256"],
                  ["domain", "dobryops.com"],
                  ["private-key", $pem]
                ],
                assert_empty: false
              }]')
              SIG_RESP=$(echo "$SIG_BODY" | curl -sS -u "admin:$ADMIN_PASSWORD" \
                -H "Content-Type: application/json" \
                -X POST "$API/settings" -d @-)
              echo "  signer response: $SIG_RESP"

              # Brevo outbound relay route — captured from the UI's
              # network tab. Creates queue.route.brevo so the routing
              # strategy can hand outbound mail to Brevo SMTP relay.
              # Credentials come from sops via env, JSON-escaped by jq.
              echo "Ensuring Brevo relay route..."
              ROUTE_BODY=$(jq -nc --arg user "$BREVO_USER" --arg key "$BREVO_KEY" '[{
                type: "insert",
                prefix: "queue.route.brevo",
                values: [
                  ["address", "smtp-relay.brevo.com"],
                  ["description", "Brevo SMTP relay"],
                  ["auth.username", $user],
                  ["port", "587"],
                  ["auth.secret", $key],
                  ["type", "relay"],
                  ["tls.implicit", "false"],
                  ["protocol", "smtp"],
                  ["tls.allow-invalid-certs", "false"]
                ],
                assert_empty: false
              }]')
              ROUTE_RESP=$(echo "$ROUTE_BODY" | curl -sS -u "admin:$ADMIN_PASSWORD" \
                -H "Content-Type: application/json" \
                -X POST "$API/settings" -d @-)
              echo "  brevo route response: $ROUTE_RESP"

              # Queue strategy — captured payload routes all non-local
              # recipients via the 'brevo' route. The schedule + tls +
              # connection blocks are unchanged from Stalwart's defaults.
              echo "Ensuring queue strategy (route via brevo)..."
              STRATEGY_RESP=$(curl -sS -u "admin:$ADMIN_PASSWORD" \
                -H "Content-Type: application/json" \
                -X POST "$API/settings" \
                -d '[{"type":"insert","prefix":null,"values":[
                  ["queue.strategy.tls.0.if","retry_num > 0 && last_error == '"'"'tls'"'"'"],
                  ["queue.strategy.tls.0.then","'"'"'invalid-tls'"'"'"],
                  ["queue.strategy.tls.1.else","'"'"'default'"'"'"],
                  ["queue.strategy.connection","'"'"'default'"'"'"],
                  ["queue.strategy.schedule.0.if","is_local_domain('"'"'*'"'"', rcpt_domain)"],
                  ["queue.strategy.schedule.0.then","'"'"'local'"'"'"],
                  ["queue.strategy.schedule.1.if","source == '"'"'dsn'"'"'"],
                  ["queue.strategy.schedule.1.then","'"'"'dsn'"'"'"],
                  ["queue.strategy.schedule.2.if","source == '"'"'report'"'"'"],
                  ["queue.strategy.schedule.2.then","'"'"'report'"'"'"],
                  ["queue.strategy.schedule.3.else","'"'"'remote'"'"'"],
                  ["queue.strategy.route.0.if","is_local_domain('"'"'*'"'"', rcpt_domain)"],
                  ["queue.strategy.route.0.then","'"'"'local'"'"'"],
                  ["queue.strategy.route.1.else","'"'"'brevo'"'"'"]
                ],"assert_empty":false}]')
              echo "  strategy response: $STRATEGY_RESP"

              # DKIM signing: disabled. Brevo signs all relayed mail with
              # its own brevo1/brevo2 selectors, which authenticate our
              # domain end-to-end. Local signing would add a header.s=default
              # signature, but Brevo modifies the body afterward (adds
              # List-Unsubscribe etc.) which invalidates the body hash —
              # receivers see `dkim=neutral` for our local sig, which is
              # cosmetic noise. Easier to skip local signing entirely.
              #
              # The [signature.default] block in config.toml and the
              # signature created via the API are still present (harmless,
              # unused) — keep them in case we ever want to re-enable
              # for a future non-Brevo path.
              echo "Ensuring DKIM auth config (signing off, verification relaxed)..."
              RULE_RESP=$(curl -sS -u "admin:$ADMIN_PASSWORD" \
                -H "Content-Type: application/json" \
                -X POST "$API/settings" \
                -d '[
                  {"type":"clear","prefix":"auth.dkim.verify."},
                  {"type":"clear","prefix":"auth.dkim.sign."},
                  {"type":"delete","keys":["auth.dkim.verify","auth.dkim.sign"]},
                  {"type":"insert","prefix":null,"values":[
                    ["auth.dkim.strict","true"],
                    ["auth.dkim.sign","false"],
                    ["auth.dkim.verify","relaxed"]
                  ],"assert_empty":false}
                ]')
              echo "  dkim-config response: $RULE_RESP"

              # Allowlist the cluster gateway IP so kube-proxy's SNAT
              # source doesn't get caught by Stalwart's brute-force
              # detector. Without this, every connection from outside
              # the cluster looks like it's coming from 10.42.0.1, and
              # routine IMAP/SMTP retries trip auto-ban → all of the
              # internet gets locked out at once.
              #
              # Also raise the auto-ban thresholds. Defaults are tuned
              # for "one client per IP" but we have all clients sharing
              # one IP (10.42.0.1) because of kube-proxy externalIPs.
              # Proper fix later: PROXY protocol on Traefik → Stalwart
              # so the real source IP is preserved.
              echo "Ensuring cluster-gateway IP allowlist + raised auto-ban thresholds..."
              SECURITY_RESP=$(curl -sS -u "admin:$ADMIN_PASSWORD" \
                -H "Content-Type: application/json" \
                -X POST "$API/settings" \
                -d '[{"type":"insert","prefix":null,"values":[
                  ["server.allowed-ip.10.42.0.1",""],
                  ["server.allowed-ip.10.42.0.0/16",""],
                  ["server.auto-ban.auth.rate","1000/1h"],
                  ["server.auto-ban.abuse.rate","500/1d"],
                  ["server.auto-ban.loiter.rate","500/1h"],
                  ["server.auto-ban.scan.rate","200/1d"]
                ],"assert_empty":false}]')
              echo "  security response: $SECURITY_RESP"

              echo "Bootstrap complete."
            ''
          ];
          env = [
            {
              name = "ADMIN_PASSWORD";
              valueFrom.secretKeyRef = {
                name = "stalwart-bootstrap-creds";
                key  = "admin_password";
              };
            }
            {
              name = "DOBRY_PASSWORD";
              valueFrom.secretKeyRef = {
                name = "stalwart-bootstrap-creds";
                key  = "dobry_password";
              };
            }
            {
              name = "DKIM_KEY_B64";
              valueFrom.secretKeyRef = {
                name = "stalwart-bootstrap-creds";
                key  = "dkim_private_key_b64";
              };
            }
            {
              name = "BREVO_USER";
              valueFrom.secretKeyRef = {
                name = "stalwart-bootstrap-creds";
                key  = "brevo_smtp_user";
              };
            }
            {
              name = "BREVO_KEY";
              valueFrom.secretKeyRef = {
                name = "stalwart-bootstrap-creds";
                key  = "brevo_smtp_key";
              };
            }
          ];
          resources = {
            requests = { cpu = "10m";  memory = "32Mi"; };
            limits   = { cpu = "200m"; memory = "64Mi"; };
          };
        }];
      };
    };
  };
}
