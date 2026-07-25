---
name: customer-clone
description: Graduate an already-migrated preview site (on .membies.com or .97demo.com) to live under the customer's real domain on 97astro1. Conversational driver — clones the converted site dir, configures the customer domain + shadow URL, then hands off to /customer-migrate from the deploy-shadow phase.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: "<dest-slug> --from <src-slug> --domain <customer-domain.com>"
---

# /customer-clone — Graduate a preview site to a customer-owned domain

Conversationally drive the **graduation** of an already-converted preview site (currently living at `<src-slug>.membies.com` or `<src-slug>.97demo.com` on server1) to a new site on **97astro1** under the customer's real domain. Wraps the bash subcommand `webengine customer-clone`.

> **Use this when:** A site has been previewing at a fleet URL for a while and the customer has approved going live on their own domain.
>
> **Don't use this when:** Starting a fresh migration from a customer's existing live site — that's `/customer-migrate`. This skill is the *graduation* path, not the *kickoff* path.

> Full procedure: `docs/manuals/CUSTOMER-MIGRATION.md` (graduation section)
> Email templates: `docs/manuals/CUSTOMER-EMAIL-TEMPLATES.md`
> Sister skill: `/customer-migrate` (handles the post-graduation flow this skill hands off to)
> Strategic context: `CLAUDE.md` § "Customer-domain migrations"

## Trigger

| Shape | Example | Purpose |
|-------|---------|---------|
| `<dest-slug> --from <src-slug> --domain <d>` | `/customer-clone customer-brand --from site19-membies --domain customer-brand.com` | Graduate site19-membies to live on customer-brand.com |
| `<dest-slug>` (existing site) | `/customer-clone customer-brand` | Resume — site has already been cloned, continue with customer-migrate handoff |
| `--list` | `/customer-clone --list` | List candidate preview sites available for graduation |

## Phase 0 — Orient

1. **Confirm the working directory** is the webengine repo root (`pwd` ends in `repos/webengine`). If not, abort.
2. **Read `docs/manuals/CUSTOMER-MIGRATION.md`** — the graduation section maps onto Phases 2–5 of this skill. Keep it open mentally.
3. **Confirm the source site exists and is in a graduatable state.** A graduatable source has:
   - `sites/<src-slug>/site.yaml` exists
   - `sites/<src-slug>/site.json` exists (converted)
   - `sites/<src-slug>/dist/` exists (built at least once)
   - Currently deployed to server1 (or wherever the preview lives)
   - `ssl.status: active` so the customer can actually preview at the shadow URL

If any of these are missing, tell the operator: "site `<src-slug>` doesn't look ready to graduate because X. Want to fix that first, or pick a different source?"

## Phase 1 — Confirm intent

Before touching anything:

1. **Show the operator the plan in plain English:**
   > "OK — I'll graduate `<src-slug>` (currently previewing at `<src-slug>.membies.com`) to a new site `<dest-slug>` living on `<customer-domain>` at 97astro1. The new site will get a shadow URL `<dest-slug>.membies.com` for staging review. Source files copy over; dist/ rebuilds fresh on first deploy. Source site stays deployed on server1 — we don't auto-undeploy. Proceed?"

2. **If the operator hasn't provided a slug or domain**, ask:
   - "What slug should the new site use? (lowercase, hyphens — e.g. `customer-brand`)"
   - "What's the customer's primary domain?"
   - Suggest a slug derived from the domain if they haven't provided one (`customer-brand.com` → `customer-brand`).

3. **Sanity check capacity on 97astro1.** The bash subcommand does this too, but warn early:
   ```bash
   # Count current sites assigned to 97astro1
   grep -l "server: \"97astro1\"" sites/*/site.yaml 2>/dev/null | wc -l
   ```
   If close to the `max_sites` ceiling in `config/servers/97astro1.yaml`, surface it.

## Phase 2 — Run the clone

```bash
webengine customer-clone <dest-slug> \
    --from <src-slug> \
    --domain <customer-domain>
```

This will:
1. rsync the source directory excluding `dist/`, `node_modules/`, `.astro/`, `.csp/api_cache/`, and `site.yaml`
2. Generate a fresh `sites/<dest-slug>/site.yaml` with the customer domain, the shadow alias, and `server: "97astro1"`
3. Set `converted.timestamp` so the next phase doesn't re-run convert
4. **Hand off** to `webengine customer-migrate <dest-slug>` automatically — which runs deploy-shadow → ssl-shadow → preview-pause

If you want to inspect the cloned files before the handoff, pass `--no-handoff`:

```bash
webengine customer-clone <dest-slug> --from <src-slug> --domain <customer-domain> --no-handoff
```

## Phase 3 — Customer preview (handed off to customer-migrate)

After the handoff, the orchestrator pauses at the **CUSTOMER PREVIEW PAUSE**. The shadow URL `<dest-slug>.membies.com` is now serving the cloned site on 97astro1.

From here, the flow is identical to a fresh `/customer-migrate`. Switch to that skill's logic:

1. **Draft the preview email.** Use `docs/manuals/CUSTOMER-EMAIL-TEMPLATES.md` § "Preview ready, request cutover window". Customize for the customer.
2. **Wait** for the operator's next invocation.
3. **When the customer approves**, continue with Phase 4 (DNS instructions).

See the `/customer-migrate` skill for full Phase 3–7 details — they are unchanged. From a UX perspective, after the clone + handoff completes, this skill *becomes* `/customer-migrate` for the rest of the flow. The skill should tell the operator that explicitly:

> "Clone complete and handed off to customer-migrate. From here the flow is identical to a fresh customer migration — preview → DNS instructions → propagation watch → SSL primary → go-live email. Run `/customer-migrate <dest-slug>` to continue, or invoke the bash phases directly: `webengine customer-migrate <dest-slug> --phase <phase>`."

## Phase 4 — When NOT to handoff

If the operator wants to inspect or edit the cloned site before deploying (e.g., they want to update copy specifically for the live domain), use `--no-handoff`:

```bash
webengine customer-clone <dest-slug> --from <src-slug> --domain <customer-domain> --no-handoff
```

After they finish editing, they can resume with:
```bash
webengine customer-migrate <dest-slug>
```

The skill should ask before defaulting to `--no-handoff`: "Do you want to make edits to the cloned site before deploying? If yes, I'll skip the auto-handoff."

## Common questions / decisions

### "Should I copy or rebuild dist/?"

The clone deliberately excludes `dist/`. The first `deploy-shadow` rebuilds it. This is intentional — rebuilding catches any environment shifts and ensures the deployed site reflects the current `src/` state, not stale build output. Don't second-guess this; it's a feature.

### "Should I undeploy the source site?"

**No, not automatically.** The clone does *not* touch the source. The source preview at `<src-slug>.membies.com` stays live on server1. Reasons:
- Customer might want to compare the live customer-domain version against the preview during cutover
- We've had cases where DNS rolls back or customer backs out — having the source preview as a fallback saves a re-deploy
- If the source becomes truly orphaned weeks later, the operator can clean it up manually with `webengine prune` or by removing from `config/servers/server1.yaml` and re-running `nginx-sync`

### "What if 97astro1 is full?"

The bash subcommand refuses if `current_sites >= max_sites` on the destination server. Two options:
1. Edit `config/servers/97astro1.yaml` to bump `max_sites` (if there's actual capacity headroom — check disk + ram on the box first)
2. Provision 97astro2 and override `--server 97astro2` (out of scope for this skill — that's a strategic ops call)

### "What if the source has weird state (e.g. failed prior deploy)?"

The clone doesn't care about the source's deployment state — it copies whatever's on disk. If the source was in a half-converted or half-deployed state, those issues come along for the ride. Tell the operator: "I noticed the source has `<state issue>`. Want to fix that on the source first, then graduate? Or proceed and accept that the new site will inherit the same issue?"

## Recovery / troubleshooting

| Symptom | Diagnosis | Fix |
|---------|-----------|-----|
| `customer-clone` aborts with "Destination already exists" | A site with that slug already exists | Pick a different slug, or pass `--force` to wipe and retry |
| Capacity check fails on 97astro1 | Server is at `max_sites` ceiling | See "What if 97astro1 is full?" above |
| Handoff fails at `deploy-shadow` | Build error in cloned src/, or SSH/rsync issue | Inspect `sites/<dest-slug>/dist/` (built locally first), then re-run `webengine customer-migrate <dest-slug> --phase deploy-shadow` |
| Shadow DNS doesn't resolve | Vultr DNS A-record for `<dest-slug>.membies.com` missing | Run `webengine dns <dest-slug> --setup --yes` then retry SSL |
| ssl-shadow validation fails | DNS propagation not done yet | Wait 5–10 min, re-run `--phase ssl-shadow` |
| Customer's domain has CAA records blocking Let's Encrypt | `ssl-primary` fails with "policy denied" | Customer needs to add `0 issue "letsencrypt.org"` CAA record, or remove restrictive CAA |

## What this skill does NOT do

- **Re-convert.** Source-of-truth content is the converted Astro project (`site.json` + `src/`). If the operator wants to re-convert the customer's source URL fresh, they should use `/customer-migrate`, not this skill.
- **Edit the source site.** Source stays on server1 untouched. Two independent deployments now exist.
- **Send email.** Drafts emails for the operator to copy/paste. Same pattern as `/customer-migrate`.
- **Decide cutover timing.** That's an operator + customer agreement. The skill stages the technical readiness; the human decides when to hand the customer DNS instructions.
- **Auto-undeploy or destroy the source.** If the operator decides later that the source preview should go away, that's a separate manual step.

## Files this skill reads/writes

| File | Mode | Purpose |
|------|------|---------|
| `sites/<src-slug>/` | read-only | Source files to clone |
| `sites/<dest-slug>/site.yaml` | write (via bash subcommand) | New site state |
| `sites/<dest-slug>/site.json`, `src/`, `public/`, etc. | write (via rsync) | Cloned content |
| `config/servers/97astro1.yaml` | read | Capacity check |
| `bin/webengine customer-clone …` | invoke | The actual orchestration |
| `bin/webengine customer-migrate …` | invoke (auto-handoff unless `--no-handoff`) | Continues from deploy-shadow onward |

## Conversational style

- **Be concrete about what's about to happen.** Always preview the bash command before running.
- **Be explicit about the handoff.** When the clone completes and customer-migrate takes over, *say so* — don't let the operator wonder which skill they're in.
- **Default to operator-friendly defaults.** Shadow URL = `<dest-slug>.membies.com`, server = 97astro1, handoff = on. Only ask if something differs.
- **When in doubt, recommend `--no-handoff`.** Better to land the clone, let the operator inspect, and explicitly run `/customer-migrate` than to barrel through and surprise them.
