---
name: abelian
version: 2.17.0
description: >
  **Adversarial collaboration framework** (Kahneman-style applied to LLM
  dispatch) for deep, innovative, long-horizon iteration with tractable
  doc and testable metric. Two LLM peers each propose AND challenge each
  other; mutual inspiration between rounds; mechanism-converge termination.
  17 INVARIANTS rules provide long-horizon scaffolding (file-gate, drift,
  nonce, anti-compaction, forbidden termination rationales, mission-thread
  goal-anchor, evidence-class enum, program-contract gate, adversarial
  goal sharpening) — shared substrate with unilateral review frameworks;
  not abelian-specific. Two iteration modes + opt-in goal-sharpening
  pre-flight:

  - **Co-research mode (default since v2.10, "auto-research-loop")** — two peer
    agents both propose AND challenge each other goal-driven; mutual inspiration
    prevents the hidden collapse of "attack-only adversary + propose-only
    generator." Best for: discovery, novel design, "where do I start",
    non-trivial work where any mutation has multiple defensible directions.
    Cost 2× per round but ~1.5× fewer rounds for non-trivial work
    (~33% net overhead). **Diversity via DIFFERENT CONTEXT FRAMING per peer
    at SAME max-effort tier** (not via downgrading one peer). Cross-model pair
    preferred for highest diversity; same-model pair with different
    context-framing is acceptable and beats opus+haiku per empirical 2026-04-26.

  - **Unilateral mode (--mode=unilateral, "auto-verify-loop")** — generator +
    adversary — mutate → evaluate → attack → keep/revert. Opt-in for known-
    target verification, ship-prep, audit, regression hardening, single-axis
    micro-optimization. Cost 1×. Cross-model adversary (Codex) opt-in for
    high-stakes.

  Default = co-research per v2.10 first-principles audit (collaborative
  framing > adversarial framing on Codex; "unilateral attack-only is itself
  a collapse vector for non-trivial work" — SKILL.md's own prior wording).
  Switch to unilateral with --mode=unilateral when the task is genuinely
  single-axis verification.

  **Skill activation rule (v2.12, INVARIANTS rule #13)**: any conversation-
  level reference to this skill — campaign or meta-audit — that involves
  ≥3 mutation proposals, protocol-level changes, or "verdict / done / keep
  / revert / accept / pareto / trade-off" vocabulary applied to mutation
  evaluation triggers a hard requirement: spawn dispatched adversary (Agent
  + Skill('dissect') OR codex exec subprocess) BEFORE reaching verdict.
  Self-attack in conversation context is unilateral self-judge (rule #8
  degraded mode), not co-research. RLHF prior overlap means mutator and
  self-attacker share the same prior over BOTH "what to mutate" and "how
  to attack mutations" — empirical 17× catch-rate ratio (peer-B vs
  self-attack, 2026-04-29 self-audit) confirms severity.

  **Target should include executable artifacts whenever possible —
  spec-only is the degraded mode for both modes.**

  **Adversarial Goal Sharpening (v2.17, opt-in, INVARIANTS rule #17)** —
  for fuzzy missions ("improve trading internal" / "make dashboard
  better"), `abelian sharpen "<mission>"` runs a 5-pass protocol
  (triage + outcome distillation + metric forge + lever surfacing +
  Takeaway derivation) that compiles fuzzy mission to rule
  #16-compliant program.md draft. Native abelian answer to OKR's
  hierarchical decomposition: per-program.md-field adversarial sharpening
  with co-research divergence. Reuses dissect attack classes c1-c4+d4,
  rule #11 nonce header, peer-A/peer-B framing. After draft → rule #16
  round-0 gate validates as if user wrote it. Triage exits early on
  `sharp` (write directly) or `fuzzy-ungrounded` (route to
  ce-brainstorm); `single-axis` triage allowed via rule #16 A v2.17
  exception (Strategy=1 + `--mode=unilateral`).

  Per-version mechanism details + razor history live in [TODO.md](TODO.md)
  and [README.md](README.md) changelog. SKILL.md description stays
  timeless; changelog rotates.

  Use when user says "abelian", "autoloop", "auto-optimize", "run experiments",
  "optimize this", or "Karpathy loop". The skill name is historical (covers
  unilateral verification too despite "research" framing); future v3.0 may flip
  default to co-research once empirical track record validates cost model.
user-invocable: true
argument-hint: 'abelian program.md [--chains=C] [--depth=L] [--candidates=M] [--adversary=<dissect|codex|both|off>] [--portfolio=K] [--mode=unilateral] [--code-review=on] | abelian sharpen "<fuzzy mission>" [--mission-file <path>] [--target-hint <paths>] [--interactive-sharpening]'
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, Skill
---

# /abelian — Compound Iteration Loop

Mutate → evaluate → **adversary** → keep/revert → repeat. When done, learnings auto-persist to `docs/solutions/` for future sessions.

**v2.1 anti-collapse:** adversary on by default (dissect), portfolio K=1, escalations file always written. Cross-model adversary (`--adversary=codex`) opt-in for high-stakes runs. `--adversary=off` is a documented escape hatch but discouraged — see Eval Discipline.

**Why these defaults:** v1.0's self-judge mode shares the mutator's biases (acknowledged in the v1 caveat). v2.0 made the adversary structural — a separate agent whose job is to FIND WHAT BREAKS, never to "agree." v2.1 adds the cross-model option: same-family Claude adversaries break self-collapse but still share RLHF priors; Codex adversary breaks model-family collapse too. Termination is exhaustion of attacks, not consensus.

## What You Need

A `program.md` with these sections:

- **Goal** — one sentence (≤200 chars). v2.16 hard-checks for measurable noun (whitelist `number | percentage | sharpe | recall | runtime | file-count | pass-rate | precision | latency | throughput | bytes | count`); standalone process-verbs (`improve | better | investigate | explore | study | examine | analyze`) are rejected as too fuzzy. Truly unspecified-metric tasks belong in `ce-brainstorm`, not abelian.
- **Task class** *(v2.14)* — one of `code | research | audit | decision | doc | mixed`. Determines mandatory Attack Classes coverage (see "Attack Class Library" below). If absent, loop emits LOUD WARNING (console + `escalations.md` + `state.json` + History row) and defaults to `task: code` for backwards-compat with v2.5+ program.md — same loud-degradation pattern as `--adversary=codex` graceful fallback. The warning explicitly invites the author to add the field; absent-field is operational, not refusal-to-start, but it is loud. For `task: mixed` campaigns (e.g., a code refactor that also rewrites the README), declare a primary class on the first line and supplementary classes after a `;`: `task: code; doc` — the loop applies BOTH library mandates.
- **Target** — files the agent may edit. v2.16 hard-checks each path's parent directory exists, and each path either (a) exists, OR (b) has explicit `create:` marker (e.g., `Target: docs/new-design.md create:`) declaring it will be created. Inside-repo only (no `..` escape, no absolute paths outside repo root).
- **Eval** — shell command outputting a number (preferred) OR `self-judge` with a frozen rubric. For non-`code` task classes, see INVARIANTS rule #8 fuzzy-ground protocol — `Eval ground:` declaration required. v2.16: round-0 runs Eval ONCE against unmutated baseline, stores result in `$RUN_DIR/round-0/eval.txt`, validates against declared Metric.baseline within Metric.tolerance.
- **Eval ground** *(v2.14, required for non-`code` task classes per INVARIANTS rule #8)* — declared ground source(s): ≥1 of (b)/(c)/(d) options from rule #8; option (a) self-ground is supplementary only.
- **Metric** — `<name>: <baseline> <direction> [<tolerance>]`. Direction ∈ `{min, max}`. Testable per positioning — rubric score, count, coverage rate, runtime; not vibes / human-acceptance-only. Tasks that cannot articulate a testable metric are out of scope for abelian (use ce-brainstorm or human discussion). **Tolerance (v2.16)**: defaults by type when omitted — `pass-rate / file-count / count` → exact (0); `float / runtime` → epsilon = max(1e-9, 0.01 × |baseline|); noisy benchmarks → repeated_median (5 runs). Tolerance enables baseline validation in round-0 step C without rejecting legitimate measurement noise.
- **Constraints** — what NOT to do
- **Strategy** — what to try, in what order. v2.16 hard-checks ≥2 axes (chains C>1 and co-research depend on diversity; single-axis = use unilateral mode + a different tool, not abelian).
- **Cells** *(portfolio mode only)* — diversity axes you want covered (e.g., "memoization", "algorithm-swap", "data-restructure"). Free-text labels.
- **Attack Classes** *(v2.5, expanded v2.14)* — taxonomy of attack vectors the adversary MUST address each round (or explicitly mark `n/a-this-target` with grep-able trace). Default 7 classes always apply; non-`code` tasks MUST opt in to ≥1 named library (research-class / audit-class / decision-class / doc-class). See "Attack Class Library" section below. v2.16: at round-0 program-adversary uses a LOCKED set independent of program.md Attack Classes — `{c1-scope-drift, c2-hidden-assumption, c3-definition-elasticity, c4-authority-by-citation, d4-scope-creep}` — for program-contract integrity check.
- **Takeaway** *(v2.16, NEW required section)* — derived contract: 3 fields, each must trace to Goal/Eval/Metric/Constraints via quote-grep + semantic linkage. NOT a parallel truth source; gate fails on Takeaway-vs-source contradiction. See "Round-0 Authoring Gate" section below for the Takeaway schema and rule #16 for full enforcement.
- **History** — auto-populated by the loop

## Round-0 Authoring Gate (v2.16) — INVARIANTS rule #16

Before round 1 hypothesizes anything, the loop runs a **Program
Contract Gate**. Without this gate, fuzzy or shallow program.md leaks
the upstream cause that v2.15's per-round mechanisms cannot fix from
below: every paraphrase of a fuzzy goal is more fuzz. Rule #16
enforces hard checklist + Takeaway-as-derived-contract + measured
baseline + file-gated program-adversary + content hash + TTY-aware
confirmation, all as a single round-0 stage that runs once before
round 1.

Full spec in `INVARIANTS.md` rule #16. Practical use:

### Takeaway section schema (NEW required v2.16)

Add to your program.md:

```markdown
## Takeaway
- **Success looks like**: <observable end-state, ≤2 lines>
- **Validated by**: <eval/metric/artifact, MUST be grep-able / runnable / countable>
- **Constraints**: <≤2 lines>
```

Each field must:
- **Success looks like** → cite a verbatim or paraphrased phrase from
  Goal AND include the Metric `name` + `direction` keywords. Paraphrase
  requires verbatim original cited inline.
- **Validated by** → cite a verbatim or paraphrased phrase from Eval or
  Metric AND be grep-able (literal pattern in named file), runnable
  (shell command), or countable (measurable count). Aesthetic or
  reader-experience claims are rejected (same protocol as v2.14
  doc-task cross-attack criterion 4).
- **Constraints** → cite ≥1 actual prohibition from program.md
  `## Constraints` section verbatim or paraphrased.

Quote-grep + semantic linkage (combined per codex round-2 review).
Quote-grep alone is theatre vulnerable ("Goal: optimize speedup →
Takeaway: speedup achieved" passes lexically, fails semantically).

**Notably absent**: `Estimated horizon`, `Estimated cost`. v2.16 cuts
these (codex round-1 attack 6) — they re-introduce v2.9-removed
cap-thinking through the back door. Cost shape is printed
informationally in step F below, not committed as program.md contract.

### What the gate runs

1. **Hard checklist** (binary, fast-fail): all program.md fields
   present + within v2.16 constraints (Goal has measurable noun,
   Target paths exist or have `create:` marker, Eval shell-runnable
   or rubric+ground, Metric has baseline+direction+tolerance, Strategy
   ≥2 axes, Attack Classes ≥1 library, Takeaway 3 fields).
2. **Round-0 baseline eval**: run Eval once against unmutated baseline,
   store `$RUN_DIR/round-0/eval.txt`, validate against
   `Metric.baseline ± Metric.tolerance`. Mismatch → refuse start OR
   re-run with `--accept-measured-baseline` (overwrites Metric.baseline,
   re-confirmation required).
3. **Round-0 program-adversary**: dissect adversary (always, regardless
   of `--adversary` flag) on program.md with locked attack classes
   `{c1-scope-drift, c2-hidden-assumption, c3-definition-elasticity,
   c4-authority-by-citation, d4-scope-creep}` (program-contract
   integrity classes). Writes `$RUN_DIR/round-0/program-adversary.txt`
   with rule #11 header (`peer: program-gate`, `evidence_class:
   theoretical`). BLOCKER → refuse start; MAJOR → stderr + escalations.md.
4. **Program contract hash**: sha256 over normalized Goal / Task class
   / Target / Eval / Eval ground / Metric / Constraints / Strategy /
   Cells / Attack Classes / Takeaway. Stored in
   `state.round_0.program_contract_hash`. Per-round refresh (rule #3
   extension) recomputes; mismatch → `state.status =
   "contract-drift-stopped"` + `reconfirmation_required: true`.
   Resolution: new RUN_ID OR `--reconfirm-gate` flag.
5. **Confirmation gate (TTY-aware)**: prints takeaway summary +
   baseline eval + adversary verdict + cost shape (informational,
   non-binding) + contract hash → waits stdin "go"/"no" on interactive
   TTY, or refuses start on non-TTY without `--auto-launch-after-gate`
   flag. No timeout (Stephen leaves runs unattended).

Cost shape format (printed, NOT committed):
```
Mode: <unilateral|co-research>; chains <C>, depth <L>, candidates <M>
Adversary: <dissect|codex|both>
Per-round adversary calls: <C × L>
Termination: mechanism-converge per rule #6 (no rounds/budget cap)
```

### Migration: `--migrate-takeaway`

For v2.5–v2.15 program.md missing the Takeaway section:

```bash
abelian program.md --migrate-takeaway
```

Drafts a Takeaway satisfying the v2.16 schema, writes in-place edit +
emits unified diff, then **exits without launching the loop**. User
reviews + commits + re-runs without the flag. Migration is intentionally
narrow (Takeaway only); other v2.16 gaps (no baseline eval, Strategy
<2 axes, missing Eval ground) require manual fix.

### Pre-flight `.gitignore` check (v2.8, retained inside round-0)

Before round 1, verify `.gitignore` covers the language ecosystem's
default build artifacts. The drift check (INVARIANTS rule #4) treats
any dirty file outside the round's plan as drift — including untracked
`__pycache__/` from a baseline `python3 bench.py` invocation. A missing
pattern = `drift-stopped` on round 1, the campaign dies before landing
a single mutation.

Minimum patterns by language:

| Language | Required `.gitignore` entries |
|---|---|
| Python   | `__pycache__/`, `*.pyc`, `.pytest_cache/`, `*.egg-info/` |
| Node     | `node_modules/`, `.next/`, `dist/`, `.turbo/` |
| Rust     | `target/` |
| Go       | `vendor/` (if not committed) |
| C/C++    | `build/`, `*.o`, `*.so`, `*.a` |

Smoketest 2026-04-28 confirmed the failure mode: a Python target with no
`.gitignore` triggered `drift-stopped` on round 1 because `bench.py`
generated `__pycache__/slow.cpython-312.pyc`. Resolution required
recovering the run, adding `.gitignore`, committing it, and restarting
with a fresh `RUN_ID`. Cheaper to verify the gitignore upfront.

Add the patterns and commit BEFORE the loop's first round — not as
part of round 1 — to keep "fixture setup" out of the campaign history.

## Adversarial Goal Sharpening (v2.17, opt-in) — INVARIANTS rule #17

Rule #16 enforces program.md sharpness but rejects fuzzy program.md
(measurable-noun whitelist, baseline tolerance, Takeaway derivation).
Rule #17 is abelian's native compiler from fuzzy mission to rule
#16-compliant program.md draft, opt-in.

Native answer to OKR's hierarchical decomposition: **per-program.md-field
adversarial sharpening with co-research divergence**. Reuses dissect
attack classes, rule #11 nonce header, peer-A/peer-B framing — turns
abelian's own machinery onto goal-authoring itself.

### Trigger

```bash
abelian sharpen "<fuzzy mission>"                # string mode
abelian sharpen --mission-file <path>            # file mode
abelian sharpen "..." --target-hint <paths>      # bound reconnaissance
abelian sharpen "..." --interactive-sharpening   # 5 mini-confirms (one per pass)
```

File auto-detect: `abelian <existing-file>` where the file LACKS a
`## Goal` section → orchestrator prompts "this looks like a draft, not
a program.md. Run sharpening to compose it? (yes / no)". Bare strings
to `abelian` are NEVER auto-classified as fuzzy missions (closes
typo-as-mission risk; explicit `sharpen` subcommand required).

### Pass 0 — Triage

Single LLM call (~$0.05). Classifies mission:

| Classification | Action |
|---|---|
| `sharp` | exit, "Already sharp; write program.md and run `abelian program.md` directly" |
| `fuzzy-but-grounded` | proceed to Pass 1 |
| `fuzzy-ungrounded` | exit, "Route to `ce-brainstorm`; no ground sources for sharpening" |
| `single-axis` | proceed; record `recommended_mode: unilateral`; rule #16 A v2.17 exception allows Strategy=1 |

### Passes 1-4 (file-gated co-research, rule #11 inherited)

Each pass writes `pass-N/{peer-A.md, peer-B.md, adversary.txt, converged.md}`.
Adversary header: `ABELIAN-ADV-v1` + `peer: sharpen-pass-N` + `evidence_class: theoretical`.

| Pass | Output | LLM dispatch | Locked attack classes | Converge predicate |
|---|---|---|---|---|
| 1 — Outcome Distillation + Grounding | observable end-state + ≥1 ground citation | 2 peer + 1 adversary | c1-scope-drift, c2-hidden-assumption | attack_survival + mission_traceability + rule_16_composability (Goal clause) |
| 2 — Metric Forge + Runnable Eval | metric (name/direction/tolerance/baseline=TBD) + runnable shell command | 2 peer + 1 adversary + 1 dry-run-parse | c3-definition-elasticity, c4-authority-by-citation | + Eval command parses to number AND files exist |
| 3 — Lever + Constraint (merged) | ≥2 Strategy axes (or 1 if single-axis) + Constraints (Pass 3 attack byproduct) | 2 peer + 1 adversary | d4-scope-creep, c1-scope-drift | + ≥2 surviving (or 1 if single-axis) |
| 4 — Takeaway Derivation | mechanical compose Takeaway 3 fields | 0 LLM (pure derivation) | n/a | mechanical_validator_passed: source_coverage + rule_16_B_quote_grep + semantic_linkage |

### Bounded reconnaissance

Sharpening reads ONLY:
- Fuzzy mission text (always)
- `--target-hint <paths>` values, if passed
- Top-3 noun keyword grep across repo (≤1 grep per noun)
- Last 200 lines of session history (Claude Code only; codex-cli records `not_available`)

Each entry recorded in `trace.json.reconnaissance[]` with `command`,
`hit_count`, `selected_excerpt_path`, `selected_excerpt_text`,
`citation_type` (`user_message | target_hint | grep_hit | session_tail`).

Forbidden: full repo TODOs scan, CLAUDE.md scan, full git log,
unrelated specs. Anti-fabrication discipline — more reconnaissance =
more authority the LLM can fabricate from weak hits.

### Composition

After Pass 4 converges, sharpening assembles a `program.md` draft from
pass artifacts (Goal from Pass 1; Eval from Pass 2; Strategy + Constraints
from Pass 3; Takeaway from Pass 4; Eval ground always includes (d) verbatim
fuzzy_mission). Draft enters rule #16 round-0 gate as if user wrote it.

### state.sharpening + trace.json

Per-pass `artifact_integrity` (path, sha256, nonce, started_at,
verdict_line, model_or_peer, retry_count) enables full audit. Pass 2
adds `eval_dry_run_parse` (verifies the metric command emits a number
before round-0 gate runs it for real). Full schema in INVARIANTS rule
#17 sections "state.sharpening schema" and "trace.json schema".

### Cost

| Component | Cost |
|---|---|
| Pass 0 triage | ~$0.05 |
| Pass 1-3 (each: 2 peer + 1 adversary) | ~$1.50 total |
| Pass 4 (mechanical) | $0 |
| **v2.17 sharpening total** | **~$1.55-2.05** |
| + rule #16 round-0 program-adversary | ~$0.10 |
| **Per fuzzy mission** | **~$1.65-2.15** |

100× ROI on a single 56-round-fuzz catch ($3-5 wasted on
attack-clean-but-mission-flat rounds).

### Fail-out paths

| Trigger | Action |
|---|---|
| Pass 0 → `sharp` | exit, "Already sharp" |
| Pass 0 → `fuzzy-ungrounded` | exit, "Route to ce-brainstorm" |
| Pass 1-3 mutual-KILL (2 retries) | re-run Pass 0 triage with diagnostic |
| Pass 4 mechanical_validator fails | route back to Pass 2 with c3-definition-elasticity input |
| All retries exhausted | escalate to user with diagnostic; abort |

### Why this and not OKR

OKR (Objective → Key Results → Tasks) is hierarchical decomposition done
by the user. abelian sharpening is per-field adversarial cycles done by
LLM peer pair + dissect adversary. In the LLM era, enumerate-and-attack
leverages model strength (parallel framings, cross-attack, mechanism
surfacing) where OKR's KR step relies on user cognitive scaffolding.
night-shift uses OKR as upstream to abelian; v2.17 is the abelian-native
alternative for users who want to stay within the framework.

## State Persistence (v2.8) — `$RUN_DIR/state.json`

The loop runs across many rounds and may survive context compaction.
`state.json` is the single source of truth for run state — not your
memory, not the History block in `program.md`. Persist after every
phase transition; re-read at every round step 0 (INVARIANTS rule #3).

`$RUN_DIR` defaults to `abelian/runs/<RUN_ID>/` where `RUN_ID` is
local-time `YYYY-MM-DD-HHMM`. Per-round artifacts live in
`$RUN_DIR/round-N/{adversary.txt, pre-files.txt, plan.md, eval.txt}`.

Minimal schema:

```json
{
  "run_id": "2026-04-28-1430",
  "status": "running",
  "mode": "git",
  "started_at": "2026-04-28T14:30:00-0700",
  "branch": "feat/xyz",
  "expected_head": "abc1234",
  "program_path": "program.md",
  "shape": {"chains": 1, "depth": 1, "candidates": 1, "portfolio": 1},
  "adversary_mode": "dissect",
  "rounds": [
    {
      "n": 1,
      "cell": "memoization",
      "status": "kept",
      "metric_value": 2.34,
      "verdict_line": "no attacks across all 7 classes",
      "adversary_file": "round-1/adversary.txt",
      "adversary_nonce": "a3f2c8e9d1b40756",
      "adversary_started_at": "2026-04-28T14:32:18.421-0700",
      "pre_files_file": "round-1/pre-files.txt",
      "coresearch_degraded": false,
      "commit": "def5678",
      "started_at": "2026-04-28T14:31:10-0700",
      "ended_at": "2026-04-28T14:34:55-0700"
    }
  ],
  "champion": {"round": 1, "metric": 2.34, "commit": "def5678"},
  "portfolio_cells": {"memoization": {"round": 1, "metric": 2.34}},
  "escalations_file": "escalations.md"
}
```

Valid run `status`: `running`, `completed`, `interrupted`, `drift-stopped`, `contract-drift-stopped` (v2.16), `gate-failed-terminal`. (`cap-fired` removed in v2.9 along with the budget cap concept; runs that previously cap-fired now run till mechanism-based converge or manual interrupt.)
- `drift-stopped` — uncommitted file outside Target (rule #4)
- `contract-drift-stopped` (v2.16) — program.md sections in the contract-hashed set (Goal / Task class / Target / Eval / Eval ground / Metric / Constraints / Strategy / Cells / Attack Classes / Takeaway) changed after round-0 confirmation. Resolution: new RUN_ID OR `--reconfirm-gate` flag re-runs round-0 (rule #16).

Valid round `status`: `pending`, `mutated`, `eval-done`, `adversary-done`, `kept`, `reverted`, `gate-failed`.

Update after: every round step transition, every commit, every revert,
status changes, eval results, post-campaign escalation review.

**v2.15 state schema additions**:

```json
"frame_break_count_consecutive": 0,
"rounds": [
  {
    ...,
    "mission_thread": { ... },          // see Mission Thread section
    "frame_break_fired": false,         // did this round fire frame-break?
    "frame_break_steps_run": []         // ["reject-pool-mining", ...]
  }
]
```

**v2.17 state schema additions** (sharpening block, populated by rule
#17 Adversarial Goal Sharpening before round_0 if sharpening was
triggered):

```json
"sharpening": {
  "fuzzy_mission_verbatim": "...",
  "triage_classification": "fuzzy-but-grounded | sharp | fuzzy-ungrounded | single-axis",
  "started_at": "...",
  "passes": [
    {"n": 0, "name": "triage", "files": ["pass-0/triage.md"]},
    {"n": 1, "name": "outcome-grounding", "converged_to": "...", "files": [...]},
    {"n": 2, "name": "metric-eval", "converged_to": "...", "files": [...]},
    {"n": 3, "name": "lever-constraint", "converged_to": "...", "files": [...]},
    {"n": 4, "name": "takeaway-derivation", "converged_to": "...", "files": [...]}
  ],
  "program_md_draft_path": "program.md",
  "trace_json_path": "$RUN_DIR/sharpening/trace.json",
  "recommended_flags": ["--mode=co-research"]
}
```

**v2.16 state schema additions** (round_0 block, populated by Program
Contract Gate before round 1):

```json
"round_0": {
  "checklist_passed": true,
  "checklist_failures": [],
  "baseline_eval": {
    "value": 0.42,
    "file": "round-0/eval.txt",
    "tolerance": 0.01,
    "matches_declared": true
  },
  "program_adversary": {
    "file": "round-0/program-adversary.txt",
    "verdict": "0 BLOCKER, 1 MAJOR, 2 MINOR",
    "evidence_class": "theoretical",
    "blockers": 0,
    "majors": 1,
    "minors": 2,
    "adversary_nonce": "...",
    "adversary_started_at": "..."
  },
  "takeaway": {
    "success_looks_like": "...",
    "validated_by": "...",
    "constraints": "..."
  },
  "program_contract_hash": "sha256:...",
  "user_confirmed_at": "2026-05-03T15:30:00.000-0700",
  "auto_launched": false,
  "bypass_reason": null,
  "reconfirmation_required": false
}
```

`frame_break_count_consecutive` resets to 0 on any round with
`mission_thread.metric_delta > 0` OR `mission_thread.blocker_status
∈ {removed, partially}`. Increments by 1 on any round that fired
frame-break. Termination via `no-proposal-after-K-frame-breaks` checks
this counter against K (default 2).

## Mission Thread per round (v2.15) — INVARIANTS rule #14

Every round populates `state.rounds[N].mission_thread` BEFORE commit-gate
runs. Missing or incomplete = commit-gate check 8 fails. Schema:

```json
"mission_thread": {
  "goal_paraphrase": "fresh paraphrase of program.md Goal, this round",
  "metric_delta": 0.42,
  "blocker_status": "removed | partially | blocked_on:<dep> | n/a",
  "mission_relevance": "one sentence: how this round serves the mission",
  "candidate_routes": [
    {"id": "route-a", "mechanism": "...", "est_metric_delta": 0.5,
     "est_cost": "cheap | medium | expensive", "blocker_chain": null},
    {"id": "route-b", "mechanism": "...", "est_metric_delta": 0.2,
     "est_cost": "medium", "blocker_chain": "blocker-X"}
  ],
  "selected_route_id": "route-a",
  "selection_reason": "route-a est highest delta; route-b cheaper but
                       smaller delta; route-c blocked-on integration
                       not yet available",
  "exploration_round": false
}
```

Field rules and rationale: see INVARIANTS rule #14 (full schema +
why-each-field). Key constraints commit-gate enforces (rule #2 check 8):

- `candidate_routes` length ≥ 2 (single-route round = gate-fail)
- `goal_paraphrase` ≠ `state.rounds[N-1].mission_thread.goal_paraphrase`
  (string-equality check; identical paraphrase = mutator did not re-read
  program.md = gate-fail)
- `selection_reason` references at least one unpicked route by id
  ("picked highest est delta" alone = gate-fail)

Goal-progress check (rule #2 check 10): at least ONE of `metric_delta > 0`,
`blocker_status ∈ {removed, partially}`, or `exploration_round: true`
with `state.frame_break_count_consecutive ≤ 2`.

**Mutator workflow per round**:

1. Re-read program.md (forced by check 8's freshness constraint).
2. Survey state.rounds[*].mission_thread.candidate_routes for unpicked
   routes from prior rounds (reject-pool warm-start; mandatory in
   Frame-break Protocol step 1, optional in normal rounds).
3. Generate ≥2 candidate_routes for THIS round, document mechanism +
   est_metric_delta + est_cost + blocker_chain for each.
4. Select one, write selection_reason citing trade-offs.
5. Implement selected route (existing Loop steps 2-7).
6. Populate metric_delta and blocker_status from eval and round outcome
   BEFORE commit-gate.

**Why this exists**: codex 56-round trading-internal PM dogfood
(2026-05-02) demonstrated that without a per-round goal-anchor, the
loop produced 26 consecutive attack-clean rounds with zero mission
metric movement. Mission Thread makes goal-relevance a structural
per-round artifact verified by commit-gate; rounds that don't earn
their commit by goal-progress evidence are reverted.

## Search Shape (v2.4) — C × L × Candidates

Default: **C=1, L=1, candidates=1** — one mutation per round, sequential. The Loop section below describes this case; most campaigns run here and should not bump these levers without cause.

For harder problems, factor compute budget across three orthogonal levers:

| Lever | What it does | Default | When to bump |
|-------|--------------|---------|--------------|
| **C** (chains) | Parallel approaches — each chain explores a *different axis* from Strategy. Chains run concurrently on ephemeral branches `abelian/chain-<c>/`. | 1 | Strategy lists multiple **independent, pre-identified** axes that don't need serial profile-guided discovery (e.g., speedup campaign targeting 3 CI methods — FisherZ / chisq / d_separation — each hits a different class, no cross-deps). Do NOT bump C when each next direction depends on the previous result. |
| **L** (depth) | Sequential refinement within a chain — each step uses evaluator feedback to improve the previous step's commit. | 1 | Evaluator output is rich (cProfile breakdown, structured error messages, failing test names) AND single-shot mutations rarely hit target. Polish-pass regime. |
| **candidates** (best-of-M) | Per-step variants — generate M candidates, pick best by **EVAL** (not adversary) before committing. Rejects are discarded, not logged per-row. | 1 | Eval is cheap (<1s) and single-sample generation variance is high (temperature-sensitive, ambiguous prompts). Cost: M× eval spend per step, 0× extra adversary. |

**Orthogonal to Portfolio K.** `--portfolio=K` maintains K diverse cells (MAP-Elites) ACROSS rounds; C/L/candidates shape WITHIN a round. Chains in C>1 can write into different portfolio cells if both are set.

### Per-round cost shape (v2.9 — informational, not a cap)

Abelian no longer requires a `--rounds` or `--budget` cap (v2.9 removed
both — see Termination Discipline). The loop runs till converge per
INVARIANTS rule #6. The v2.4–v2.5 budget accounting block is retained
below as **informational** so users can sanity-check their program.md
target before starting; the formula no longer drives a `--confirm-budget`
gate, but is useful for setting realistic expectations on cost per round
and total cost at typical convergence (3–10 rounds for most campaigns).

```
Per-round cost shape:
  Shape:           chains=C, depth=L, candidates=M, portfolio=K
  Eval runs:       C × L × M
  Adversary calls: C × L
  Fix-iter multiplier: ~1.5 cycles per attack (write fix → re-eval → maybe re-adversary)
                       α (attack rate): dissect ~0.6, codex xhigh ~0.8, both ~1.0
                       β (fix cost): ~1.5 eval+adversary units
                       → effective per-round multiplier ~1.9× (dissect) / ~2.2× (codex) / ~2.5× (both)
  Adversary cost: codex xhigh (latest stable) ≈ $0.5–2/call
  Typical convergence: 3–10 rounds depending on Strategy axis count and program.md target tightness
```

**Empirical from P0 audit campaign 2026-04-26**: raw formula under-estimated 2–12× when fix-iter cycles weren't counted; v2.5 multiplier accounts for this. If you're cost-sensitive, run a single dry-round first to calibrate before letting the till-converge loop proceed unattended.

### Parallel expansion semantics (C>1 or L>1 or candidates>1)

- **C chains in parallel** (per round): each chain runs The Loop's steps 1-5 independently on `abelian/chain-<c>/` branch. After all C chains complete step 5, "Place" picks the best chain's commit as new champion; others go to portfolio cells (if K>1) or revert.
- **L depth per chain** (per chain): steps 1-5 repeat L times sequentially within a chain. Each step refines on the previous step's commit using evaluator feedback from that commit. Adversary runs once per step. A revert at any step terminates that chain (don't keep refining a broken trunk).
- **Candidates M per step** (inside step 1): Hypothesize generates M testable variants. Each is mutated + evaluated separately (no adversary yet). Best-eval variant is chosen; ONLY that variant gets adversary + Confirm + Place. Rejected variants logged as summary line, not full rows.

### Invocation

```
/abelian program.md \
  --chains=C       # default 1
  --depth=L        # default 1
  --candidates=M   # default 1
  --portfolio=K    # default 1 (single champion)
  --mode=co-research  # optional, switches to peer-attack mode
  --adversary=codex   # optional, cross-family adversary (high stakes)
```

**No `--rounds` / `--budget` flag**. Abelian runs **till converge** per
INVARIANTS rule #6 (v2.15: goal-met / no-proposal-after-K-frame-breaks /
mutual-KILL). `adversary-exhausted` and metric-only `plateau` are NOT
standalone termination conditions in v2.15 — they trigger Frame-break
Protocol (see "Frame-break Protocol" section) instead of stopping the
loop. Manual abort: send SIGINT (Ctrl+C) → `status=interrupted` +
handoff. See "Termination Discipline" below for the rationale.

## The Loop

For each round:

0. **Refresh (v2.8)** — `cat $SKILL_DIR/INVARIANTS.md && cat $RUN_DIR/state.json` from disk. Conversation memory of these rules drifts after R3+ compactions; the file is truth. INVARIANTS rule #3.
1. **Hypothesize** — read Strategy + state.json `rounds[]` + current state → generate ONE testable change. Tag the change with a cell label (free-text, ≤3 words).
2. **Mutate** — apply the change (minimal, one idea per round). Before writing, snapshot pre-files: `mkdir -p $RUN_DIR/round-N && { git ls-files -z; git ls-files -z --others --exclude-standard; } | sort -zu > $RUN_DIR/round-N/pre-files.txt`. INVARIANTS rule #5.
3. **Evaluate** — run eval command, or self-judge against frozen rubric. Write metric value to `$RUN_DIR/round-N/eval.txt` and update `state.rounds[N].metric_value`.
4. **Adversary** — spawn `Agent(general-purpose)` that runs `Skill('dissect')` on the diff + eval output. Adversary subagent MUST write full attack list (or `n/a-this-target` per class) to `$RUN_DIR/round-N/adversary.txt` BEFORE returning, and the verdict line MUST be recorded in `state.rounds[N].verdict_line`. INVARIANTS rules #1, #7. (See Adversary section.)
5. **Confirm** — no attacks: run commit-gate (INVARIANTS rule #2, **10 always-on checks + 1 conditional**, v2.15):
   1–7: `adversary.txt` non-empty + header block nonce matches `state.adversary_nonce` + mtime in `(adversary_started_at, now)` + verdict_line `grep -qF` in body + drift check + `pre-files.txt` exists + eval value matches state.
   **8 (v2.15, rule #14)**: `state.rounds[N].mission_thread` complete (7 fields populated, ≥2 candidate_routes, goal_paraphrase ≠ prior round's, selection_reason references at least one unpicked route).
   **9 (v2.15, rule #15)**: adversary header `evidence_class:` field present and in whitelist (`theoretical | paper | replay | settled | dry_run | live`); both peer-A and peer-B in co-research.
   **10 (v2.15, rule #14)**: goal-progress required — `mission_thread.metric_delta > 0` OR `blocker_status ∈ {removed, partially}` OR (`exploration_round=true` AND `state.frame_break_count_consecutive ≤ 2`). Pure attack-survival with `metric_delta=0 AND blocker=n/a AND exploration=false` is gate-fail.
   **11 (conditional, rule #12)**: when `--code-review=on`, run `codex review --uncommitted -c 'model_reasoning_effort="high"'` → `codex-review.txt` non-empty AND no `[P1]`/`[P2]` markers.
   All checks pass → `git commit`. Any fail → revert (`git checkout` + scoped clean of new files via pre/post diff), mark round `gate-failed`. With attacks: convert each to a verification (regression test, worst-case benchmark input, or added rubric criterion) and re-eval. Any verification fails → revert. Black-box eval with no augmentation surface: log attack as `provisional-flag`, keep but mark.
6. **Place** — K=1 mode: replace champion if better, else revert. K>1 mode: replace THIS cell's incumbent only if it beats that cell's score. New cell label → seed that cell.
7. **Record** — append to History: kept/reverted/error, cell, adversary-result, metric delta.
8. **Adapt** — 5 consecutive reverts → shift strategy. 5 rounds with no new cell filled (K>1) → write to `escalations.md`. All directions exhausted → stop early.

## Adversary

**Driver-neutral protocol**: a fresh adversary subagent receives a prompt that includes verbatim `program.md` Goal/Target/Constraints/Attack-Classes + a fresh nonce + ISO timestamp, executes in isolated context with its own tool access (Read/Bash/Write or equivalent), writes the attack list to `$RUN_DIR/round-N/adversary.txt` with a mandatory `ABELIAN-ADV-v1` header (rule #11), and returns the verdict line. Two reference dispatches:

- **Claude Code primary**: `Agent(general-purpose)` running `Skill('dissect')` — see [`drivers/claude-code/README.md`](drivers/claude-code/README.md). This is the default for `/abelian program.md` invocation in a Claude Code session. Adversary subagent is a Claude with same RLHF family as the mutator — structural role split, weak prior split.
- **Codex CLI primary**: `codex exec - -s workspace-write` subprocess + the [`prompts/dissect.md`](prompts/dissect.md) template — see [`drivers/codex-cli/README.md`](drivers/codex-cli/README.md). Self×self default (codex × codex with different prompt context per role at full max-effort). No wrapper script — codex CLI is itself an LLM agent harness consuming SKILL.md directly, the same way Claude Code does.

Both drivers honor the same protocol and INVARIANTS. The descriptions below use Claude Code idiom (Agent / Skill / MCP) because abelian's original implementation was Claude Code. Codex CLI users substitute `codex exec` for `Agent(...)` and `prompts/dissect.md` content for `Skill('dissect')`. Mechanism, header, gate, and INVARIANTS are byte-for-byte identical.

Override via `--adversary=<value>`:

| Value | Adversary | Prior separation | Cost | When to use |
|-------|-----------|------------------|------|-------------|
| `dissect` (default) | Claude subagent + `Skill('dissect')` | Weak (same RLHF family) | Low | Most cases, zero-config, portable |
| `codex` | codex CLI subprocess: `codex exec - -s read-only -c 'model_reasoning_effort="high"' < prompt`. Requires codex CLI installed (`npm i -g @openai/codex`) + `codex login` (auth lives in `~/.codex/auth.json`). The orchestrator may alternatively use a codex MCP wrapper if one is configured — the protocol does not depend on the dispatch mechanism. | Strong (cross model family) | High | High stakes, self-judge eval, key decisions |
| `both` | Both adversaries; **union of attacks** (no consensus required) | Strongest | Highest | 24/7 night-shift, PR-level / production decisions |
| `off` | None | — | None | Shell-eval only; **refused** when Eval is `self-judge` |

**File-gated output (v2.8).** The adversary subagent MUST write its full attack list (or empty list with explicit `n/a-this-target` per attack class) to `$RUN_DIR/round-N/adversary.txt` BEFORE returning. Co-research writes `peer-A.txt` and `peer-B.txt` separately. Conversation-only return = invalid, fails commit-gate. The agent prompt MUST quote `program.md` Goal/Target/Constraints/Attack-Classes verbatim — paraphrasing forbidden. INVARIANTS rules #1, #7.

**Header-block protocol (v2.8 anti-fabrication).** Before each adversary call, the mutator generates a fresh `nonce` (16 hex via `secrets.token_hex(8)`) and `started_at` (ISO ms) and writes both into `state.rounds[N].{adversary_nonce, adversary_started_at}`. The prompt instructs the subagent to write a mandatory header block (`ABELIAN-ADV-v1` + run_id + round + peer + nonce + started_at + verdict, then `---`, then attacks) as the first lines of the output file. Commit-gate verifies nonce match + mtime in valid range + verdict in body. INVARIANTS rule #11. This is friction-level defense (not cryptographic) targeting Threat-1: post-compaction "forgot to call adversary" silent fabrication. A mutator must now cat state.json to find the nonce, which triggers cat INVARIANTS, which surfaces "must actually call adversary."

**Adversary's job (unilateral mode):** find what breaks, NOT propose alternatives. Cannot endorse, only attack.

**Adversary's job (co-research mode, v2.15):** find what breaks AND optionally write an informational `alternative_routes:` section at end of attacks (after `---`-delimited attack content). Alternative routes are **non-binding** (commit-gate ignores their content; rule #11 header-block validation does not extend to this section), but **readable** by the next round's mutator/peer when generating `mission_thread.candidate_routes` (rule #14 reject-pool mining + Frame-break Protocol step 5). Schema per rule #11 (each entry has `id`, `mechanism`, `est_metric_delta`, `rationale`).

The unilateral-mode prohibition stands because (a) unilateral has no peer to consume alternative routes, and (b) without a peer's review, adversary-as-proposer reintroduces the propose-attack collapse v2.6 was designed to prevent. Co-research mode has both safeguards: the OTHER peer's adversary call independently attacks any mutation derived from these alternative routes.

**Why this is the right partial-relaxation**: the line-273 ban (v2.0+) prevented adversary-collapse to "all-KILL" by structurally separating roles. v2.15 keeps the role separation in the binding gate (alternative_routes does NOT count as a verdict; the verdict line is still attack-only) while allowing the adversary to contribute creative direction signal that the next round MAY mine. This is the difference between "stuck adversary" and "co-researcher offering a different angle." Codex 56-round PM dogfood (2026-05-02) showed the adversary-as-only-attacker telos exhausts itself within frame; allowing informational propose lets the loop break frame at the source where stuck-ness was first detected.

**Code Review supplemental layer (`--code-review=on`)**: orthogonal to the adversary call above, abelian can run codex CLI's purpose-built `codex review --uncommitted` as an additional gate before commit (INVARIANTS rule #12). This is a code-quality layer using codex's built-in P1/P2/P3 severity schema — different from rule #1's domain-specific attack-class adversary. Output to `round-N/codex-review.txt` (no header block — rule #11 does not apply to this file). Commit-gate adds the conditional check (rule #2 check 11) when enabled: no `[P1]`/`[P2]` markers in codex-review.txt. Use for ship-prep, PR-level decisions, security-sensitive mutations. Default off because cost roughly doubles per round.

**Graceful degradation (loud, never silent):**
- `--adversary=codex` + codex CLI unavailable (binary missing OR `~/.codex/auth.json` absent OR codex MCP wrapper not configured) → degrade to `dissect`, **write notice in 3 places**: console (stderr), `abelian/escalations.md`, and History row for the affected rounds. Continue loop.
- `--adversary=both` + codex CLI unavailable → degrade to `dissect`-only with same 3-place notice. Continue loop.
- Degradation decision is made **once at loop start** — don't re-check codex every round (noise + unpredictable runs).
- The notice must include the why: "codex CLI not reachable (run `codex login` and verify `codex exec --version`); cross-model adversary disabled; runs are weaker on prior diversity for this session."
- `--adversary=off` + Eval=`self-judge` → **hard refuse to start** (no degradation). This combination has zero LLM check on a vibes-based eval — structurally unsafe.

**Honest limit:** Default `dissect` breaks structural self-collapse but does NOT break model-family collapse. Two Claudes with role split still share RLHF priors. For high-stakes decisions, `--adversary=codex` is the cross-model upgrade — don't default-trust the default.

**v2.15 termination shift**: termination is no longer "adversary exhausted across N rounds." Adversary-exhausted is now an **informational signal** that triggers Frame-break Protocol (5-step mandatory creative-escape sequence; see "Frame-break Protocol" section). Only after K consecutive frame-break rounds yield no positive-EV `candidate_route` does the loop terminate via `no-proposal-after-K-frame-breaks`. Termination conditions per rule #6: `goal-met | no-proposal-after-K-frame-breaks | mutual-KILL | user-interrupt`.

**Why this changed (v2.15)**: codex 56-round trading-internal PM dogfood (2026-05-02) showed attack-survival as standalone gate produces "attack PASS, mission metric flat" rounds indefinitely. v2.14 had no mechanism to flag this; every commit was gate-clean. v2.15 makes goal-progress a structural commit-gate check (rule #2 check 10) and removes adversary-exhausted from termination — attack mechanism is 100% preserved (every round still runs adversary with nonce header per rule #11 and attack-class checklist), but attacks no longer terminate the loop on their own. **v2.5 refinement still applies**: when adversary-exhausted DOES contribute to a frame-break trigger, "exhausted" still means measured ACROSS the Attack Class Checklist — single-adversary single-frame exhaustion is not even enough to trigger frame-break, let alone terminate.

**v2.6 fundamental upgrade — Co-Research Mode**: unilateral attack-only is
itself a collapse vector when the work involves discovery, not just
verification. Stephen 2026-04-26: "竞争合作最重要——两边要都互相 challenge
和互相启发，不然会坍缩，要 goal driven." When generator only proposes and
adversary only attacks, two failure modes:
- Adversary collapses to "all-KILL" (no path forward — see polymarket Codex
  topping at +3.6% sharpe in adversarial mode vs 20%+ in collaborative)
- Generator collapses to RLHF prior (no fresh attack frame inspires it)

Co-research mode (`--mode=co-research`) makes both agents do BOTH propose
AND challenge each other, with goal-driven termination. See "Co-Research
Mode" section below.

## Co-Research Mode (v2.6) — Bidirectional Peer Challenge

**Why** (Stephen 2026-04-26 directive): "竞争合作最重要——两边要都互相
challenge 和互相启发，不然会坍缩，要 goal driven."

Unilateral attack-only is a hidden collapse vector for any non-trivial
work involving discovery (not just verification). Two failure modes:
- **Adversary-collapse**: pure-attack adversary tops out at "all-KILL"
  (polymarket Codex adversarial mode capped +3.6% sharpe; collaborative
  mode found 20%+ structural arb in same time).
- **Generator-collapse**: propose-only generator with no fresh attack
  frame collapses to RLHF prior; no inspiration in.

Co-research makes BOTH agents do BOTH actions per round, with mandatory
cross-model pairing for prior diversity.

### Mode comparison

| Mode | Generator role | Adversary role | Cost | When |
|---|---|---|---|---|
| Unilateral (default v2.5) | propose + implement | attack-only | 1× | Verification of known target, ship-prep, audit |
| **Co-research (v2.6)** | A: propose + challenge B  |  B: propose + challenge A | 2× | Discovery, novel design, research, "where do I even start" |

### Co-research loop per round

1. **Parallel propose** — A and B each generate one mutation toward the
   declared goal (Stephen's framing: "goal driven"). They MUST take
   different angles (enforced via Strategy axes; if axes collapse,
   ESCALATE). Each writes to `abelian/peer-A/round-N/` and
   `abelian/peer-B/round-N/`.
2. **Parallel implement** — each on its own branch.
3. **Eval both** — execution gate + eval fitness. Both must pass
   execution gate (no spec-only champions).
4. **Cross-attack** — A attacks B's mutation through the v2.5 Attack
   Class Checklist. B attacks A's mutation symmetrically. Self-attack
   permitted but tracked separately (`source: self-check` vs
   `source: peer-attack`); only peer-attack counts toward exhaustion.
5. **Verification** — each attack converts to a probe. Probe pass =
   attack falsified, mutation survives that attack. Probe fail =
   mutation reverts on its branch (does NOT take down the campaign).
6. **Champion** — surviving best-eval mutation = round champion.
   Loser branch is preserved (portfolio-style) — failed mutations
   are training data for next round, not garbage.
7. **Mutual inspiration** — explicit step. Each agent reads:
   - the OTHER's mutation (what new direction did they try?)
   - the OTHER's attacks on ITSELF (what did they catch?)
   These feed into the agent's NEXT propose. The prompt for round R+1
   MUST include "your peer's last mutation was X, your peer's attacks
   on you were Y — use both to inform your R+1 proposal."
8. **Goal-driven termination** — see Termination subsection below.

### Pair configuration

`--pair=<A>,<B>` configures the two peers. **Diversity comes from
DIFFERENT CONTEXT FRAMING per peer, not from one peer being weaker.**
Stephen 2026-04-26 correction: "co-research 也要用 opus 4.7 max effort
不一样的 context 而已" — downgrading one peer to a smaller model dilutes
proposal quality without proportionate diversity gain. Both peers should
run at full capability; diversity is engineered via prompt framing
(different file reads, different attack angle, different goal-emphasis).

| Pair | Diversity source | Cost | Allowed? |
|---|---|---|---|
| `claude-opus,codex-latest` (currently `gpt-5.5`) | Cross-model + per-peer context-framing | Highest | ✓ default for high-stakes |
| `claude-opus,claude-opus + different context` | Per-peer context-framing only | High×2 | ✓ default when codex unavailable |
| `claude-opus,claude-haiku` | Cross-scale (weaker B) + context-framing | Medium | ⚠ fallback only — Peer B proposes weaker, less productive synthesis |
| `claude-opus,claude-opus + same context` | None | High×2 | ✗ rejected — pure RLHF-prior overlap, no signal |

**Empirical validation (2026-04-26 audit-followup-boss-grasp campaign,
first co-research dogfood)**:
- Round 1 used opus×haiku (BOSS bug): haiku Peer B gave decent attack
  list but missed the synthesis. Peer A had to drive the dispatch-level
  fix solo.
- Round 2 used opus×opus + different-context (GRaSP cache enable):
  Peer B caught 2 attacks Peer A would've shipped without (d>30 OOM
  risk, CV-determinism future-proofing). Synthesis materially improved.

Confirms: **same-tier model with different context >> different-tier
same-context** for substantive co-research.

### Context-framing recipes for opus×opus pairs

To engineer diversity without different models:
- Peer A: load codebase top-down (read main entry → trace down to bug site)
- Peer B: load codebase bottom-up (read leaf utility → trace up to caller)
- Peer A prompted as "implementer" (propose fix)
- Peer B prompted as "auditor" (propose attack list against any fix)
- Peer A reads `Strategy` axes 1, 3, 5; Peer B reads axes 2, 4, 6
- Peer A starts from "what's the smallest fix", B starts from "what's
  the most robust fix"

The dispatch should give each peer a DIFFERENT slice of context, not
just a different prompt prefix.

When codex CLI unavailable at startup → degrade to `claude-opus,claude-opus
+ different context`, NOT to `claude-opus,claude-haiku`. Loud notice
in console + escalations.md (same protocol as unilateral).

### Doc-task cross-attack: making prose attackable (v2.14)

Code-diff cross-attack has clear failure modes (test fail / type error /
regression). Doc-diff has none — peers attacking each other's prose
naturally degenerate into "I prefer my style," which is unilateral self-
attack disguised as cross-review (rule #13's same-prior collapse, applied
to evaluation rather than mutation).

A "real attack" on a doc must satisfy ALL FIVE criteria:

1. **Concrete** — cite the specific line / paragraph / claim being attacked
   (line N or quoted phrase verbatim).
2. **Falsifiable** — the attack states what would have to be true for the
   doc to be wrong, in a form the author can verify or refute.
3. **Class-grounded** — labeled with a doc-class attack class (C1–C4 from
   the Attack Class Library) or another named class.
4. **Explicit falsification statement with grep-able / runnable / countable X**
   — every attack MUST include a sentence in the form
   `"this is wrong if X, because the doc claims Y"`, where:
   - X is one of: (a) a grep-able quote/pattern in the doc or another
     file (e.g., `grep -F "foo" file.md returns 0 hits`), (b) a shell
     command output (e.g., `running scripts/check.py exits ≠ 0`), (c) a
     count/measurement (e.g., `the doc has 3 sections claiming Z but
     only 1 has supporting evidence`), or (d) a verifiable factual claim
     about external state (e.g., `numpy 2.0 removed np.foo per
     numpy/numpy#1234`).
   - X is NOT: aesthetic preference, reader hypothesis ("a reader cannot
     follow"), tone judgment, rigor judgment, "feels" / "seems" /
     "unclear" / "hard-to-follow" / "muddled" / "lacks rigor" / "could be
     clearer" / variants thereof.
   - Y is a verbatim or paraphrased quote from the doc, with the doc's
     line number cited.
5. **Resolvable** — the doc author can either (a) accept and edit, (b)
   point to where the doc already addresses the attack, or (c) explicitly
   defer with rationale. "I disagree" without one of these three is invalid.

**Cross-attack prompt template (co-research peer dispatch, doc-task)**:

> You are reviewing peer-A's draft of [doc target, path]. Your job is to
> find what BREAKS, not what you would have written differently. Apply the
> doc-class attack library (C1–C4) plus any program.md domain extensions.
>
> For each attack, output exactly this structure:
>
> ```
> [class label, e.g., C1 / C2 / domain-name]
> Cite: <line N or "quoted phrase">
> Falsification: this is wrong if <X — grep-able / runnable / countable observation>, because the doc claims (line M) <Y verbatim>
> Severity: BLOCKER | MAJOR | MINOR
> Resolution: <accept-and-edit | already-addressed-at-line-N | defer-with-rationale>
> ```
>
> Empty attack list is acceptable IFF every C1–C4 was concretely probed
> against the draft AND the n/a reason includes a **grep-able trace**, not
> a bare assertion. Example acceptable: `C1 n/a — grep -nE "scope|expand|
> beyond" draft.md returned only Goal-declared entries at lines 12–18`.
> Example rejected: `C1 n/a — no scope drift`.

**Forbidden in attacks** (orchestrator auto-rejects round; respawn required):
- Any attack lacking the explicit "this is wrong if X, because Y" form
  (criterion 4) — this is the structural defense; literal-string filters
  on phrases like "could be clearer" are bypassable, the form requirement
  with grep-able / runnable / countable X is not.
- X reduces to aesthetic / reader-experience / tone / rigor judgment, even
  when wrapped in the falsification form.
- Class label without falsification statement.
- n/a-this-target without grep-able trace.

**Failure modes**:

- Peer returns >50% attacks failing criterion 4 → re-spawn with explicit
  "criterion 4 violation, retry with grep-able / runnable / countable X
  required."
- After 2 re-spawn failures on the same peer → escalate
  (`escalations.md`, mark doc-task `cross-attack-degenerate`) AND switch
  to **dispatched-single-adversary mode**: orchestrator dispatches a
  brand-new adversary subagent (`Agent + Skill('dissect')` or
  `codex exec` subprocess), writing nonce-headered `adversary.txt` per
  rule #11. State.json records this round with
  `state.rounds[N].coresearch_degraded: true` for post-campaign provenance.
  This is unilateral mode (rule #1 + rule #11 + rule #8 self-judge gate
  all active), NOT mutator-attacks-own-propose-in-conversation (forbidden
  by rule #13). Escalation acknowledges co-research has degenerated for
  this round; it does NOT relax the dispatched-adversary requirement.

**Applies to**: SKILL.md edits, program.md drafts, design docs, proposal
docs, plan files, decision recs, research-output writeups.

**Does NOT apply to**: code-diff (use default 7 + code-domain extensions),
executable specs (use research-class + execution gate per rule #9), data
analysis output (use research-class + audit-class).

### Goal-driven termination (v2.15 — applies to BOTH modes now)

v2.15 unifies the termination schema across unilateral and co-research
(previously, co-research had its own narrower set; v2.15 extends the
co-research telos to unilateral and adds Frame-break Protocol as the
shared creative-escape mechanism).

Both modes terminate on (per INVARIANTS rule #6):

1. **Goal met** — eval ≥ target (unilateral) OR champion eval ≥ target
   (co-research) → DONE.
2. **No-proposal-after-K-frame-breaks** — `state.frame_break_count_consecutive
   ≥ K` (default K=2) AND the most recent Frame-break Protocol run
   yielded no `candidate_routes` entry with `est_metric_delta > 0`
   despite executing all 5 frame-break steps. This is the v2.15
   "creative exhaustion" termination — the LLM has tried both its
   primary frame and 5 expansions and still cannot generate a
   positive-EV next step. **Plateau-on-metric and adversary-exhausted
   alone do NOT terminate**; they trigger Frame-break Protocol instead.
3. **Mutual KILL deadlock** (co-research only) — N=3 rounds where both
   agents' mutations revert to baseline (every attack succeeds on both
   sides) → ESCALATE ("the goal as framed may be impossible / requires
   architecture change").
4. **User interrupt** — SIGINT/SIGTERM → `status=interrupted`, finish
   current atomic operation, write handoff, exit.

`adversary-exhausted` and `metric-plateau-alone` are explicitly NOT
termination conditions in v2.15 (either mode). They are signals that
trigger Frame-break Protocol. See "Frame-break Protocol" section
below for the 5-step creative-escape sequence the loop runs BEFORE
declaring `no-proposal-after-K-frame-breaks`.

### Cost vs unilateral

2× per round (two implement + two eval + two attack). Mitigated by:
- Higher per-round info gain (two angles explored, mutual inspiration)
- Lower expected total rounds (goal-driven plateau detection stops earlier)
- Better escape from local optima (one peer's failure becomes the other's input)

Empirical (TBD; first co-research run will calibrate): expect 2× cost
per round but ~1.5× fewer rounds for non-trivial work → ~33% net
overhead for substantially better diversity coverage.

### When NOT to use co-research

- Trivial fix (typo, rename, single-line patch) — overhead dominates
- Pure verification of known target (use unilateral with attack-class
  checklist + cross-model adversary instead)
- Single-axis optimization with one obvious mechanism (no diversity
  to leverage)
- Cost-sensitive batch (cron jobs, nightly sweeps) — unilateral is cheaper

## Frame-break Protocol (v2.15) — creative escape, not termination

When a round looks "stuck" — adversary returns no attacks, OR
metric_delta is ≤ 0, OR all candidate_routes have est_metric_delta ≤
0 — v2.14 would have called this plateau or adversary-exhausted and
terminated the loop. v2.15 instead treats stuck-ness as the **exact
moment LLM creative capacity should fire**, not the moment to give
up. The loop runs Frame-break Protocol BEFORE any termination claim.

### Trigger conditions

Frame-break fires (sets `state.rounds[N].frame_break_fired = true` and
increments `state.frame_break_count_consecutive`) when ANY of:

1. Adversary verdict is `no-attacks` for the round (proxy for
   adversary-exhausted, single round)
2. `mission_thread.metric_delta ≤ 0` AND `blocker_status ∉ {removed,
   partially}`
3. All entries in `mission_thread.candidate_routes` have
   `est_metric_delta ≤ 0` (or all marked `unknown` outside an
   exploration-round chain ≤ 2)

Resetting: `frame_break_count_consecutive = 0` whenever a subsequent
round produces `metric_delta > 0` OR `blocker_status ∈ {removed,
partially}`. The counter measures *consecutive* exhaustion only.

### The 5 mandatory steps (in order, all must run before declaring no-proposal)

When triggered, BEFORE the round's final state is written and BEFORE
considering termination, the mutator MUST execute:

**Step 1 — Reject-pool mining**

Scan `state.rounds[*].mission_thread.candidate_routes` (all prior rounds,
all peers in co-research). Surface the top-3 unselected routes ranked by
`est_metric_delta > 0`. Promote them to the current round's
`candidate_routes` (de-duped against existing entries by mechanism
similarity). Record in `state.rounds[N].frame_break_steps_run` with
the source rounds.

Why: best-of-M historically discarded M-1 with no inheritance. Frame-break
treats the discard pool as warm-start fuel.

**Step 2 — Attack-class library escalation**

Load 1 additional attack-class library not currently in program.md
Attack Classes from abelian's library set (default-7, doc-class,
research-class, audit-class, decision-class, code-domain extensions —
whichever is most cross-domain to the current Task class). Re-spawn
the adversary with the expanded class list and an explicit "find
attacks the prior frame missed because it didn't have these classes"
prompt. Write to `$RUN_DIR/round-N/adversary-frame-break.txt` with
its own nonce header (rule #11 applies).

Why: codex 2026-04-26 P0 audit dogfood — dissect declared exhausted
but missed `subprocess command injection` because the class wasn't in
its frame. Frame-break expands the frame.

**Step 3 — Peer framing swap (co-research mode only)**

Swap peer-A's and peer-B's context-framing for the next round's
proposal step. Examples:
- A=optimist/B=auditor → B=optimist/A=auditor
- A reads Strategy axes 1,3,5 → reads 2,4,6 next round
- A starts top-down → starts bottom-up
- A "smallest fix" → "most robust fix"

If unilateral mode, skip this step (no peer to swap with), record
`step-3: skipped (unilateral)` in `frame_break_steps_run`.

Why: same context-framing two rounds in a row produces same RLHF prior
output. Forced swap surfaces the framing-locality of the stuck-ness.

**Step 4 — Goal re-paraphrase from current state**

Re-read program.md Goal verbatim, then prompt mutator to write a fresh
`goal_paraphrase` for next round based on "where we currently are vs
the goal" rather than re-hashing the original framing. The paraphrase
MUST cite the current metric value and the gap to target. Allow up to
N=2 speculative routes (`est_metric_delta: "unknown"`) to seed
exploration; this exploration window is bounded by the
`exploration_round=true` constraint and `frame_break_count_consecutive
≤ 2` guard in commit-gate check 10.

Why: original program.md framing may be exhausted but a re-paraphrase
from current state surfaces unknown-unknown directions. The bounded
exploration window prevents the loop from becoming pure exploration.

**v2.16 — abort-to-round-0 conditions**: step 4 distinguishes two
outcomes (rule #16 boundary):

- **In-frame re-paraphrase** (default): Takeaway and program-contract
  hash still valid; mutator generates fresh paraphrase from current
  metric vs target gap; loop continues normally with bounded
  exploration.
- **Contract invalidity surfaces** → abort to round-0 with
  `state.round_0.reconfirmation_required = true`:
  - `metric_delta` direction inverts mid-run (sign change with absolute
    value ≥ `Metric.tolerance`) — metric no longer measures the goal
    as Takeaway claimed.
  - `Takeaway.Validated_by` stops being grep-able / runnable (e.g.,
    cited file deleted, cited shell command missing).
  - Program-contract hash mismatch surfaces during refresh.

Aborting to round-0 is the correct response to contract invalidity:
the LLM cannot creatively escape a broken contract; only the human
can re-confirm. Resume after re-confirmation via `--reconfirm-gate`.

**Step 5 — Cross-peer alternative_routes mining (co-research mode only)**

For each peer, read the OTHER peer's most recent `peer-X.txt`
informational `alternative_routes:` section (line 273 partial
relaxation product). Promote any route with `est_metric_delta > 0`
to the next round's `mission_thread.candidate_routes` for THIS peer.
Record in `frame_break_steps_run`.

If unilateral mode, skip (no peer to mine), record `step-5: skipped
(unilateral)` in `frame_break_steps_run`.

Why: bonus prompt edit to line 273 lets co-research adversary suggest
informational routes; without a mining step, that signal would be
unused. Frame-break makes it consumed.

### Termination via no-proposal-after-K-frame-breaks

Only after ALL applicable steps run (steps 1, 2, 4 always; steps 3 and
5 in co-research mode) AND the resulting `mission_thread.candidate_routes`
for the next round contains zero entries with `est_metric_delta > 0`
AND this state has held for `frame_break_count_consecutive ≥ K`
(default K=2) → terminate with `status=completed`,
`termination.condition = "no-proposal-after-K-frame-breaks"`.

This is the v2.15 "creative exhaustion" termination. It is materially
stricter than v2.14's `adversary-exhausted` because it requires the LLM
to have demonstrably tried 5 forms of frame-breaking and still found
nothing. K=2 (consecutive) means the loop must have failed to escape
on at least 2 different rounds with full frame-break sequences before
giving up.

### Why not just "stop on plateau"

Stopping on plateau = telling the LLM "your creative capacity is
bounded by the current frame's vocabulary." Frame-break encodes the
opposite: "your creative capacity is precisely for breaking frames;
plateau is when you should fire it, not when you should give up."

Plateau-as-termination was a v1.x adversarial-loop inheritance: in
optimization, plateau is gradient-zero, stop. In adversarial, plateau
is no-attack-lands, stop. In **goal-driven co-research**, plateau is
"current frame's candidate pool exhausted, time to escape frame." The
escape mechanism is the 5-step protocol; only when the LLM has tried
all 5 and can produce no positive-EV route is exhaustion real.

### Cost

Frame-break adds ~1× round cost when fired (one extra adversary call
in step 2, no extra eval). With K=2 default, the worst-case overhead
above v2.14 termination is ~2 extra rounds × ~1× round = ~2 round-equivalents
before terminate. In return, the loop catches "we're stuck within the
frame, what other frames are there?" — the exact failure mode codex's
56-round PM dogfood demonstrated v2.14 could not catch.

### State.json frame-break trace

```json
"frame_break_count_consecutive": 1,
"rounds": [
  ...,
  {
    "n": 27,
    "frame_break_fired": true,
    "frame_break_steps_run": [
      "step-1: mined 2 routes from rounds 12, 19",
      "step-2: escalated to research-class library, found 1 new attack",
      "step-3: skipped (unilateral)",
      "step-4: re-paraphrased goal from current metric (0.42 vs target 0.8)",
      "step-5: skipped (unilateral)"
    ],
    "mission_thread": { ... },
    "verdict_line": "1 attack found via library escalation"
  }
]
```

## Attack Class Checklist (v2.5)

Single adversaries have frames. dissect R3 in a P0 audit campaign (2026-04-26)
declared "exhausted" but missed `subprocess command injection` — a class
that wasn't in its frame. Codex on the eventual PR caught it. Rule: every
round, adversary MUST address each class in the checklist (even if just
to mark `n/a-this-target`). Missing class = round not complete.

### Default 7 classes (universal)
| # | Class | What to probe |
|---|---|---|
| 1 | **auth-surface** | unauthenticated paths, header injection, token comparison (constant-time?), missing endpoints |
| 2 | **fp-numerics** | associativity (Python `+=` vs `np.sum`), pairwise vs sequential reduction, NaN/Inf propagation, ddof confusion |
| 3 | **race / TOCTOU** | validate-then-use gap, lock release ordering, shared-state mutation outside lock |
| 4 | **version-drift** | cross-package compat (e.g., NetworkX 3.3 removed `d_separated`), legacy method signatures, retired API symbols |
| 5 | **layout-sensitive** | bash quirks (`set -o pipefail` + `grep -q` SIGPIPE, `set -e` in `if`), encoding (UTF-8 vs ASCII), OS path separators, line endings |
| 6 | **unauth surface info-leak** | `/health` over-share, error messages reflecting input, 404 echoes user-controlled `id` |
| 7 | **error-path / log-poisoning** | control-char injection, oversized input reflection, traceback leaking secrets/paths |

### Attack Class Library (v2.14, named domain taxonomies)

Beyond the default 7, abelian ships named libraries for non-code domains.
Without a library, attack-class coverage varies per author and per campaign
(TODO.md gap #3, "trial-and-error per user"); a named library standardizes
the address-list so coverage doesn't depend on what the program.md author
happened to think of.

Each library is opt-in. Cite by name in `program.md` Attack Classes section
as a list:

```markdown
## Attack Classes
- default
- doc-class
- research-class
- regime-shift-2026Q1     # custom domain-specific
- liquidity-cliff         # custom domain-specific
```

**Migration**: existing program.md Attack Classes sections written under
v2.5 syntax (bullet list of strings) remain valid and are treated as
`[default] + <listed bullets>`. Library names are new identifiers; the
list-of-strings grammar is unchanged.

**Namespace discipline** (NEW v2.14): the four library identifiers
(`research-class`, `audit-class`, `decision-class`, `doc-class`) and any
future `*-class` suffix are RESERVED. Custom domain-specific extensions
must NOT use the `*-class` suffix (collision risk: a v2.5 program.md that
named a custom extension `audit-class` for an unrelated auditing concern
now ambiguously triggers v2.14's audit-class library mandate). On v2.14
migration, rename custom-class collisions to `<domain>-custom`,
`<domain>-extension`, or another scheme. Loop refuses to start when a
custom name in Attack Classes matches a reserved library identifier
unless explicit `--accept-reserved-name-collision` flag passed.

#### research-class (6 classes, for empirical investigation / data analysis)

| # | Class | What to probe |
|---|---|---|
| R1 | **selection-bias** | sample selection process, survivorship effects, any filter that conditions on the outcome variable |
| R2 | **overfit** | in-sample tuning vs out-of-sample test, hyperparameter search degrees of freedom, multiple-comparisons inflation |
| R3 | **regime-shift** | training distribution vs deployment distribution, structural breaks, non-stationarity |
| R4 | **look-ahead** | future information leaking into past features, temporal join correctness, t+1 features used at t |
| R5 | **target-leakage** | target's own derivative used as a feature (proxy variable), train/val contamination via shared keys |
| R6 | **replication-failure** | does the result hold on independent data / different seed / different operationalization, or sample-specific |

#### audit-class (4 classes, for review / verification of prior claims)

| # | Class | What to probe |
|---|---|---|
| A1 | **confirmation-bias** | did the analyst frame queries to find evidence FOR a held belief? what alternative would have falsified the conclusion |
| A2 | **motivated-reasoning** | does the analyst have stake in the outcome? are negatives soft-pedaled |
| A3 | **cherry-pick** | reported subset vs underlying population — was anything excluded without justification |
| A4 | **strawman** | does the prior claim being audited match what the original author actually wrote (verbatim grep), or a softer version |

#### decision-class (4 classes, for high-stakes choice under uncertainty)

| # | Class | What to probe |
|---|---|---|
| D1 | **sunk-cost** | does the recommendation justify keeping prior commitment because of past investment alone |
| D2 | **loss-aversion** | is the recommendation systematically conservative because losses loom larger than gains, asymmetrically with the actual payoff distribution |
| D3 | **availability-heuristic** | is the example set memory-of-recent-events vs base-rate-representative |
| D4 | **scope-creep** | does the proposed action stretch beyond the stated decision boundary (e.g., "fix bug" turns into "redesign module") |

#### doc-class (4 classes, for prose / spec / proposal documents)

| # | Class | What to probe |
|---|---|---|
| C1 | **scope-drift** | does the doc's claim/proposal exceed what the Goal section authorized — added requirements, larger surface, broader audience |
| C2 | **hidden-assumption** | what unstated **logical/conceptual** premise must hold for the doc's conclusion to be true; cite the line where the assumption hides. Distinct from default class #5 layout-sensitive (which covers physical/encoding/format premises). When doc contains code samples, BOTH must be probed. |
| C3 | **definition-elasticity** | does a term shift meaning between sections (e.g., "user" = end-user in §1, = developer in §3) — break the chain |
| C4 | **authority-by-citation** | a claim is supported by citing X without checking X actually says it; or appeal to "best practice" without source |

#### Code-domain extensions (existing, unchanged)

- **Code-speedup campaigns**: `bit-identity-vs-baseline`, `override-hook-preservation`, `cache-key-completeness`, `cache-eviction-bounded`
- **API service campaigns**: `subprocess command injection`, `path traversal beyond suffix check`, `symlink escape from sandbox dir`
- **Data pipeline campaigns**: `schema drift`, `null/missing-value handling`, `unicode normalization`, `timezone semantics`
- **ML training campaigns**: prefer **research-class** (R1–R6 covers train/val contamination, regime mismatch, target leakage); add domain extensions on top as needed

**Library opt-in is mandatory for non-code tasks.** The `task:` field in
program.md (see "What You Need" above) declares task class. Loop refuses
to start when `task != code` AND Attack Classes does not list at least
one non-default library. Existing v2.5 program.md without `task:` field
defaults to `task: code` — backwards-compat — but emits a loud warning
(see "What You Need").

### Adversary prompt requirement (loop enforces)
The Agent prompt for each round MUST include:
> Address EACH attack class below. For each: either provide a specific attack, or explicitly mark `n/a-this-target` with one-sentence reason. Round is incomplete if any class is unaddressed.
> Classes: [list from program.md]

If adversary returns without addressing all classes → loop re-spawns with explicit "missing class X" reminder. After 2 re-spawn failures on same class → escalate (write to escalations.md).

## Eval Discipline

Self-judge shares the mutator's biases (the v1 caveat). Hierarchy of evals, best to worst:

1. Shell command returning a number (deterministic, non-LLM)
2. Shell command running a test suite (deterministic, non-LLM)
3. Self-judge with frozen rubric (LLM, but constrained)
4. Self-judge freeform (LLM, vibes — refuse to use)

**Strong default (v2.3): if Target includes any executable artifact (code, scripts, runnable specs, queryable data), use levels 1-2 — actually run it.** Self-judge (level 3) is the **degraded mode** for cases where execution truly cannot apply (paradigm exploration, design discussion, qualitative judgment). When you have execution available and choose self-judge anyway, you're choosing rubric-vibes over ground truth — defensible only if runtime cost is genuinely prohibitive AND adversary will catch what you'd have caught by running. Most rounds should be executable.

When self-judge is unavoidable:
- Rubric frozen in `program.md` Metric BEFORE loop starts (no rubric drift mid-run)
- `--adversary` MUST be on — loop refuses to start with `--adversary=off` + self-judge
- Self-judge runs in a separate `Agent` call from the mutator, no shared context
- **Schema-grounding required (v2.2)** — if the mutation references external schema (file paths, column names, API contracts, stored data formats, function signatures), the self-judge MUST verify each reference against the actual source (`Read` the file, run a SQL probe, hit the API) BEFORE scoring. A self-judge that scored ≥ rubric_max without a grounding step is structurally untrustworthy and must be re-scored as 0 on the affected dimensions. Pre-emption ("I expect adversary will probe X") catches things you already know to look for; grounding catches the unknown unknowns. Added after abelian's own first real run (Polymarket Round 1, 2026-04-22) where 2 BLOCKER typos were 4/4 self-judged then immediately caught by Codex SQL grounding.

LLMs never argue "this is better." They argue "this passes/fails the rubric." Verdicts are red/green, not vibes.

## Portfolio Mode (`--portfolio=K`, default K=1)

With K>1: maintain top-K solutions indexed by behavior cell.

- Each kept mutation lives on its own git branch: `abelian/portfolio/<cell-slug>`
- New mutation replaces a cell's incumbent only if it beats that cell's score
- Loop's objective shifts from "optimize one" to **"fill cells"** — Quality-Diversity / MAP-Elites style
- Compound doc includes a per-cell comparison table at the end

Use when multiple valid approaches exist (architectures, algorithm classes, tradeoff axes — speed vs memory vs simplicity). Skip for single-axis micro-optimization where diversity has no meaning.

If `program.md` lists Cells, the loop targets those cells explicitly. If not, the LLM auto-tags and the cell space grows organically.

## Escalation (`abelian/escalations.md`)

The loop writes to escalations file (does NOT stop the loop) whenever:

- **Diversity collapse** (K>1): 5+ rounds with no new cell filled and candidate edit-distance falling
- **Adversary↔eval contradiction**: adversary insists on attack but eval keeps passing → eval is too narrow; needs human to expand it
- **Source-of-truth drift**: re-reading `program.md` Goal mid-run yields a different interpretation than round 0 → loop has rewritten the spec in its head
- **Attack-class re-spawn failure** (v2.5): adversary failed to address a checklist class after 2 reminder re-spawns

Escalations are first-class output. The loop continues on tractable branches; the final compound doc surfaces escalations under "Decisions Awaiting Human."

### Mandatory Post-Campaign Escalation Review (v2.5)

Happy-path triggers above don't fire when adversary catches all attacks
and they all convert to probes — yet the loop often **knowingly punts**
items (P-too-low to fix this campaign / P-out-of-scope / design-decision-
deferred-to-human). These deferred items belong in `escalations.md` but
get lost in compound doc footnotes.

**Rule**: before writing the compound doc, the loop runs ONE final
adversary call with this prompt:

> The campaign converged. List concrete items the loop SKIPPED, DEFERRED,
> or DECLINED to address that a human reviewer should know. Format each as:
> `[severity] item-name — what would be needed / why deferred`. Empty list
> is acceptable IFF the campaign was truly exhaustive on the in-scope items.

Output appends to `escalations.md` (header `## Post-campaign deferrals`).

**Compound doc enforcement**: the "Open escalations" section becomes
**required**. Either:
- N items listed (copied from escalations.md), OR
- Explicit statement: "Loop ran post-campaign escalation review and found
  zero deferred items — campaign is exhaustive on in-scope items."

A compound doc with empty "Open escalations" + no explicit-attempt
statement = **protocol violation**. The loop refuses to claim "done" until
this section is filled.

**Why mandatory**: this turns "0 escalations" from a default into a
deliberate claim. Prevents the silent kicked-down-the-road items (e.g.,
P0-audit campaign 2026-04-26 had 4 deferred items in compound doc but
escalations.md was empty — wrong place, wrong visibility for reviewers).

## Termination Discipline (v2.15 rewrite of v2.9)

Abelian runs **till converge**. There is no `--rounds` cap, no `--budget` flag, no wallclock cap. A loop's termination claim is valid only if backed by mechanism, not preference. INVARIANTS rule #6 enumerates 5 forbidden rationales — "diminishing returns", "time/token remaining", "deferred to next session", "foundation in place", "cleaner to ship". These are stopping preferences disguised as conclusions; treat them as hard refusals.

**v2.15 telos shift**: termination requires goal-progress evidence OR creative exhaustion (Frame-break Protocol fired without yielding a positive-EV route), NOT adversary-exhaustion alone. The loop's goal is goal-fulfillment, not attack-survival. Adversary mechanism is preserved (every round still runs adversary with nonce header per rule #11 + attack-class checklist), but adversary-exhausted no longer terminates by itself — it triggers Frame-break Protocol, which is the LLM's creative-escape opportunity.

Valid termination conditions (v2.15, K=2 default for frame-break exhaustion threshold):

- **Goal met** — eval ≥ target (unilateral) OR champion ≥ target (co-research)
- **No-proposal-after-K-frame-breaks** — `state.frame_break_count_consecutive ≥ K` (default K=2) AND the most recent Frame-break Protocol run yielded no `mission_thread.candidate_routes` entry with `est_metric_delta > 0` despite executing all 5 mandatory frame-break steps. This is the "creative exhaustion" termination — the LLM has demonstrably tried both its primary frame and 5 frame-break expansions without finding a positive-EV next step. See "Frame-break Protocol" section.
- **Mutual KILL deadlock** (co-research only) — N=3 rounds where both agents' mutations revert to baseline (every attack succeeds on both sides). Escalates with "the goal as framed may be impossible / requires architecture change."

**v2.15 removed conditions** (compared to v2.14):
- ~~**Adversary exhausted across attack classes for N=3 consecutive rounds**~~ — REMOVED as standalone termination. Now triggers Frame-break Protocol; only after K consecutive frame-breaks fail does the loop terminate via no-proposal-after-K-frame-breaks. This closes the v2.14 failure mode where attack-survival could substitute for goal-progress.
- ~~**Plateau (metric stopped improving alone)**~~ — REMOVED as standalone termination. Now triggers Frame-break Protocol. Plateau is the moment the LLM should creatively escape, not give up.

If a mechanism signal would not fire by round 3+K=5, the loop has not actually converged. Either tighten the program.md target/eval or wait for the user to abort manually.

**Manual abort path** (not a termination condition, an emergency stop):
- User sends SIGINT (Ctrl+C) or SIGTERM
- Abelian marks `state.status = "interrupted"`, finishes the current round's atomic operation if mid-commit (per night-shift's "finish current task" pattern), writes handoff/compound-doc with explicit interrupted marker, exits.

**Contract-drift re-entry (v2.16)**: when a run hit
`status=contract-drift-stopped` (rule #16 program-contract hash
mismatch during refresh), the run is paused, not terminated. Resume:

```bash
abelian program.md --reconfirm-gate  # same RUN_ID
```

Re-runs the full round-0 Program Contract Gate (steps A–F) — fresh
checklist + fresh baseline eval + fresh program-adversary + new
contract hash + new confirmation. On approval, sets
`state.round_0.reconfirmation_required = false`, stores new hash,
clears `contract-drift-stopped`, and resumes from the next round
(rounds completed before drift remain valid; mid-drift round if any
was reverted on the gate trip). State.json gains a
`reconfirmation_history[]` array recording each re-gate event with
old hash → new hash transition.

Alternative: start a new RUN_ID with the modified program.md. Choose
based on whether the contract change is semantically continuous
(re-confirm same campaign) or a new campaign altogether.

**Self-check before terminating** (mandatory): re-read INVARIANTS rule #6 from disk (rule #3) and verify your claimed reason is on the v2.15 valid list, not the forbidden list. Document the rule-#6 self-check in `state.termination` block:

```json
"termination": {
  "condition": "goal-met | no-proposal-after-K-frame-breaks | mutual-KILL | interrupted",
  "evidence": "<verbatim quote from eval/adversary/state — for no-proposal, must cite frame_break_count_consecutive and last frame-break run's empty positive-EV route list>",
  "rounds_at_termination": 12,
  "frame_break_count_consecutive": 2,
  "rule6_self_check": "<one sentence — which forbidden rationale was tempting and why it does not apply>"
}
```

If you cannot fill `rule6_self_check` with a substantive answer, you are about to terminate on a preference. Run another round.

If terminating via `no-proposal-after-K-frame-breaks`, the `evidence` field MUST include the most recent round's `frame_break_steps_run` array showing all applicable steps actually executed. Termination claim with `frame_break_count_consecutive < K` or with empty `frame_break_steps_run` is gate-fail (loop refuses to terminate).

## When It Ends: Auto-Compound

**Step 0 (v2.5 mandatory)**: run the Post-Campaign Escalation Review (see
Escalation section). Loop refuses to write compound doc until escalations.md
either has the deferred items OR has the explicit "0 deferrals attempted"
statement.

After the loop ends, automatically write learnings to:

```
docs/solutions/[category]/[goal-slug]-[date].md
```

Contents:
- **What worked** — kept mutations ranked by impact, grouped by cell (portfolio mode)
- **What didn't** — reverts grouped by failure pattern (eval-fail / adversary-fail / both)
- **Adversary catches** — attacks that flipped "kept" → "reverted" (highest-signal entries; prioritize for future sessions)
- **Judgment calls** — non-obvious decisions that mattered
- **Baseline → Final** — quantified improvement; per-cell deltas in portfolio mode
- **Open escalations** *(MANDATORY v2.5)* — copy of unresolved items from escalations.md including the post-campaign deferrals section. If empty, MUST include the explicit statement "Loop ran post-campaign escalation review and found zero deferred items — campaign is exhaustive on in-scope items." A blank section without this statement = protocol violation.
- **Next session starting point**

**Locked template (v2.8).** Field order is fixed (What worked → What didn't → Adversary catches → Judgment calls → Baseline → Open escalations → Next session). No free-form prose between fields, no embellishment. The headline of any user-facing summary derived from this doc MUST be the verbatim first sentence of "What worked" — do not paraphrase, do not compose new wording. Cross-doc visual consistency is what makes scan-review across compound docs possible.

CE-compatible YAML frontmatter:

```yaml
---
title: "[Goal] optimization: [baseline]→[final]"
date: YYYY-MM-DD
category: [auto-detected]
module: [from program.md Target]
problem_type: best_practice
severity: medium
applies_when:
  - "Re-optimizing [Target] in future sessions"
  - "Similar optimization problems in [domain]"
tags: [abelian, from program.md]
---
```

Future `/abelian` runs on the same target: search `docs/solutions/` first. If a prior compound doc exists, load its "what worked / what didn't / adversary catches" into Strategy + Cells before starting. **Each run starts where the last one ended.**

Future `/ce:plan` runs: the learnings-researcher finds these docs automatically. No extra step needed.

## Execution Gate (v2.3 termination requirement)

Adversary-exhaustion is **necessary but not sufficient** for termination. The loop also requires an execution gate: at least one round per cell must have produced a Target artifact that:

1. Was **actually executed** in this loop (level 1 or 2 eval)
2. Eval at execution-time was **deterministic non-LLM** (shell returns a number, tests pass/fail, output matches acceptance criteria)
3. Adversary saw the **execution output**, not just the spec

**Why:** adversaries also tire. After N rounds, "no new attacks" can mean either "the artifact is good" or "adversary's attack imagination within its frame is exhausted." Two LLMs reaching mutual silence ≠ artifact surviving real execution. Polymarket Round 1-RETRY (2026-04-22) closed 5 attacks DISMISSED on a SPEC for fixing audit.py + aggregate_hourly.py — but no code was written or run. That's a checkpoint, not a destination. The execution gate forces the loop to reach "did it actually work" rather than stop at "did the spec survive review."

**For doc-only Target** (paradigm exploration, design docs where no code exists yet): execution gate becomes "the doc was consumed by a downstream process / human and they confirmed it solved their problem." Default loop **must NOT** terminate on adversary-exhaustion alone if no executable round exists for the target cell.

**How to apply at program.md level:** mark Target executable artifacts with shell-runnable Eval; set `termination_requires_execution_gate: true` (default). Doc-only mode set `termination_requires_execution_gate: false` explicitly + provide a downstream-confirmation step.

**Key inversion:** when execution is in the loop, the abelian structure becomes MORE valuable, not less — adversary now has two surfaces (code logic + actual output), mutation is verifiable via git, portfolio cells produce real numbers. Spec-only mode is the corner case; executable mode is the bedrock.

## Safety Rules

- Never edit files outside Target
- Never modify the eval command itself (adding regression tests to expand coverage is OK; changing what is measured is not)
- Never run with `--adversary=off` when Eval is `self-judge` — refuse to start (no degradation)
- When requested adversary is unavailable (e.g., codex CLI binary missing OR not auth'd OR codex MCP wrapper not configured), degrade gracefully to `dissect` — but the degradation MUST be loud (console + escalations.md + History). Silent fallback is forbidden.
- Always revert on error
- If metric worsens >50% in one round, flag and revert
- **Long eval MUST be detached (v2.4).** Eval commands with any of: wallclock >30s, spill to disk, window/sort over >10M rows, or known memory footprint >2 GB MUST run via `nohup <cmd> > logs/X.log 2>&1 & echo $! > logs/X.pid`. Inline (blocking) eval is ONLY for deterministic <30s shell commands. Rationale: in-session OOM can kill the loop's parent Claude process (confirmed 2026-04-22 Polymarket DuckDB spill + 2026-04-24 FCI bench 57GB RSS balloon). Detached eval survives session death; the next round reads `logs/X.pid` + `logs/X.log` to pick up. Cap `--threads` to ~half of cores for jobs with spill-manager (DuckDB, joblib with BLAS inner) to leave headroom.
- Respect time budget
- Escalations file is always written (empty file is fine — proves the gate ran)
- Adversary subagent context is isolated per round; never share its conversation across rounds
- **Production-runtime safety (v2.7, 2026-04-26).** When Target includes a file that a production process (cron, supervisor, systemd watchdog, hot-reload server) imports continuously, the loop MUST address the file-save vs git-commit timeline gap. Two failure modes happen at every mid-cell save, not at commit boundaries: (a) production picks up WIP intermediate state between adversary rounds; (b) a fresh-fixture eval passes while the deployed state is incompatible.

  **Required mitigations (pick at least one per cell that touches such a file):**
  1. **Suspend the production process** for the campaign window — comment cron entry / stop systemd unit / pause watcher. Resume + verify one full cycle clean before claiming the cell done.
  2. **Run eval against actual deployed state** alongside fresh-fixture eval — e.g.: `python3 -c "from <target> import <init>; import sqlite3; <init>(sqlite3.connect('<prod_db_backup>'))" || exit 1`. The prod-backup must be snapshotted at campaign start (not refreshed mid-run).
  3. **Pre-commit DDL audit** — for any new schema column added to a cron'd DB, the loop's eval MUST verify a matching idempotent ALTER block exists. Sketch: `new_cols = git diff | grep '^\+\s+\w+ (TEXT|INTEGER|REAL)'; alters = git diff | grep 'ALTER TABLE.*ADD COLUMN'; assert alters >= new_cols`. CREATE TABLE IF NOT EXISTS alone is insufficient — it silently skips against an incumbent schema.

  **Why mandatory**: 2026-04-26 pm-live-trade-infra Cell 2. I edited scanner.py twice within one commit (v1 fills schema → R2 hardening). Cron picked up v1 between edits, created production fills with 18 columns. R2 commit landed with `CREATE TABLE IF NOT EXISTS` (skipped) + `CREATE INDEX ON fills(mode, status)` (failed `no such column: mode`). Scanner crash-looped 36 minutes. The loop's adversary R2 actually flagged "schema-break" as an attack class but the verification test (`test_fills_schema_idempotent_double_migration`) only ran against fresh tmp_db — never against an incumbent v1 schema. Post-campaign reviewer correctly identified BLOCKER #1 but ran AFTER all 8 commits had landed; production was already broken. The structural insight: **abelian's atomicity model is "git commit = round = atomic deployment boundary," but cron/supervisor/watchdog observe file-save, not commit. Multi-edit commits leak intermediate states to production runtime regardless of git's view.**

  **Diagnostic for whether this rule applies**: search the cron / supervisor / systemd config for the Target file path. If found, the rule applies. If unsure, suspend cron — cheap insurance.
