# Engineer node — bootstrapping

One-time setup that can't be expressed declaratively in nix because the
upstream (pangolin admin UI, sops) is out-of-band. Re-run only when a
fresh install of the engineer node is needed.

## 1. Pangolin kernel-WG site (Stage 0 of `infrastructure/pangolin-kwg`)

These steps mint the Basic WireGuard site and the Integration API key
that `services.pangolin-kwg` needs. See
`infrastructure/pangolin-kwg/PLAN.md` for the full plan.

### 1.1 Stage 0 investigation (do this on a throwaway site first)

Before touching real configuration, validate against pangolin v1.17.1:

1. **Throwaway Basic WG site.** Pangolin UI → Sites → Create Site → choose
   "Basic WireGuard". Capture the issued config: gerbil's peer pubkey,
   endpoint host:port, the address assigned inside the tunnel, and the
   AllowedIPs to install on the client. Record verbatim.
2. **Per-resource tunnel port allocation.** Add a test TCP resource bound
   to the throwaway site (e.g. `proxy-port: 12345`). With `wg-quick up`
   on a sacrificial machine using the issued config, tcpdump the wg
   interface and `curl localhost:12345` from the VPS shell. Confirm what
   (dst IP, dst port) pangolin actually writes inside the tunnel for that
   resource. This drives the natRules shape.
3. **Blueprint REST API.** Settings → Integrations → mint an API key.
   Confirm with curl:
   ```
   curl -X PUT https://pangolin.dobryops.com/api/v1/org/<orgId>/blueprint \
     -H "Authorization: Bearer <key_id>.<key_secret>" \
     -H "Content-Type: application/json" \
     -d '{"blueprint":"<base64-encoded-yaml>"}'
   ```
   Expect 2xx. Re-PUT the same payload — should be idempotent. Test a
   garbage payload — record the error format.
4. **Free LAN IP range** (only if pursuing axis B). Pick a non-DHCP
   range, e.g. `192.168.1.200/29`. Confirm the home router won't fight
   ARP announcements for those IPs.

Tear down the throwaway site, test resource, and API key. Save findings
to `nodes/engineer/pangolin-kwg-investigation.md`.

### 1.2 Real site provisioning

Once Stage 0 is settled and the natRules format is known:

1. **Generate the host's WG keypair on engineer:**
   ```
   sudo install -d -m 0700 /root/wg-bootstrap
   sudo sh -c 'wg genkey | tee /root/wg-bootstrap/privatekey | wg pubkey > /root/wg-bootstrap/publickey'
   sudo cat /root/wg-bootstrap/publickey
   ```
   (Copy the pubkey somewhere; you'll paste it into the pangolin UI.)
2. **Pangolin UI → Sites → Create Site → Basic WireGuard.**
   - Name: `engineer-kernel`
   - Client Public Key: paste the pubkey from step 1
   - Capture the issued values: gerbil pubkey, endpoint, tunnel address, AllowedIPs.
3. **Pangolin UI → Settings → Integrations.** Create an API key for
   blueprint sync. Capture as `<key_id>.<key_secret>`.
4. **`sops edit secrets/secrets.yaml`** and add:
   ```yaml
   pangolin:
     api-keys:
       blueprint-sync: <key_id>.<key_secret>
     instances:
       engineer-kernel:
         wg_private_key: |
           <contents of /root/wg-bootstrap/privatekey>
         peer_pubkey: <gerbil's pubkey>
         endpoint: <gerbil-host:port>
         address: <assigned-tunnel-CIDR>
         allowed_ips: <space-or-newline-separated CIDRs>
   ```
5. **Shred the temporary key files:**
   ```
   sudo shred -u /root/wg-bootstrap/privatekey
   sudo rm -rf /root/wg-bootstrap
   ```
6. **Add `services.pangolin-kwg` config** by importing `./pangolin-kwg.nix`
   from `nodes/engineer/default.nix`. The file should look roughly like:
   ```nix
   { config, ... }: {
     services.pangolin-kwg = {
       enable   = true;
       orgId    = "<orgId from pangolin URL>";
       endpoint = "https://pangolin.dobryops.com";
       instance = "engineer-kernel";
       site = {
         privateKeySopsPath = "pangolin/instances/engineer-kernel/wg_private_key";
         peerPublicKey      = "<paste pubkey>";
         endpoint           = "<paste endpoint>";
         address            = [ "<paste CIDR>" ];
         allowedIPs         = [ "<paste CIDRs>" ];
       };
       # natRules populated from Stage 0 findings
       natRules = {
         # example, replace once Stage 0 confirms the actual listenPort:
         # traefik_dashboard = { listenPort = 12345; target = "traefik-dashboard.kube-system.svc.cluster.local:8080"; };
       };
     };
   }
   ```
7. **Rebuild:** `deploy engineer` (or however your flow runs nixos-rebuild).
   Verify:
   - `wg show pangolin-kwg` shows the peer + recent handshake.
   - `systemctl status pangolin-kwg-blueprint-sync` → `active (exited)`.
   - `nft list table inet pangolin-kwg` → DNAT chain visible.

### 1.3 First per-resource migration

Pick a low-stakes resource (e.g. `traefik_dashboard`) and flip
`viaKernelWg = true` in its `pangolin-blueprint.nix`. Rebuild. The
existing newt blueprint loses the entry, the kwg path picks it up, and
the resource binds to `engineer-kernel` in pangolin. Verify the URL still
loads.

## Rotating the Integration API key

1. Pangolin UI → Settings → Integrations → revoke + recreate.
2. `sops edit secrets/secrets.yaml` → update
   `pangolin/api-keys/blueprint-sync`.
3. Rebuild — `pangolin-kwg-blueprint-sync.service` re-runs with the new key.
