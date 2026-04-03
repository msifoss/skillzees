---
name: staff-rfc
description: Staff Engineer RFC — full repo analysis, staff panel review, and RFC proposal for starting conversations and gathering feedback early
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebFetch, WebSearch
argument-hint: "<focus area or direction — e.g., 'DevOps blockers', 'production readiness', 'security posture'> [--rtf]"
---

# /staff-rfc — Staff Engineer RFC Generator

Scan the current repository end-to-end, run a full staff engineer panel, and produce an RFC document that proposes a solution and invites discussion. The RFC states the problem, proposes a concrete approach, names alternatives considered, and asks specific open questions.

> An RFC (Request for Comment) is a lightweight document for proposing and discussing technical decisions before committing to implementation. It's a way to think out loud, gather feedback early, and build shared understanding across the team. RFCs are not meant to be perfect or final. They're meant to start conversations. The staff panel provides the analytical backbone; the RFC provides the proposal.

## Trigger

User invokes `/staff-rfc <focus>` with a direction or focus area for the RFC.

## Arguments

| Argument | Description |
|----------|-------------|
| `<focus>` | The focus area or direction for the RFC. Can be a topic ("DevOps blockers"), a question ("are we production-ready?"), or a concern ("security posture for audit"). If omitted, auto-detect the most pressing blockers or gaps. |
| `--rtf` | Optional flag. If present, also produce an RTF version alongside the Markdown. |

Examples:
- `/staff-rfc "DevOps blockers preventing production deployment"`
- `/staff-rfc "production readiness"` — assess ops gaps and what needs to clear
- `/staff-rfc "security posture" --rtf` — security-focused RFC with RTF output
- `/staff-rfc` — auto-detect the biggest impediments in the repo

---

## Phase 0 — Deep Repo Scan

Before anything else, build a comprehensive understanding of the repository. Scan everything — do not assume a particular doc structure. Adapt to whatever exists.

### 0a. Project Identity

Determine what this project is and does:

1. **Read project root files** — README.md, CLAUDE.md, pyproject.toml, package.json, Cargo.toml, go.mod, or whatever identifies the project
2. **Read changelog / version info** — CHANGELOG.md, version files, git tags
3. **Read security docs** — SECURITY.md, threat models, audit logs
4. **Identify the tech stack** — language, framework, infrastructure, external dependencies

Produce a **Project Summary** (2-3 sentences: what it is, who it's for, what stage it's at).

### 0b. Documentation Scan

Search for and read all documentation that could inform the RFC:

```
Scan targets (check all, read what exists):
- docs/**/*.md           — all documentation
- .github/workflows/     — CI/CD pipelines
- infra/                 — infrastructure-as-code
- tickets/, issues/      — tracked work items
- *.json, *.yaml         — config, tracking files
- CLAUDE.md              — AI context
- SECURITY.md            — security model
- .ai-dlc.local.yaml     — per-project config
```

Also run:
- `git log --oneline -20` — recent commit context
- `git status` — current working state
- `git tag -l` — release history

### 0c. Blocker & Gap Detection

Based on the scan, identify:

1. **Blockers** — things that prevent progress, require external action, or are stuck
2. **Gaps** — missing capabilities, stale docs, untested code, ops readiness holes
3. **Risks** — security items, architectural debt, dependency concerns
4. **Tickets/work items** — any tracked items in draft, blocked, or unassigned state

If the user provided a `<focus>`, filter findings through that lens. If no focus was provided, identify the category with the highest-impact blockers and use that as the focus.

### 0d. Produce Problem Statement

Synthesize findings into a structured problem statement:

```
**What's happening:** [current state]
**What should be happening:** [desired state]
**What's in the way:** [blockers, with dependency chain if applicable]
**Why it matters:** [impact of inaction — quantified where possible]
**Constraints:** [team size, permissions, budget, timeline, external dependencies]
```

---

## Phase 1 — Staff Engineer Panel

Convene the full staff engineer panel to analyze the problem. This follows the same panel methodology as `/staff`.

### The Panelists

Each panelist analyzes the problem **independently**.

