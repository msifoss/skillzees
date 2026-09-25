---
name: dns-forensics
description: Diagnose "my website is down" complaints by reconstructing what changed in a domain's DNS. Compares current live DNS against historical DNS (dnshistory.org, crt.sh, HackerTarget passive DNS, Wayback) to identify what the customer changed, when, and how to restore it. Use when a customer reports their site is down/broken and the cause is likely DNS-related (record wipe, nameserver migration, cert-authority handoff).
user-invocable: true
allowed-tools: Bash, WebFetch, Read, Write
argument-hint: <domain>
---

# /dns-forensics — Reconstruct what changed in a domain's DNS

Diagnostic skill for the recurring "customer says their site is down" support pattern. Given a domain, this compares the **current live DNS** to the **historical DNS** and produces a specific story about what changed, when it changed, and what the restore steps are.

> Born from the 2026-07-05 Stoic Jiu Jitsu incident, where Marcus Douthitt migrated DNS from Rackspace (97 Display managed) to GoDaddy (customer managed) while trying to add Mailchimp records, wiping the apex A record and breaking his site. dnshistory.org showed us the pre-incident zone; live `dig` showed the post-incident zone; the delta was the whole story.

## Trigger

User invokes `/dns-forensics <domain>` or describes an incident matching the pattern:
- "customer X says their website is down"
- "the site was working, now it isn't"
- "customer added DNS records and now the site broke"
- "why is domain.com serving a parking page"

The domain argument is required. Strip protocol/path if user passes a full URL.

## The pattern this skill diagnoses

This skill exists because **the same class of incident recurs**: a 97 Display customer with a managed website gets asked by some third-party service (Mailchimp, Referrizer, a new email tool) to add DNS records. The customer:

1. Doesn't have direct access to the managed DNS zone (which usually lives on Rackspace/Stabletransit under 97 Display administration)
2. Goes to their **registrar** (usually GoDaddy) and tries to add records there
3. GoDaddy's guided "Connect your domain" flow silently **switches nameservers away from Rackspace to GoDaddy's own** (`ns*.domaincontrol.com`)
4. GoDaddy's zone template does NOT include the customer's actual A/CNAME/MX records — it defaults to a parking-page redirect
5. Website goes down; customer opens a ticket with 97 Display saying "the site is broken"

The fix is almost never "rebuild the site" — it's "restore the DNS records that were on Rackspace before the customer flipped the nameservers."

## What this skill produces

A structured forensic report answering:

1. **What is the current live DNS state?** (nameservers, A, MX, TXT, SPF, DKIM, DMARC)
2. **What was the historical DNS state?** (via dnshistory.org, crt.sh, HackerTarget passive DNS, Wayback)
3. **What changed?** (nameserver migration, record wipes, cert-authority handoff)
4. **When did it change?** (last-observed dates from historical sources; cert-issuance dates from CT logs)
5. **What platform was the site on?** (fingerprint via headers, IPs, CT log issuer patterns)
6. **What are the restore steps?** (specific record-by-record recovery)

---

## Instructions (model-facing)

Follow these phases in order. Announce briefly what you're doing between phases; do not paste raw command output back to the user.

### Phase 1 — Live DNS pull

Run one Bash block that captures the current state via `dig` and public whois. Capture:
- Authoritative nameservers (`dig +short $D NS`)
- A / AAAA records for apex and www
- MX records
- TXT records (with special attention to SPF, DMARC, DKIM selectors, verification tokens)
- SOA (serial number is a signal — high serial revision within a single day = customer thrashing the zone)
- CAA records
- Registrar + last-updated date (from whois)
- IP whois for the apex A record (identifies parking, cloud provider, our fleet)
- HTTP fingerprint (`curl -sSI` on apex and www) — Server header, ARRAffinity cookie, Content-Length (a 114-byte body is almost always a parking-page redirect)

Save these to variables — they become the "current state" side of the diff.

### Phase 2 — Historical DNS pull

Pull historical DNS from as many free sources as possible in parallel. **`dnshistory.org` is the primary source** — it's a free service that keeps observed DNS snapshots per domain, indexed by first-seen/last-seen dates per record. Their coverage typically catches nameserver changes and A-record migrations within days.

Sources to try, in order of usefulness for this class of incident:

