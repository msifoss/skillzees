---
name: webteam
description: Team sync for Astro website repos — checks git/GitHub/server state and tells you exactly what to do next
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: [help | sync | preflight | deploy | status | onboard]
---

# /webteam — Team Sync & Collaboration Dashboard

Team sync skill for Astro website repos with multi-collaborator deployments. Gathers git, GitHub, and server state, then tells the user exactly what to do next — with the actual commands to run.

> Not a dashboard you have to interpret. A coworker who says "here's the situation, here's what you do."

## Trigger

User invokes `/webteam` with optional arguments.

## Arguments

| Argument | Description |
|----------|-------------|
| `help` | Quick reference: the 6-step session workflow |
| *(none)* or `sync` | Full sync check: git status + remote comparison + deploy diff + config health |
| `preflight` | Pre-deploy validation: build test, config check, SSH access, uncommitted changes |
| `deploy` | Gated deploy: preflight checks -> build -> deploy -> verify -> log |
| `status` | What's live on the server vs what's in the repo |
| `onboard` | Guide a new collaborator through setup |

Parse `$ARGUMENTS` to determine mode. If empty or unrecognized, default to `sync`.

---

## Mode: `help`

Print this exactly (no checks, no dashboards, no tool calls — just output the text):

````
## How to Work on the Website

Every session follows the same pattern: pull, branch, work, commit, push, merge, deploy.

### 1. Get current main
```
/webteam                                  # check sync status, PRs, what needs attention
git pull origin master                    # get latest changes
```
Always start here. Run `/webteam` to see the full picture, then pull so you're current.

### 2. Branch
```
git checkout -b yourname/short-description
```
Never work directly on master. One branch per task. Name it after what you're doing.

### 3. Do work
```
/radar                                    # see the prioritized backlog
```
Make your changes. Not sure what to work on? `/radar` pulls analytics and project state to tell you what matters most.

### 4. Commit
```
git add src/pages/the-file-you-changed.astro
git commit -m "type: description"
```
Stage specific files — don't `git add .` blindly. Commit types: `feat`, `fix`, `content`, `docs`, `chore`, `security`.

### 5. Push
```
git push -u origin yourname/short-description
```
This puts your branch on GitHub so others can see it.

### 6. Merge
```
gh pr create --title "type: description"
gh pr merge <number>
git checkout master && git pull           # get back to main with your merged changes
```
Create a PR even if you're merging it yourself — it leaves a record. Merge when you're satisfied.

### 7. Deploy
```
/webteam preflight                        # 9-point check before deploying
npm run deploy                            # build + ship to production
/webteam status                           # verify what's live
/captainslog                              # log what you shipped
```
Not every merge needs an immediate deploy. But don't let undeployed commits pile up — if master has changes that aren't live, ship them.

---

### Commit types
| Type | When |
|------|------|
| `feat` | New feature or page |
| `fix` | Bug fix |
| `content` | Blog posts, copy changes |
| `docs` | Documentation only |
| `chore` | Build, config, dependencies |
| `security` | Security-related changes |

### Commands reference
| Command | What it does |
|---------|-------------|
| `/webteam` | Full sync dashboard — run at start of session |
| `/webteam help` | This reference card |
| `/webteam preflight` | Pre-deploy checks (9-point checklist) |
| `/webteam deploy` | Gated deploy: preflight + build + deploy + verify |
| `/webteam status` | What's live on the server vs what's in the repo |
| `/webteam onboard` | New collaborator setup guide |
| `/radar` | What should I work on next? (prioritized with analytics) |
| `/captainslog` | Log what you did — run at end of session or after deploy |
````

That's it. No tool calls, no analysis. Just print the reference card above and stop.

---

## Phase 0 — Detect Project Context

Before running checks, gather project context:

```bash
# Identify the project
ls package.json astro.config.* 2>/dev/null
ls config.yaml config.local.yaml 2>/dev/null
ls scripts/deploy.sh scripts/deploy.conf 2>/dev/null
ls CONTRIBUTING.md CLAUDE.md 2>/dev/null
```

Read `CLAUDE.md` (or `README.md`) to understand:
- Site URL and server details
- Deploy command and method
- Config file structure (committed vs gitignored)
- Security rules

