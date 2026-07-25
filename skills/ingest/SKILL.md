# /ingest — CallHero Data Pipeline

> Diagnose gaps, fill them, prove parity. One command for the entire transcript → embedding → quality → enrichment → classification pipeline.

## When to Use

- Periodic catchup: "are we current?"
- After data lake backfill brings in new calls
- When dev and prod might be out of sync
- After noticing missing categories, embeddings, or transcripts
- When the user says "ingest", "sync", "catchup", "backfill", "embed", "classify", "vectorize", or "parity check"

## Arguments

Usage: `/ingest [options]`

Natural language after the command controls scope. No args = full diagnostic + fill gaps on both envs.

| Option | Default | Examples |
|--------|---------|----------|
| Environment | both | "just dev", "prod only" |
| Workers | 8 | "4 workers", "single threaded" |
| Scope | gaps only | "full sync", "everything", "catchup from zero" |
| Steps | all needed | "just embed", "classify only", "status only", "skip classify" |
| Limit | none | "just 100", "limit 500" |
| Include transcript ingest | only if gap | "also ingest transcripts", "ingest scraped files" |

## Prerequisites

- AWS SSO session active
- Python venv at `.venv/`

## Important: CLI Arg Order

Global args go BEFORE the subcommand. Subcommand args go AFTER:
```bash
python scripts/ingest-transcripts.py --stage prod --via-lambda embed --workers 8
#                                     ^^^^ globals ^^^^           ^^^^ sub args ^^^^
```

## Important: Lambda Proxy 5K Row Cap

`_handle_db_exec` in `analytics_handler.py` line 519 caps `fetchall` at 5,000 rows OR 5MB. Commands that process large backlogs (embed, classify) must be **looped until they return 0**. The skill handles this automatically.

## Instructions

### Phase 1 — Pre-flight

Verify AWS session:
```bash
aws sts get-caller-identity --output json 2>&1
```
If expired: `aws sso login --profile default`

Parse the user's prompt for scope overrides (see Arguments table).

### Phase 2 — Diagnose

Run status on target envs and collect gap counts:

```bash
cd /Users/msichris/repos/callhero && source .venv/bin/activate
python scripts/ingest-transcripts.py --stage dev --via-lambda status 2>&1
python scripts/ingest-transcripts.py --stage prod --via-lambda status 2>&1
```

Also query the specific gaps that status doesn't break out:

```python
# Via Lambda proxy db_exec (use the LambdaDbProxy pattern from ingest-transcripts.py):
# Embedding gap:
SELECT COUNT(*) FROM transcripts WHERE embedding IS NULL AND full_text IS NOT NULL AND LENGTH(full_text) > 0

# Classification gap:
SELECT COUNT(*) FROM calls c JOIN transcripts t ON t.call_id = c.id LEFT JOIN call_assessments ca ON ca.call_id = c.id WHERE ca.id IS NULL AND t.full_text IS NOT NULL AND LENGTH(t.full_text) > 0

# Transcript gap (calls flagged but missing row):
SELECT COUNT(*) FROM calls WHERE has_transcript = true AND id NOT IN (SELECT call_id FROM transcripts)
```

Present a **gap dashboard**:
```
Gap Dashboard:
                          Dev          Prod         Delta
  Calls                 584,334      584,349         +15
  Transcripts            51,561       51,999        +438
  Non-empty              51,497       51,936        +439
  Embeddings             51,497       51,936        100% / 100%
  Classifications        51,400       52,000        100% / 100%
  Quality metrics        16,242       16,190         -52
  Embed gap                   0            0       ✓ OK
  Classify gap                0            0       ✓ OK
```

If all gaps are zero: "Everything's caught up! No action needed." and stop (unless user asked for "full sync" or "force").

### Phase 3 — Plan

Based on gaps, build an execution plan. Steps run in this order (skip any where gap = 0):

| Order | Step | Command | Condition | Loops? |
|-------|------|---------|-----------|--------|
| 1 | Ingest scraped transcripts | `ingest --workers {W}` | Transcript count differs between envs, or user requested | No |
| 2 | Generate embeddings | `embed --workers {W}` | Embedding gap > 0 | **Yes — loop until 0** |
| 3 | Compute quality metrics | `quality` | Quality gap > 0 | No (single-threaded, no --workers) |
| 4 | Enrich from Athena | `enrich` | Enrichment gap > 0 | No (single-threaded, no --workers) |
| 5 | Classify calls | `classify --workers {W}` | Classification gap > 0 | **Yes — loop until 0** |

