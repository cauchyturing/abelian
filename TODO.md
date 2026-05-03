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

## v2.16 — Round-0 Program Contract Gate (2026-05-03)

**Trigger**: hours after v2.15 shipped, grep'd SKILL.md for 4 program.md authoring properties → 4/4 missing. v2.15's per-round mechanisms paraphrase fuzz forward if program.md itself is fuzzy at round-0.

**Designed via 2-round co-research with codex (peer-B, gpt-5.5 xhigh)**, 12 verified findings integrated.

### Spec landed

- **rule #16 (NEW) — Program Contract Gate** (subsections A-I in INVARIANTS.md): hard checklist (Goal measurable noun + Target paths exist OR `create:` marker + Eval shell-runnable OR rubric + Metric baseline+direction+tolerance + Strategy ≥2 axes + Attack Classes ≥1 library + Takeaway present) | Takeaway as derived contract (3 fields, quote-grep + semantic linkage to Goal/Eval/Metric/Constraints) | round-0 baseline eval (validates declared baseline ± tolerance) | dissect program-adversary always (locked classes {c1, c2, c3, c4, d4}; rule #11 header inherited) | sha256 program contract hash (per-round refresh recomputes; mismatch → `contract-drift-stopped`) | TTY-aware confirmation (interactive stdin go/no no timeout; non-TTY refuses unless `--auto-launch-after-gate`) | `--migrate-takeaway` drafts Takeaway only + exits.
- **rule #14 extension** — commit-gate check 8 extends: `mission_relevance` quote-greps ≥1 phrase from `Takeaway.Validated_by`.
- **rule #4 extension** — `contract-drift-stopped` distinct from ordinary `drift-stopped` (resumable via `--reconfirm-gate`).
- **state.json** — `round_0` block (11 fields).
- **SKILL.md** — "Round-0 Authoring Gate" replaces "Pre-Flight"; `.gitignore` check retained inside.
- **Frame-break Step 4** — abort to round-0 on metric_delta sign-inversion / Takeaway.Validated_by no-longer-runnable / contract-hash mismatch.
- **Termination Discipline** — `--reconfirm-gate` re-entry path for `contract-drift-stopped`.

### Surface area