Read `scripts/deploy.conf.example` (if exists) for deploy config template.

**Adaptive behavior:** If no `scripts/deploy.sh` exists, adapt — the project may use a different deploy method (Vercel, Netlify, manual rsync). Report what's found and adjust checks accordingly.

---

## Mode: `sync` (default)

Full team sync dashboard. Present as a formatted report.

### 1. Git Sync Status

```bash
# Current branch and tracking
git branch -vv --no-color | grep '^\*'

# Commits ahead/behind remote
git fetch --quiet 2>/dev/null
git status -sb --no-color

# Uncommitted changes
git status --porcelain

# Recent local commits not yet pushed
git log --oneline @{u}..HEAD 2>/dev/null || echo "No upstream tracking"

# Recent remote commits not yet pulled
git log --oneline HEAD..@{u} 2>/dev/null || echo "Up to date"
```

Present as:

```
## Git Sync

| Check | Status |
|-------|--------|
| Branch | master (tracking origin/master) |
| Local ahead | 0 commits |
| Remote ahead | 2 commits — PULL NEEDED |
| Uncommitted | 3 files modified |
| Stashed | 0 stashes |
```

If remote is ahead, warn: **"Remote has changes you don't have. Run `git pull` before deploying."**

### 2. Deploy Diff

Compare what's in the repo vs what was last deployed:

```bash
# Last deploy commit (from captain's log or git tags)
git log --oneline -5

# Check if deploy.conf exists
ls scripts/deploy.conf 2>/dev/null
```

If SSH access is available (deploy.conf exists and SSH works):
```bash
# Check what's live on the server
source scripts/deploy.conf 2>/dev/null
ssh -i "$DEPLOY_KEY" -p "${DEPLOY_PORT:-22}" -o ConnectTimeout=5 -o BatchMode=yes \
    "${DEPLOY_USER:-deploy}@${DEPLOY_HOST}" \
    "readlink /var/www/sites/*/current 2>/dev/null; cat /var/www/sites/*/current/.deploy-meta 2>/dev/null" \
    2>/dev/null || echo "SSH not available"
```

### 3. Config Health

```bash
# Check committed config exists
ls config.yaml 2>/dev/null

# Check local config exists (should be gitignored)
ls config.local.yaml 2>/dev/null

# Verify config.local.yaml is in .gitignore
grep -q 'config.local.yaml' .gitignore 2>/dev/null && echo "gitignored" || echo "NOT GITIGNORED — DANGER"

# Check deploy.conf exists and is gitignored
ls scripts/deploy.conf 2>/dev/null
grep -q 'deploy.conf' .gitignore 2>/dev/null && echo "gitignored" || echo "NOT GITIGNORED"
```

Present as:

```
## Config Health

| File | Status |
|------|--------|
| config.yaml | Present |
| config.local.yaml | Present, gitignored |
| deploy.conf | Present, gitignored |
| .env | Not found (OK) |
```

Flag any secrets files that are NOT gitignored as **CRITICAL**.

### 4. GitHub Activity

Query GitHub for team-wide visibility. If `gh` CLI is not authenticated or network is unavailable, fall back to local git data and note "GitHub data unavailable."

```bash
# Open pull requests — who's working on what right now
gh pr list --state open --json number,title,author,headRefName,createdAt,updatedAt,reviewDecision \
    --template '{{range .}}#{{.number}} {{.author.login}}: {{.title}} ({{.headRefName}}) [{{.reviewDecision}}]{{"\n"}}{{end}}' \
    2>/dev/null || echo "GitHub unavailable"

# Recently merged PRs (last 7 days) — what shipped recently
gh pr list --state merged --limit 10 \
    --json number,title,author,mergedAt,headRefName \
    --template '{{range .}}#{{.number}} {{.author.login}}: {{.title}} (merged {{.mergedAt}}){{"\n"}}{{end}}' \
    2>/dev/null

# Active remote branches (not stale) — who has work in progress
git branch -r --no-merged origin/master 2>/dev/null | grep -v HEAD

# Recent commits by author (local fallback)
git shortlog -sn --since="7 days ago" --no-merges

# Last 10 commits with authors
git log --oneline --format="%h %an: %s" -10
```

Present as:

```
## Team Activity

### Open PRs
| # | Author | Title | Branch | Review |
|---|--------|-------|--------|--------|
| 12 | mary | Migrate blog batch 3 | mary/blog-batch-3 | PENDING |
| 11 | chris | Redesign footer | chris/footer-redesign | APPROVED |

### Recently Merged (7 days)
| # | Author | Title | Merged |
|---|--------|-------|--------|
| 10 | mary | Migrate blog batch 2 | 2 days ago |

### Active Branches (unmerged)
- origin/mary/blog-batch-3 (2 commits ahead)
- origin/chris/footer-redesign (5 commits ahead)

### Commits This Week
| Author | Commits |
|--------|---------|
| Chris | 8 |
| Mary | 12 |
```

### 5. What To Do Next

This is the most important section. Based on everything gathered above, tell the user **exactly what to do**, in order, with the actual commands. Not suggestions — instructions.

**Analyze the situation and pick the matching scenario:**

**Scenario A — Behind remote (someone else pushed/merged):**
```
## Next Steps

You're behind origin/master. Someone pushed changes you don't have.

1. Stash or commit your local changes first:
   git stash                    # if you're mid-work
   git add -A && git commit     # if your changes are ready

2. Pull the latest:
   git pull --rebase origin master

3. If you stashed, pop it:
   git stash pop
```

**Scenario B — On a feature branch, work in progress:**
```
## Next Steps

You're on branch `chris/nav-redesign`. Keep working, or if you're done:

1. Push your branch:
   git push -u origin chris/nav-redesign

2. Open a PR:
   gh pr create --title "Redesign main nav" --body "Summary of changes"

3. Ask a teammate to review (tag them on the PR or message them)
```

**Scenario C — On master, uncommitted changes:**
```
## Next Steps

You have uncommitted changes on master. You should be on a branch.

1. Create a branch for your work:
   git checkout -b chris/describe-your-changes

2. Commit:
   git add -A && git commit -m "type: description"

3. Push and open a PR:
   git push -u origin chris/describe-your-changes
   gh pr create
```

**Scenario D — Clean master, in sync, nothing to do:**
```
## Next Steps

You're up to date. Pick something to work on:

1. Check for PRs that need your review:
   gh pr list --state open

2. Start new work on a branch:
   git checkout -b yourname/feature-description

3. Or deploy if there are undeployed commits:
   /webteam preflight
```

**Scenario E — Open PRs need attention:**
```
## Next Steps

There are open PRs that need action:

1. PR #12 (mary) needs review — you should review it:
   gh pr view 12
   gh pr review 12 --approve    # if it looks good

2. PR #11 (chris) is approved — merge it:
   gh pr merge 11

3. After merging, pull and consider deploying:
   git pull
   /webteam deploy
```

**Scenario F — Ready to deploy (master has undeployed commits):**
```
## Next Steps

Master has commits that aren't deployed yet. Ship it:

1. Run preflight checks:
   /webteam preflight

2. If all green, deploy:
   npm run deploy

3. Log the deploy:
   /captainslog
```

**Always include the actual commands. Never say "consider" or "you might want to." Say "do this."**

**If multiple scenarios apply, combine them in priority order:** behind remote first, then PRs needing attention, then local work guidance.

---

## Mode: `preflight`

Pre-deploy validation checklist. Every check must pass before deploying.

### Checks

Run all checks and present as a pass/fail checklist:

```bash
# 1. Clean working tree
test -z "$(git status --porcelain)" && echo "PASS" || echo "FAIL: uncommitted changes"

# 2. On correct branch (master or main)
BRANCH=$(git branch --show-current)
[[ "$BRANCH" == "master" || "$BRANCH" == "main" ]] && echo "PASS" || echo "WARN: on branch $BRANCH"

# 3. Up to date with remote
git fetch --quiet
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "none")
[[ "$LOCAL" == "$REMOTE" ]] && echo "PASS" || echo "FAIL: not in sync with remote"

# 4. config.local.yaml exists
test -f config.local.yaml && echo "PASS" || echo "FAIL: config.local.yaml missing"

# 5. deploy.conf exists
test -f scripts/deploy.conf && echo "PASS" || echo "FAIL: scripts/deploy.conf missing"

# 6. Build succeeds
npx astro build 2>&1 | tail -5

# 7. SSH connectivity
source scripts/deploy.conf 2>/dev/null
ssh -i "$DEPLOY_KEY" -p "${DEPLOY_PORT:-22}" -o ConnectTimeout=5 -o BatchMode=yes \
    "${DEPLOY_USER:-deploy}@${DEPLOY_HOST}" "echo ok" 2>/dev/null \
    && echo "PASS" || echo "FAIL: SSH connection failed"

# 8. No approved PRs waiting to merge (would be missed by this deploy)
APPROVED=$(gh pr list --state open --json reviewDecision,number,title,author \
    --jq '[.[] | select(.reviewDecision == "APPROVED")] | length' 2>/dev/null || echo "0")
[[ "$APPROVED" == "0" ]] && echo "PASS" || echo "WARN: $APPROVED approved PR(s) not yet merged"

# 9. No open PRs touching the same files you changed
# (conflict risk check)
OPEN_PR_FILES=$(gh pr list --state open --json number,files \
    --jq '.[].files[].path' 2>/dev/null | sort -u)
CHANGED_FILES=$(git diff --name-only origin/master...HEAD 2>/dev/null | sort -u)
OVERLAP=$(comm -12 <(echo "$OPEN_PR_FILES") <(echo "$CHANGED_FILES") 2>/dev/null)
[[ -z "$OVERLAP" ]] && echo "PASS" || echo "WARN: Files overlap with open PRs: $OVERLAP"
```

Present as:

```
## Preflight Checklist

| # | Check | Result |
|---|-------|--------|
| 1 | Clean working tree | PASS |
| 2 | On master branch | PASS |
| 3 | Synced with remote | FAIL — 2 commits behind |
| 4 | config.local.yaml | PASS |
| 5 | deploy.conf | PASS |
| 6 | Build succeeds | PASS (47 pages) |
| 7 | SSH connectivity | PASS |
| 8 | No approved PRs waiting | WARN — 1 approved PR not merged |
| 9 | No file conflicts with open PRs | PASS |

**Result: 7/9 passed, 1 warning, 1 failure. Fix item 3 before deploying.**
```

If all pass: **"All preflight checks passed. Ready to deploy with `npm run deploy`."**

If any fail: **"Fix the failing checks before deploying."** with specific remediation for each failure.

---

## Mode: `deploy`

Gated deployment. Runs preflight first, then deploys if all checks pass.

### Steps