#### Tim — Staff Engineer, SpaceX
**Philosophy:** "The best part is no part." Ruthless simplification. Thinks in failure modes and blast radius.
**Strengths:** Risk quantification (Probability x Consequence matrices), eliminating unnecessary complexity, finding the minimal viable fix.
**Signature move:** Calculates risk scores for each option, kills the ones with bad ratios.
**On process:** Deeply skeptical of organizational friction. If something takes 5 minutes but has been waiting 2 weeks, the problem is not the work — it's the queue.

#### Rob — Staff Engineer, Roblox
**Philosophy:** "Deduplicate based on the cost of divergence, not the existence of duplication." Thinks in developer cognitive load and real-world failure modes.
**Strengths:** Finding latent bugs hiding in "harmless" issues, developer experience, documentation drift, practical risk assessment.
**Signature move:** Discovers that what looks like a cosmetic issue is actually a live problem.
**On documentation:** If the docs say one thing and the code says another, both are wrong — one factually, one by omission.

#### Fran — Staff Engineer, Meta
**Philosophy:** "Move fast with stable infra." Finds the 80/20 split. Knows when something is fine and when it's a liability.
**Strengths:** Pragmatic bucketing (dangerous vs aesthetic), CI/CD integration, team scaling patterns, clear heuristics.
**Signature move:** Sorts everything into "fix yesterday" vs "don't care" with unambiguous criteria.
**On execution:** "The gap between 'documented' and 'in the queue' is where projects die."

#### Al — Staff Engineer, AWS (adapts to relevant service team)
**Philosophy:** Deep platform knowledge. Has seen thousands of customer architectures. Knows the sharp edges.
**Strengths:** Platform-specific expertise, under-documented features, deployment coupling, scaling concerns, IAM/networking gotchas.
**Signature move:** Reframes the problem from a platform perspective and catches missing permissions, config gaps, or service limits before they bite.
**On architecture:** Thinks in terms of the right long-term pattern, but honest about whether the project's scale justifies it yet.

#### Will Larson — Moderator
**Role:** Does NOT analyze independently. Instead:
1. Listens to all four panelists
2. Asks clarifying questions that expose hidden assumptions
3. **Investigates the answers** — actually checks the codebase, git history, config files
4. Identifies where panelists agree and disagree
5. Makes the final ruling with explicit rationale

### Per-Panelist Output

Each panelist produces:

```
### [Name] — Staff Engineer, [Company]

**Assessment:**
[Their analysis — what's dangerous, what's not, what breaks, what's stale]

**Key quote:**
"[One memorable line that captures their position]"

**Recommendation:**
[Their preferred approach + effort estimate]

**Unique contribution:**
[Something only this panelist noticed]
```

### Rules
- Each panelist MUST have a **unique contribution**
- Panelists CAN disagree
- Reference specific files, line numbers, and code when possible
- Include effort estimates
- Al's expertise adapts to the problem domain (IAM, networking, compute, storage, etc.)

---

## Phase 2 — Consensus & Decision

### Consensus Matrix

```
| Question | Tim | Rob | Fran | Al |
|----------|-----|-----|------|-----|
| [Key decision 1] | YES/NO | YES/NO | YES/NO | YES/NO |
| ... | | | | |
```

Note unanimous agreements, majority positions, and key disagreements.

### Will Larson's Clarifying Questions

Before ruling, Will asks 3-5 questions that expose hidden assumptions. **Actually investigate the answers** — check files, run git commands, verify claims. If an answer contradicts a panelist's assumption, note it.

### Will Larson's Decision

Will synthesizes the panel into an ordered action plan:

```
| Priority | Action | Owner | Effort |
|----------|--------|-------|--------|
| P0 | [Immediate action] | [Who] | [Time] |
| P1 | [This week] | [Who] | [Time] |
| P2 | [This sprint] | [Who] | [Time] |
```

Include a **"What NOT to do"** table — things explicitly deferred with rationale.

---

## Phase 3 — Write the RFC

Now produce the RFC document. The tone should be collaborative and open — proposing a solution and inviting feedback, not demanding resources or escalating blockers.

### Writing Style Guide

