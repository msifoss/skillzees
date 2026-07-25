---
name: a2p-audit
description: Run an A2P 10DLC website compliance audit against a live URL — checks all 16 items required for Twilio campaign registration and saves a dated report
user-invocable: true
allowed-tools: Bash, Read, Write, WebFetch, WebSearch
argument-hint: "<url>"
---

# /a2p-audit — A2P 10DLC Website Compliance Audit

Run a full 16-point A2P 10DLC compliance audit against a live website. Fetches the page and its linked legal pages, checks every item required for Twilio campaign registration, outputs a pass/fail table in chat, and saves a dated markdown report.

## Trigger

User invokes `/a2p-audit <url>` where `<url>` is the live page to audit — typically the lead-capture form page.

Example: `/a2p-audit https://afencinitas.com`

---

## Phase 1 — Fetch and Parse the Main Page

Fetch the URL provided. Extract:

- Full HTML source
- Page title
- Business name, address, phone visible on page
- All email addresses visible on page
- All links in the footer (href values + link text)
- All `<form>` elements:
  - All `<input>` fields: type, name, id, `required` attribute, label text
  - All `<input type="checkbox">` fields: name, id, `checked` attribute (default state), associated label text
- All inline consent/disclosure text (paragraphs near checkboxes or submit buttons)
- HTTP response code

If the page returns a non-200 status, report it and stop.

---

## Phase 2 — Identify Legal Page Links

From the page HTML, find links to:
- **Privacy Policy** — look for links with text or href containing "privacy"
- **Terms & Conditions / Terms of Use** — look for links containing "terms" (excluding SMS-specific terms)
- **SMS / Text Messaging Terms** — look for links containing "text-messaging", "sms-terms", "messaging-terms", "text-terms"

If a legal page link is not found on the page at all, that is a separate FAIL from the page being inaccessible.

Fetch each discovered legal page URL and record:
- HTTP status code
- For Privacy Policy: presence of SMS/text opt-out language; business address; contact email
- For SMS Terms: presence of STOP keyword; HELP keyword; "message and data rates" language (flag if preceded by "standard"); "not a condition of purchase" language; frequency disclosure ("recurring" or "frequency varies")
- For T&C: accessible (HTTP 200 is sufficient)

---

## Phase 3 — Run All 16 Checks

Evaluate each item. Use PASS / FAIL / PARTIAL with a one-line note.

### Checklist

| # | Item | How to evaluate |
|---|---|---|
| 1 | Privacy Policy page — publicly accessible | HTTP 200 on discovered privacy link |
| 2 | Privacy Policy — SMS/text data handling addressed | Privacy page contains opt-out language for SMS/text |
| 3 | Privacy Policy — business name, address, contact | Privacy page contains a physical address AND an email address |
| 4 | Text Messaging Terms page — publicly accessible | HTTP 200 on discovered SMS terms link |
| 5 | SMS Terms — STOP keyword for opt-out | "STOP" appears in SMS terms page OR in checkbox/consent text on main page |
| 6 | SMS Terms — HELP keyword | "HELP" appears in SMS terms page OR in checkbox/consent text on main page |
| 7 | SMS Terms — message & data rates disclosure | "message and data rates" language present; NOT preceded by the word "standard" |
| 8 | SMS Terms — consent not condition of purchase | "not a condition of purchase" present in SMS terms OR consent text |
| 9 | Terms & Conditions — publicly accessible | HTTP 200 on discovered T&C link |
| 10 | Footer — links to Privacy Policy, T&C, SMS Terms | All three link types present in footer |
| 11 | Consent text — links to legal pages | Form consent/checkbox labels contain links to Privacy Policy AND SMS Terms (T&C link is a plus) |
| 12 | Business domain email visible | An email address is visible on the main page OR in the footer |
| 13 | Site live and accessible, matches business identity | Main page returns HTTP 200; business name visible |
| 14 | Mobile phone field is OPTIONAL (not required) | Phone/mobile `<input>` does NOT have `required` attribute; label says "optional" or has no asterisk |
| 15 | Dedicated, unchecked SMS opt-in checkbox | At least one `<input type="checkbox">` exists with consent/SMS-related label text |
| 16 | All consent checkboxes unchecked by default | No consent-related checkbox has the `checked` attribute in HTML |

### PARTIAL vs FAIL guidance

- **FAIL** — item is entirely absent or clearly broken (HTTP 500, field is `required`, checkbox is `checked`)
- **PARTIAL** — item is present but incomplete (e.g. STOP present but HELP missing; footer has 2 of 3 links; email in linked page but not on main page)

---

## Phase 4 — Score and Classify

Count PASS, FAIL, PARTIAL results.

**Overall status:**
- **COMPLIANT** — 16 PASS, 0 FAIL, 0 PARTIAL
- **PARTIALLY COMPLIANT** — Any PARTIAL or 1–3 FAILs
- **NON-COMPLIANT** — 4+ FAILs or any CRITICAL FAIL (items 4, 14, 15, 16 are CRITICAL)

Critical items (carrier reviewers weight these highest):
- **Item 14** — Phone required = CRITICAL FAIL
- **Item 15** — No SMS checkbox = CRITICAL FAIL
- **Item 16** — Pre-checked checkbox = CRITICAL FAIL
- **Item 4** — SMS Terms inaccessible = CRITICAL FAIL

---

## Phase 5 — Output Report

### Chat output format

```
## A2P 10DLC Compliance Audit — [Business Name]
**URL:** [url] | **Date:** [today]
**Overall Status:** COMPLIANT / PARTIALLY COMPLIANT / NON-COMPLIANT
**Score:** [N] / 16 passing ([F] failed, [P] partial)

### Checklist

| # | Item | Status | Notes |
|---|---|---|---|
| 1 | Privacy Policy — publicly accessible | ✅ PASS / ❌ FAIL / ⚠️ PARTIAL | [note] |
...

### Issues

[For each FAIL or PARTIAL, one section:]

#### Issue [N]: [Item name] — [CRITICAL/MAJOR/MINOR]
**Evidence:** [what was found]
**Fix:** [specific, actionable fix]

### What's Passing
[2–4 bullet points on strengths]

### Next Steps
[Numbered priority list to reach COMPLIANT]
```

### Saved report

Save the full report as markdown to:
```
docs/audits/a2p/YYYYMMDD-HHMM-<domain-slug>-a2p-audit.md
```

Where `<domain-slug>` is the domain with dots replaced by dashes (e.g. `afencinitas-com`).

Create `docs/audits/a2p/` if it doesn't exist.

---

## Notes

- This audit checks organic A2P 10DLC compliance signals — it does not access Twilio's internal vetting system and cannot guarantee campaign approval.
- Items 1–3 defer to the linked privacy policy page content, not the main page. If the privacy link is broken, items 1–3 are all FAIL.
- For item 15, TWO separate checkboxes (transactional + marketing) is better than one combined checkbox — note both if present.
- "Consent embedded in submit button text" (no checkbox at all) = FAIL for item 15, regardless of how good the consent language is.
- Run this audit after every form change and before Twilio campaign submission.
