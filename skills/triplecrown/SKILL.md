---
name: triplecrown
description: Merchant legitimacy & fraud investigation for Member Solutions boarding review. Runs WHOIS+DNS+site+registry+brand-authorization+HubSpot cross-checks, tests every benign explanation before naming risk patterns, and renders a 4-page navy/gold PDF verdict (DECLINE / PROCEED WITH CAUTION / LEGITIMATE). Use when a merchant applies for a Member Solutions account, when a boarded merchant needs a routine review, or when a chargeback pattern raises a flag.
user-invocable: true
allowed-tools: Bash, WebFetch, WebSearch, Read, Write, AskUserQuestion, mcp__claude_ai_HubSpot__search_crm_objects, mcp__claude_ai_HubSpot__get_crm_objects
argument-hint: <domain> [--hubspot-id <id>] [--depth quick|standard|exhaustive]
---

# /triplecrown — Merchant deep-dive investigation

> **⚠️ FROZEN as of 2026-07-24.** This is the local **Claude Code** version of the skill. It requires Bash, Python 3.11+, and WeasyPrint installed on the local machine. The **preferred version for all Member Solutions users is now the Claude Desktop skill** — see [`SKILL-desktop.md`](SKILL-desktop.md) and [`docs/DESKTOP-SETUP.md`](docs/DESKTOP-SETUP.md).
>
> This local version stays available as a fallback if the MCP server at `https://triplecrown.membies.com` is unreachable. Bug fixes will be back-ported here; no new features. Full retirement scheduled for 2026-09-22 (60 days after freeze), assuming clean Desktop operation.

Repeatable investigation pattern for evaluating whether a merchant applying to Member Solutions is legitimate, fraudulent, or elevated-risk. Born from three foundational investigations run in July 2026:

- **onemedicalsuppliesinc.com** → DECLINE (identity impersonation of a real Miami DME shop)
- **deeprootsathletics.com** → LEGITIMATE (small BC personal-training studio, one CRM reconciliation)
- **sunficent.com** → PROCEED WITH CAUTION (grey-market nail-polish reseller with a fake NM address)

The skill produces a 4-page navy/gold WeasyPrint PDF at `YYYYMMDD-HHMM-<slug>-merchant-review.pdf` in the current working directory.

Full method: [`docs/METHOD.md`](docs/METHOD.md). Source catalog: [`docs/INGREDIENTS.md`](docs/INGREDIENTS.md). Design system: [`docs/DESIGN.md`](docs/DESIGN.md).

---

## Trigger

User invokes `/triplecrown <domain>` or a description matching:

- "run a deep dive on <domain>"
- "underwriting review for <domain>"
- "is <domain> legit"
- "fraud check on <domain>"
- "same analysis we did on <prior-merchant> but for <new-domain>"

Strip protocol/path if a full URL is passed. Normalize to `example.com` (lowercase, no `www.`).

---

## What this skill produces

A structured 4-page PDF:

1. **Cover** — verdict (DECLINE / PROCEED WITH CAUTION / LEGITIMATE) with color-shifted KPI card, bottom-line paragraph, what-checks-out tick list.
2. **Signal matrix** — every claim the site/CRM makes vs. reality, color-coded (green corroborated, amber reconciliation, red disqualifier).
3. **Why the verdict** — benign explanations tested (all four, in order) followed by ranked risk patterns.
4. **Actions + sources** — recommended underwriting actions, verifiable source list.

Also writes an evidence bundle JSON to `fixtures/<slug>.json` in the triplecrown repo so the report is fully reproducible.

---

## Phases

Announce briefly what you're doing between phases. Do not paste raw command output back to the user. Each phase has a **GATE** — if the gate condition isn't met, follow the recovery instruction and continue.

### Phase 0 — Parse args, ask clarifying questions

