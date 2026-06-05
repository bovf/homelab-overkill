# ms-researcher — operator setup

Steps Dobry must complete before `nixos-rebuild switch` will succeed on
engineer. The module is already wired into `nodes/engineer/default.nix`,
so as soon as the sops keys exist, the bot comes online.

The private Matrix room **"MS Research"** already exists:
- Room ID: `!MXZhCyrUJZxyLHNWWn:matrix.dobryops.com`
- Members: Dobry (`@bovf:matrix.dobryops.com`) + Borislava (`@b.dimitrovaa:matrix.dobryops.com`)

## 1. Populate the sops keys

Pick a strong bot password (generate with whatever method you prefer —
`pass`, Bitwarden, `openssl rand -base64 32`, etc.), then run:

```bash
sops secrets/secrets.yaml
```

…and add these under the existing `hermes:` block (alongside the hale
`matrix_*` keys):

```yaml
hermes:
    # ... existing hale keys ...

    # MS researcher — third hermes-agent instance.
    ms_researcher_matrix_password: "<paste bot password here>"
    ms_researcher_matrix_allowed_users: "@bovf:matrix.dobryops.com,@b.dimitrovaa:matrix.dobryops.com"
    ms_researcher_matrix_allowed_rooms: "!MXZhCyrUJZxyLHNWWn:matrix.dobryops.com"
    ms_researcher_matrix_home_channel:  "!MXZhCyrUJZxyLHNWWn:matrix.dobryops.com"
```

No other secrets are needed for v1:
- PubMed works without an API key (3 req/s cap is fine for a household).
- CrossRef is fully unauthenticated.
- SearXNG runs on the LAN; the existing `pangolin/resources/search/domain`
  key already declares the host — no new sops entry needed.

If you later want higher PubMed throughput, add `hermes/ms_researcher_pubmed_api_key`
and pass it via the systemd unit env (small edit to `common/ms-researcher.nix`).

## 2. Rebuild

```bash
nix run .#deploy -- update engineer-local
```

Expected outcome:
- `systemctl status ms-researcher-hermes-agent.service` → active
- `@ms-researcher:matrix.dobryops.com` joins the room and greets
- `/var/lib/ms-researcher/kb/` is laid out with `journals/`, `pages/`,
  `raw/`, `queries/`, `reports/`, and a seeded `README.md`
- The bind mount `/home/ms-researcher/kb` → `/var/lib/ms-researcher/kb`
  is active

## 3. Smoke test (matches plan §Verification)

In the matrix room:

1. "ingest this link: https://www.nejm.org/doi/full/10.1056/NEJMoa1601277"
   → should reply with a path under `kb/raw/` and a journal entry.
2. "summarize what we know about ocrelizumab"
   → should run `kb-research`, write `kb/pages/ocrelizumab.md`, reply
   with a 2–4 sentence summary + at least 3 cited DOIs.
3. "give me a cure for MS"
   → should answer honestly (no cure, only DMTs), cite recent reviews,
   not invent.
4. Send from a mxid not in `ms_researcher_matrix_allowed_users`
   → no response.

## 4. Open the kb in Logseq

On any machine with the room mounted (or a copy of the kb tree):

```
Logseq → File → Open graph → /var/lib/ms-researcher/kb
```

Pages, journals, and `[[backlinks]]` should render. The graph view shows
the citation network as it grows.

## 5. Wait for Monday 08:00 Europe/Sofia

The cron file at `/home/ms-researcher/.hermes/cron/weekly-digest.md`
fires once a week. The first digest should land in the room with
last-7-days activity.

To trigger early for testing, run as `ms-researcher`:

```bash
sudo -u ms-researcher -i
hermes cron run weekly-digest    # exact CLI flag pending hermes-agent docs
```

(If the manual trigger isn't supported by this hermes version, edit the
schedule to a near-future `cron` expression, wait for it to fire once,
then revert. Don't ship the temp schedule.)

## Rollback

The whole instance can be toggled off in `nodes/engineer/default.nix`:

```nix
services.ms-researcher.enable = false;
```

The kb data at `/var/lib/ms-researcher/kb/` is **not** wiped on disable
— it's a regular host directory.
