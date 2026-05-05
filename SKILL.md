---
name: abelian
version: 3.0.0
description: >
  **Adversarial collaboration framework** (Kahneman-style applied to LLM
  dispatch) for deep, innovative, long-horizon iteration with tractable
  doc and testable metric.

  **One loop, one discipline**: every configured peer (default 2)
  proposes AND attacks every other peer's proposals. Mutual inspiration
  between rounds. Mechanism-converge termination. 18 INVARIANTS rules
  harden against fabrication, drift, compaction, mission drift,
  cross-layer evidence confusion, fuzzy-program-contract, fuzzy-mission,
  and propose/counter discipline asymmetry.

  **Asymmetric peer discipline (rule #18)**: when a peer is in PROPOSE
  mode (generating a mutation, candidate route, outcome distillation,
  metric forge, lever surfacing, or any "what should we try?" output),
  it must be **innovative AND grounded** — novel framings + ≥1
  cited file / command / output (no vibes, no fabrication). When a peer
  is in COUNTER mode (responding to another peer's attack on its own
  work), it must be **strictly verification-oriented** — convert the
  attack to a probe (regression test / benchmark / rubric criterion /
  shell command), run it, return PASS/FAIL evidence. Argumentation
  without falsification target is forbidden in counter mode; if the
  attack cannot be converted to a probe, the mutation reverts.

  **Two stages, ONE loop, auto-detected from input**:
  - `abelian program.md` — sharp contract; skip goal-authoring stage
  - `abelian --mission "<fuzzy text>"` — fuzzy mission; goal-authoring
    stage runs first (rule #17), produces program.md draft, then loop
    enters round-0 gate and round-mutation stage

  Same mechanism (propose + attack + converge) applied at different
  abstraction layers. Goal-authoring is not a separate mode; it is the
  loop operating on the goal as the artifact.

  **Peer configuration** is auto-detected from driver (Claude Code → `claude+claude`; codex CLI → `codex+codex`). Cross-family `claude+codex` is opt-in via program.md `Peer policy: cross-family` (doubles cost, requires both LLMs available).

  Default cost with 2 peers is explicit, not hidden: 2 proposals + 2 evals
  + 2 cross-attacks per round, plus probes and optional codex review.
  Diversity comes from DIFFERENT CONTEXT FRAMING per peer at SAME
  max-effort tier.

  Tasks that genuinely fit single-peer review (typo fix, single-axis verify,
  ship-prep against a known target) are out of abelian's scope — abelian
  is for adversarial collaboration on innovative work, not single-axis
  verification. Use a separate review tool for those.

  **Skill activation rule (rule #13)**: any conversation-level reference
  to this skill — campaign or meta-audit — that involves ≥3 mutation
  proposals, protocol-level changes, or "verdict / done / keep / revert
  / accept / pareto / trade-off" vocabulary applied to mutation evaluation
  triggers a hard requirement: spawn a dispatched peer (Agent + prompts/dissect.md inlined
  OR codex exec subprocess) BEFORE reaching verdict. Self-challenge in
  conversation context is unilateral self-judge (rule #8 degraded mode),
  not co-research. RLHF prior overlap means an agent attacking its own
  propose shares priors over BOTH "what to mutate" and "how to attack" —
  empirical 17× catch-rate gap (peer-B vs self-challenge, 2026-04-29
  self-audit) confirms severity.

  **Target should include executable artifacts whenever possible —
  spec-only is the degraded mode for both modes.**

  Version history: see [README.md](README.md) Changelog or `git log`.

  Use when user says "abelian", "autoloop", "auto-optimize", "run experiments",
  "optimize this", "Karpathy loop", or any adversarial-collaboration mutation
  campaign. v3.0 collapses prior mode lexicon (unilateral / co-research / dissect /
  codex / off) into ONE loop with peer configuration; legacy flags
  deprecated, see Migration section.
user-invocable: true
argument-hint: 'abelian program.md  |  abelian --mission "<fuzzy text>"  |  abelian --mission-file <path>'
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, Skill
---

# /abelian — Adversarial Collaboration Loop

Two peers each propose AND attack each other's proposals → keep/revert by goal-progress + attack-survival → mutual inspiration → repeat. Goal-met / no-proposal-after-K-frame-breaks / mutual-KILL = converge. Learnings auto-persist to `docs/solutions/` for future sessions.

Defaults: peer challenge always on (no off-switch); same-family 2-peer pair auto-detected from driver; portfolio K=1; mechanism-converge termination (no rounds/budget/wallclock cap). Cross-family pair, search shape, code-review supplemental, etc. declared in program.md (no CLI flags).

## What You Need

A `program.md` with these sections:

- **Goal** — one sentence (≤200 chars). v2.16 hard-checks for measurable noun (whitelist `number | percentage | sharpe | recall | runtime | file-count | pass-rate | precision | latency | throughput | bytes | count`); standalone process-verbs (`improve | better | investigate | explore | study | examine | analyze`) are rejected as too fuzzy. Truly unspecified-metric tasks belong in `ce-brainstorm`, not abelian.
- **Task class** — one of `code | research | audit | decision | doc | mixed`. Determines mandatory Attack Classes coverage. If absent, loop emits LOUD WARNING (stderr + `escalations.md` + state.json + History row) and defaults to `code` for v2.5+ backwards-compat. `task: mixed` declares primary + supplementary classes (`task: code; doc` applies both library mandates).
- **Target** — files the agent may edit. v2.16 hard-checks each path's parent directory exists, and each path either (a) exists, OR (b) has explicit `create:` marker (e.g., `Target: docs/new-design.md create:`) declaring it will be created. Inside-repo only (no `..` escape, no absolute paths outside repo root).
- **Eval** — shell command outputting a number (preferred) OR `self-judge` with a frozen rubric. For non-`code` task classes, see INVARIANTS rule #8 fuzzy-ground protocol — `Eval ground:` declaration required. v2.16: round-0 runs Eval ONCE against unmutated baseline, stores result in `$RUN_DIR/round-0/eval.txt`, validates against declared Metric.baseline within Metric.tolerance.
- **Eval ground** *(v2.14, required for non-`code` task classes per INVARIANTS rule #8)* — declared ground source(s): ≥1 of (b)/(c)/(d) options from rule #8; option (a) self-ground is supplementary only.
- **Metric** — `<name>: <baseline> <direction> [<tolerance>]`. Direction ∈ `{min, max}`. All progress gates use direction-normalized `progress_delta`: for `max`, `new - old`; for `min`, `old - new`. Testable per positioning — rubric score, count, coverage rate, runtime; not vibes / human-acceptance-only. Tasks that cannot articulate a testable metric are out of scope for abelian (use ce-brainstorm or human discussion). **Tolerance (v2.16)**: defaults by type when omitted — `pass-rate / file-count / count` → exact (0); `float / runtime` → epsilon = max(1e-9, 0.01 × |baseline|); noisy benchmarks → repeated_median (5 runs). Tolerance enables baseline validation in round-0 step C without rejecting legitimate measurement noise.
- **Constraints** — what NOT to do
- **Strategy** — what to try, in what order. v2.16 hard-checks ≥2 axes (chains C>1 and co-research depend on diversity; single-axis = use unilateral mode + a different tool, not abelian).
- **Cells** *(portfolio mode only)* — diversity axes you want covered (e.g., "memoization", "algorithm-swap", "data-restructure"). Free-text labels.
- **Attack Classes** *(v2.5, expanded v2.14)* — taxonomy of attack vectors the adversary MUST address each round (or explicitly mark `n/a-this-target` with grep-able trace). Default 7 classes always apply; non-`code` tasks MUST opt in to ≥1 named library (research-class / audit-class / decision-class / doc-class). See "Attack Class Library" section below. v2.16: at round-0 program-adversary uses a LOCKED set independent of program.md Attack Classes — `{c1-scope-drift, c2-hidden-assumption, c3-definition-elasticity, c4-authority-by-citation, d4-scope-creep}` — for program-contract integrity check.
- **Takeaway** *(v2.16, NEW required section)* — derived contract: 3 fields, each must trace to Goal/Eval/Metric/Constraints via quote-grep + semantic linkage. NOT a parallel truth source; gate fails on Takeaway-vs-source contradiction. See "Round-0 Authoring Gate" section below for the Takeaway schema and rule #16 for full enforcement.
- **History** — auto-populated by the loop

**Optional sections** (declare in program.md to override defaults; no CLI flags):

- **Shape** — `chains: 1 / depth: 1 / candidates: 1 / portfolio: 1` (per-round compute levers; bump only when Strategy has independent axes / eval rich enough for refinement / variance high / multiple cells worth keeping)
- **Peer policy** — `same-family` (default) | `cross-family` (claude+codex; doubles cost, requires both LLMs available)
- **Code review** — `on` (rule #12 supplemental code-quality gate; default off — cost roughly doubles per round)

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
- **Validated by**: <eval/metric/artifact, grep-able / runnable / countable>
- **Constraints**: <≤2 lines>
```

Quote-grep + semantic linkage (rule #16 B): Success cites Goal phrase + Metric name+direction; Validated_by cites Eval/Metric phrase + grep-able/runnable; Constraints cites ≥1 actual prohibition. Aesthetic / reader-experience claims rejected (rule #14 doc-task criterion 4). Full enforcement: rule #16 B.

### Round-0 gate steps (full spec: rule #16)

1. **Hard checklist** (binary fast-fail): all program.md fields per "What You Need" + Takeaway 3 fields present.
2. **Baseline eval**: run Eval once on unmutated tree → `round-0/eval.txt`; validate against `Metric.baseline ± Metric.tolerance`. Mismatch → TTY prompt "measured X vs declared Y; accept measured? (y/edit/abort)". Non-TTY → exit `gate-failed-terminal` with edit instructions.
3. **Program-peer-challenge**: spawn dissect peer with locked attack classes `{c1, c2, c3, c4, d4}` → `round-0/program-peer-challenge.txt` with rule #11 header (`peer: program-gate`). BLOCKER → refuse; MAJOR → stderr + escalations.md.
4. **Contract hash**: sha256 over normalized program-contract sections; stored in `state.round_0.program_contract_hash`. Per-round refresh (rule #3) recomputes; mismatch → `contract-drift-stopped`. Resolution: new RUN_ID OR re-run `abelian program.md` (TTY prompt re-runs round-0 with new hash).
5. **Confirmation**: print Takeaway + baseline + peer-challenge verdict + contract hash + cost shape → TTY prompt "go/no" (no timeout). Non-TTY: exit `gate-failed-terminal` with the printed summary so user can review and re-invoke (no auto-launch in non-TTY — peer-challenge cost requires explicit human go).

### Migration & pre-flight

v2.x program.md missing `## Takeaway` → round-0 hard checklist fails → TTY prompt "draft Takeaway from Goal/Eval/Metric/Constraints? (y/n)". On `y`: writes Takeaway to program.md + emits diff + exits (user reviews + commits + re-invokes). Other v2.x gaps (no baseline, Strategy <2 axes, missing Eval ground) require manual fix — automated migration of more fields = silent fabrication.

Pre-flight `.gitignore`: ensure language build artifacts ignored before round 1 (Python `__pycache__/`, Node `node_modules/`, Rust `target/`, Go `vendor/`, C/C++ `build/` + `*.o/*.so/*.a`). Missing pattern → drift-stopped on round 1.

## Goal-Authoring Stage — INVARIANTS rule #17

Triggered by `abelian --mission "<fuzzy text>"`. Rule #17 is abelian's native compiler from fuzzy mission to rule #16-compliant program.md draft. Same propose+attack discipline as the round loop, applied at goal-authoring level.

```bash
abelian --mission "<fuzzy text>"     # string
abelian --mission-file <path>        # file (may include `Target hint:` section to bound reconnaissance)
```

File auto-detect: `abelian <existing-file>` lacking `## Goal` → prompt "Run goal-authoring stage? (y/n)". Bare strings NEVER auto-classified (typo risk).

### 5 passes (full schema in INVARIANTS rule #17)

| # | Output | Cost | Locked attack classes |
|---|---|---|---|
| 0 — Triage | classification: `sharp / fuzzy-but-grounded / fuzzy-ungrounded / single-axis` | ~$0.05 | n/a |
| 1 — Outcome Distillation + Grounding | observable end-state + ≥1 ground citation | ~$0.5 | c1, c2 |
| 2 — Metric Forge + Runnable Eval | metric + runnable Eval shell + dry-run-parse | ~$0.5 | c3, c4 |
| 3 — Lever + Constraint | ≥2 Strategy axes + Constraints (Pass 3 attack byproduct) | ~$0.5 | d4, c1 |
| 4 — Takeaway Derivation | mechanical compose Takeaway 3 fields | $0 | n/a (mechanical_validator) |

Pass 0 exits early on `sharp` (already program.md-grade) or `fuzzy-ungrounded` (route to ce-brainstorm) or `single-axis` (route to a different review tool).

### Bounded reconnaissance

Reads only: fuzzy mission text, optional `Target hint:` paths declared in mission-file, top-3-noun keyword grep, last 200 lines of session history. Forbidden: full repo TODOs, CLAUDE.md, full git log. Each citation recorded in trace.json with `citation_type` (`user_message | target_hint | grep_hit | session_tail`).

### Cost

~$1.65-2.15 per fuzzy mission ($1.55 sharpening + $0.10 round-0 program-adversary). 100× ROI on a single multi-round-fuzz catch.

### Why not OKR

OKR is user-driven hierarchical decomposition (Objective → KR → Task). v3.0 is per-field adversarial cycles done by peer pair + dissect — leverages LLM enumeration + cross-attack rather than user cognitive scaffolding. Full schema, fail-out paths, and trace.json structure live in INVARIANTS rule #17.

## State Persistence — `$RUN_DIR/state.json`

`state.json` is the single source of truth across context compactions; persist after every phase transition; re-read at round step 0 (rule #3). `$RUN_DIR = abelian/runs/<RUN_ID>/` (`RUN_ID` = local-time `YYYY-MM-DD-HHMM`). Per-round artifacts at `$RUN_DIR/round-N/{peer-A/, peer-B/, peer-A.txt, peer-B.txt, pre-files.txt, champion.md}`; each peer dir holds its own `proposal.md`, `diff.patch`, and `eval.txt`.

Top-level keys:

```
run_id, status, mode, started_at, branch, base_commit, expected_head, program_path,
shape (chains/depth/candidates/portfolio), peers, frame_break_count_consecutive,
rounds[], champion, portfolio_cells, escalations_file,
sharpening,    // see rule #17
round_0        // see rule #16 H
```

Per-round keys (within `rounds[]`): `n, cell, status, peer_candidates[{slot, route_id, metric_value, progress_delta, diff_patch, eval_file}], champion_slot, champion_metric_value, champion_progress_delta, peer_<slot>_{verdict_line, nonce, started_at, file}, mission_thread (rule #14), pre_files_file, frame_break_fired, frame_break_steps_run[], commit, started_at, ended_at`.

Run `status`: `running | completed | interrupted | drift-stopped (rule #4) | contract-drift-stopped (rule #16) | gate-failed-terminal`. Round `status`: `pending | mutated | eval-done | peer-done | kept | reverted | gate-failed`.

`frame_break_count_consecutive` resets on any round with `champion_progress_delta > 0` OR `blocker_status ∈ {removed, partially}`. Increments on each fired frame-break. Termination via `no-proposal-after-K-frame-breaks` checks against K (default 2).

## Mission Thread per round — rule #14

Every round populates `state.rounds[N].mission_thread` (7 fields) BEFORE commit-gate. Anchors per-round work to goal; closes the gap where `progress_delta` could be 0 round-after-round while attacks landed clean.

Peer workflow:

1. Re-read program.md (forced — `goal_paraphrase` MUST differ from prior round).
2. Survey prior `candidate_routes` for unpicked routes with positive `est_progress_delta` (reject-pool warm-start).
3. Generate ≥2 `candidate_routes` for THIS round (mechanism + `est_progress_delta` + est_cost + blocker_chain); assign at least one route to each peer.
4. Peers implement their assigned routes, cross-attack, then the orchestrator selects champion + writes `selection_reason` citing ≥1 unpicked route's trade-off by id.
5. Populate `champion_progress_delta` + `blocker_status` from eval/outcome.

Full schema + field rules: rule #14. Commit-gate: rule #2 check 8 (completeness + freshness + selection_reason trade-off cited) + check 10 (goal-progress: `champion_progress_delta > 0` OR `blocker_status ∈ {removed, partially}` OR `exploration_round: true` with `frame_break_count_consecutive ≤ 2`).

## Search Shape

Default `chains=1, depth=1, candidates=1, portfolio=1` — one true peer co-research round: peer-A and peer-B each produce one candidate, then cross-attack and champion selection. Most campaigns run here.

For harder problems, declare in program.md `## Shape`:

| Lever | What it does | When to bump |
|---|---|---|
| `chains: C` | parallel chains — each explores a different Strategy axis | Strategy has ≥2 independent pre-identified axes |
| `depth: L` | sequential refinement within a chain (uses prior eval feedback) | Eval output rich + single-shot rarely hits target |
| `candidates: M` | per-step best-of-M variants (rejects logged) | Eval cheap AND single-sample variance high |
| `portfolio: K` | K diverse cells across rounds (MAP-Elites) | Multiple valid mechanisms worth keeping per cell |

Per-round cost with peer count `P` (default 2): `Eval runs = C×L×M×P`, cross-attack calls = `C×L×M×P×(P-1)`, plus probe commands and optional champion-only `codex review`. Typical convergence remains mechanism-dependent, not promised by a fixed multiplier.

### Invocation

```
abelian program.md                          # sharp contract
abelian --mission "<fuzzy text>"            # fuzzy mission, string
abelian --mission-file <path>               # fuzzy mission, file
```

No `--rounds`, `--budget`, or wallclock flags — mechanism-converge per rule #6. Manual abort: SIGINT.

All other behavior (peer pair, search shape, code-review supplemental, baseline acceptance, contract drift re-entry, takeaway migration, non-TTY autostart) is set in program.md sections OR resolved at TTY-interactive prompts during round-0 / drift events. No CLI flag soup.

## The Loop

For each round:

0. **Refresh (v2.8)** — `cat $SKILL_DIR/INVARIANTS.md && cat $RUN_DIR/state.json` from disk. Conversation memory of these rules drifts after R3+ compactions; the file is truth. INVARIANTS rule #3.
1. **Propose** — peer-A and peer-B each select one grounded route from `candidate_routes` (different angles) and write `$RUN_DIR/round-N/peer-<slot>/proposal.md`.
2. **Mutate** — each peer implements only its route on an isolated branch/worktree. Before writes, snapshot pre-files: `mkdir -p $RUN_DIR/round-N && { git ls-files -z; git ls-files -z --others --exclude-standard; } | sort -zu > $RUN_DIR/round-N/pre-files.txt`. INVARIANTS rule #5.
3. **Evaluate** — run Eval for each candidate. Write `$RUN_DIR/round-N/peer-<slot>/eval.txt`, `diff.patch`, metric value, and direction-normalized `progress_delta`.
4. **Cross-attack** — peer-A attacks peer-B's diff+eval; peer-B attacks peer-A's diff+eval. Each challenge runs `prompts/dissect.md inlined` (Claude) or fresh `codex exec` (Codex CLI), writes `$RUN_DIR/round-N/peer-<slot>.txt` BEFORE returning, and records `state.rounds[N].peer_<slot>_verdict_line`. INVARIANTS rules #1, #7, #18.
5. **Verify** — attacks convert to probes. Probe fail or non-codifiable attack → candidate reverts; passing candidates survive.
6. **Champion / Confirm** — best surviving `progress_delta` wins. Run commit-gate (rule #2, 10 always-on + 1 conditional) on champion + peer files. Conditional: champion-only codex-review clean of P1/P2 when program.md declares `Code review: on` (11). Pass → `git commit`. Fail → revert.
7. **Place** — K=1 mode: replace champion if better, else revert. K>1 mode: replace THIS cell's incumbent only if it beats that cell's score. New cell label → seed that cell.
8. **Record** — append to History: kept/reverted/error, cell, peer-attack result, champion `progress_delta`.
9. **Living spec (R2+ conditional)** — after the mutual-inspiration handoff, only when `N >= 2` AND at least one revert occurred in the previous 2 rounds, run the spec-proposal prompt through the configured peer-family dispatch path: `Agent(...)` for Claude-family drivers, `codex exec` for Codex-family drivers, or a loud `codex unavailable` / fallback notice if the configured subprocess is unavailable:

   ```text
   Read program.md and state.json rounds 0-2. What 1-3 specific changes to Goal/Constraints/Strategy would make this campaign more likely to succeed based on what actually happened? Justify each change with evidence from rounds. Only propose if there's signal the current spec is wrong — no aesthetic drift. If reverts were implementation failures (wrong code, not wrong direction), respond: NO_SPEC_CHANGE.
   ```

   Write output to `$RUN_DIR/round-N/spec-proposal.md`. Orchestrator reviews before round `N+1`; no automatic program.md rewrite.
10. **Adapt** — 5 consecutive reverts → shift strategy. 5 rounds with no new cell filled (K>1) → write to `escalations.md`. All directions exhausted → stop early.

## Peer Challenge

Challenge peer receives a prompt with verbatim `program.md` Goal/Target/Constraints/resolved Attack-Classes + the opponent's diff + eval + fresh nonce + ISO timestamp + `prompts/dissect.md` inlined → writes attack list to `peer-<slot>.txt` with rule #11 header → returns verdict line. Both drivers preserve isolated context: Claude Code uses `Agent(general-purpose)`, codex CLI uses fresh `codex exec` subprocesses.

Each peer's CHALLENGE phase (rule #18 COUNTER mode) may also write an informational `alternative_routes:` section after attacks — non-binding but mineable by next round's `mission_thread.candidate_routes` (rule #14 reject-pool / Frame-break step 5).

### Pair configuration

Driver default is same-family (`claude+claude` for Claude Code; `codex+codex` for codex CLI). Cross-family `claude+codex` opt-in via program.md `Peer policy: cross-family`. Diversity comes from DIFFERENT CONTEXT FRAMING per peer at SAME max-effort tier (don't downgrade one peer).

| Pair | Diversity source | When |
|---|---|---|
| `claude+codex` | Cross-family + framing | High-stakes |
| `claude+claude` (Claude Code default) | Same-family + different framing | Most cases, codex unavailable |
| `codex+codex` (codex CLI default) | Same-family + different framing | Codex-CLI-native runs |

Context-framing recipes (peers must read DIFFERENT slices, not just different prompts): top-down vs bottom-up code reading; implementer vs auditor framing; Strategy axes 1,3,5 vs 2,4,6; smallest-fix vs most-robust-fix; etc.

### Doc-task cross-attack (v2.14)

Doc-diff has no test/type/regression failure mode. Peers attacking prose degenerate into "I prefer my style" (rule #13 same-prior collapse). v2.14 fix: every doc attack MUST satisfy criterion-4 form `"this is wrong if X, because the doc claims Y at line M"` where X is **grep-able / runnable / countable / verifiable factual claim** about external state. Aesthetic / "feels off" / "unclear" / "lacks rigor" attacks auto-rejected. Empty attack list acceptable IFF each Attack Class concretely probed AND `n/a` reason includes grep-able trace.

If >50% of a peer's attacks fail criterion-4 after re-spawn → escalate to `state.rounds[N].coresearch_degraded: true` + dispatch a single fresh peer (rule #1 + #11 still binding).

Applies to: SKILL.md / program.md / design docs / proposals / decision recs / research writeups. Does NOT apply to code-diff (use default Attack Classes) or executable specs (use rule #9 execution gate).

### Cost

Default 2-peer round = 2 proposal/implementation candidates + 2 evals + 2 cross-attacks, plus probes and optional champion-only code review. Cost is higher than reviewer-only loops; gain is real proposal diversity, not just duplicate review.

## Frame-break Protocol — creative escape, not termination

Plateau in a goal-driven co-research loop is when LLM creative capacity should fire, not when the loop should quit. Frame-break runs BEFORE any termination claim.

### Trigger

Fires (sets `frame_break_fired=true`, increments `frame_break_count_consecutive`) when ANY of:
1. Both peers' verdicts = no attacks (challenge-exhausted, single round)
2. `champion_progress_delta ≤ 0` AND `blocker_status ∉ {removed, partially}`
3. All `candidate_routes` have `est_progress_delta ≤ 0` (or all `"unknown"` outside an exploration chain ≤ 2)

Resets `frame_break_count_consecutive = 0` on any round with `champion_progress_delta > 0` OR `blocker_status ∈ {removed, partially}`.

### 5 mandatory steps (in order)

| # | Step | Action | Records in `frame_break_steps_run` |
|---|---|---|---|
| 1 | Reject-pool mining | Scan `state.rounds[*].mission_thread.candidate_routes`; promote top-3 unselected `est_progress_delta > 0` routes to current round (dedupe by mechanism) | source rounds |
| 2 | Attack-class library escalation | Load 1 additional library (cross-domain to Task class); fresh peer challenge with expanded classes → `round-N/peer-frame-break.txt` (rule #11 nonce header) | added library + new attacks count |
| 3 | Peer framing swap | Swap peers' context-framing for next round (optimist↔auditor; top-down↔bottom-up; Strategy axes 1,3,5↔2,4,6; smallest-fix↔robust-fix) | new framing pair |
| 4 | Goal re-paraphrase from current state | Mutator writes fresh `goal_paraphrase` based on current metric vs target gap; allow ≤2 speculative routes (`est_progress_delta: "unknown"`) bounded by `frame_break_count_consecutive ≤ 2` | re-paraphrased goal + speculative routes |
| 5 | Cross-peer alternative_routes mining | Promote each peer's informational `alternative_routes` (with `est_progress_delta > 0`) into the OTHER peer's next-round `candidate_routes` | promoted routes |

**Step 4 abort to round-0 instead of in-frame re-paraphrase** when contract invalidity surfaces (rule #16 I): raw metric movement contradicts `Metric.direction` by ≥ tolerance; `Takeaway.Validated_by` stops being grep-able/runnable; program-contract hash mismatch. Sets `state.round_0.reconfirmation_required = true`. Resume by re-invoking `abelian program.md` — TTY prompt walks user through fresh round-0 gate; non-TTY: exit with diagnostic.

### Termination via `no-proposal-after-K-frame-breaks`

Fires when ALL applicable steps run AND next-round `candidate_routes` contains zero entries with `est_progress_delta > 0` AND `frame_break_count_consecutive ≥ K` (default K=2). Materially stricter than challenge-exhaustion alone — requires 2 separate frame-break rounds across all 5 steps to have failed to surface positive-EV next steps.

### Cost

~1× round when fired (one extra peer challenge call in step 2, no extra eval). K=2 worst-case = ~2 round-equivalents before terminate. Catches "stuck within frame, what other frames exist?" — the failure mode v2.14 could not catch.

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

Library opt-in mandatory for non-code tasks (`task != code` AND no library listed → refuse start). `*-class` suffix RESERVED for libraries (custom extensions use `<domain>-custom` etc.).

#### research-class (empirical investigation / data analysis)

| # | Class | Probe |
|---|---|---|
| R1 | selection-bias | sample selection conditioning on outcome |
| R2 | overfit | in-sample tune vs out-of-sample test |
| R3 | regime-shift | train distribution vs deploy distribution |
| R4 | look-ahead | future info leaking into past features |
| R5 | target-leakage | target derivative as feature; train/val contamination |
| R6 | replication-failure | does result hold on independent data / seed / op |

#### audit-class (review / verification of prior claims)

| # | Class | Probe |
|---|---|---|
| A1 | confirmation-bias | did analyst frame queries to find evidence FOR held belief |
| A2 | motivated-reasoning | analyst stake in outcome; negatives soft-pedaled |
| A3 | cherry-pick | reported subset vs population; unjustified exclusion |
| A4 | strawman | claim matches what original author wrote (verbatim) |

#### decision-class (high-stakes choice under uncertainty)

| # | Class | Probe |
|---|---|---|
| D1 | sunk-cost | recommendation keeps commitment due to past investment alone |
| D2 | loss-aversion | systematically conservative vs actual payoff distribution |
| D3 | availability-heuristic | example set is recent-memory vs base-rate-representative |
| D4 | scope-creep | action stretches beyond stated decision boundary |

#### doc-class (prose / spec / proposal)

| # | Class | Probe |
|---|---|---|
| C1 | scope-drift | claim/proposal exceeds Goal section authority |
| C2 | hidden-assumption | unstated logical premise required for conclusion (cite line) |
| C3 | definition-elasticity | term shifts meaning between sections |
| C4 | authority-by-citation | claim cites X without verifying X says it |

#### Code-domain extensions

- Speedup: `bit-identity-vs-baseline`, `override-hook-preservation`, `cache-key-completeness`, `cache-eviction-bounded`
- API service: `subprocess command injection`, `path traversal beyond suffix check`, `symlink escape from sandbox dir`
- Data pipeline: `schema drift`, `null/missing-value handling`, `unicode normalization`, `timezone semantics`
- ML training: prefer research-class (R1-R6); add extensions on top

### Peer prompt requirement

Each peer prompt MUST include: "Address EACH attack class below; either specific attack OR `n/a-this-target` with grep-able trace. Round incomplete if any class unaddressed." After 2 re-spawn failures on same class → escalate to escalations.md.

## Eval Discipline

Self-judge shares the mutator's biases (the v1 caveat). Hierarchy of evals, best to worst:

1. Shell command returning a number (deterministic, non-LLM)
2. Shell command running a test suite (deterministic, non-LLM)
3. Self-judge with frozen rubric (LLM, but constrained)
4. Self-judge freeform (LLM, vibes — refuse to use)

**Strong default (v2.3): if Target includes any executable artifact (code, scripts, runnable specs, queryable data), use levels 1-2 — actually run it.** Self-judge (level 3) is the **degraded mode** for cases where execution truly cannot apply (paradigm exploration, design discussion, qualitative judgment). When you have execution available and choose self-judge anyway, you're choosing rubric-vibes over ground truth — defensible only if runtime cost is genuinely prohibitive AND adversary will catch what you'd have caught by running. Most rounds should be executable.

When self-judge is unavoidable:
- Rubric frozen in `program.md` Metric BEFORE loop starts (no rubric drift mid-run)
- Peer challenge MUST be on — loop refuses to start without configured peers (no off-switch)
- Self-judge runs in a separate `Agent` call from the mutator, no shared context
- **Schema-grounding required (v2.2)** — if the mutation references external schema (file paths, column names, API contracts, stored data formats, function signatures), the self-judge MUST verify each reference against the actual source (`Read` the file, run a SQL probe, hit the API) BEFORE scoring. A self-judge that scored ≥ rubric_max without a grounding step is structurally untrustworthy and must be re-scored as 0 on the affected dimensions. Pre-emption ("I expect adversary will probe X") catches things you already know to look for; grounding catches the unknown unknowns. Added after abelian's own first real run (Polymarket Round 1, 2026-04-22) where 2 BLOCKER typos were 4/4 self-judged then immediately caught by Codex SQL grounding.

LLMs never argue "this is better." They argue "this passes/fails the rubric." Verdicts are red/green, not vibes.

## Portfolio Mode (`portfolio: K` in program.md `## Shape`, default K=1)

With K>1: maintain top-K solutions indexed by behavior cell.

- Each kept mutation lives on its own git branch: `abelian/portfolio/<cell-slug>`
- New mutation replaces a cell's incumbent only if it beats that cell's score
- Loop's objective shifts from "optimize one" to **"fill cells"** — Quality-Diversity / MAP-Elites style
- Compound doc includes a per-cell comparison table at the end

Use when multiple valid approaches exist (architectures, algorithm classes, tradeoff axes — speed vs memory vs simplicity). Skip for single-axis micro-optimization where diversity has no meaning.

If `program.md` lists Cells, the loop targets those cells explicitly. If not, the LLM auto-tags and the cell space grows organically.

## Escalation (`abelian/escalations.md`)

Loop writes (does NOT stop) on:
- **Diversity collapse** (K>1): 5+ rounds, no new cell filled, candidate edit-distance falling
- **Peer↔eval contradiction**: peer insists attack, eval keeps passing → eval too narrow; human expands
- **Source-of-truth drift**: program.md Goal re-reads inconsistently mid-run (rule #16 hash catches contract drift)
- **Attack-class re-spawn failure**: peer failed to address a class after 2 re-spawns

**Mandatory post-campaign deferral review**: before writing compound doc, run a final peer call asking for skipped/deferred/declined items + severity. Output appends to `escalations.md ## Post-campaign deferrals`. Compound doc's "Open escalations" section is REQUIRED — either list deferrals OR explicit "0 deferrals attempted" statement. Prevents silent kicked-down-the-road items.

## Termination Discipline

Loop runs till converge. No rounds/budget/wallclock caps. Termination claims valid only if mechanism-backed; rule #6's 5 forbidden rationales (diminishing returns / time-remaining / deferred-future / foundation-in-place / cleaner-to-ship) are hard refusals.

Valid termination conditions (full spec: rule #6):

- **Goal met** — champion satisfies Metric direction (`max`: eval ≥ target; `min`: eval ≤ target)
- **No-proposal-after-K-frame-breaks** (K=2 default) — Frame-break Protocol fired all applicable steps; resulting `candidate_routes` has zero `est_progress_delta > 0`; held for K consecutive rounds. Creative-exhaustion, not challenge-exhaustion.
- **Mutual KILL deadlock** — N=3 rounds where both peers' mutations revert (every attack succeeds on both sides) → escalate.
- **User interrupt** — SIGINT/SIGTERM → finish current atomic op, write handoff, exit.

**Self-check before terminating**: write `state.termination = {condition, evidence, rounds_at_termination, frame_break_count_consecutive, rule6_self_check}` block. `evidence` must cite verbatim eval/state. For `no-proposal-after-K-frame-breaks`, `evidence` MUST include `frame_break_steps_run` array showing applicable steps actually executed; missing → gate-fail.

**Contract-drift re-entry**: `contract-drift-stopped` is paused, not terminated. Re-invoke `abelian program.md` with same RUN_ID → loop detects existing state + drift → TTY prompt walks user through fresh round-0 (new checklist/baseline/peer-challenge/hash); on approval clears state. Non-TTY: exit with diagnostic. Alternative: new RUN_ID.

## When It Ends: Auto-Compound

After loop ends, automatically write learnings to `docs/solutions/[category]/[goal-slug]-[date].md`.

Locked field order (no free-form prose between fields, no embellishment):

1. **What worked** — kept peer candidates ranked by impact, grouped by cell (portfolio mode)
2. **What didn't** — reverts grouped by failure pattern (eval-fail / peer-attack-fail / both)
3. **Peer-attack catches** — attacks that flipped kept → reverted (highest-signal; prioritize for future sessions)
4. **Judgment calls** — non-obvious decisions that mattered
5. **Baseline → Final** — quantified improvement; per-cell deltas
6. **Open escalations** (MANDATORY) — copy from escalations.md OR explicit "0 deferrals" statement
7. **Next session starting point**

CE-compatible YAML frontmatter (`title`, `date`, `category`, `module`, `problem_type`, `severity`, `applies_when[]`, `tags[]`).

Headline of any user-facing summary MUST be the verbatim first sentence of "What worked" — no paraphrase. Future `abelian program.md` runs on same target search `docs/solutions/` first; load prior compound doc into Strategy + Cells before starting. **Each run starts where the last one ended.**

## Execution Gate — rule #9

Termination requires an executed artifact: ≥1 round per cell with deterministic non-LLM eval (level 1-2: shell number / test pass-fail) where the peer saw the execution output. Two peers reaching mutual silence on a SPEC ≠ artifact surviving real execution.

Doc-only target: `termination_requires_execution_gate: false` declared + downstream-confirmation step. Default = true.

## Migration

v2.x → v3.0 deprecation map (legacy flags, header rename, file layout): see [MIGRATION.md](MIGRATION.md). Loop warns + maps observed legacy flags at startup (writes notice to stderr + `escalations.md`).

## Safety Rules

- Never edit files outside Target.
- Never modify the eval command (adding regression tests OK; changing measurement is not).
- Always revert on error. Metric worsens >50% in one round → flag and revert.
- **Long eval MUST be detached** (>30s wallclock / spill / window-sort >10M rows / >2GB RSS): `nohup <cmd> > logs/X.log 2>&1 & echo $! > logs/X.pid`. In-session OOM kills the parent loop. Cap `--threads` to ~half cores when spill-manager involved (DuckDB, joblib).
- Escalations file always written (empty OK — proves gate ran).
- Peer subagent context isolated per round; no shared conversation across rounds.
- **Production-runtime safety (rule #10)**: when Target includes a file imported by a continuously-running process (cron / supervisor / systemd / hot-reload), pick ≥1 mitigation per cell that touches it: (a) suspend production process for campaign window; (b) eval against snapshot of deployed state alongside fresh-fixture eval; (c) idempotent-ALTER assertion on every new schema column (`CREATE TABLE IF NOT EXISTS` alone silently skips against an incumbent schema). Diagnostic: search cron/supervisor config for Target path. If unsure, suspend cron — cheap insurance.
