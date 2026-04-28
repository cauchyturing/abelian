---
name: abelian
version: 2.8.2
description: >
  **Umbrella name for two distinct iteration modes** sharing common
  anti-collapse + anti-compaction infrastructure (portfolio, escalation,
  attack-class checklist, schema-grounding, execution-gate, post-campaign
  escalation review, plus v2.8: file-gated commits, drift check, per-round
  INVARIANTS.md re-read, state.json source-of-truth, forbidden termination
  rationales, pre-files snapshot, locked compound template — see INVARIANTS.md):

  - **Unilateral mode (default, "auto-verify-loop")** — generator + adversary —
    mutate → evaluate → attack → keep/revert. Best for: verification of known
    target, ship-prep, audit, regression hardening. Cost 1×. Cross-model
    adversary (Codex) opt-in for high-stakes.

  - **Co-research mode (v2.6, "auto-research-loop")** — two peer agents both
    propose AND challenge each other goal-driven; mutual inspiration prevents
    the hidden collapse of "attack-only adversary + propose-only generator."
    Best for: discovery, novel design, "where do I start", research with no
    obvious target. Cost 2×. **Diversity via DIFFERENT CONTEXT FRAMING per
    peer at SAME max-effort tier** (not via downgrading one peer). Cross-model
    pair preferred for highest diversity; same-model pair with different
    context-framing is acceptable and beats opus+haiku per empirical 2026-04-26.

  Pick mode by phase: known-target verification → unilateral; discovery /
  non-trivial design → co-research (--mode=co-research).

  **Target should include executable artifacts whenever possible —
  spec-only is the degraded mode for both modes.**

  Use when user says "abelian", "autoloop", "auto-optimize", "run experiments",
  "optimize this", or "Karpathy loop". The skill name is historical (covers
  unilateral verification too despite "research" framing); future v3.0 may flip
  default to co-research once empirical track record validates cost model.
user-invocable: true
argument-hint: 'abelian program.md [--rounds=N] [--chains=C] [--depth=L] [--candidates=M] [--adversary=<dissect|codex|both|off>] [--portfolio=K]'
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, Skill
---

# /abelian — Compound Iteration Loop

Mutate → evaluate → **adversary** → keep/revert → repeat. When done, learnings auto-persist to `docs/solutions/` for future sessions.

**v2.1 anti-collapse:** adversary on by default (dissect), portfolio K=1, escalations file always written. Cross-model adversary (`--adversary=codex`) opt-in for high-stakes runs. `--adversary=off` is a documented escape hatch but discouraged — see Eval Discipline.

**Why these defaults:** v1.0's self-judge mode shares the mutator's biases (acknowledged in the v1 caveat). v2.0 made the adversary structural — a separate agent whose job is to FIND WHAT BREAKS, never to "agree." v2.1 adds the cross-model option: same-family Claude adversaries break self-collapse but still share RLHF priors; Codex adversary breaks model-family collapse too. Termination is exhaustion of attacks, not consensus.

## What You Need

A `program.md` with these sections:

- **Goal** — one sentence
- **Target** — files the agent may edit
- **Eval** — shell command outputting a number (preferred) OR `self-judge` with a frozen rubric
- **Metric** — name, direction (min|max), baseline
- **Constraints** — what NOT to do
- **Strategy** — what to try, in what order
- **Cells** *(portfolio mode only)* — diversity axes you want covered (e.g., "memoization", "algorithm-swap", "data-restructure"). Free-text labels.
- **Attack Classes** *(v2.5)* — taxonomy of attack vectors the adversary MUST address each round (or explicitly mark `n/a-this-target`). Default 7 classes apply; add domain-specific ones. Closes "single-adversary single-frame exhaustion" gap. See "Attack Class Checklist" section below.
- **History** — auto-populated by the loop

## Pre-Flight (v2.8)