1. **State the problem before jumping to solutions.** The reader should feel the pain before seeing the fix.
2. **Be honest about what you don't know.** Open questions are a strength, not a weakness.
3. **Be specific enough that someone could disagree with the details.** Vague proposals get vague responses.
4. **Short paragraphs.** Rarely more than 3-4 sentences. Often just one or two.
5. **Tables over prose for structured data.** If it has columns, use a table.
6. **Concrete over abstract.** "406 tests" not "comprehensive test coverage." "37 minutes" not "minimal effort."
7. **No filler.** No "In order to..." or "It should be noted that..." Just state the thing.
8. **Keep it short enough that people will actually read it.** Appendices for depth.
9. **Include alternatives you considered, even briefly.** This shows rigor and helps reviewers engage.
10. **Name specific people if you need specific input.** The Feedback Requested section should be actionable.

### RFC Structure

The RFC MUST follow this structure:

```markdown
# RFC: [Title]

**Author:** [from git config or CLAUDE.md]
**Date:** YYYY-MM-DD
**Status:** Draft

---

## Summary

[One or two sentences on what you're proposing. Someone should be able
to read this and know whether the rest is relevant to them.]

---

## Problem

[What's the issue or opportunity? Why does it matter now? Include enough
context that someone unfamiliar can follow along.

Include one concrete scenario or example that illustrates the problem
in human terms — not abstract, but a real situation the reader will
recognize.]

---

## Proposal

[What are you suggesting we do? Be specific enough that someone could
disagree with the details.

Get technical here. Include diagrams, pseudo-code, data flows, API
sketches — whatever helps communicate your thinking. This doesn't need
to be implementation-ready, but it should be concrete enough that
reviewers can engage with the specifics.

If a working prototype exists, describe it here with stats — but frame
it as validation of the approach, not a finished product.]

---

## Technical Considerations

[What are the interesting technical details? Consider:

- How does this interact with existing systems?
- What are the performance, scaling, or reliability implications?
- Are there data model changes or migration concerns?
- What dependencies does this introduce?
- Where are the complexity hotspots?
- What are the cost and security implications?

Not all of these will apply. Include what's relevant.]

---

## Alternatives Considered

[What other approaches did you explore? What were the tradeoffs?
Even brief notes here are valuable — they show you've thought through
the space and help reviewers understand why you landed where you did.

Include the staff panel's key observations here — unanimous agreements,
notable disagreements, and 1-2 quotable lines from panelists.]

---

## Open Questions

[What are you unsure about? What would help you move forward?
This is a good place to tag people directly.

Be specific: "I'm not sure about the data model" is less useful than
"I'm unsure whether we store cancellation reasons on the membership
or as a separate event — each has tradeoffs for reporting."

Lead with questions, not asks. The goal is to start a conversation.]

---

## References

[Links to related documents, prior art, external resources, or
relevant code. Include the staff panel backing document.]

---

## Feedback Requested From

[Name specific people and why you want their input:

- @[name] — [reason, e.g., "owns the billing integration"]
- @[name] — [reason]
]

---

## Discussion

[Leave this section empty — it's where comments and feedback go.
Inline comments throughout the document are also welcome.]
```

### Tone Calibration

The RFC should read as a proposal, not an escalation:

| Instead of... | Write... |
|---------------|----------|
| "We need IT to unblock X" | "The approach requires X, which involves [specific Azure/infra work]" |
| "This has been blocked for 28 days" | "A working prototype exists and has been validated" |
| "The ask" | "Open questions" / "Feedback requested" |
| "What happens after these clear" | "Next steps (proposed)" |
| "One bold sentence demanding a resource" | "What would help us move forward" |

The goal is for the reader to finish the RFC and think "which of my teams should pilot this?" — not "oh, this is a resource request with extra steps."

### Output Location

Save the RFC to:
```
docs/RFCs/YYYYMMDD-HHMM-RFC-[Topic-Slug].md
```

Create the `docs/RFCs/` directory if it doesn't exist.

If `--rtf` flag was provided, also produce:
```
docs/RFCs/YYYYMMDD-HHMM-RFC-[Topic-Slug].rtf
```

### RTF Generation

When producing RTF:
- Use Helvetica family (Bold for headers, Regular for body, Courier for code)
- Match the markdown structure section-for-section
- Use italic + muted color for panel notes / callouts
- Bold for field labels in tables
- Standard letter size (8.5x11), 1-inch margins

---

## Phase 4 — Staff Panel Document

