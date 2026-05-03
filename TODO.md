# Abelian TODO

Tracked at the protocol level. Issues filed on GitHub mostly track items here.

## Open

### Smoketest of `--code-review=on` path (rule #12, v2.11)

`codex review --uncommitted` verified functional locally 2026-04-28 (via
`bun /home/bht/.npm-global/bin/codex review --help`; node not in PATH but
bun shim works per `~/.bashrc`). Not yet exercised end-to-end in an
abelian campaign — first user enabling `--code-review=on` will be the
smoketest. Specific points to verify:

- codex review respects `~/.codex/config.toml` defaults (model selection,
  sandbox mode) — orchestrator passes `-c 'model_reasoning_effort="high"'`
  override
- `codex-review.txt` output format: confirm `[P1]/[P2]/[P3]` markers
  follow expected pattern; if codex's output schema diverges, gate
  check needs adjustment
- Loop-until-clean semantics: night-shift uses fix → re-review → max
  10 rounds before revert. Abelian's current default is single-pass
  (P1/P2 → revert immediately, let mutator propose differently next
  round). May want to add `--code-review-max-rounds=N` knob if real
  campaigns show benefit from in-round iteration.
- bun shim ergonomics: when `node` not in PATH, orchestrator must use
  `bun codex review ...`. Document this clearly in dispatch path.

### Smoketest of codex CLI primary path

The Claude Code path was smoketested 2026-04-28 (count_duplicate_pairs
campaign, full v2.8 protocol exercised). The codex CLI path **invocation
form** (cat SKILL.md INVARIANTS.md prompts/dissect.md → codex exec) has
not been exercised against a real codex CLI session. First user should
verify:

- codex `-s workspace-write` sandbox flag is correct for your codex CLI
  version (`codex exec --help | grep -A 2 sandbox`)
- codex's prompt budget is sufficient for SKILL.md + INVARIANTS.md +
  prompts/dissect.md + state.json (with accumulated rounds) + git diff
  in a single inlined prompt. v2.10 estimate: ~40K tokens at run start,
  growing ~2-5K per round. If codex CLI version caps below ~80K
  effective input, recommend stripping comments from SKILL.md or
  passing only recent N rounds in state.json.
- codex's adversary dispatch via fresh `codex exec` subprocess works as
  expected (isolated context, returns verdict, writes adversary.txt
  with header)

### Self-test artifacts in repo

Currently no `examples/` directory. Add a minimal smoketest target
(e.g., the count_duplicate_pairs campaign from 2026-04-28) so users can
copy-paste verify before running on their own codebase. Useful for
both drivers.

### Cross-family adversary reference wrapper

Documented as a sketch in `drivers/codex-cli/README.md`. If a real
team adopts abelian via codex CLI and needs cross-RLHF-family priors,
ship a working `cross-family-adversary.py` (anthropic SDK + tool-use
loop preserving the nonce-defense — main session does NOT write
adversary.txt directly; Claude does via tool use). ~80 lines Python.
Defer until concrete demand.

### Co-research diversity-collapse detection

INVARIANTS rule #6 says co-research plateau requires "candidate
edit-distance falling between peer mutations" alongside no eval
improvement. The mechanism for measuring edit distance (Levenshtein
on the diff strings? AST distance? semantic distance?) is not
specified. Current default: orchestrator may interpret loosely
("two peers proposing essentially the same change"). v2.11 may
specify a concrete metric.

### Examples / case studies

A few worked-through examples (speedup / refactor / API audit) in
`examples/` would help adoption. Currently the only documented
campaign is the smoketest commit history.

## Won't fix (decisions, not bugs)

- **No `--push` or `--pr` support.** Users review `git log BASE..HEAD`
  and decide what ships. Mirrors night-shift.
- **No daemon / continuous mode.** Abelian is bounded by mechanism
  convergence. For overnight autonomy use night-shift; for continuous
  iteration use ralph-loop.
