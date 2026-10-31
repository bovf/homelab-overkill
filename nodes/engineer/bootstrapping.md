# Engineer WireGuard setup

[Operations](../../docs/operations.md) · [Network map](../../docs/project-context.md#network-paths)

Use this for a **new/recovered Basic WireGuard site**, not a routine rebuild.
Disk installation and SSH/SOPS staging are in the operations guide. Preserve
Pangolin's database, site identity and keys; do not recreate a working site to
troubleshoot a tunnel.

## 1. Provision the site and API key

In the Pangolin organization:

1. Recover `engineer-kernel`, or create a Basic WireGuard site for a genuinely
   new installation. Store its client private key securely; give Pangolin only
   the public key. Record site ID, tunnel CIDR, Gerbil public key and endpoint.
2. Create an integration key permitted to update the organization's blueprint.
   Attic's post-sync repair also needs `listResources`, `listTargets` and
   `updateTarget`. The current endpoint is `https://api.dobryops.com`, not a
   guessed dashboard API path.
3. Put credentials in the corresponding Bitwarden notes and synchronize to SOPS:

   ```text
   pangolin/instances/engineer-kernel/wg_private_key
   pangolin/instances/engineer-kernel/site_id
   pangolin/api-keys/blueprint-sync
   ```

These are nested YAML paths, not literal slash-named keys. Store the API token
as `<key_id>.<key_secret>`. Keep private values out of Nix, shell history and
logs. Reconcile direct SOPS edits back into Bitwarden before the next pull/sync.

## 2. Match the client configuration

Compare the issued values with [`pangolin-kwg.nix`](pangolin-kwg.nix):
`blueprintSync.{orgId,endpoint}` and `site.{privateKeySopsPath,siteIdSopsPath,
peerPublicKey,endpoint,address,allowedIPs,listenPort,persistentKeepalive}`.
The [shared module](../../infrastructure/pangolin-kwg/default.nix) supplies the
MTU. Keep it aligned with the peer and preserve the MSS/reverse-path handling.

If the tunnel address changes, find every consumer first:

```bash
rg -n '100\.89\.128\.16|viaKernelWg|targetPort|externalIPs' nodes common workloads infrastructure
```

Blueprint rendering rewrites backend hostnames, **not ports**. Each Kubernetes
backend must have a unique `(externalIP, protocol, Service port)` matching its
resource's `targetPort`. Host SSH/k3s listen directly; Heavy SSH uses host DNAT.
MetalLB's LAN pool and router-side routing are separate from the tunnel.

## 3. Deploy and verify

After reviewing keys, backups and the diff, from the operator shell:

```bash
nix run .#deploy -- update engineer-local
```

On Engineer:

```bash
sudo wg show pangolin-kwg
sudo systemctl --no-pager status wg-quick-pangolin-kwg.service pangolin-kwg-blueprint-sync.service
sudo journalctl -u pangolin-kwg-blueprint-sync.service -n 50 --no-pager
```

Confirm a recent handshake after traffic, successful blueprint sync and an actual
backend response. A successful Nix switch or SSO redirect alone is insufficient.
Sync sends base64-encoded JSON to `/v1/org/<orgId>/blueprint`, replacing the **whole
organization blueprint**; never test with a partial production payload. The
activation restart is best-effort. CI Newt has a separate ConfigMap flow.

Current Pangolin handles Basic WG peers upstream. The old
`gerbil-basic-wg-reconcile` service is removed; inspect Pangolin/Gerbil logs and
peer state before replacing keys or restoring that workaround.

## Heavy workstation SSH

[`pangolin-resources.nix`](pangolin-resources.nix) keeps Engineer management SSH
separate from Heavy. Both public SSH resources default to **disabled**. Enable
manually in Pangolin only when needed; startup/rebuild blueprint sync resets them.

```text
Pangolin TCP 2224 → Engineer WG TCP 2224 → Heavy LAN SSH TCP 22
```

Keep Heavy's LAN address reserved and its authorized keys correct. This is raw
TCP, not browser SSO: verify **Heavy's** host-key fingerprint. Masquerading means
Heavy sees Engineer's LAN address; a source-IP ban can block all forwarded clients.
The encrypted `pangolin/resources/heavy_ssh/port` must be the **string** `"2224"`,
not a numeric YAML leaf. Keep the Bitwarden note aligned.

Before deployment, without decrypting secrets or contacting hosts:

```bash
nix eval --offline --no-write-lock-file --impure --file nix/apps/check-heavy-ssh.nix
```

For an approved rollout, deploy Engineer and the VPS, allow TCP 2224 in the
provider firewall, verify whole-org sync, then temporarily enable both SSH
resources. Verify host keys before testing:

```bash
ssh -p 2224 heavy@pangolin.dobryops.com 'test "$(hostname)" = heavy'
ssh engineer-remote hostname
```

Disable the resources afterward. Check existing public apps too; do not repoint
`engineer_ssh` at Heavy or use `engineer-remote` for a reboot.

## Rotate the integration key

Create a replacement with the required permissions; keep the old key valid if
possible. Update Bitwarden/SOPS, deploy Engineer, verify sync and Attic's target
repair, then revoke the old key. Emergency revocation can interrupt sync until
the replacement is deployed. Do not print either credential while diagnosing it.