Save the full panel analysis (not the RFC — the detailed panel output) to:
```
docs/key_findings/YYYYMMDD-HHmm-[Topic-Slug]-Staff-Engineer-Panel.md
```

This is the backing document. The RFC references it; the panel doc contains the full independent analyses, consensus matrix, clarifying questions, and decision.

Structure:

```markdown
# [Topic] — Staff Engineer Panel Analysis

**Date:** YYYY-MM-DD
**Panel:** Tim (SpaceX), Rob (Roblox), Fran (Meta), Al (AWS), Will Larson (Moderator)
**Trigger:** [What prompted this analysis]

---

## Problem Statement
[From Phase 0]

## Panel Analysis
[Full per-panelist output from Phase 1]

## Consensus Matrix
[From Phase 2]

## Clarifying Questions
[Will's questions + investigated answers]

## Will Larson's Decision
[Ordered action plan + deferrals]

## Key Takeaways
[3-5 generalizable insights]

## Files Referenced
[Table of files discussed]
```

---

## Quality Standards

### What makes a good staff-rfc

1. **The summary is the RFC.** A reader who only reads the summary knows what's proposed and whether it's relevant to them.
2. **Problem before solution.** The reader should feel the pain before seeing the fix. Include at least one concrete scenario.
3. **Concrete numbers everywhere.** Tests passing, lines of code, onboarding time, cost per team — not adjectives.
4. **Open questions are specific.** "What should we do about X?" is less useful than "Should we do A or B? Here are the tradeoffs."
5. **Panel adds value.** The panel catches something the initial scan missed — a false assumption, a tone problem, a missing perspective. If the panel just agrees, it wasn't run well.
6. **Collaborative tone.** The reader should finish and think "which of my teams should pilot this?" not "oh, this is a resource request."
7. **Honest about unknowns.** The RFC explicitly states what the author doesn't know and what input would help.
8. **Alternatives considered.** Even brief notes show the author thought through the space.

### What makes a bad staff-rfc

- Reads as an escalation or resource demand disguised as a proposal
- No concrete scenario in the problem section (abstract problems get abstract responses)
- Panel agrees on everything (personas not differentiated)
- Open questions are vague ("thoughts?" instead of specific tradeoff questions)
- Over-scoped (tries to solve everything instead of proposing one thing clearly)
- Filler prose ("It is worth noting that..." — just note it)
- Prototype stats presented as a fait accompli instead of validation of the approach
- Examples that leak frustration (e.g., referencing real blockers in "neutral" scenarios)

### Voice calibration

- **The RFC** sounds like a thoughtful proposal from a senior IC: clear, specific, open to feedback, backed by evidence but not demanding.
- **Tim** sounds like someone who ships rockets — quantitative, direct, zero tolerance for queue time.
- **Rob** sounds like someone running systems at massive scale — practical, bug-hunting, finds the doc that lies.
- **Fran** sounds like Meta's "move fast" culture — pragmatic buckets, clear heuristics, no ambiguity.
- **Al** sounds like an AWS service team engineer — deep platform knowledge, catches missing permissions, honest about trade-offs.
- **Will (moderator)** sounds like a VP of Engineering — synthesizes, questions assumptions, makes the call.

---

## Adaptation Notes

- **Al's expertise adapts** to the project's infrastructure. Python CLI with AWS? Al is from IAM/CloudFormation. Kubernetes deployment? Al is from EKS. Database-heavy? Al is from RDS/Aurora.
- **The focus area shapes everything.** "Security posture" means the panel digs into SECURITY.md, IAM policies, secrets management, and dependency scanning. "Production readiness" means ops checklist, CI/CD, monitoring, and rollback. "DevOps blockers" means tickets, permissions, infrastructure provisioning. Let the focus guide what gets depth.
- **No project doc structure is assumed.** The scan phase adapts to whatever exists — a fully documented AI-DLC project, a bare repo with just source code, or anything in between. The RFC quality scales with available documentation but should never fail due to missing docs.
- **RFC numbering** — Use sequential numbering if prior RFCs exist in `docs/RFCs/`. If this is the first, start with RFC-YYYY-001.
- **Author detection** — Try `git config user.name`, then CLAUDE.md, then fall back to "Engineering".