Before the first round, verify `.gitignore` covers the language
ecosystem's default build artifacts. The drift check (INVARIANTS rule #4)
treats any dirty file outside the round's plan as drift — including
untracked `__pycache__/` from a baseline `python3 bench.py` invocation.
A missing pattern = `drift-stopped` on round 1, the campaign dies before
landing a single mutation.

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
  "shape": {"rounds": 10, "chains": 1, "depth": 1, "candidates": 1, "portfolio": 1},
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

Valid run `status`: `running`, `completed`, `interrupted`, `drift-stopped`, `cap-fired`, `gate-failed-terminal`.
Valid round `status`: `pending`, `mutated`, `eval-done`, `adversary-done`, `kept`, `reverted`, `gate-failed`.

Update after: every round step transition, every commit, every revert,
status changes, eval results, post-campaign escalation review.

## Search Shape (v2.4) — C × L × Candidates

Default: **C=1, L=1, candidates=1** — one mutation per round, sequential. The Loop section below describes this case; most campaigns run here and should not bump these levers without cause.

For harder problems, factor compute budget across three orthogonal levers:

| Lever | What it does | Default | When to bump |
|-------|--------------|---------|--------------|
| **C** (chains) | Parallel approaches — each chain explores a *different axis* from Strategy. Chains run concurrently on ephemeral branches `abelian/chain-<c>/`. | 1 | Strategy lists multiple **independent, pre-identified** axes that don't need serial profile-guided discovery (e.g., speedup campaign targeting 3 CI methods — FisherZ / chisq / d_separation — each hits a different class, no cross-deps). Do NOT bump C when each next direction depends on the previous result. |
| **L** (depth) | Sequential refinement within a chain — each step uses evaluator feedback to improve the previous step's commit. | 1 | Evaluator output is rich (cProfile breakdown, structured error messages, failing test names) AND single-shot mutations rarely hit target. Polish-pass regime. |
| **candidates** (best-of-M) | Per-step variants — generate M candidates, pick best by **EVAL** (not adversary) before committing. Rejects are discarded, not logged per-row. | 1 | Eval is cheap (<1s) and single-sample generation variance is high (temperature-sensitive, ambiguous prompts). Cost: M× eval spend per step, 0× extra adversary. |

**Orthogonal to Portfolio K.** `--portfolio=K` maintains K diverse cells (MAP-Elites) ACROSS rounds; C/L/candidates shape WITHIN a round. Chains in C>1 can write into different portfolio cells if both are set.

### Budget accounting (v2.4 requirement, v2.5 corrected)

Loop MUST announce before starting:

```
Campaign: <name>
Shape:    rounds=R, chains=C, depth=L, candidates=M, portfolio=K
Raw budget:        R × C × L × M       eval runs
                   R × C × L           adversary calls
Effective budget:  raw × (1 + α × β)   accounts for fix-iter cycles
                   α = expected attack rate per round
                       (dissect 0.6, codex xhigh 0.8, both 1.0)
                   β = avg fix cost in eval+adversary units (default 1.5)
                   → multiplier ~1.9× (dissect) / ~2.2× (codex) / ~2.5× (both)
Adversary cost note: codex xhigh (latest stable, currently gpt-5.5) ≈ $0.5-2/call.
```

**v2.5 budget correction**: v2.4 raw formula systematically under-estimated 2-12× (P0 audit campaign 2026-04-26: budget said 6 calls, actual was ~12 evals + 4 large adversary calls + multiple fix-iter cycles ≈ 60min wall). Each adversary attack triggers ~1.5 fix-iter cycles (write fix → re-eval → maybe re-adversary). Plan with the multiplier.

User confirms before loop begins. Refuse to start if (effective budget > 30) without explicit `--confirm-budget` flag.

### Parallel expansion semantics (C>1 or L>1 or candidates>1)