1. **Run preflight** (all 9 checks from `preflight` mode)
2. **Gate check**: If any FAIL, STOP. If only WARNs (like approved PRs waiting), present them and let the user decide.
3. **Confirm with user**: Present the preflight results and ask "Deploy to production? (WARNs noted above)"
4. **Deploy**: Run `npm run deploy` (or the project's deploy command from CLAUDE.md)
5. **Verify**: Check HTTP status of the live site
6. **Notify**: If there are open PRs by other authors, note "Consider notifying Mary that a deploy went out — her PR #12 may need rebasing."
7. **Log**: Recommend running `/captainslog` or `/changelog` to document the deploy

### Post-Deploy Verification

```bash
# Check site is responding
curl -s -o /dev/null -w "%{http_code}" ${SITE_URL:-https://msi.membies.com}/ 2>/dev/null || echo "000"

# Check key pages
for path in "/" "/blog" "/contact" "/about"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${SITE_URL:-https://msi.membies.com}${path}" 2>/dev/null)
    echo "$path: $STATUS"
done
```

Present as:

```
## Post-Deploy Verification

| Page | Status |
|------|--------|
| / | 200 |
| /blog | 200 |
| /contact | 200 |
| /about | 200 |

Deployment verified. Site is live.
```

---

## Mode: `status`

What's deployed vs what's in the repo. Read-only, no actions.

### Gather

```bash
# Local state
git log --oneline -1
git rev-list --count HEAD

# Remote state
git fetch --quiet 2>/dev/null
git log --oneline origin/master -1 2>/dev/null

# Server state (if SSH available)
source scripts/deploy.conf 2>/dev/null
SSH_CMD="ssh -i $DEPLOY_KEY -p ${DEPLOY_PORT:-22} -o ConnectTimeout=5 -o BatchMode=yes"
$SSH_CMD "${DEPLOY_USER:-deploy}@${DEPLOY_HOST}" "
    echo 'RELEASE:' \$(readlink ${DEPLOY_PATH:-/var/www/sites/msi}/current 2>/dev/null | xargs basename)
    echo 'DISK:' \$(du -sh ${DEPLOY_PATH:-/var/www/sites/msi}/current/ 2>/dev/null | cut -f1)
    echo 'RELEASES:' \$(ls ${DEPLOY_PATH:-/var/www/sites/msi}/releases/ 2>/dev/null | wc -l)
    echo 'API_OK:' \$(curl -s -o /dev/null -w '%{http_code}' http://localhost/api/contact.php -H 'Host: msi.membies.com' 2>/dev/null)
" 2>/dev/null
```

Present as:

```
## Deployment Status

| Layer | Value |
|-------|-------|
| Local HEAD | abc1234 feat: Add new blog post |
| Remote HEAD | abc1234 (in sync) |
| Live release | 20260307-143022 |
| Releases on server | 3 |
| Site disk usage | 45M |
| Site HTTP | 200 |
| API HTTP | 200 |
```

### Content Stats

```bash
# Count content
find src/content/blog -name "*.md" 2>/dev/null | wc -l
find src/pages -name "*.astro" 2>/dev/null | wc -l
```

```
## Content

| Type | Count |
|------|-------|
| Blog posts | 78 |
| Pages | 13 |
| Components | 22 |
```

---

## Mode: `onboard`

Interactive onboarding guide for new collaborators. Reads CONTRIBUTING.md and walks through setup.

### Steps

1. **Read CONTRIBUTING.md** and present the quick start steps
2. **Check prerequisites**: node, npm, git, ssh-keygen
3. **Validate setup**:
   - `config.local.yaml` exists
   - `scripts/deploy.conf` exists
   - SSH key is configured and accessible
   - `npm install` completes
   - `npm run dev` starts successfully (run briefly, then kill)
4. **Report** what's ready and what needs attention

Present as:

```
## Onboarding Checklist

| Step | Status | Action |
|------|--------|--------|
| Clone repo | PASS | — |
| npm install | PASS | — |
| config.local.yaml | MISSING | Copy config.example.yaml and fill in secrets |
| deploy.conf | MISSING | Copy scripts/deploy.conf.example |
| SSH key | NOT TESTED | Generate key and send .pub to admin |
| Dev server | PASS | Starts on localhost:4321 |
```

If SSH key is missing, provide the generation command:
```bash
ssh-keygen -t ed25519 -f ~/.ssh/msi_deploy -N "" -C "collaborator@example.com"
```

And remind: "Send your public key (`~/.ssh/msi_deploy.pub`) to the project admin to get deploy access."

---

## Cross-Skill Recommendations

After any mode, suggest relevant skills based on findings:

| Finding | Recommend |
|---------|-----------|
| Many uncommitted changes | `/pm` to track what's in progress |
| Ready to deploy | `/webteam deploy` or `npm run deploy` |
| Post-deploy | `/captainslog` to document the deploy |
| Config issues found | `/security-audit` to check for exposed secrets |
| Large content changes | `/changelog` to document what changed |
| New collaborator joining | `/webteam onboard` then `/motherhen` for project health |
| Architectural questions | `/staff` for team discussion |
| Open PRs need review | Review PRs before deploying — `gh pr view <number>` |
| Approved PRs not merged | Merge approved PRs before deploying — `gh pr merge <number>` |
| Stale branches (>7 days unmerged) | Check with author or clean up — `git push origin --delete <branch>` |

---

## Output Format

All modes produce a structured dashboard with:
1. **Header** with mode name and timestamp
2. **Status tables** with clear PASS/FAIL/WARN indicators
3. **Recommendations** section with prioritized next actions
4. **Cross-skill suggestions** when relevant

Keep output concise. The dashboard should fit in one screen for `sync` and `status` modes.

---

## Conventions

- Timeouts on all SSH/network commands (5s connect, 15s total)
- Never store or display secrets — only check for their existence
- Read-only by default — only `deploy` mode makes changes
- Adapt to project structure — don't assume paths, read from config files
- If SSH is not configured, skip server checks gracefully and note it
- All git operations use `--quiet` for fetch to avoid noisy output