- **No multi-target campaigns in one run.** One `program.md` = one
  Target = one campaign. Run multiple campaigns for multiple targets.
- **No bash wrapper script** (v2.10 removed). Both drivers are LLM
  agent harnesses orchestrating SKILL.md directly. Adding a shell
  layer is redundant.

## v2.13 → future: NS-borrowable backlog (Stephen 2026-04-29 audit)

After v2.13 reframe (abelian = adversarial collaboration framework), 6 NS
features remain considered for borrow. Priority by abelian-fit:

**High priority**:
- **Plan-first ratchet** (NS Inner 1) —落盘 `round-N/plan.md` (files/approach/test-strategy/risks) before mutate; commit-gate adds 9th check (plan.md non-empty + Target files referenced). Prevents "想不清就开干". Earlier proposed (peer-A Vector A) but not shipped.
- **Codex review loop-until-clean** (NS Inner 3) — rule #12 升级: P1/P2 found → fix → re-review → max 10 rounds → revert. Single-pass current form misses NS's true effect source.

**Medium priority**:
- **Eval evidence completeness check** (NS Inner 4 reframed) — embed in step 3 Eval rather than separate step (peer-B F2.3 self-attack 学到): require deliverable existence + UI screenshot for UI tasks.
- **Subagent delegation rules** — co-research peer dispatch prompts MUST include "you may NOT git add/commit, you may NOT modify outside Target". Currently implicit.
- ~~**Mid-run direction propose + adversary review**~~ (NS #2/#3) — RESOLVED in v2.15 by Mission Thread (rule #14) + Frame-break Protocol. Per-round candidate_routes generation IS the mid-run direction propose; commit-gate checks 8 + 10 IS the adversary review of direction relevance.

**Low priority** (defer until empirical need surfaces):
- **Stop / Resume / Abandon** — only relevant if abelian truly runs 4h+ long-horizon campaign and gets interrupted.
- **"Never push to remote"** — explicit safety rule for autonomous loop. Quick add (1 line in INVARIANTS or Safety Rules section).

## v2.13 → future: abelian-specific gaps surfaced by dry-run (Stephen 2026-04-29) — RESOLVED in v2.14

Dry-run of abelian co-research on a doc-task (1-page abelian-vs-night-shift
selector) surfaced 3 fundamental gaps. All 3 resolved in v2.14 (this commit)
after peer-B R1+R2 cross-attack rounds (`/tmp/peer-b-attack.md`,
`/tmp/peer-b-attack-r2.md`).

- ~~**Schema-grounding for fuzzy ground sources** (rule #8 extension)~~ — resolved: INVARIANTS rule #8 expanded with **Fuzzy-ground self-judge** subsection. New `Eval ground:` declaration in program.md (≥1 of (b)/(c)/(d); option (a) self-ground supplementary only). Quote-grep gate replaces vibes-grounding; untraced dimensions auto-scored 0; contradictions flag round `fuzzy-ground-violation` and revert.
- ~~**Doc-task cross-attack quality**~~ — resolved: SKILL.md Co-Research Mode gains **Doc-task cross-attack** subsection. Five-criterion attack form with mandatory falsification statement (`"this is wrong if X, because the doc claims Y"`, X must be grep-able / runnable / countable; aesthetic / tone / rigor X auto-rejected). After 2 re-spawn failures, escalates to dispatched-single-adversary mode with `state.rounds[N].coresearch_degraded: true` provenance.
- ~~**Attack-class library by domain**~~ — resolved: SKILL.md Attack Class Checklist gains **Attack Class Library** subsection. 4 named libraries (research-class R1–R6; audit-class A1–A4; decision-class D1–D4; doc-class C1–C4) plus existing code-domain extensions. Namespace discipline reserves `*-class` suffix for libraries. New `task:` field in program.md drives mandatory-library check; loud-warn on absent field (defaults to `task: code` for v2.5 backwards-compat).

Verdict trail: v2.14 draft v1 (peer-B R1: MAJOR-REVISION-REQUIRED, 4
BLOCKERS / 4 MAJORS / 3 MINORS) → draft v2 (peer-B R2: ACCEPT-WITH-FIXES,
1 NEW BLOCKER / 2 NEW MAJORS / 2 NEW MINORS) → v2.14.0 commit (NEW
BLOCKER 1 resolved via loud-warn pattern; NEW MAJOR 1 via grep-able-X
requirement; NEW MAJOR 2 via `coresearch_degraded` schema field).

Positioning preserved: `adversarial collaboration on deep + innovative +
long-horizon iteration with tractable doc + testable metric`. Tasks with
no testable metric remain out of scope (use ce-brainstorm).

## v2.15 — telos shift to goal-driven co-research (Stephen 2026-05-03)

Trigger: codex 56-round trading-internal PM dogfood (2026-05-02) where
attack-clean rounds produced zero mission-metric movement (rounds 30-56).
v2.14 had no mechanism to flag "attack PASS, mission flat" as gate-fail;
v2.15 makes goal-progress structurally required and replaces
plateau-as-termination with Frame-break Protocol (5-step creative-escape).

**Changes**:

- **INVARIANTS rule #14 — Mission Thread per round** (NEW): every round
  must populate 7-field `mission_thread` block (goal_paraphrase fresh
  vs prior round / metric_delta / blocker_status / mission_relevance /
  candidate_routes ≥2 LLM-generated alternatives / selected_route_id /
  selection_reason citing trade-offs). Forces per-round program.md
  re-read and N-best route enumeration.
- **INVARIANTS rule #15 — Evidence Class enum** (NEW): adversary header
  block gains mandatory `evidence_class:` line, whitelist
  `theoretical | paper | replay | settled | dry_run | live`. Prevents
  cross-layer evidence confusion (v2.14 cron-vs-WS bug class).
- **INVARIANTS rule #2 commit-gate**: 7 always-on checks → 10 always-on +
  1 conditional. New checks: 8 (mission_thread completeness + freshness),
  9 (evidence_class enum), 10 (goal-progress required). Conditional check
  11 is the v2.11 codex-review check (renumbered from 8).
- **INVARIANTS rule #6 termination**: removed `adversary-exhausted`
  and metric-only `plateau` as standalone termination conditions.
  These now trigger Frame-break Protocol instead. New termination:
  `no-proposal-after-K-frame-breaks` (default K=2). Termination set:
  `goal-met | no-proposal-after-K-frame-breaks | mutual-KILL | interrupted`.
- **SKILL.md Frame-break Protocol** (NEW section): 5 mandatory steps
  when round looks "stuck" (adversary-exhausted OR metric stalled OR
  candidate_routes weak). Steps: reject-pool mining (mine prior unselected
  routes with positive est_delta), attack-class library escalation
  (load 1 cross-domain library, fresh adversary call), peer framing swap
  (co-research only), goal re-paraphrase from current state (allow
  bounded speculative routes), cross-peer alternative_routes mining
  (co-research only). Frame-break encodes "plateau is when LLM
  creative capacity should fire, not when loop should give up."
- **SKILL.md adversary line 273 partial relaxation**: co-research mode
  adversary may write informational `alternative_routes:` section after
  attacks (rule #11 schema extension). Non-binding, gate ignores, but
  readable by next round's mission_thread.candidate_routes generation
  (Frame-break Protocol step 5). Unilateral mode keeps the original
  attack-only ban (no peer to consume alternatives = adversary-as-proposer
  collapse vector).
- **state.json schema**: added `frame_break_count_consecutive` (top-level)
  and `mission_thread`, `frame_break_fired`, `frame_break_steps_run`
  per round.
- **SKILL.md duplicate self-check block**: cleaned (v2.14 had the
  termination self-check json appearing twice on lines 736-747 and
  749-759; v2.15 keeps single canonical version with v2.15 condition
  list).
- **Mid-run direction propose + adversary review (TODO Medium priority)**:
  RESOLVED by Mission Thread + Frame-break Protocol. Stephen's note in
  v2.13 future TODOs was "Strategy in program.md is pre-fixed; long-
  horizon innovative task may benefit from 'round N: should we revise
  direction?' with adversary review." Mission Thread's per-round
  candidate_routes generation IS that mid-run direction propose; commit-
  gate 8 + 10 IS that adversary review of direction relevance.

**What v2.15 does NOT change** (anti-paradigm-reset razor):
- Adversary mechanism 100% preserved: every round still spawns isolated
  adversary, still requires nonce header (rule #11), still validates
  attack-class checklist, still blocks commit on attack-fail. Attack
  mechanism is necessary but no longer sufficient.
- Co-research mode (v2.10) and mutual inspiration step (v2.10) preserved.
- Attack-class libraries (v2.14) preserved; Frame-break Protocol step 2
  builds on the library mechanism.
- All v2.0-v2.14 rules #1-#13 preserved verbatim except rule #2
  (commit-gate count) and rule #6 (termination conditions) which gain
  v2.15 additions documented above.
- Backward compatibility: v2.5+ program.md without v2.15 fields gets
  loud warning and starts; mutator must populate mission_thread per
  round (forced by commit-gate, not by program.md schema).

**Razor history (in-conversation, 2026-05-02 → 2026-05-03)**:
v2.15 spec went through 4 razors before this commit landed:
1. First razor — Tier-1/2/3 split with handoff command + synthesis
   packet → Stephen razored to single skill, no new commands, no
   new artifacts.
2. Second razor — paradigm-reset v3.0 framing (commit-gate inversion,
   adversary role full rewrite) → Stephen razored: attacks/challenge
   are load-bearing; v2.10-v2.14 IS the递进 chain toward goal-driven
   co-research; v2.15 is the next increment, not a paradigm reset.
3. Third razor — convergence "adversary-exhausted AND last-3-rounds-
   metric-progress → still terminate" → Stephen razored: that's
   terminating in winning state; the right move is delete adversary-
   exhausted entirely as standalone termination.
4. Fourth razor — "adv-exhausted + metric stalled = stop via plateau" →
   Stephen razored: that's exactly when LLM should innovatively inspire
   and propose, not stop. Plateau triggers Frame-break Protocol; only
   no-proposal-after-K-frame-breaks (creative exhaustion) terminates.

Final razored version is the spec landed in this commit.

## v3.0 — future (deferred, NOT scoped for v2.15)

Architectural changes that would require breaking program.md schema or
multi-peer dispatch rewrite:

- **N>2 peers** — co-research is currently 2-peer hardcoded. True
  competitive-cooperative ensemble with N peers requires dispatch /
  voting / mutual inspiration semantics rewrite. Defer until 2-peer
  with v2.15's 4-route candidate pool (2 peers × 2 routes) proves
  insufficient on real campaigns.
- **commit-gate inversion** — make goal-progress the PRIMARY check
  with attack-survival as filter (current v2.15: both required, OR'd
  with exploration-round exemption). True inversion would let
  metric-improving mutations land even with adversary attacks if
  attacks don't predict regression. v2.15 keeps both as required
  (necessary AND condition), which is the right safety-first compromise
  for now.
- **Adversary role full rewrite (line 273 ban removed entirely)** —
  v2.15 only relaxes for co-research, informational. Full removal would
  make adversary a co-researcher in unilateral mode too. Risky without
  empirical track record on the partial co-research relaxation first.

## v2.16 — Round-0 Program Contract Gate (Stephen 2026-05-03)

Trigger: hours after v2.15 shipped, Stephen flagged a 4th layer ABOVE
v2.15's per-round mechanisms — program.md ITSELF can be fuzzy / shallow
/ unconfirmed at round-0, so Mission Thread paraphrases fuzzy goal into
more fuzz round after round. Grep'd SKILL.md: 4/4 missing (program.md
authoring guidance, depth gate, takeaway summarization, user
confirmation before launch). v2.16 closes this upstream cause.

**Co-research with codex (peer-B), 2 rounds to convergence**:

- **Round 1**: peer-A (me, opus 4.7) sent v2.16 spec draft + 6 self-attacks
  + 6 push axes. peer-B (codex gpt-5.5 xhigh) returned 6 attacks (2
  BLOCKER + 4 MAJOR + 1 MINOR/MAJOR) + 4 alternative routes. Strong
  findings: (BLOCKER-1) Takeaway as parallel truth source — adversary
  prompts only quote Goal/Target/Constraints not Takeaway, so Takeaway
  could drift without per-round mechanism catching; (BLOCKER-2) no
  immutable round-0 contract — confirmation without hash = decoration;
  (MAJOR-3) declared baseline syntactic not measured — false baseline
  poisons every metric_delta in v2.15's gate; (MAJOR-4) program-adversary
  not file-gated — violates rule #1; (MAJOR-5) Target paths-exist
  rejects valid create-artifact campaigns; (MAJOR-6) Estimated horizon
  re-introduces v2.9-removed cap-thinking.
- **Round 2**: peer-A absorbed all 6 (each for structural reason, not
  deference) + sent 6 counter-pushes (C1-C6). peer-B returned 3 more
  MAJOR attacks + verdicts on push axes + convergence signal. Round-2
  findings: exact baseline match brittle (need Metric.baseline_tolerance);
  Takeaway quote-grep alone is theatre (need + semantic linkage —
  Success cite Goal + Metric name+direction; Validated_by cite
  Eval/Metric + grep-able/runnable; Constraints cite ≥1 actual
  prohibition); hash mismatch as drift-stopped too coarse (need
  contract-drift-stopped + reconfirmation_required + --reconfirm-gate).
  Push axes verdicts: collapse `--no-confirm` and non-TTY autostart
  to single `--auto-launch-after-gate` flag (same security event);
  round-0 adversary always dissect (cheap universal sanity); document
  hash overhead explicitly. Codex signaled converge after this round.

**Final v2.16 spec landed**:

- **INVARIANTS rule #16 — Program Contract Gate** (NEW, single dense
  rule per codex Route-1 with est_metric_delta +1.6 spec-quality):
  - **A** Hard checklist: Goal has measurable noun (whitelist + blacklist),
    Target paths parent-dir-exists + path-exists OR `create:` marker,
    Eval shell-runnable OR rubric+ground, Metric has baseline+direction+tolerance,
    Strategy ≥2 axes, Attack Classes ≥1 library, Takeaway present.
  - **B** Takeaway = derived contract (3 fields, no Estimated horizon):
    Success/Validated_by/Constraints with quote-grep + semantic linkage
    to Goal/Eval/Metric/Constraints. Gate fails on contradiction.
  - **C** Round-0 baseline eval: shell run once at unmutated state →
    `round-0/eval.txt`; validates against Metric.baseline ± Metric.tolerance.
    Mismatch → refuse OR `--accept-measured-baseline` overwrite + reconfirm.
  - **D** Round-0 program-adversary: dissect always (cheap universal
    sanity, ~$0.10), regardless of `--adversary` flag; locked attack
    classes `{c1-scope-drift, c2-hidden-assumption, c3-definition-elasticity,
    c4-authority-by-citation, d4-scope-creep}`; rule #11 header inherited;
    BLOCKER → refuse start. Respawn-twice-then-refuse on invalid.
  - **E** Program contract hash: sha256 over normalized Goal / Task class
    / Target / Eval / Eval ground / Metric / Constraints / Strategy /
    Cells / Attack Classes / Takeaway. History excluded. Per-round
    refresh (rule #3 extension) recomputes; mismatch → `contract-drift-stopped`
    + `reconfirmation_required: true`. Resolution: new RUN_ID OR
    `--reconfirm-gate` re-runs round-0 with new hash.
  - **F** Confirmation gate (TTY-aware): interactive stdin go/no, no
    timeout. Non-TTY: refuse unless `--auto-launch-after-gate` flag.
    Single flag covers both batch-confirm-bypass and non-TTY autostart.
    Bypass writes `state.round_0.{auto_launched, bypass_reason}` audit.
  - **G** Migration: `--migrate-takeaway` drafts Takeaway only + exits.
    Never autostart. Other v2.16 gaps require manual fix.
- **INVARIANTS rule #14 extension**: commit-gate check 8 extends — when
  Takeaway present, `mission_relevance` MUST quote-grep ≥1 phrase from
  `Takeaway.Validated_by`. Closes the gap where mission_relevance could
  be vibe-trace.
- **INVARIANTS rule #4 extension**: distinguish `contract-drift-stopped`
  (rule #16, intentional human re-edit, resumable) from ordinary
  `drift-stopped` (uncommitted file, terminal).
- **SKILL.md "Round-0 Authoring Gate" section** (NEW, replaces
  Pre-Flight; .gitignore check retained inside).
- **state.json**: `round_0` block (checklist / baseline_eval /
  program_adversary / takeaway / program_contract_hash /
  user_confirmed_at / auto_launched / bypass_reason /
  reconfirmation_required).
- **Frame-break Step 4 abort condition**: stays in-frame when Takeaway
  + contract still valid; aborts to round-0 with reconfirmation_required
  on metric_delta sign-inversion / Takeaway.Validated_by no-longer-runnable
  / contract-hash mismatch.
- **Termination Discipline**: `--reconfirm-gate` re-entry path documented
  for resuming a `contract-drift-stopped` run.

**v2.16 Razor history (in-conversation 2026-05-03, plus codex co-research)**:

1. Stephen razored the 4 missing pieces in SKILL.md → forced v2.16 from
   "vague suggestion" to "concrete proposal".
2. peer-A self-attacks A1-A6 → caught 5 issues before peer-B saw them
   (whitelist exception, depth-check ROI, Takeaway theatre risk, autonomy
   trade-off, feature creep, A6 unresolved).
3. peer-B codex round-1 attacks → caught 6 more I missed (Takeaway-as-truth,
   no hash, syntactic baseline, file-gating violation, create-marker, cap-thinking).
4. peer-A counter-pushes C1-C6 → tightened hash scope to Strategy/Cells/Attack
   Classes, narrowed migration to Takeaway-only, specced TTY-aware,
   added c3+c4 attack classes, made trace mechanism quote-grep concrete.
5. peer-B codex round-2 → 3 more MAJORs (baseline tolerance, semantic
   linkage, contract-drift-stopped distinct status) + collapsed flags
   to one + signaled converge.

Final spec is the integration of all 12 verified-substantive findings
across 2 rounds, single PR, single dense rule #16. ~530 line increment
on top of v2.15. No new commands. New flags: `--auto-launch-after-gate`,
`--migrate-takeaway`, `--reconfirm-gate`, `--accept-measured-baseline`.
New status: `contract-drift-stopped`. New required program.md section:
`## Takeaway`.

**Backwards compat**: v2.5–v2.15 program.md without Takeaway section
gets clear migration path (`--migrate-takeaway`); other v2.16 fields
(baseline tolerance default, create: marker for new files, Strategy
≥2 axes hard-check) require manual program.md fix. Loud-fail beats
quiet-helpful for fields where automated migration would be silent
fabrication.

**Cost**: +$0.10/start (dissect program-adversary). On a typical
$3-5 multi-round campaign this is 2-3% overhead, 50× ROI on a single
56-round-fuzz catch.