| | Count |
|---|---|
| New INVARIANTS rule | 1 (rule #16) |
| Existing rules extended | 2 (#4 status, #14 trace) |
| New flags | 4 (`--auto-launch-after-gate / --migrate-takeaway / --reconfirm-gate / --accept-measured-baseline`) |
| New run status | 1 (`contract-drift-stopped`) |
| New program.md required section | 1 (`## Takeaway`) |
| New commands / new files | 0 |
| Diff (v2.16 over v2.15) | ~530 lines |

### Razor history

| # | Source | Caught |
|---|---|---|
| 1 | Stephen | flagged 4 missing pieces (authoring guidance / depth gate / takeaway / confirmation) |
| 2 | peer-A self-attack (A1-A6) | whitelist exception, depth-check ROI, theatre risk, autonomy, feature-creep, frame-break boundary |
| 3 | peer-B codex round-1 (2 BLOCKER + 4 MAJOR + 1 MINOR/MAJOR) | Takeaway-as-parallel-truth, no hash, syntactic baseline, file-gating violation, create-marker, cap-thinking |
| 4 | peer-A counter-push (C1-C6) | hash scope to Strategy/Cells/Attack Classes, migration narrowed to Takeaway-only, TTY-aware spec, c3+c4 attack classes, trace via quote-grep |
| 5 | peer-B codex round-2 (3 MAJOR + verdicts) | baseline tolerance, semantic linkage, `contract-drift-stopped` distinct status, flags collapsed to one |

### Backwards compat

v2.5-v2.15 program.md without Takeaway → `--migrate-takeaway` (Takeaway-only draft + exit). Other v2.16 fields (baseline tolerance default, `create:` marker, Strategy ≥2 axes) require manual fix. Loud-fail beats quiet-helpful where automated migration = silent fabrication.

### Cost

+$0.10/start (dissect program-adversary). On $3-5 multi-round campaign = 2-3% overhead. 50× ROI on a single 56-round-fuzz catch.

## v2.17 — Adversarial Goal Sharpening (2026-05-03)

**Trigger**: hours after v2.16 shipped, Stephen flagged: rule #16 hard-checklist REJECTS fuzzy program.md (measurable-noun whitelist), routing fuzzy missions to ce-brainstorm. But user goals are often fuzzy at first contact. OKR (night-shift's hierarchical decomposition Objective→KR→Task) is one method to compile fuzzy → sharp; what's abelian's native method? Answer: **adversarial sharpening** — recursive application of abelian's own propose+attack+converge to goal-authoring itself.

**Designed via 2-round co-research with codex (peer-B, gpt-5.5 xhigh)**, 10 verified findings integrated, ACCEPT-WITH-FIXES convergence.

### Spec landed

- **rule #17 (NEW) — Adversarial Goal Sharpening Protocol** (opt-in): triggered by `abelian sharpen "<fuzzy mission>"` or `abelian sharpen --mission-file <path>`. Bare strings to `abelian` NEVER auto-classified as fuzzy missions (closes typo-as-mission risk per codex round-2 attack 2). File auto-detect: existing file lacking `## Goal` section prompts user to run sharpening.
- **rule #16 A amendment**: Strategy=1 allowed IFF `state.sharpening.triage_classification = "single-axis"` AND `--mode=unilateral`. Closes codex round-2 attack 1 (single-axis triage was guaranteed gate-fail without amendment).
- **5-pass protocol** (Pass 0 triage + Pass 1-3 file-gated co-research + Pass 4 mechanical):

| Pass | Output | Adversary classes | Cost |
|---|---|---|---|
| 0 — Triage | sharp / fuzzy-but-grounded / fuzzy-ungrounded / single-axis classification | n/a | ~$0.05 |
| 1 — Outcome Distillation + Grounding | observable end-state + ≥1 ground citation | c1, c2 | ~$0.5 |
| 2 — Metric Forge + Runnable Eval | metric (name/direction/tolerance/baseline=TBD) + runnable shell command + dry-run-parse | c3, c4 | ~$0.5 |
| 3 — Lever + Constraint (merged per Route A) | ≥2 Strategy axes + Constraints | d4, c1 | ~$0.5 |
| 4 — Takeaway Derivation | mechanical compose Takeaway 3 fields | mechanical_validator (3 sub-checks) | $0 |

- **Bounded reconnaissance**: fuzzy mission text + `--target-hint` paths + top-3 noun grep + last 200 lines of session history. Forbidden: full repo TODOs, CLAUDE.md, full git log. Each entry recorded in trace.json with command + hit_count + selected_excerpt + citation_type (codex round-2 attack 4).
- **Mechanical converge predicate** (3 conditions per pass): attack_survival + mission_traceability + rule_16_composability (codex round-1 attack 5: not "peers agree", v2.15 anti-consensus posture).
- **Pass 4 mechanical_validator** (codex round-2 verdict 1 rename): source_coverage + rule_16_B_quote_grep + semantic_linkage. Not "attack_survival trivial" — it's deterministic validation, distinct semantics.
- **Output bundle** (Route D): `$RUN_DIR/sharpening/{pass-0/triage.md, pass-N/{peer-A.md, peer-B.md, adversary.txt, converged.md}, trace.json}` + composed `program.md`. Per-pass `artifact_integrity` (path/sha256/nonce/started_at/verdict_line/model_or_peer/retry_count) for full audit (codex round-2 verdict 5).
- **Eval ground always includes (d) verbatim fuzzy_mission** (codex round-1 attack 6): rule #8 native anchor preserved.
- **Rule #16 round-0 takeover**: after sharpening produces draft, rule #16 round-0 gate runs as if user wrote program.md. Round-0 baseline eval against Pass 2's pre-validated Eval command closes the `TBD-measure-at-round-0` placeholder.

### Surface area

| | Count |
|---|---|
| New INVARIANTS rule | 1 (rule #17) |
| Existing rules amended | 1 (#16 A Strategy ≥2 exception) |
| New subcommand | 1 (`abelian sharpen`) |
| New flags | 3 (`--mission-file`, `--target-hint`, `--interactive-sharpening`) |
| New triage classifications | 4 (sharp / fuzzy-but-grounded / fuzzy-ungrounded / single-axis) |
| Reused machinery | dissect attack classes c1-c4+d4, rule #11 nonce header, peer-A/peer-B framing, rule #8 fuzzy-ground option (d) |
| Diff (v2.17 over v2.16) | ~600 lines |

### Razor history (codex co-research)

| # | Source | Caught |
|---|---|---|
| 1 | Stephen | flagged "OKR is one method, what's yours in the new era" — pushed for native abelian method |
| 2 | peer-A self-attack (A1-A6) | overlap with rule #16, cost ~$2.5, separate vs extend rule #16, intervention default, fail-out specificity, reconnaissance scope |
| 3 | peer-B codex round-1 (6 attacks: 2 BLOCKER + 4 MAJOR) | file-gated artifacts (BLOCKER), TBD baseline + runnable eval (MAJOR), Pass 1 grounding before outcome (MAJOR), single-axis legitimate exit (MAJOR), mechanical converge predicate not "peers agree" (MAJOR), fuzzy_mission preserved as Eval ground (d) (MAJOR) |
| 4 | peer-A counter-pushes (C1-C6) | reject Route B (rule #17 separate), Pass 0 triage NOT embedded in Pass 1, Pass 4 mechanical predicate, single-axis redirect WITHIN abelian, reconnaissance scope discipline, trace.json schema |
| 5 | peer-B codex round-2 (4 attacks: all MAJOR) | rule #16 A exception needed for single-axis, no broad string auto-detect (typo risk), Pass 4 predicate naming (mechanical_validator_passed), reconnaissance provenance recording with citation_type |

Final spec is integration of all 10 verified findings across 2 rounds, single PR, single dense rule #17. 

### Backwards compat

`abelian program.md` unchanged behavior — sharpening is purely additive opt-in. v2.5-v2.16 program.md files run as before. `abelian sharpen` is new entrypoint; users with sharp goals never trigger it.

### Cost

~$1.65-2.15 per fuzzy mission ($0.05 triage + $1.5 Pass 1-3 + $0 Pass 4 + $0.10 round-0). 100× ROI on a single 56-round-fuzz catch ($3-5 wasted on attack-clean-but-mission-flat rounds).

### Why this not OKR

OKR is hierarchical decomposition done by user (KR step requires user cognitive scaffolding). v2.17 is per-field adversarial sharpening done by LLM peer pair + dissect adversary. In LLM era: enumerate-and-attack uses model strength (parallel framings, cross-attack, mechanism surfacing) where OKR's KR step relies on user's structured thinking. night-shift uses OKR upstream of abelian; v2.17 keeps users within the framework.