- **C chains in parallel** (per round): each chain runs The Loop's steps 1-5 independently on `abelian/chain-<c>/` branch. After all C chains complete step 5, "Place" picks the best chain's commit as new champion; others go to portfolio cells (if K>1) or revert.
- **L depth per chain** (per chain): steps 1-5 repeat L times sequentially within a chain. Each step refines on the previous step's commit using evaluator feedback from that commit. Adversary runs once per step. A revert at any step terminates that chain (don't keep refining a broken trunk).
- **Candidates M per step** (inside step 1): Hypothesize generates M testable variants. Each is mutated + evaluated separately (no adversary yet). Best-eval variant is chosen; ONLY that variant gets adversary + Confirm + Place. Rejected variants logged as summary line, not full rows.

### Invocation

```
/abelian program.md \
  --rounds=R \
  --chains=C      # default 1
  --depth=L       # default 1
  --candidates=M  # default 1
  --portfolio=K   # default 1 (single champion)
  --adversary=codex
```

## The Loop

For each round:

0. **Refresh (v2.8)** — `cat $SKILL_DIR/INVARIANTS.md && cat $RUN_DIR/state.json` from disk. Conversation memory of these rules drifts after R3+ compactions; the file is truth. INVARIANTS rule #3.
1. **Hypothesize** — read Strategy + state.json `rounds[]` + current state → generate ONE testable change. Tag the change with a cell label (free-text, ≤3 words).
2. **Mutate** — apply the change (minimal, one idea per round). Before writing, snapshot pre-files: `mkdir -p $RUN_DIR/round-N && { git ls-files -z; git ls-files -z --others --exclude-standard; } | sort -zu > $RUN_DIR/round-N/pre-files.txt`. INVARIANTS rule #5.
3. **Evaluate** — run eval command, or self-judge against frozen rubric. Write metric value to `$RUN_DIR/round-N/eval.txt` and update `state.rounds[N].metric_value`.
4. **Adversary** — spawn `Agent(general-purpose)` that runs `Skill('dissect')` on the diff + eval output. Adversary subagent MUST write full attack list (or `n/a-this-target` per class) to `$RUN_DIR/round-N/adversary.txt` BEFORE returning, and the verdict line MUST be recorded in `state.rounds[N].verdict_line`. INVARIANTS rules #1, #7. (See Adversary section.)
5. **Confirm** — no attacks: run commit-gate (INVARIANTS rule #2, 7 checks: `adversary.txt` non-empty + header block nonce matches `state.adversary_nonce` + mtime in `(adversary_started_at, now)` + verdict_line `grep -qF` in body + drift check + `pre-files.txt` exists + eval value matches state). All 7 pass → `git commit`. Any fail → revert (`git checkout` + scoped clean of new files via pre/post diff), mark round `gate-failed`. With attacks: convert each to a verification (regression test, worst-case benchmark input, or added rubric criterion) and re-eval. Any verification fails → revert. Black-box eval with no augmentation surface: log attack as `provisional-flag`, keep but mark.
6. **Place** — K=1 mode: replace champion if better, else revert. K>1 mode: replace THIS cell's incumbent only if it beats that cell's score. New cell label → seed that cell.
7. **Record** — append to History: kept/reverted/error, cell, adversary-result, metric delta.
8. **Adapt** — 5 consecutive reverts → shift strategy. 5 rounds with no new cell filled (K>1) → write to `escalations.md`. All directions exhausted → stop early.

## Adversary

**Driver-neutral protocol**: a fresh adversary subagent receives a prompt that includes verbatim `program.md` Goal/Target/Constraints/Attack-Classes + a fresh nonce + ISO timestamp, executes in isolated context with its own tool access (Read/Bash/Write or equivalent), writes the attack list to `$RUN_DIR/round-N/adversary.txt` with a mandatory `ABELIAN-ADV-v1` header (rule #11), and returns the verdict line. Two reference dispatches:

- **Claude Code primary**: `Agent(general-purpose)` running `Skill('dissect')` — see [`drivers/claude-code/README.md`](drivers/claude-code/README.md). This is the default for `/abelian program.md` invocation in a Claude Code session. Adversary subagent is a Claude with same RLHF family as the mutator — structural role split, weak prior split.
- **Codex CLI primary**: `codex exec - -s workspace-write` subprocess + the [`prompts/dissect.md`](prompts/dissect.md) template — see [`drivers/codex-cli/README.md`](drivers/codex-cli/README.md) and the runnable [`drivers/codex-cli/abelian.sh`](drivers/codex-cli/abelian.sh). Self×self default (codex × codex with different prompt context per role at full max-effort).

Both drivers honor the same protocol and INVARIANTS. The descriptions below use Claude Code idiom (Agent / Skill / MCP) because abelian's original implementation was Claude Code. Codex CLI users substitute `codex exec` for `Agent(...)` and `prompts/dissect.md` content for `Skill('dissect')`. Mechanism, header, gate, and INVARIANTS are byte-for-byte identical.

Override via `--adversary=<value>`:

| Value | Adversary | Prior separation | Cost | When to use |
|-------|-----------|------------------|------|-------------|
| `dissect` (default) | Claude subagent + `Skill('dissect')` | Weak (same RLHF family) | Low | Most cases, zero-config, portable |
| `codex` | Codex MCP (`mcp__codex__codex`, **latest stable** — currently `gpt-5.5` — + xhigh per `feedback_codex_review_config.md`) | Strong (cross model family) | High | High stakes, self-judge eval, key decisions |
| `both` | Both adversaries; **union of attacks** (no consensus required) | Strongest | Highest | 24/7 night-shift, PR-level / production decisions |
| `off` | None | — | None | Shell-eval only; **refused** when Eval is `self-judge` |

**File-gated output (v2.8).** The adversary subagent MUST write its full attack list (or empty list with explicit `n/a-this-target` per attack class) to `$RUN_DIR/round-N/adversary.txt` BEFORE returning. Co-research writes `peer-A.txt` and `peer-B.txt` separately. Conversation-only return = invalid, fails commit-gate. The agent prompt MUST quote `program.md` Goal/Target/Constraints/Attack-Classes verbatim — paraphrasing forbidden. INVARIANTS rules #1, #7.

**Header-block protocol (v2.8 anti-fabrication).** Before each adversary call, the mutator generates a fresh `nonce` (16 hex via `secrets.token_hex(8)`) and `started_at` (ISO ms) and writes both into `state.rounds[N].{adversary_nonce, adversary_started_at}`. The prompt instructs the subagent to write a mandatory header block (`ABELIAN-ADV-v1` + run_id + round + peer + nonce + started_at + verdict, then `---`, then attacks) as the first lines of the output file. Commit-gate verifies nonce match + mtime in valid range + verdict in body. INVARIANTS rule #11. This is friction-level defense (not cryptographic) targeting Threat-1: post-compaction "forgot to call adversary" silent fabrication. A mutator must now cat state.json to find the nonce, which triggers cat INVARIANTS, which surfaces "must actually call adversary."

**Adversary's job:** find what breaks, NOT propose alternatives. Cannot endorse, only attack.

**Graceful degradation (loud, never silent):**
- `--adversary=codex` + Codex MCP unavailable → degrade to `dissect`, **write notice in 3 places**: console (stderr), `abelian/escalations.md`, and History row for the affected rounds. Continue loop.
- `--adversary=both` + Codex MCP unavailable → degrade to `dissect`-only with same 3-place notice. Continue loop.
- Degradation decision is made **once at loop start** — don't re-check Codex every round (noise + unpredictable runs).
- The notice must include the why: "Codex MCP `mcp__codex__codex` not reachable; cross-model adversary disabled; runs are weaker on prior diversity for this session."
- `--adversary=off` + Eval=`self-judge` → **hard refuse to start** (no degradation). This combination has zero LLM check on a vibes-based eval — structurally unsafe.

**Honest limit:** Default `dissect` breaks structural self-collapse but does NOT break model-family collapse. Two Claudes with role split still share RLHF priors. For high-stakes decisions, `--adversary=codex` is the cross-model upgrade — don't default-trust the default.

Termination = "adversary exhausted attacks across N rounds," not "metric stopped improving alone." This is the structural anti-collapse: there's no vocabulary for "agree to stop." **v2.5 refinement**: "exhausted" must be measured ACROSS the Attack Class Checklist below, not within a single adversary's frame — single-adversary single-frame exhaustion ≠ attack-space exhaustion.

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

When unavailable Codex MCP at startup → degrade to `claude-opus,claude-opus
+ different context`, NOT to `claude-opus,claude-haiku`. Loud notice
in console + escalations.md (same protocol as unilateral).

### Goal-driven termination (replaces adversary-exhaustion)

Co-research terminates on:
1. **Goal met** — champion eval ≥ target → DONE.
2. **Plateau + diversity collapse** — N consecutive rounds with no eval
   improvement AND candidate edit-distance falling → ESCALATE + STOP.
   This is the structural anti-collapse: if both agents are converging
   on similar mutations AND the metric isn't moving, the loop has
   exhausted productive disagreement, not attack space.
3. **Mutual KILL deadlock** — N rounds where both agents' mutations
   revert to baseline (every attack succeeds on both sides) → ESCALATE
   ("the goal as framed may be impossible / requires architecture change").

Adversary-exhausted alone is **NOT** a termination condition in co-research
mode. Without active proposals from both peers, "no attacks left" is
indistinguishable from "no proposals left to attack." Goal-fitness +
diversity are the dual termination signals.

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

### Domain-specific extensions (add in `program.md` Attack Classes section)
- **Code-speedup campaigns**: `bit-identity-vs-baseline`, `override-hook-preservation`, `cache-key-completeness`, `cache-eviction-bounded`
- **API service campaigns**: `subprocess command injection`, `path traversal beyond suffix check`, `symlink escape from sandbox dir`
- **Data pipeline campaigns**: `schema drift`, `null/missing-value handling`, `unicode normalization`, `timezone semantics`
- **ML training campaigns**: `target leakage`, `train/val contamination`, `regime mismatch`, `bootstrap stability`

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

## Termination Discipline (v2.8)

A loop's termination claim is valid only if backed by mechanism, not preference. INVARIANTS rule #6 enumerates 5 forbidden rationales — "diminishing returns", "time remaining", "deferred to next session", "foundation in place", "cleaner to ship". These are stopping preferences disguised as conclusions; treat them as hard refusals.

Valid termination conditions only:

- **Goal met** — eval ≥ target (unilateral) OR champion ≥ target (co-research)
- **Adversary exhausted across all attack classes** + execution gate satisfied (INVARIANTS rule #9)
- **Plateau + diversity collapse** — N rounds no eval improvement AND candidate edit-distance falling (co-research)
- **Mutual KILL deadlock** — every peer attack succeeds on both sides for N rounds (co-research)
- **--rounds cap fired** — handled by the runtime, no rationale required

If your honest framing of "why stop" reduces to a forbidden rationale, do NOT write the termination claim or post-campaign compound doc. Run another round. The cap will catch the runtime case on its own.

**Self-check before terminating** (mandatory): re-read INVARIANTS rule #6 from disk (rule #3) and verify your claimed reason is on the valid list, not the forbidden list. Document the rule-#6 self-check in `state.termination` block:

```json
"termination": {
  "condition": "goal-met | adversary-exhausted | plateau | mutual-KILL | cap-fired",
  "evidence": "<verbatim quote from eval/adversary/state>",
  "rule6_self_check": "<one sentence — which forbidden rationale was tempting and why it does not apply>"
}
```

If you cannot fill `rule6_self_check` with a substantive answer, you are about to terminate on a preference. Run another round.

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
- When requested adversary is unavailable (e.g., Codex MCP missing), degrade gracefully to `dissect` — but the degradation MUST be loud (console + escalations.md + History). Silent fallback is forbidden.
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