Present the plan:
```
Execution plan:
  1. [skip] Ingest — no transcript gap
  2. Embed — 16,167 missing on prod (4 passes × 5K, ~8 min)
  3. [skip] Quality — caught up
  4. [skip] Enrich — caught up
  5. Classify — 20,375 dev + 23,918 prod (~5 passes each, ~25 min)

  Environments: dev + prod (parallel)
  Workers: 8
  Estimated time: ~30 minutes
```

If user already said "just do it" / "go" / similar, skip confirmation.

### Phase 4 — Execute

For each step that needs to run:

**Standard command pattern:**
```bash
python scripts/ingest-transcripts.py --stage {stage} --via-lambda {subcommand} --workers {W} 2>&1
```

**Loop-until-zero pattern (embed + classify):**
```bash
for i in 1 2 3 4 5 6 7 8 9 10; do
  echo "=== Pass $i ==="
  python scripts/ingest-transcripts.py --stage {stage} --via-lambda {subcommand} --workers 8 2>&1 | tail -6
  echo
done
```
The loop runs up to 10 passes. Each pass processes up to 5K rows. A pass that generates 0 means done. For gaps > 50K, increase loop count accordingly.

**Parallel execution rules:**
- Dev and prod can run **fully in parallel** (separate Lambda functions, separate RDS, separate Bedrock sessions)
- Fire both as background tasks, wait for both to complete
- For embed + classify: loop both envs simultaneously

**Step-specific notes:**
- `quality` and `enrich` are **single-threaded** (no `--workers` support). Usually fine — gaps are small. Warn if gap > 10K.
- `ingest` reads from `~/repos/ScrapeConnect/transcripts/` (~28K .txt files). Only needed if transcript counts differ between envs or user explicitly requests.

**Timeouts:** Use 600000ms (10 min) for background tasks. Large classify runs (20K+) may take 25+ minutes — chain multiple loops or use longer timeouts.

### Phase 5 — Verify & Report

After all steps complete, re-run the gap dashboard from Phase 2 on both envs.

Present a **parity report**:
```
Pipeline complete!

                          Dev          Prod         Match?
  Transcripts            51,561       51,999        ~match (scraped file variance)
  Embeddings             51,497       51,936        ✓ 100% coverage both
  Classifications        51,497       51,936        ✓ 100% coverage both
  Quality metrics        16,242       16,190        ~match
  Embed gap                   0            0        ✓
  Classify gap                0            0        ✓

Steps executed:
  Embed (prod):    16,167 new (4 passes, 8 workers, 8m 12s)
  Classify (dev):  20,375 new (5 passes, 8 workers, 22m 04s)
  Classify (prod): 23,918 new (5 passes, 8 workers, 25m 31s)
```

## Error Handling

- **Bedrock throttling**: Reduce workers if you see throttle errors. Default 200ms (embed) / 500ms (classify) rate limits per worker.
- **Lambda concurrency**: AnalyticsIngestion has `ReservedConcurrentExecutions: 10`. With 8 workers each holding a proxy connection plus normal SQS processing, this is tight. If Lambda throttling appears, drop to 4 workers.
- **Lambda 5K row cap**: Handled automatically by the loop pattern. The cap is in `analytics_handler.py` line 519 (`raw[:5000]`) and is NOT configurable.
- **Lambda 5MB response limit**: Embed and classify fetch IDs only (tiny payload), then each worker fetches `full_text` individually per row.
- **Partial progress / idempotency**: Every step is idempotent. Embed: `WHERE embedding IS NULL`. Classify: `WHERE a.id IS NULL`. Safe to interrupt and re-run.
- **Quality/enrich single-threaded**: No `--workers` support. Usually fine for small gaps. Note in the plan if gap > 10K.

## Pipeline Commands Reference

| Command | Script | Workers? | Loops? | Rate Limit | Bedrock Model |
|---------|--------|----------|--------|------------|---------------|
| `ingest` | ingest-transcripts.py | `--workers N` | No | N/A (DB-bound) | None |
| `embed` | ingest-transcripts.py | `--workers N` | **Yes** | 200ms/worker | Titan V2 (1024-dim) |
| `quality` | ingest-transcripts.py | No | No | N/A | None |
| `enrich` | ingest-transcripts.py | No | No | N/A (Athena) | None |
| `classify` | ingest-transcripts.py | `--workers N` | **Yes** | 500ms/worker | Nova Micro |
| `status` | ingest-transcripts.py | No | No | N/A | None |

## Related Scripts (not run by this skill)

These are separate concerns with their own workflows:

- `scripts/backfill-calls.py datalake_backfill` — bulk insert call metadata from Athena
- `scripts/backfill-calls.py phone_backfill` — backfill customer_phone from Athena
- `scripts/import-hubspot-profiles.py` — HubSpot contact sync + phone matching
