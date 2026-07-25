---
name: perf-check
description: Run a multi-provider performance check (Lighthouse CLI + PageSpeed Insights + CrUX) against any URL on membersolutions.com or external. Accepts both natural language ("homepage on PSI only") and structured flags (--providers=lighthouse --n=3).
user-invocable: true
allowed-tools: Bash, Read
argument-hint: [url-or-alias | natural-language description | --flags]
---

# /perf-check — Multi-Provider Performance Check

Wraps `scripts/perf-check.js` with smart URL aliasing and natural-language argument parsing. Runs Lighthouse CLI (local), PageSpeed Insights API (Google-hosted Lighthouse), and Chrome UX Report API (real-user field data) against the URLs you specify and prints a unified markdown summary.

> The script does the measurement; this skill does the parsing.

## What this skill does NOT do

- **Does not commit** the report. After running, just prints the summary and offers to commit if asked.
- Does not bump versions, push to remote, or trigger deploys.
- Does not modify thresholds — those live in `scripts/perf-thresholds.json`.

## Trigger

User invokes `/perf-check` with optional arguments. Args may be: a URL, a path, an alias, plain English, structured flags, or any mix.

If invoked with **no args**, run the default 3-URL reference set across all 3 providers on mobile (n=2 median). This is the same behavior as `npm run perf:check` plus PSI + CrUX enrichment.

---

## Phase 0 — Parse the arguments

The user input arrives as one string. Pull these out, in this order:

### 1. Structured flags (pass through unchanged)

If the user typed any of these literal flags, pass them straight through to the script. Don't translate.

| Flag | Values |
|------|--------|
| `--providers=` | comma list: `lighthouse,psi,crux` (any subset) |
| `--n=` | integer 1-5 |
| `--device=` | `mobile`, `desktop`, `both` |
| `--strategy=` | `median`, `min`, `max`, `mean` |
| `--format=` | `md`, `json`, `both` |
| `--prefix=` | string |
| `--no-fail` | bool flag |
| `--quiet` | bool flag |

### 2. URL extraction

Walk the words/phrases. Map each in this priority:

**Bare URL** (contains `://`) → use verbatim.

**Bare path** (starts with `/`) → prefix with `https://membersolutions.com`.

**Bare slug** (looks like `platform-tour` — alphanumeric + hyphens, no slashes) → treat as path: `https://membersolutions.com/<slug>/`.

**Aliases** (case-insensitive):