Extract the domain. If no domain provided, ask for it. Then use `AskUserQuestion` with the three clarifying questions (reuse this exact set — it's the pattern refined across the three investigations):

**Q1 — Merchant status:** "Is <domain> already in Member Solutions' HubSpot / boarded as a merchant, or is this a cold prospect/applicant?"
- Cold — no HubSpot record
- Applicant under review
- Already boarded — in HubSpot
- I don't know — you check

**Q2 — Angle:** "What's driving this deep dive — what should the report emphasize?"
- Fraud / legitimacy screen (default)
- Onboarding fit assessment
- Competitor / market intel
- You decide from what you find

**Q3 — Depth:** "How much digging should I do before writing the PDF?"
- Standard 4-page report (recommended) — ingredients 1–11 from INGREDIENTS.md
- Quick screen only — ingredients 1–3
- Exhaustive — ingredients 1–18 including gap-fillers

Skip Q1 if `--hubspot-id` was passed. Skip all three if user said "same as before" — reuse defaults.

**GATE:** If the user gave a company id or a link like `https://app.hubspot.com/contacts/9221154/record/0-2/<id>`, extract the id and skip Q1. Recovery: proceed with defaults if the user is impatient.

### Phase 1 — WHOIS + DNS + HTTP fingerprint

One Bash call:

```
/Users/msichris/repos/triplecrown/scripts/whois_dns.sh <domain>
```

Read the output and capture:
- **Domain age** — creation date, expiration, registrar, privacy-shield use
- **Nameservers** — hosting hint (Wix / Squarespace / Cloudflare / Netlify / GoDaddy DNS)
- **MX** — email provider (Microsoft 365 / Google Workspace / Zoho / other)
- **A records** — CDN identification via IP range
- **TXT / SPF / DMARC** — auth posture, verification tokens for other services
- **HTTP headers** — server fingerprint (Wix, Netlify, Squarespace)

**GATE:** If WHOIS is heavily redacted (e.g., `.uk` or `.eu` registries hide most), fall through to Phase 2 and note this in the signals matrix as `whois: privacy-shielded, verification limited`.

### Phase 2 — Site page scrape

WebFetch each of these URLs in parallel (up to 6 at a time — Claude Code will queue):

- `https://<domain>/`
- `https://<domain>/about`
- `https://<domain>/contact`
- `https://<domain>/privacy-policy` (also try `/privacy`)
- `https://<domain>/terms-of-service` (also try `/terms`)
- `https://<domain>/faq`
- `https://<domain>/support`
- `https://<domain>/shipping` (also try `/shipping-returns`)

**Prompt template** (use verbatim for the home page; adjust "extract" list for interior pages):

> Extract: company name, tagline, physical address, phone, email, all named people (founders/staff/team), services/products offered, listed prices or MCC-relevant categories, social links, copyright year, legal/policy links, payment methods, industry/vertical, and any About text. Also note hosting hints if visible (Netlify, Vercel, Squarespace, Wix), any staging URL leaks in meta tags (og:image), and unusual asset filenames.

Also run one Bash to grep the raw HTML for meta tags:

```
curl -sSL -A "Mozilla/5.0" https://<domain>/ | grep -aoiE '(og:[a-z_]+|twitter:[a-z_]+)"[^>]*content="[^"]{0,200}"' | head -20
```

Capture: brand identity, ownership disclosure, staff, ToS language quality (template lift vs. custom), any "monthly billing" or "auto-renewal" clauses, hidden staging URLs.

**GATE:** If the site is entirely 404 or returns a parking page, this alone is a strong DECLINE signal. Recovery: proceed to Phase 3 and note the site is dark.

### Phase 3 — Corporate entity registry lookup

Determine the applicable registry from the claimed address:

| State/Province claimed | Registry URL |
|---|---|
| Florida | `search.sunbiz.org` |
| New Mexico | `enterprise.sos.nm.gov` |
| British Columbia | BC Registry (`corporateonline.gov.bc.ca`) |
| Delaware | `icis.corp.delaware.gov` (paid) |
| Wyoming | `wyobiz.wyo.gov` |
| California | `bizfileonline.sos.ca.gov` |
| New York | `apps.dos.ny.gov` |
| Texas | `mycpa.cpa.state.tx.us/coa` |
| Ontario | `appmybizaccount.gov.on.ca` |

Try WebFetch on the registry search URL. Many state portals **return 403 to automated fetch** — that's expected. Recovery: use WebSearch `"<entity name>" secretary of state <state>` to find a BizProfile.net or OpenCorporates aggregate record.

**GATE:** If entity name doesn't exist in the registry OR the officers/registered address don't match what the site claims → strong impersonation signal, route toward DECLINE. Recovery: note the discrepancy in signals and preserve for page-3 benign-explanations test.

### Phase 4 — Physical address & phone reverse-lookup

Address:
- WebSearch `"<full address>" business` — find who actually operates there.
- WebSearch `"<address>" LoopNet OR Crexi OR SmartCapital` — commercial property record.
- Cross-check against the merchant name.

Phone:
- WebSearch `"<phone number>" business OR scam OR spam`
- Note area code vs. address geography mismatch.

**GATE:** If the address belongs to a totally unrelated business (auto shop for a nail polish site, etc.) → strong CAUTION or DECLINE signal. Recovery: capture the unrelated business's name and phone for the signals matrix; keep going.

### Phase 5 — Brand-authorization check

If the site sells branded goods, check the brand's diversion / authorized-reseller policy. Reference table in `docs/METHOD.md` (OPI, Essie, Zoya, LVMH brands, Nike, Apple, etc.).

For each brand: WebFetch the diversion page, note the policy language, note the brand-protection contact.

**GATE:** If the merchant sells restricted brands and makes no authorized-reseller claim → grey-market risk pattern. Recovery: add a signals row and a risk-pattern entry on page 3.

Skip this phase if the merchant sells services (training studio, consulting) or unbranded/generic goods.

### Phase 6 — Trust scoring & external reviews

- WebFetch `https://www.scamadviser.com/check-website/<domain>` — trust score, WHOIS-owner check, SSL type, Tranco rank.
- WebSearch `"<domain>" reviews trustpilot OR sitejabber OR reddit` — customer reviews.
- WebSearch `"<domain>" -site:<domain> reviews scam OR complaint OR fraud` — negative signals.
- Optional: check BBB search for a business profile.

**GATE:** If ScamAdviser returns a hard-negative flag (score <30) OR the site appears in scam registries → route toward DECLINE.

### Phase 7 — HubSpot pull (if applicable)

If Phase 0 answers indicated already-boarded, or if `--hubspot-id` was provided:

```
mcp__claude_ai_HubSpot__search_crm_objects
  objectType: "companies"
  query: "<domain-or-name>"
  properties: ["name","domain","website","phone","address","city","state","zip","country","industry","lifecyclestage","hs_lead_status","hubspot_owner_id","createdate","hs_lastmodifieddate","founded_year","numberofemployees","num_associated_contacts","num_associated_deals","hs_analytics_source","hs_analytics_source_data_1","hs_analytics_source_data_2"]
```

Then get the full record:

```
mcp__claude_ai_HubSpot__get_crm_objects
  objectType: "companies"
  objectIds: [<id>]
  properties: [...same as above...]
```

Then associated contacts and deals:

```
mcp__claude_ai_HubSpot__search_crm_objects
  objectType: "contacts"
  filterGroups: [{associatedWith: [{objectType: "companies", operator: "EQUAL", objectIdValues: [<id>]}]}]
  properties: ["firstname","lastname","email","phone","jobtitle","lifecyclestage","hs_lead_status","hs_analytics_source","createdate","hubspot_owner_id","num_associated_deals"]
```

```
mcp__claude_ai_HubSpot__search_crm_objects
  objectType: "deals"
  filterGroups: [{associatedWith: [{objectType: "companies", operator: "EQUAL", objectIdValues: [<id>]}]}]
  properties: ["dealname","amount","deal_currency_code","dealstage","pipeline","closedate","createdate","hubspot_owner_id"]
```

Portal is **9221154** (Member Solutions). If the user specified a different portal, override. Always include `deal_currency_code` when pulling `amount` — the HubSpot connector requires the currency pair together.

**GATE:** If the merchant is in HubSpot but on a different portal (97 Display, portal 7126753), confirm with the user before proceeding.

### Phase 8 — Gap-fillers (only if `--depth exhaustive`)

- **Wayback Machine** — `web.archive.org/web/*/<domain>` for historical snapshots. Note: may 403 from some environments.
- **crt.sh** — `https://crt.sh/?q=<domain>&output=json` for SSL cert transparency; look for sibling domains under the same cert.
- **WHOIS-history registrant lookup** — `viewdns.info/whoishistory/?domain=<domain>` for pre-privacy-shield registrant records.
- **Reverse image search** on the hero product photo — Google Lens or `lens.google.com` (manual step; note the recommendation for the analyst).

**GATE:** Skip entirely for `--depth quick` or `--depth standard`. Only run on `--depth exhaustive`.

### Phase 9 — Benign-explanations test

**This is the discipline that keeps verdicts credible.** Rule out each benign explanation in order before naming any risk pattern. Verbatim list from `docs/METHOD.md`:

1. **Rebrand / new e-commerce arm of an existing legitimate business.**
2. **Legitimate new e-commerce arm requiring separate registration.**
3. **Lead-gen, affiliate, or B2B directory site (not merchant of record).**
4. **Small owner-operated drop-shipper with a virtual mailbox.**

For each, write one line about *why the observed evidence weakens or fails* the explanation. If any survives with reasonable strength, verdict cannot be DECLINE — force CAUTION or LEGITIMATE.

**GATE:** If you name a risk pattern before completing this test, stop and restart Phase 9. This is non-negotiable — it's the failure mode that produces false-positive declines.

### Phase 10 — Assemble fixture JSON

Write the evidence bundle to `/Users/msichris/repos/triplecrown/fixtures/<slug>.json` following the schema of the existing three fixtures. The schema is loose — any missing optional field renders cleanly. Minimum required fields:

```json
{
  "domain": "...",
  "prepared_date": "YYYY-MM-DD",
  "analyst": "Chris Fossenier",
  "sub": "one-line subtitle for the report",
  "merchant": {"entity": "...", "address": "..."},
  "hubspot": {"portal": "9221154", "company_id": "...", "company_name": "..."},  // optional
  "verdict": {"level": "decline|caution|legitimate", "label": "DECLINE|PROCEED WITH CAUTION|LEGITIMATE", "note": "..."},
  "kpis": [{"label": "...", "value": "...", "note": "..."}, ...],  // 2 items (verdict is auto-appended as 3rd)
  "bottom_line": "HTML-safe paragraph text",
  "checks_out": [{"heading": "...", "body": "..."}],
  "signals": [{"signal": "...", "claim": "...", "reality": "...", "color": "g|a|r"}],
  "page3": {"title": "...", "sub": "...", "callout": {"heading": "...", "body": "..."}},
  "benign_explanations": [{"title": "...", "body": "..."}],
  "risk_patterns": [{"title": "...", "body": "..."}],
  "reconciliation_items": [{"title": "...", "body": "..."}],  // LEGITIMATE verdicts only
  "actions": [{"body": "..."}],
  "sources": [{"label": "...", "body": "..."}]
}
```

HTML in string values is passed through unescaped by the Jinja2 template (`| safe` applied) — use `<strong>`, `<em>`, `<code>` freely.

**GATE:** If any required field is missing, render will still succeed but the section will be blank. Prefer to include a placeholder like `"body": "See page 3."` rather than omit.

### Phase 11 — Render PDF

Get the current time and slug:

```bash
DATE=$(date +%Y%m%d-%H%M)
SLUG=$(echo <domain> | sed 's/\.com$//;s/\./_/g')  # e.g. sunficent, deeprootsathletics
```

Render:

```bash
cd /Users/msichris/repos/triplecrown
python3 scripts/render.py \
  --fixture fixtures/<slug>.json \
  --output <cwd>/${DATE}-${SLUG}-merchant-review.pdf
```

Where `<cwd>` is the user's working directory (not the triplecrown repo). This puts the PDF alongside the user's other daily-work files.

Then open it: `open <path>`.

**GATE:** If WeasyPrint isn't installed (`which weasyprint` empty), install it: `brew install weasyprint` or `pip install weasyprint`. Recovery: fall back to `--html-only` and open the HTML in a browser.

### Phase 12 — Report back

One short paragraph summarizing:
- Verdict + one-line reason
- Path to the PDF
- Any items that need user follow-up (e.g., "the NM SOS lookup 403'd — please verify entity manually")

Do not paste the whole report content back into chat — the user has the PDF.

---

## File-naming rules

All output files use `YYYYMMDD-HHMM-<slug>.<ext>` — the HHMM is required (global user rule). Never `YYYYMMDD-<slug>`.

---

## Reproducibility

Every finished investigation writes its fixture JSON to `fixtures/`. Anyone can later run:

```
python3 scripts/render.py --fixture fixtures/<slug>.json --output /tmp/regen.pdf
```

And regenerate the exact same PDF. This is the acceptance test for the whole pipeline. Three reference fixtures (`onemedical.json`, `deeproots.json`, `sunficent.json`) live in `fixtures/` and reproduce the three reference PDFs in `examples/`.

---

## What NOT to do

- **Don't name a risk pattern before completing Phase 9** (benign-explanations test). This is the top-priority failure mode.
- **Don't override the verdict** because "it feels off." If the evidence doesn't support DECLINE, don't decline. CAUTION exists specifically for the gray zone.
- **Don't publish a report without a "Confidence" statement** in the page-4 footer. Underwriting needs to know where you're solid and where you're inferring.
- **Don't skip the HubSpot pull** if the merchant is boarded — the CRM record often has data (deal currency, lifecycle stage, notes) that reshapes the analysis.
- **Don't include the raw command output in the PDF.** The PDF is for underwriting, not for you. Include only synthesized findings.
- **Don't touch `templates/report.css` or `templates/report.html.j2` per-case.** The design is fixed. If a specific case needs a new component (e.g., a table on page 3), add it to the template and update this SKILL.md to document it.

---

## When to escalate to a human

- Merchant is on the MATCH/TMF list (Member Solutions internal check, not MCP-accessible).
- Verdict is DECLINE **and** the applicant claims to be the impersonation victim (potential real-world crime — coordinate with the actual business before publishing).
- Chargeback rate on a boarded merchant crosses 0.75% mid-investigation.
- Any request from the merchant to change bank account or authorized signer.