1. **dnshistory.org** — `https://dnshistory.org/dns-records/<domain>`
   Use WebFetch (the page is HTML but readable; if it doesn't return useful text via curl, use WebFetch and ask for a structured extraction of every record group with first-seen and last-seen dates)

2. **crt.sh** — `https://crt.sh/?q=<domain>&output=json`
   Every TLS cert issued for the domain since ~2018. **Certificate issuance is a proxy for A-record ownership**: the host had to prove control over the domain (via DNS challenge) to get the cert issued. Sudden appearance of a new CA (e.g. GoDaddy) after years of a different CA (e.g. Sectigo) is a strong signal that DNS moved.

3. **HackerTarget** — free API, no key needed:
   - `https://api.hackertarget.com/dnslookup/?q=<domain>` (current, but authoritative)
   - `https://api.hackertarget.com/hostsearch/?q=<domain>` (passive DNS memory — reveals subdomains and their historical IPs)
   - `https://api.hackertarget.com/reverseiplookup/?q=<ip>` (what else lives on the same host, useful for fleet ID)

4. **Wayback Machine** — `http://archive.org/wayback/available?url=<domain>&timestamp=<YYYYMMDD>`
   Doesn't store DNS but stores the rendered page. If Wayback has a snapshot from before the incident, the page body identifies the platform (97 Astro branding, WordPress markers, generator meta tags, CDN URLs like `97displaylive.blob.core.windows.net`).

5. **SecurityTrails** — `https://securitytrails.com/domain/<domain>/history/a`
   Usually blocked by Cloudflare challenge from `curl`. **Try via WebFetch** — the AI-driven fetch sometimes gets through. If it doesn't, skip; other sources usually suffice.

6. **VirusTotal** — `https://www.virustotal.com/gui/domain/<domain>/relations`
   Passive DNS. Public web UI works via WebFetch. Skip if all above sources give a clear picture.

**IMPORTANT nuance about dnshistory.org's dates:** the "last updated" date on each record group is dnshistory's **last-observed** date, not the change date. If a record's last-observed date is meaningfully before today, that record MAY have changed after that date. Do not assume "last updated 2026-06-26" means the record was still that value on 2026-06-27 — cross-check against current `dig` output. **The dnshistory snapshot is the pre-incident state; the current `dig` output is the post-incident state; the delta is the whole story.**

### Phase 3 — Reconstruct the timeline

Build a chronological table showing key transitions. Use certificate-transparency dates as the most reliable timeline anchor:

| Date range | Nameservers | Apex A | Platform | Cert CA |
|---|---|---|---|---|
| Historical | (from dnshistory) | (from dnshistory) | (inferred from Wayback + CT) | (from crt.sh) |
| Current | (from live dig) | (from live dig) | (from HTTP fingerprint) | (from crt.sh, most recent) |

Look for the transition points. A change in cert CA (Sectigo → GoDaddy DV) is often the strongest single signal — it usually means the customer clicked through a GoDaddy setup flow that re-provisioned the domain under GoDaddy's control.

### Phase 4 — Identify the pattern

Common patterns worth naming explicitly:

| Pattern | Signals | Diagnosis |
|---|---|---|
| **Nameserver hijack via registrar setup flow** | NS changed from Rackspace/managed to `domaincontrol.com` / registrar defaults; new GoDaddy DV cert issued in last 7 days; apex A points to parking IPs (`15.197.*`, `3.33.*`) | Customer clicked "Connect your domain" at their registrar. Wipe of managed zone. |
| **DNS records deleted individually** | NS unchanged; apex A missing or replaced; some MX/TXT preserved | Customer edited individual records at the DNS panel, likely trying to add third-party service records, deleted the wrong thing. |
| **Certificate expiry, not DNS** | DNS matches historical; A record still resolves to our host; HTTPS fails with cert error | Not a DNS issue at all — go check cert renewal on the fleet. |
| **Cache TTL, not real change** | DNS matches historical; site works from some networks but not others | Not resolved, propagation delay. |
| **Third-party integration side-effect** | DNS mostly intact but MX/SPF/DKIM records changed; site itself still resolves | Mailchimp/Referrizer/etc. rewrote email auth records but didn't touch the site A record. Site works; email may be broken. |

### Phase 5 — Restore steps

Give the user a specific, ordered restore checklist:

1. **Named record targets:** for each missing/changed record, show the historical value that needs to be restored (e.g. "apex A: currently `15.197.148.33`, historically `20.49.104.5` — restore to `20.49.104.5`")
2. **Nameserver decision:** if NS was migrated, name the choice — "switch nameservers back to Rackspace (`dns1.stabletransit.com`, `dns2.stabletransit.com`) so 97 Display can manage the zone again, OR keep NS on the new registrar and re-create every record manually"
3. **Cert cleanup:** if a new CA was involved, mention removing bindings so it stops advertising a conflicting cert
4. **Post-restore verification:** what to check once records are back (`dig +short apex A` should match; `curl -sSI` should return real Server header, not parking-page 114-byte body)

### Phase 6 — Report

Deliver as a single structured markdown report to the user with these sections:

- **Executive summary** (2–3 sentences: what happened and how to fix it)
- **Current live DNS**
- **Historical DNS** (with dnshistory.org / crt.sh / etc. as citation for each timeline claim)
- **Timeline of changes**
- **Pattern diagnosis** (which named pattern from Phase 4)
- **Restore steps**
- **Notes on data sources** — explicitly credit dnshistory.org, crt.sh, HackerTarget, Wayback as the sources consulted. Users can visit those directly to double-check.

---

## Reference commands

### Live DNS pull (Phase 1)

```bash
D=<domain>
dig +short $D NS
dig +short $D A
dig +short $D AAAA
dig +short $D MX
dig +short $D TXT
dig +short $D SOA
dig +short $D CAA
dig +short www.$D A
dig +short www.$D CNAME
# Common subdomains that indicate integrated services
for sub in _dmarc mail em ref._domainkey google._domainkey k1._domainkey selector1._domainkey selector2._domainkey mailchimp; do
  R=$(dig +short $sub.$D 2>/dev/null | head -3)
  [ -n "$R" ] && echo "$sub.$D: $R"
done
whois $D 2>/dev/null | grep -iE '^(registrar:|name server:|updated date:|creation date:|status:)'
IP=$(dig +short $D A | head -1)
[ -n "$IP" ] && whois $IP 2>/dev/null | grep -iE '^(orgname:|netname:|country:|city:)'
curl -sSI --max-time 10 "https://$D/" | head -20
```

### Historical DNS via dnshistory.org (Phase 2, primary)

`dnshistory.org` returns HTML. `curl` often works; if it doesn't, use WebFetch with a prompt like:

> Extract every DNS record group (SOA, NS, A, AAAA, MX, TXT, CNAME) from the dnshistory.org page for `<domain>`. For each group, list the first-seen date, last-seen date, and value. Preserve the "history:<n>" counts if visible.

Example URL: `https://dnshistory.org/dns-records/<domain>`

### Certificate Transparency via crt.sh (Phase 2)

```bash
curl -sSL "https://crt.sh/?q=<domain>&output=json" | python3 -c "
import sys, json
d = json.load(sys.stdin)
seen = set()
rows = []
for c in d:
    key = (c.get('not_before','')[:10], c.get('common_name',''))
    if key in seen: continue
    seen.add(key)
    rows.append((c.get('not_before','')[:10], c.get('issuer_name','')[:60], c.get('common_name','') or c.get('name_value','')[:40]))
rows.sort(reverse=True)
for r in rows[:30]:
    print(f'{r[0]}  [{r[1]}]  {r[2]}')
"
```

### HackerTarget passive DNS (Phase 2)

```bash
# Current authoritative DNS
curl -sS "https://api.hackertarget.com/dnslookup/?q=<domain>"
# Passive subdomain memory — shows subdomains AND the IPs they've resolved to
curl -sS "https://api.hackertarget.com/hostsearch/?q=<domain>"
# What else lives on the current IP (fleet fingerprint)
curl -sS "https://api.hackertarget.com/reverseiplookup/?q=<ip>"
```

### Wayback platform check (Phase 2)

```bash
# Find the closest snapshot before a given date
curl -sS "http://archive.org/wayback/available?url=<domain>&timestamp=<YYYYMMDD>"
# Then fetch the snapshot URL and grep for platform signatures:
# - 97display / 97displaylive.blob.core.windows.net → 97 Display Astro fleet
# - wp-content / wp-includes → WordPress
# - astro-island / _astro/ → Astro (any hosting)
# - <meta name="generator" content="..."> → generic CMS fingerprint
```

---

## Known 97 Display fleet fingerprints

Use these to identify whether a site was on our infrastructure and which stack:

| Signal | Meaning |
|---|---|
| Nameservers `dns1.stabletransit.com` / `dns2.stabletransit.com` | Rackspace Cloud DNS — 97 Display managed |
| SOA RName `sample.<domain>` | 97 Display zone provisioning template — reliable ownership signal |
| Apex A `20.49.104.5` | 97 Display Astro fleet, Azure Blue-193 cluster |
| www CNAME `karateaqua*.azurewebsites.net` | 97 Display Astro Blue-193 App Service (naming from a former martial-arts starter project, now general-purpose) |
| HTTP `Server: Microsoft-IIS/10.0` + `X-AspNetMvc-Version: 5.3` + `ARRAffinity` cookie | Azure App Service (97 Astro fleet) |
| HTTP CSP with `paypal.com` + `braintreegateway.com` | 97 Display Astro checkout/enrollment pattern |
| Cert issuer `Sectigo Limited` on apex+www, renewed annually | 97 Display fleet cert automation (before Let's Encrypt migration) |
| Cert issuer `Let's Encrypt` on `email.mg.<domain>` subdomain | Mailgun delegated sending domain (customer-configured, not fleet) |
| Ref to `97displaylive.blob.core.windows.net` in HTML | 97 Display Astro asset CDN |
| Classic 97 CRM sites (older, non-Astro) | No ARRAffinity, server-rendered from CRM DB, no Azure App Service in front |

## Known incident signatures

| Signature | Diagnosis |
|---|---|
| Apex A: `15.197.148.33` or `3.33.130.190` (both AWS `AT-88-Z`), NS: `ns*.domaincontrol.com` | GoDaddy "Connect Domain" / parked-domain default. Customer flipped NS to GoDaddy and did not populate the zone. |
| Response body: `<!DOCTYPE html><html><head><script>window.onload=function(){window.location.href="/lander"}</script></head></html>` (114 bytes) | GoDaddy domain-parking landing redirect. Diagnostic of the same flow above. |
| New GoDaddy DV cert issued within last 7 days when historical certs were Sectigo | Customer took DNS control at GoDaddy in the last week; the new cert was auto-issued by GoDaddy as part of their domain-connect flow. |
| MX changed to `<domain>.mail.protection.outlook.com` disappearing | Microsoft 365 mail routing was severed. Email broken in addition to web. |

## Attribution

When you deliver the report, always cite the historical DNS sources you used so the user can double-check. In particular:

- **dnshistory.org** (`https://dnshistory.org/dns-records/<domain>`) — free historical DNS with first-seen/last-seen dates per record
- **crt.sh** — free Certificate Transparency log search
- **HackerTarget** — free passive DNS API
- **archive.org Wayback Machine** — historical page snapshots

These are the primary sources this skill draws from. Users should be able to visit the dnshistory.org URL and see the same data you cited.

## Reference incident

The 2026-07-05 Stoic Jiu Jitsu case is the canonical example this skill was built to handle. See `docs/wrapit/20260705-*-stoic-jiu-jitsu-dns-forensics.md` (if wrapped) or the ticket at HubSpot company `15717619335` for the full transcript. Short version:

- **Pre-incident (through 2026-06-26 per dnshistory.org):** NS on Rackspace (`dns1/dns2.stabletransit.com`), apex A `20.49.104.5` (97 Astro Blue-193), MX to Outlook 365, SPF for Outlook + Mailchimp
- **Trigger:** Customer tried to add Mailchimp DNS records but couldn't find where in Rackspace's panel (he didn't have access). Went to GoDaddy where his domain was registered.
- **What happened:** GoDaddy's guided setup flow migrated nameservers from Rackspace to GoDaddy's own (`ns43/ns44.domaincontrol.com`), which put the zone under GoDaddy's default template (parking-page redirect), silently discarding every Rackspace-managed record.
- **Post-incident (2026-07-05 per live `dig`):** NS on GoDaddy, apex A on AWS parking IPs, no MX, no SPF, no anything. Site returns 114-byte parking redirect.
- **Fix:** Marcus needs to either (a) switch NS back to Rackspace and let 97 Display re-establish the managed zone, or (b) manually recreate every record inside GoDaddy's DNS panel using the pre-incident record list dnshistory.org captured.
