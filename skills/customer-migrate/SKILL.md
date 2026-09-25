---
name: customer-migrate
description: Conversational driver for end-to-end customer-domain website migrations on the WebEngine fleet — scaffolds the site, runs the convert/deploy pipeline, generates registrar-tailored DNS instructions, drafts customer emails, and pauses for human-in-the-loop approvals.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: "<slug> [--domain ...] | resume | status"
---

# /customer-migrate — Customer-Domain Website Migration

Drive an end-to-end customer-domain migration conversationally. This skill wraps `webengine customer-migrate` (the bash orchestrator) and `tools/registrar-detect.sh`, plus reads/writes `sites/<slug>/site.yaml` for state. The skill's job is the **human-in-the-loop layer** — drafting customer emails, deciding when to pause for customer responses, and recovering from common mid-flow snags.

> Full procedure: `docs/manuals/CUSTOMER-MIGRATION.md`
> Email templates: `docs/manuals/CUSTOMER-EMAIL-TEMPLATES.md`
> Strategic context: `CLAUDE.md` § "Customer-domain migrations"

## Trigger

User invokes `/customer-migrate` with one of these argument shapes:

| Shape | Example | Purpose |
|-------|---------|---------|
| `<slug> --domain <d>` | `/customer-migrate inspiration-martial-arts --domain tryinspirationmartialarts.com` | New migration kickoff |
| `<slug>` (existing site) | `/customer-migrate inspiration-martial-arts` | Resume — read state, continue from current phase |
| `<slug> status` | `/customer-migrate inspiration-martial-arts status` | Just print current phase, no action |
| `<slug> --phase <p>` | `/customer-migrate inspiration-martial-arts --phase ssl-primary` | Run only one phase |

Or invoked without args: list any in-flight customer migrations and ask which to continue.

## Phase 0 — Orient

Before doing anything:

1. **Confirm the working directory.** This skill only works inside the `webengine` repo. `pwd` should end in `repos/webengine`. If not, abort with "this skill must be run from the webengine repo root".
2. **Read `docs/manuals/CUSTOMER-MIGRATION.md` for the seven-step flow.** Keep it open mentally — every action you take should map to one of those steps.
3. **Read `docs/manuals/CUSTOMER-EMAIL-TEMPLATES.md` once.** When the flow needs an email, you draft it from the matching template, filling in real customer data.

## Phase 1 — Determine state

Given a `<slug>`, check `sites/<slug>/site.yaml` and report current phase:

```bash
SITE_YAML="sites/${slug}/site.yaml"
[[ -f "${SITE_YAML}" ]] || echo "NEW MIGRATION (no site.yaml yet)"

# Read these fields (yq):
# .domain             — primary domain
# .aliases[]          — shadow URL(s)
# .server             — should be "97astro1"
# .converted.timestamp
# .deployed.timestamp
# .ssl_shadow.status
# .ssl.status
```

Map to a phase:

| State | Current phase | Next action |
|-------|--------------|-------------|
| no site.yaml | _start_ | Phase 2 — kickoff |
| site.yaml exists, no `.converted` | scaffold done | Run `convert` |
| `.converted` set, no `.deployed` | converted | Run `deploy-shadow` |
| `.deployed` set, no `.ssl_shadow.status` | deployed | Run `ssl-shadow` |
| `.ssl_shadow.status == active`, no `.ssl.status` | shadow live | **Pause for customer** — preview then DNS |
| `.ssl.status == active` | live | Smoke test, send go-live email, monitor |

Tell the user: "You're at phase **X**. Recommended next action is **Y**. Proceed?"

## Phase 2 — Kickoff (new migration)

When the user is starting fresh:

1. **Gather inputs conversationally** if not provided in args:
   - Customer brand slug (lowercase, hyphens — confirm spelling)
   - Customer's primary domain
   - Source URL (default to `https://<domain>/`)
   - Source type (wordpress / webflow / clone)
   - Shadow alias (default `<slug>.membies.com`)

2. **Critical kickoff question:** "Where does the customer's email for `<domain>` live today?" If the same provider as their current website, flag this — it might break under naive A-record-only migration. Recommend the operator follow up with the customer before proceeding.

3. **Confirm the plan in plain English** before running anything: "OK, I'll scaffold a new site at `sites/<slug>/` with:
   - Primary domain: `<domain>`
   - Shadow URL: `<shadow>`
   - Server: 97astro1
   - Source: `<source-url>` (`<type>`)
   - Template: core1 (the default — see CLAUDE.md for when to override with clone)

   Proceed?"

4. **Run the orchestrator** with the gathered inputs:

```bash
webengine customer-migrate <slug> \
  --domain <domain> \
  --source-url <source-url> \
  --source-type <type> \
  --shadow <shadow>
```

This will run scaffold + convert + deploy-shadow + ssl-shadow, then pause for customer preview.

## Phase 3 — Customer preview

When the orchestrator pauses for customer approval (after shadow URL is live):

1. **Draft the preview email.** Fill in `docs/manuals/CUSTOMER-EMAIL-TEMPLATES.md` § "Preview ready, request cutover window" with the actual customer name, brand, slug, domain. Show the draft to the operator. Never send email yourself — the operator copies the draft into their email client.

2. **Wait.** Don't loop, don't poll. The next time the operator invokes this skill (`/customer-migrate <slug>`), continue from there.

3. **When the operator returns** with "customer approved":
   - Confirm the cutover window the customer agreed to
   - Then proceed to Phase 4

## Phase 4 — DNS instructions

1. **Generate the registrar-tailored instructions:**

```bash
webengine customer-migrate <slug> --phase instructions
```