| Phrase | Resolves to |
|--------|-------------|
| `homepage`, `home`, `the homepage`, `/`, `the home page`, `the site` | `https://membersolutions.com/` |
| `FBA`, `assessment`, `free billing assessment`, `the assessment` | `https://membersolutions.com/free-billing-assessment/` |
| `blog`, `the blog`, `blog index` | `https://membersolutions.com/blog/` |
| `platform tour`, `the tour`, `tour` | `https://membersolutions.com/platform-tour/` |
| `about`, `about us`, `about page` | `https://membersolutions.com/about-us/` |
| `top 3`, `default`, `reference`, `the defaults` | (3 default URLs — leave the script's default) |
| `top 5`, `extended`, `all 5` | 5 default URLs (homepage + FBA + platform-tour + types-of-memberships blog + about-us) |
| `all` (alone, no provider context) | top 5 |

Strip these connecting words before alias matching: `the`, `our`, `a`, `and`, `&`, `,`, `also`, `plus`.

If the user mentions multiple targets, collect them all (`homepage and FBA` → 2 URLs).

If no URL was extracted at all, omit URL args (script will use its 3-URL default).

### 3. Provider extraction

Look for these keywords:

| Phrase | Maps to |
|--------|---------|
| `lighthouse`, `LH`, `CLI`, `local`, `lighthouse CLI` | `lighthouse` |
| `PSI`, `pagespeed`, `pagespeed insights`, `google's hosted`, `google hosted`, `google` | `psi` |
| `CrUX`, `crux`, `field`, `field data`, `real users`, `real user data`, `RUM` | `crux` |
| `lab`, `lab data` | `lighthouse,psi` (both lab) |
| `lab + field`, `lab and field`, `everything`, `all providers`, `all 3`, `all three` | all 3 |

**Modifiers:**
- If the input contains `only`, `just`, `solo`, `nothing else` after a provider name, that's the ONLY provider to set.
- "no PSI" / "skip PSI" → exclude that provider from the default 3.

If no provider words appear, default to all 3 (script default).

### 4. Device extraction

| Phrase | Maps to |
|--------|---------|
| `mobile`, `phone`, `on phone`, `mobile only` | `mobile` (default) |
| `desktop`, `on desktop`, `desktop only` | `desktop` |
| `both`, `mobile and desktop`, `desktop and mobile`, `both form factors` | `both` |

### 5. n / runs extraction

Patterns to match:

- `n=3`, `n 3`, `--n=3` → `--n=3`
- `3 runs`, `3 times`, `3 samples`, `run it 3 times` → `--n=3`
- `thorough`, `careful`, `confidence`, `extra runs` → `--n=3` (bump default)
- `quick`, `fast`, `single run`, `one run`, `n=1` → `--n=1`

If no signal, leave default (n=2).

### 6. Strategy / format / no-fail / quiet

These rarely appear in natural language, but support them if the user is explicit:

- `median`, `worst`, `worst case` → `--strategy=median` (default) / `min` / `max`
- `JSON only`, `--format=json` → `--format=json`
- `don't fail`, `--no-fail`, `informational only` → `--no-fail`

### 7. Ambiguity handling

If the input is genuinely ambiguous (e.g., `/perf-check check stuff`):

1. Print the parsed interpretation: `I parsed this as: <urls>, providers=<list>, device=<device>, n=<n>`.
2. Run with the closest-best guess.
3. If the input clearly couldn't be parsed at all, ASK before running.

Always tell the user the resolved invocation before running it. They should never wonder which URLs got measured.

---

## Phase 1 — Build and run the command

Compose the perf-check.js invocation. Order: flags first, URLs last.

```bash
cd /Users/msichris/repos/msi-web && node scripts/perf-check.js [flags] [URLs]
```

Examples of compositions:

| Input | Resolves to |
|-------|-------------|
| (empty) | `node scripts/perf-check.js` |
| `homepage` | `node scripts/perf-check.js https://membersolutions.com/` |
| `homepage and FBA on mobile with all 3 providers` | `node scripts/perf-check.js https://membersolutions.com/ https://membersolutions.com/free-billing-assessment/` |
| `check the platform tour with PSI only` | `node scripts/perf-check.js --providers=psi https://membersolutions.com/platform-tour/` |
| `5 runs against homepage and FBA on desktop` | `node scripts/perf-check.js --providers=lighthouse --n=5 --device=desktop https://membersolutions.com/ https://membersolutions.com/free-billing-assessment/` |
| `just CrUX field data on top 3` | `node scripts/perf-check.js --providers=crux` |
| `--providers=lighthouse,psi --n=3 https://membersolutions.com/about-us/` | passthrough |
| `membersolutions.com/blog/some-post/` | `node scripts/perf-check.js https://membersolutions.com/blog/some-post/` |
| `thorough check of homepage` | `node scripts/perf-check.js --n=3 https://membersolutions.com/` |
| `quick lighthouse check on the assessment page` | `node scripts/perf-check.js --providers=lighthouse --n=1 https://membersolutions.com/free-billing-assessment/` |

Run via the Bash tool. The script prints the markdown summary to stdout, plus a footer with the report file path.

> Note: The script can take 30s-3min depending on URL count and `n` value (Lighthouse CLI is the slow part — PSI + CrUX are HTTP API calls). Use Bash with a generous `timeout` (e.g., 600000 ms for the default invocation).

---

## Phase 2 — Display + offer to commit

After the script returns:

1. **Show the markdown summary** the script printed (the user already sees it as Bash output, but reiterate the headline result):
   - Overall: PASS or FAIL
   - Per-URL: which providers passed/failed
   - Any threshold violations
2. **Show the report path**: the `Report (markdown):` and `Report (json):` lines from script stdout.
3. **Offer to commit** as a one-liner:
   > Want me to commit this report? Just say so.
   
   Do NOT auto-commit. Reports are diagnostic; the user decides if they want history.

If exit code was non-zero (script failed thresholds and `--no-fail` wasn't set):
- Make the FAIL prominent in the summary
- Tell the user the JSON+HTML for failing Lighthouse runs is preserved in `docs/audits/regression/` for forensic review

If PSI was rate-limited:
- Mention it once in the summary (not loudly — it's a known soft failure mode)

If CrUX skipped due to missing key:
- Mention it once with the fix: "Set CRUX_API_KEY env var or `analytics.secrets.crux_api_key` in config.local.yaml. Get a key at https://console.cloud.google.com/ → enable Chrome UX Report API."

---

## Examples — full invocations

### Example 1: Default

```
User: /perf-check
```

Skill: `cd /Users/msichris/repos/msi-web && node scripts/perf-check.js`

3 default URLs × all 3 providers on mobile, n=2 median.

### Example 2: Single alias

```
User: /perf-check homepage
```

Skill resolves `homepage` → `https://membersolutions.com/`, runs all 3 providers.

### Example 3: Natural language + provider filter

```
User: /perf-check the homepage on PSI only
```

Skill: `node scripts/perf-check.js --providers=psi https://membersolutions.com/`

### Example 4: Mixed structured + bare path

```
User: /perf-check --providers=lighthouse --n=1 /platform-tour/
```

Skill: `node scripts/perf-check.js --providers=lighthouse --n=1 https://membersolutions.com/platform-tour/`

### Example 5: Multiple URLs, both devices, thorough

```
User: /perf-check thorough check of homepage and FBA on both mobile and desktop
```

Skill: `node scripts/perf-check.js --n=3 --device=both https://membersolutions.com/ https://membersolutions.com/free-billing-assessment/`

### Example 6: External URL

```
User: /perf-check https://glofox.com/
```

Skill: `node scripts/perf-check.js https://glofox.com/`

(External URLs work — useful for competitive checks.)

### Example 7: JSON only (skill mode)

```
User: /perf-check --format=json --quiet --providers=psi homepage FBA
```

Skill: `node scripts/perf-check.js --format=json --quiet --providers=psi https://membersolutions.com/ https://membersolutions.com/free-billing-assessment/`

### Example 8: Field data only

```
User: /perf-check just CrUX on top 5
```

Skill: `node scripts/perf-check.js --providers=crux https://membersolutions.com/ https://membersolutions.com/free-billing-assessment/ https://membersolutions.com/platform-tour/ https://membersolutions.com/blog/types-of-memberships/ https://membersolutions.com/about-us/`

(Or just `--providers=crux` alone — the script's default 3-URL set is fine if the user doesn't say "top 5".)

---

## Output format

The skill should produce, after running:

```
[script output — markdown report]

Reports saved at:
- /abs/path/to/docs/audits/regression/<prefix>.md
- /abs/path/to/docs/audits/regression/<prefix>.json

Want me to commit this report? Just say so.
```

If the user replies with anything affirmative ("yes", "sure", "commit it", "yes please"), commit just the report files (NOT the script itself, NOT thresholds.json) with a message like `chore(perf): perf-check report YYYYMMDD-HHMM`.

---

## Reference

- Script: `scripts/perf-check.js`
- Thresholds: `scripts/perf-thresholds.json`
- Output dir: `docs/audits/regression/`
- See `CLAUDE.md` → "Performance Patterns" section for context on what these checks are catching.
