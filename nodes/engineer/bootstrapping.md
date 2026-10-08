# Engineer node — bootstrapping

This runbook covers the out-of-band Pangolin Basic WireGuard site and integration
API credential. It describes the current module interface, not an unimplemented
migration plan. For disk installation and SSH/SOPS key staging, use the
[README setup](../../README.md#quick-start); for data recovery, see
[mutable state](../../docs/project-context.md#mutable-state-and-recovery).

Do not recreate an existing site during a routine rebuild. Preserve its identity,
Pangolin database, and credentials. Site creation, credential rotation, and host
activation are operator actions, not safe documentation checks.

## 1. Provision or recover the Basic WireGuard site

1. In the managed Pangolin organization, recover the existing `engineer-kernel`
   site or create a Basic WireGuard site for a genuinely new installation.
   Generate/store the client private key securely; give Pangolin only its public
   key. Record the site ID, assigned tunnel CIDR, Gerbil public key, endpoint,
   and allowed peer routes.
2. Create an integration API key with permission to update the organization's
   blueprint. Store its `<key_id>.<key_secret>` value securely. The current client
   uses the integration endpoint `https://api.dobryops.com`, **not** a guessed
   dashboard API path.
3. Keep these values in the corresponding Bitwarden notes and synchronize them
   into SOPS using the [secrets workflow](../../nix/apps/secrets.nix). The required
   secret paths are:

   ```text
   pangolin/instances/engineer-kernel/wg_private_key
   pangolin/instances/engineer-kernel/site_id
   pangolin/api-keys/blueprint-sync
   ```

   These are nested YAML keys in `secrets/secrets.yaml`, not literal slash-named
   keys. Do not put private keys or API credentials in a Nix expression, shell
   history, documentation, or a graph export. If editing SOPS directly, reconcile
   the Bitwarden source before a later `pull`/`sync` can overwrite that edit.

## 2. Match the checked-in client configuration

[`pangolin-kwg.nix`](pangolin-kwg.nix) is already imported by
[`default.nix`](default.nix). Compare the issued site values with that file rather
than adding a second configuration:

- Organization and integration endpoint belong under
  `services.pangolin-kwg.blueprintSync.{orgId,endpoint}`.
- `site.privateKeySopsPath` and `site.siteIdSopsPath` point to the two site secrets.
- `site.peerPublicKey`, `endpoint`, `address`, and `allowedIPs` describe the actual
  peer. Current tunnel address: `100.89.128.16/30`; allowed peer:
  `100.89.128.1/32`; UDP listen port: `51820`; keepalive: `5` seconds.
- The shared [module](../../infrastructure/pangolin-kwg/default.nix) supplies MTU
  `1280`. Keep it aligned with the VPS tunnel configuration.
- Kubernetes backends use Service `externalIPs` on the tunnel IP and distinct
  ports; engineer SSH/k3s API bind directly. `natRules.heavy_ssh` forwards tunnel
  TCP `2224` to the heavy workstation at `192.168.1.5:22`. The
  [NAT module](../../infrastructure/pangolin-kwg/nat.nix) supplies DNAT,
  masquerading for return traffic, and forwarding/MSS handling.

If the assigned tunnel address changes, trace every reference before deploying:

```bash
rg -n '100\.89\.128\.16|viaKernelWg|targetPort|externalIPs' nodes common workloads infrastructure
```

The blueprint renderer rewrites target **hostnames**, not target ports. Update
Service ports and resource ports together; no two backends may claim the same
`(externalIP, protocol, port)` tuple. Check LAN IP allocation/routing separately
against [`metallb.nix`](metallb.nix); L2 advertisement does not configure the router.

## 3. Deploy and verify

After reviewing keys, node target, and configuration changes, from the repo's dev
shell:

```bash
nix run .#deploy -- update engineer-local
```

On `engineer`, inspect without printing secret files:

```bash
sudo wg show pangolin-kwg
sudo systemctl --no-pager status wg-quick-pangolin-kwg.service pangolin-kwg-blueprint-sync.service
sudo journalctl -u pangolin-kwg-blueprint-sync.service -n 50 --no-pager
```

Confirm a recent handshake after traffic, a successful blueprint oneshot, and an
expected application response through the intended access path. An HTTP redirect
to SSO alone does not prove backend health. A successful NixOS activation alone
does not prove blueprint publication: the activation restart is best-effort.

[`blueprint.nix`](../../infrastructure/pangolin-kwg/blueprint.nix) converts the
rendered YAML to JSON, base64-encodes it, and PUTs it to
`<blueprintSync.endpoint>/v1/org/<orgId>/blueprint`. That endpoint replaces the
**entire organization blueprint**. Do not test it with a partial resource payload
against the real organization. The CI-managed Newt ConfigMap flow remains a
separate publication path.

Pangolin 1.24 includes Basic WG peers in Gerbil's configuration, so the old
`gerbil-basic-wg-reconcile.service` workaround is no longer needed. If peers
disappear after a VPS Gerbil restart, inspect Pangolin/Gerbil logs and the kernel
peer state before replacing keys or sites.

## Heavy workstation SSH

The separate `heavy_ssh` resource preserves engineer's management SSH endpoint.
Both public SSH resources default to **disabled**; enable them manually in
Pangolin only when needed. Blueprint synchronization resets them to disabled.
Local engineer SSH is unaffected.

```text
pangolin.dobryops.com:2224 -> engineer 100.89.128.16:2224 -> heavy 192.168.1.5:22
```

Keep heavy's LAN address static/reserved and authorize the client's SSH key on
heavy. This raw TCP resource does not use Pangolin browser SSO; SSH authentication
and the host-key fingerprint belong to heavy. Masquerading makes heavy see
engineer's LAN address, so source-IP-based bans can block every forwarded client.

The encrypted `pangolin/resources/heavy_ssh/port` value must be the string
`"2224"`, not the number `2224`; `sops-nix` does not install numeric secret leaves.
Keep the Bitwarden `pangolin` note in sync before the next secrets `pull`/`sync`.

Check configuration without decrypting secrets or contacting hosts:

```bash
nix eval --offline --impure --file nix/apps/check-heavy-ssh.nix
```

When deployment is authorized, rebuild engineer and the VPS, allow TCP `2224` in
any provider firewall, and confirm full blueprint synchronization succeeded.
Manually enable the two SSH resources in Pangolin for testing, verify heavy's
host-key fingerprint before accepting the new endpoint, then run:

```bash
ssh -p 2224 heavy@pangolin.dobryops.com 'test "$(hostname)" = heavy'
ssh engineer-remote hostname
```

Both checks must pass while enabled; disable the resources again afterward. Do
not repoint `engineer_ssh` to heavy. Also check existing public applications after
activating the NAT rules.

## Rotating the integration API key

1. Create a replacement key; keep the old one valid during the transition where
   possible.
2. Update `pangolin/api-keys/blueprint-sync` in the secure source and synchronize
   the encrypted file. Do not include the credential in a commit message.
3. Rebuild engineer and verify the sync service and affected resources as above.
4. Revoke the old key after the replacement works. If immediate revocation is
   required by an incident, expect sync downtime until the replacement is deployed.