This wraps `tools/registrar-detect.sh` and prints click-by-click instructions for the customer's specific registrar (GoDaddy/Namecheap/Cloudflare/Route 53/Squarespace/etc.).

2. **Draft the DNS-change email.** Fill in `docs/manuals/CUSTOMER-EMAIL-TEMPLATES.md` § "DNS change instructions" with the registrar-detect output pasted into the marked block. Show the operator the full draft.

3. **Wait again.** This is the second human-in-the-loop pause — customer pushes the change at their registrar, then replies.

## Phase 5 — DNS propagation watch

When the operator returns with "customer pushed DNS":

1. **Verify propagation:**

```bash
dig +short <domain> @8.8.8.8
# Expect: 149.28.37.145 (97astro1)
```

2. **If propagation incomplete** (resolves to old IP or empty), tell the operator:
   - Most propagation takes 5 min - 4 hours
   - Some registrars + DNSSEC setups take longer
   - Don't panic, don't have the customer make further changes
   - Try again in 30-60 min

   Optionally draft `docs/manuals/CUSTOMER-EMAIL-TEMPLATES.md` § "DNS propagation taking longer than expected" if it's been >4h.

3. **When propagation is good**, proceed to Phase 6.

## Phase 6 — Issue SSL + go live

```bash
webengine customer-migrate <slug> --phase ssl-primary
webengine customer-migrate <slug> --phase smoke
```

If `ssl-primary` fails:
- Most likely cause: DNS not yet propagated to where Let's Encrypt's validation server queries. Retry in 30 min.
- Other cause: rate limit (50 certs/domain/week — unlikely for a single customer domain unless we've been retrying a lot).
- Other cause: customer has CAA records that don't allow Let's Encrypt. Tell the operator to ask the customer to add `0 issue "letsencrypt.org"` to their DNS, or remove existing restrictive CAA.

## Phase 7 — Go-live communication

After smoke tests pass:

1. **Draft the go-live email.** Fill in `docs/manuals/CUSTOMER-EMAIL-TEMPLATES.md` § "Site is live" with customer-specific data.

2. **Recommend 24h monitoring:**
   - `webengine health <slug>` — daily
   - Watch for any customer reports of breakage
   - Verify forms/integrations actually fire (often the operator skips this and finds out a week later)

## Recovery / troubleshooting

If something goes wrong mid-flow, this skill should help diagnose:

| Symptom | Diagnosis | Fix |
|---------|-----------|-----|
| Convert fails on Webflow source | Mapper extractor missing fields | Run `webengine convert <slug>` manually with `--force`; iterate on `lib/agent/core1_mapper_wp.py` (see `docs/key_findings/20260427-1115-try2-core1-webflow-design-panel.md` for what to look for) |
| Deploy fails: rsync permission denied | SSH key not loaded for 97astro1 | Verify `~/.ssh/webengine_deploy` exists, `ssh deploy@149.28.37.145 'echo ok'` succeeds |
| `ssl-shadow` fails: "challenge failed" | DNS for shadow URL hasn't propagated to LE validators | Wait 5-10 min, retry. Confirm with `dig <shadow> @8.8.8.8` |
| `ssl-primary` fails: HTTP 403 on validation | nginx vhost doesn't include the primary domain in `server_name` | Run `webengine nginx-sync 97astro1` to regenerate from the now-updated site.yaml |
| Customer says site looks broken post-cutover | Either rendering bug we missed or DNS lag for some visitors | Check `https://<domain>/` from multiple resolvers (8.8.8.8, 1.1.1.1, customer's ISP). If only some see breakage, it's DNS lag — wait. If all see it, draft `docs/manuals/CUSTOMER-EMAIL-TEMPLATES.md` § "Issue post-cutover (rollback notice)" and have the customer revert their A record while we fix |

## What this skill does NOT do

- **Send email.** The skill drafts emails for the operator to copy into their actual email client. We don't have customer email addresses on the system.
- **Provision infrastructure.** 97astro1 already exists. If it's full (>30 sites), the operator decides whether to scale up the existing box, provision 97astro2, or pause migrations — that's a strategic call, not a skill action.
- **Run the design panel.** If the converted site looks bad, suggest the operator invoke `/design-panel sites/<slug>/dist/index.html` separately and fix whatever it surfaces.
- **Make the cutover decision.** The operator and customer agree on a cutover window. The skill never auto-pushes anything that visibly impacts the customer's domain without explicit confirmation.

## Conversational style

When driving the flow:

- **Be concrete.** Always show the operator what you're about to run before running it.
- **Be patient.** The flow takes hours-to-days end-to-end (most of that waiting on customer responses). Don't act like every invocation should be a full sprint.
- **Be honest about uncertainty.** "DNS propagation usually takes <1h but can take up to 24h" is better than a confident "should be done soon".
- **Stay in operator-voice for emails.** Drafts are first-person from the operator, not "we at WebEngine" or "your migration team". The operator-customer relationship is personal, not corporate.

## Files this skill reads/writes

| File | Mode | Purpose |
|------|------|---------|
| `sites/<slug>/site.yaml` | read+write | State (current phase tracked here) |
| `docs/manuals/CUSTOMER-MIGRATION.md` | read | The runbook |
| `docs/manuals/CUSTOMER-EMAIL-TEMPLATES.md` | read | Email template source |
| `tools/registrar-detect.sh` | invoke (via orchestrator) | DNS instructions |
| `bin/webengine customer-migrate ...` | invoke | Phase execution |

The skill never edits `lib/`, `docs/manuals/`, or other repo files. State lives in `site.yaml`.
