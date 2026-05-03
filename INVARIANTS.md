# Abelian INVARIANTS — read at start of every round

These rules are NON-NEGOTIABLE. Context compaction is not an excuse.
"Time efficiency" is not an excuse. "Trivial round" is not an excuse.
"Self-judge eval is small" is not an excuse.

If you are an LLM running this loop and you find yourself rationalizing
why a rule below "doesn't apply this time" — that is the exact failure
mode the rule exists to catch. Stop and re-read.

## 1. Adversary output must be on disk

Each round's adversary call writes `$RUN_DIR/round-N/adversary.txt`
(unilateral) or `$RUN_DIR/round-N/peer-A.txt` + `peer-B.txt`
(co-research) BEFORE the call returns. Empty file = adversary was not
actually run. Conversation-only adversary output is invalid and fails
commit-gate (rule #2).

## 2. Commit-gate (10 always-on checks + 1 conditional, all must pass before `git commit`)

1. `$RUN_DIR/round-N/adversary.txt` exists and is non-empty.
2. The file starts with the standard adversary header block (rule #11)
   and its `nonce` field equals `state.rounds[N].adversary_nonce`.
3. The file's mtime is later than `state.rounds[N].adversary_started_at`
   and earlier than `now()`. (`stat -c %Y adversary.txt` vs ISO parse.)
4. `state.rounds[N].verdict_line` appears verbatim in `adversary.txt`
   body (`grep -qF "$VERDICT" adversary.txt`). Closes the "compacted
   agent fabricates a clean review" hole.
5. Drift check passes (rule #4).
6. `$RUN_DIR/round-N/pre-files.txt` exists (rule #5).
7. Eval ran in this round's process and produced the metric value
   recorded in `state.rounds[N].metric_value`.
8. **Mission Thread completeness (v2.15, rule #14)** —
   `state.rounds[N].mission_thread` is present with all 7 fields populated;
   `candidate_routes` length ≥ 2; `goal_paraphrase` differs from
   `state.rounds[N-1].mission_thread.goal_paraphrase` (string equality
   check; identical paraphrase = mutator skipped re-reading program.md =
   gate-fail); `selection_reason` mentions at least one unpicked route
   from `candidate_routes` by id. See rule #14 for schema.
9. **Evidence Class enum (v2.15, rule #15)** — `adversary.txt` header
   block contains `evidence_class:` line and value is in the v15 whitelist
   (`theoretical | paper | replay | settled | dry_run | live`).
   `peer-A.txt` and `peer-B.txt` both validated in co-research mode.
10. **Goal-progress required (v2.15, rule #14)** — at least ONE of:
    (a) `mission_thread.metric_delta > 0`,
    (b) `mission_thread.blocker_status` ∈ `{removed, partially}`,
    (c) `mission_thread.exploration_round = true` AND
    `state.frame_break_count_consecutive ≤ 2` (i.e., the round is
    explicitly an exploration / frame-break round and we have not
    chained more than 2 consecutive exploration rounds).
    Pure attack-survival with `metric_delta = 0 AND blocker_status = n/a
    AND exploration_round = false` is gate-fail. This is the structural
    enforcement of "attack must serve goal, not exist for its own sake."

11. **Code Review supplemental (conditional, rule #12, opt-in via `--code-review=on`)** —
    `$RUN_DIR/round-N/codex-review.txt` exists, non-empty, AND contains
    no `[P1]` or `[P2]` severity markers. Skipped silently (with loud
    notice) if codex CLI unavailable, per rule #12 graceful degradation.

Any failure → revert this round (`git checkout` + scoped clean of
new files via pre-files diff), mark round `gate-failed` in state, do
NOT commit. Hard gate.

## 3. Per-round refresh (anti-compaction)

At step 0 of every round, before any other action:

```bash
cat $SKILL_DIR/INVARIANTS.md
cat $RUN_DIR/state.json
```

Re-read from disk, not from your memory of the conversation. After 3+
rounds your memory of these rules is wrong; the file is the source of
truth. Skipping this read because "I remember the rules" is a
rationalization (see header note).

## 4. Drift check before any write/commit/revert

Git mode only. Before any commit, revert, or rollback:

- `git rev-parse HEAD` == `state.expected_head`
- `git branch --show-current` == `state.branch`
- The set of dirty files matches this round's plan. Compute it via
  three SEPARATE git commands. **Do NOT parse `git status --porcelain`**
  — wrapping it in `.strip().splitlines()` eats the leading space of
  the first ` M file` entry, off-by-one drops the first character of
  the filename, and a smoketest false-positive ("low.py" instead of
  "slow.py") confirmed this gotcha 2026-04-28. Use:

  ```python
  modified  = run(['git','diff','--name-only']).splitlines()
  staged    = run(['git','diff','--cached','--name-only']).splitlines()
  untracked = run(['git','ls-files','--others','--exclude-standard']).splitlines()
  dirty = sorted(set(modified + staged + untracked))
  ```

  Allowed dirty: files this round's plan declares as Target, plus any
  file under `abelian/runs/<RUN_ID>/`. Anything else = drift.

Any mismatch → set `state.status = "drift-stopped"`, write nothing
else, terminal-only summary, exit. Do not attempt to "recover" — the
human must investigate.

**v2.16 — `contract-drift-stopped` distinction**: rule #16 (Program
Contract Gate) introduces a separate hash-based drift signal over
program.md sections (Goal / Task class / Target / Eval / Eval ground /
Metric / Constraints / Strategy / Cells / Attack Classes / Takeaway).
When the per-round refresh recomputes the contract hash and finds a
mismatch with `state.round_0.program_contract_hash`, the loop sets
`state.status = "contract-drift-stopped"` (NOT `drift-stopped`) and
writes `state.round_0.reconfirmation_required = true`. The two
statuses are kept distinct because they signal different human-action
paths:
- `drift-stopped` (this rule, #4) — uncommitted file outside Target;
  human investigates which process / edit caused it.
- `contract-drift-stopped` (rule #16) — program.md itself was edited
  after round-0 confirmation; human either starts a new run with new
  hash, OR explicitly re-gates with `--reconfirm-gate` flag (re-runs
  full round-0 authoring gate, prints new takeaway + new estimated
  cost, awaits new "go").

## 5. Pre-files snapshot before mutate

Before step 2 (Mutate) writes anything:

```bash
mkdir -p $RUN_DIR/round-N
{ git ls-files -z; git ls-files -z --others --exclude-standard; } \
  | sort -zu > $RUN_DIR/round-N/pre-files.txt
```

Used by scoped revert to remove new files cleanly. Missing pre-files
= commit-gate refusal (rule #2 check 4). Missing pre-files = revert
cannot run cleanly = drift-stopped on first failure.

## 6. Forbidden termination rationales

Abelian runs **till converge**. There is no `--rounds` cap, no `--budget`
flag, no wallclock cap (v2.9 removed all of these). The only fallback for
"stop now" is the user sending SIGINT/SIGTERM — manual emergency abort,
marked `status=interrupted`, NOT a valid termination signal.

The loop MUST NOT terminate or write a "done" claim if the
load-bearing reason for stopping reduces to ANY of:

- "Diminishing returns" / "remaining work is lower-value"
- "Time remaining is short" / "tokens running out" / "running long"
- "Deferred to future campaign / TODO / next session"
- "Foundation in place" / "natural stopping point" / "good break here"
- "Cleaner to ship what we have than fold in more"

These are stopping preferences, not goal-fulfillment. Termination is
justified only by mechanism. **v2.15: telos shift — termination requires
goal-progress evidence OR creative exhaustion (frame-break protocol
fired without yielding a positive-EV route), NOT adversary-exhaustion
alone. The loop's goal is goal-fulfillment, not attack-survival.**

Valid termination conditions (v2.15):

- **Goal met** — eval ≥ target (unilateral) OR champion ≥ target (co-research)
- **No-proposal-after-frame-breaks** — `state.frame_break_count_consecutive
  ≥ K` (default K=2) AND the most recent frame-break protocol run
  (see SKILL.md "Frame-break Protocol" section) yielded no
  `candidate_routes` entry with `est_metric_delta > 0` despite running
  ALL 5 mandatory frame-break steps (reject-pool mining, attack-class
  library escalation, peer framing swap if co-research, goal
  re-paraphrase from current state, cross-peer alternative_routes
  mining if co-research). This is the v2.15 "creative exhaustion"
  termination — the LLM has tried both its primary frame and 5 frame-break
  expansions and still cannot generate a positive-EV next step.
- **Mutual KILL deadlock** — N=3 rounds where every peer attack succeeds
  on both sides (co-research only).

**v2.15 removed conditions (compared to v2.14)**:

- ~~**Adversary exhausted**~~ — REMOVED as standalone termination. No
  attacks ≠ goal met. If adversary is exhausted but metric is still
  progressing, the loop is in a winning state and must continue. If
  adversary is exhausted AND metric stalled, that triggers Frame-break
  Protocol (NOT termination); only after K consecutive frame-break
  rounds yield no positive-EV route does the loop terminate via
  no-proposal-after-frame-breaks. Adversary-exhausted is now an
  informational signal that contributes to frame-break trigger, not a
  standalone termination.
- ~~**Plateau** (metric stopped improving alone)~~ — REMOVED as standalone
  termination. Plateau triggers Frame-break Protocol (the LLM is
  expected to creatively escape, not give up). Termination via plateau
  only fires through the no-proposal-after-frame-breaks path above.

If a mechanism signal would not fire by round 3, the loop has not
actually converged. Either tighten program.md (target/eval) or wait
for the user to abort. "Running long" is a forbidden rationale —
either fire a real mechanism signal or let the user SIGINT.

**Rationale (v2.15 telos shift)**: v1.x – v2.14 inherited the
adversarial-loop telos in which "no more attacks land" was equivalent
to "done." Codex 56-round PM dogfood (2026-05-02) demonstrated the
failure mode at scale: 56 rounds with attack-survival as the gate, but
mission metric did not move meaningfully because no rule forced
attacks to serve goal. v2.15 telos: the loop is goal-driven
co-research, not adversary-defense. Adversary mechanisms (rules #1, #7,
#11, #13) are 100% preserved — every round still spawns isolated
adversary, still requires nonce header, still falsifies via attack
classes. What changed: attack-survival is now necessary but not
sufficient. Mission Thread (#14) anchors per-round work to goal;
Evidence Class (#15) prevents cross-layer evidence confusion; Frame-break
Protocol expands the loop's response to plateau from "stop" to
"creatively break frame." This is the structural cash-out of v2.13's
"Adversarial Collaboration Framework" rename — collaboration in the
mechanism, not just the marketing copy.

## 7. Verbatim Goal/Target/Constraints in adversary prompts

The adversary subagent prompt MUST include the literal text of
`program.md` Goal / Target / Constraints / Attack-Classes — quoted
inline in the prompt or read from the actual file. Paraphrasing
forbidden. Agent-rewritten goal in adversary's head is the
source-of-truth-drift escalation trigger; verbatim quoting prevents
the silent rewrite.

This applies to:
- Adversary calls (every round)
- Self-judge calls (every round, when used)
- Co-research peer-attack prompts (both directions)
- Post-campaign escalation review

## 8. Self-judge discipline

- `--adversary=off` + Eval=`self-judge` → **hard refuse to start**.
  No degradation path. Zero LLM check on vibes eval = structurally
  unsafe.

- **Concrete-ground self-judge** (default, v2.2): self-judge MUST verify
  external schema (file paths, columns, API contracts, function
  signatures) by reading actual source before scoring. Self-judge that
  scored ≥ rubric_max without grounding step is auto-rescored to 0 on
  affected dimensions.

- **Fuzzy-ground self-judge** (v2.14, for doc / research / audit /
  decision tasks): when Target produces prose, design rationale, decision
  rec, or research output where "external schema" does NOT exist as
  concrete files / columns / signatures, schema-grounding adapts as
  below. The metric stays testable (rubric score with quote-grep gate);
  abelian's positioning requires it. Tasks that cannot articulate any
  ground source are out of scope for abelian — use ce-brainstorm or
  human discussion.

  **Required**: program.md MUST declare ≥1 ground source upfront, in a
  new `Eval ground:` section. Eligible sources:

  - (a) program.md `Goal` and `Constraints` sections themselves
    (self-ground — but Goal is one sentence per the program.md schema,
    so option (a) is **insufficient alone**: must be paired with at
    least one of (b)/(c)/(d) below);
  - (b) a user-supplied reference doc, cited by absolute path;
  - (c) an existing canonical doc in the repo (prior compound doc,
    README, ARCHITECTURE.md, prior `docs/solutions/` entry), cited by
    path;
  - (d) the verbatim user message that initiated the campaign, copied
    into the program.md `Eval ground:` section as a fenced block.

  **Quote-grep gate** (replaces vibes-grounding): self-judge MUST, for
  each rubric dimension, either:
  - Provide a verbatim or paraphrased quote from the ground source that
    supports the claim being scored (verbatim original phrase MUST be
    cited alongside any paraphrase), OR
  - Mark the dimension `not-traceable` → that dimension scored 0.

  Claims in the deliverable that contradict the ground source → entire
  round flagged `fuzzy-ground-violation`, treated as gate-fail (revert).
  No "almost-traces"; the gate is binary.

  **Why mandatory**: without a declared ground, "self-judge against
  program.md" can quietly drift into "self-judge against my interpretation
  of program.md," which is unilateral self-justification (rule #13's
  same-prior collapse, applied to evaluation). The forced-upfront
  declaration makes the trace verifiable post-hoc and gives the adversary
  a concrete attack surface ("you claimed X; the ground source says Y").

  **Anchor**: see TODO.md "v2.13 → future: abelian-specific gaps surfaced
  by dry-run" (Stephen 2026-04-29) for the originating gap report. The
  protocol above is the resolution.

- Self-judge runs in isolated subagent, no shared context with mutator.
- Rubric frozen in `program.md` Metric BEFORE loop starts; mid-run
  rubric drift forbidden.

## 9. Execution gate (termination requirement)

Termination requires at least one round per cell produced an artifact
that:

1. Was actually executed in this loop (level 1 or 2 eval — shell
   number or test-suite, not self-judge).
2. Eval at execution time was deterministic non-LLM.
3. Adversary saw the execution output, not just the spec or diff.

Adversary-exhaustion alone is necessary but not sufficient. Two LLMs
reaching mutual silence on a spec-only target ≠ artifact survived
real execution. Doc-only mode requires explicit
`termination_requires_execution_gate: false` + a downstream-confirmation
step.

## 10. Production-runtime safety

If Target includes a file imported by a continuously-running process
(cron, supervisor, systemd watchdog, hot-reload server, FastAPI
auto-reload), at least one of these MUST hold for the campaign:

- (a) Suspend the production process for the campaign window. Resume
  + verify one full cycle clean before claiming the cell done.
- (b) Eval against a snapshot of deployed state alongside fresh-fixture
  eval (e.g., copy of prod sqlite at campaign start; re-run eval
  against it after each cell).
- (c) Idempotent-ALTER assertion on every schema column added: `git
  diff` of the round MUST show ALTER TABLE … ADD COLUMN coverage for
  every new column. `CREATE TABLE IF NOT EXISTS` alone silently skips
  against an incumbent schema.

Diagnostic for whether this rule applies: search the cron / supervisor
config for the Target file path. If found, the rule applies. If
unsure, suspend cron — cheap insurance.

## 11. Adversary header block (mandatory format)

Every `adversary.txt` (and `peer-A.txt` / `peer-B.txt` in co-research)
MUST begin with this header block, written by the adversary subagent
itself, before any attack content:

```
ABELIAN-ADV-v1
run_id: <state.run_id>
round: <N>
peer: unilateral | peer-A | peer-B
nonce: <state.rounds[N].adversary_nonce>
started_at: <ISO 8601 with milliseconds>
verdict: <single-line verdict, identical to state.rounds[N].verdict_line>
evidence_class: theoretical | paper | replay | settled | dry_run | live
---
<attack content begins here>

[optional, co-research only — v2.15] alternative_routes:
  - id: <slug>
    mechanism: <one-line description>
    est_metric_delta: <float | "unknown">
    rationale: <why peer would consider this>
```

`evidence_class` is REQUIRED (v2.15, rule #15). Whitelist:
- `theoretical` — pure analysis of code/spec without execution
- `paper` — paper trade / dry computation, no real-world commit
- `replay` — historical data replay through pipeline
- `settled` — observed against settled real-world outcome
- `dry_run` — system-level dry-run with full pipeline but no commit
- `live` — observed against live production system

Choose the strongest (rightmost on the ladder) class actually exercised.
`live` claims must be reproducible from `state.rounds[N]` artifacts.
Cross-class confusion ("we ran a paper test, the live behavior must be
the same") is the v2.14 cron-vs-WS bug class — rule #15 makes the layer
explicit per-round.

`alternative_routes` is OPTIONAL and ONLY in co-research mode (v2.15).
Adversary in unilateral mode remains attack-only (line 273 in SKILL.md
preserved for unilateral). Co-research adversary may write informational
alternative routes the next round's mutator MAY mine when generating
`mission_thread.candidate_routes` (rule #14). Commit-gate (rule #2 check
8) does NOT validate `alternative_routes` content; this section is
non-binding informational signal, not a commitment.

**Mutator protocol**:

1. Before calling `Agent(adversary)`, generate:
   - `nonce = python3 -c "import secrets; print(secrets.token_hex(8))"`
     (16 hex chars)
   - `started_at = $(date +%Y-%m-%dT%H:%M:%S.%3N%z)` (ISO ms)
   Write both to `state.rounds[N].{adversary_nonce, adversary_started_at}`.

2. The adversary prompt MUST include `run_id`, `round`, `peer`,
   `nonce`, `started_at` verbatim and instruct the subagent:
   > "Write the ABELIAN-ADV-v1 header block (these EXACT field
   > values) as the first lines of `$RUN_DIR/round-<N>/adversary.txt`,
   > then `---`, then the attack list. Do not omit the header. Do
   > not change the nonce or started_at."

3. After subagent returns, extract the verdict line from the body
   (or accept it via subagent return value), record in
   `state.rounds[N].verdict_line`. Commit-gate (rule #2) verifies the
   header before commit.

**Honest scope**: this is friction-level defense, not cryptographic.
A mutator deliberately bypassing the adversary call could fabricate
the entire header (it just wrote the nonce to state). The header's
real value is anti-Threat-1 (compaction oversight): an R5+ compacted
mutator that "forgot" it skipped adversary cannot silently hand-write
adversary.txt — it must first cat state.json to find the round's
nonce, which triggers the rule #3 reading reflex (cat INVARIANTS) and
surfaces rule #1 ("must actually call adversary"). The friction
converts a silent skip into a deliberate sabotage, and deliberate
sabotage is loud + traceable in post-campaign review of round
artifacts.

For Threat-2 (deliberate fabrication) and Threat-3 (lazy adversary
output), see attack-class checklist (program.md) and post-campaign
escalation review respectively.

## 12. Code Review supplemental gate (opt-in, v2.11+)

`--code-review=on` enables an additional code-quality review layer that
runs **after** rule #1's dissect/codex adversary call and **before**
rule #2's commit-gate. It uses codex CLI's purpose-built `codex review`
subcommand (with its built-in P1/P2/P3 severity schema) — separate from
and supplemental to rule #1's domain-specific attack-class adversary.

**Why supplemental, not replacement**: dissect adversary covers
domain-specific attack classes the program.md author defined (e.g.
"correctness must match O(N²) baseline", "integer-overflow at N=4M").
codex review covers code-quality issues codex's built-in prompt is
tuned for (style, common bugs, missed edge cases). Different
maintenance domains; both useful when stakes are high.

**Invocation**:

```bash
codex review --uncommitted -c 'model_reasoning_effort="high"' \
  2>&1 | tee $RUN_DIR/round-N/codex-review.txt
```

`--uncommitted` reviews staged + unstaged + untracked changes — exactly
abelian's state at this loop step (mutation written to working tree, not
yet committed). If `node` is not in PATH, prefix with `bun
/path/to/codex` (per `~/.bashrc` shim convention).

**Commit-gate addition** (rule #2 conditional check 11 in v2.15
numbering, formerly check 8 in v2.14, when `--code-review=on`):

11. `$RUN_DIR/round-N/codex-review.txt` exists, non-empty, AND contains
    no `[P1]` or `[P2]` severity markers.

**Loop semantics**: night-shift's "fix → re-review → max 10 rounds →
revert" pattern is allowed but optional. Simplest form: a single
review pass; if P1/P2 present, revert immediately and let mutator
propose differently next round. Up to the orchestrator's discretion;
the gate-check itself is binary.

**Graceful degradation** (loud, never silent):
- `--code-review=on` + codex CLI unavailable (binary missing OR
  `~/.codex/auth.json` absent) → skip rule #12 only (don't fail loop),
  write notice in 3 places (console + escalations.md + History row)
- Fall back to rule #2's 10-always-on-check gate (v2.15) with rule #12
  marked "skipped: codex unavailable"

**Honest scope**: rule #12 has **no nonce header protection** (rule #11
does not apply — codex review's CLI doesn't accept custom prompt
injection that would let the orchestrator inject a header block). A
mutator that wanted to fabricate `codex-review.txt` could. The
practical mitigation: mutator cannot predict codex's actual review
wording, so fabrication requires writing a plausible P1/P2-free
review — non-trivial effort. This is friction-level defense, weaker
than rule #11's nonce protection but better than no gate.

**When to enable**: ship-prep, PR-level decisions, security-sensitive
mutations, code-quality ratchet campaigns. Default off because cost
doubles per round and most campaigns (speedup / refactor) are
already covered by dissect's attack-class checklist.

## 13. Self-attack is not adversary (v2.12)

A mutator agent attacking its own propose in conversation context
(no spawn, no isolated context, no nonce header) is unilateral
self-judge (rule #8 degraded mode), NOT co-research (rule #1 +
co-research mode default since v2.10). RLHF prior overlap = same-prior
collapse vector.

**Empirical anchor (2026-04-29 abelian self-audit dogfood)**: peer-A
(orchestrator Claude) self-attack on 5 mutation propose found 1
obvious finding (Validate-vs-Eval overlap). Spawned peer-B (Agent +
Skill('dissect')) on identical input found 17 attacks across 5
dimensions, including 4 foundational frame challenges peer-A could
not see (e.g., "abelian vs night-shift cosmetic copy" / "propose+verify
structurally not fit fuzzy task" / "Phase 2 dogfood polymarket =
best-fit case sampling bias"). 17 / 1 = 17× catch rate ratio confirms
RLHF prior overlap is severe — mutator and self-attacker share the
same prior over BOTH "what to mutate" and "how to attack mutations".

**Trigger**: any conversation-level abelian/autoresearch reference
that involves ANY of:

- ≥3 mutation proposals (protocol / architecture / strategy / memory)
- Protocol-level change (INVARIANTS / state.json schema / commit-gate)
- "verdict / done / keep / revert / accept / pareto / trade-off"
  vocabulary applied to mutation evaluation

**Required action when triggered**: spawn dispatched adversary (Agent
+ Skill('dissect') OR codex exec subprocess) writing nonce-headered
adversary file (rule #11) BEFORE reaching verdict. Self-attack in
conversation context does NOT count.

**Forbidden mode**: "I attacked my own propose and found these issues"
phrased as adversary substitute. This is mutator's same RLHF prior
attacking same RLHF prior — by construction, cannot find what the
prior overlooks.

**Graceful degradation if you genuinely cannot spawn**: write a single
file `unilateral-self-judge.md` (no nonce header, no rule #11
protection) with explicit `MODE: unilateral self-judge — degraded;
rule #1 not satisfied; verdict provisional only` header. Notify in 3
places (console + escalations.md + conversation log) — same loud-
degradation pattern as rule #8 / `--adversary=off`.

**Honest scope**: rule #13 has no nonce protection (orchestrator can
fake the "I'm self-judging" header just like rule #11's adversary
header). The structural gate IS the spawn requirement; if you skip
spawn, the only defense is loudness — declare degraded mode + tell
the user to run co-research peer manually.

**This rule applies even when**:

- Discussing abelian protocol changes (meta-task — do NOT cite
  `feedback_human_peer_beats_llm_team_for_design_work.md` "small surface
  design" memory to justify skipping rule #13; that memory covers
  human-as-peer-B reactive review, not LLM mutator's own self-attack)
- "Just one quick analysis" / "informal discussion" — these are
  forbidden-rationale variants of rule #6
- User asks for your "honest opinion" — opinion ≠ adversary; opinion
  is mutator output, adversary is dispatched challenge with isolated
  context

**Anti-pattern caught 2026-04-29**: peer-A used its own freshly-shipped
memory (`feedback_human_peer_beats_llm_team_for_design_work.md`) to
retroactively justify skipping co-research, treating Stephen's reactive
question as "human peer-B substitute". Stephen's question is review,
not active peer-attack. Real peer-B is a spawned agent with isolated
context. Self-justification by selectively invoking own memory is the
exact same-prior collapse rule #13 prevents.

## 14. Mission Thread per round (v2.15) — anchor every round to goal

Every round MUST populate `state.rounds[N].mission_thread` with all
seven fields below BEFORE the round's commit-gate runs. Missing or
incomplete mission_thread = commit-gate check 8 fails = revert.

```json
"mission_thread": {
  "goal_paraphrase": "fresh paraphrase of program.md Goal, this round",
  "metric_delta": 0.42,
  "blocker_status": "removed | partially | blocked_on:<dep> | n/a",
  "mission_relevance": "one sentence: how this round serves the mission",
  "candidate_routes": [
    {
      "id": "route-a",
      "mechanism": "what this route DOES, one line",
      "est_metric_delta": 0.5,
      "est_cost": "cheap | medium | expensive",
      "blocker_chain": "if removing a blocker, which one"
    },
    { "id": "route-b", ... }
  ],
  "selected_route_id": "route-a",
  "selection_reason": "must mention at least one unpicked route's tradeoff",
  "exploration_round": false
}
```

**Field rules**:

- `goal_paraphrase` — paraphrase of program.md Goal, fresh this round.
  String-equality check against `state.rounds[N-1].mission_thread.goal_paraphrase`
  MUST fail (i.e., this round's paraphrase MUST differ from prior round's).
  Identical paraphrase = mutator did not re-read program.md = commit-gate
  fails. Forces per-round Goal re-read; closes the v2.14 root cause where
  program.md was read once at round 0 then INVARIANTS re-read per round
  but goal-anchor did not propagate.

- `metric_delta` — change in target metric this round (positive =
  improvement under min/max declared in program.md Metric). May be
  `null` if no eval ran (must pair with `exploration_round: true` and
  `blocker_status` in `{removed, partially}` or `mission_relevance` that
  explains the round's role as setup-for-next-round).

- `blocker_status` — `removed` if a blocker was retired this round;
  `partially` if blocker chain advanced but not finished; `blocked_on:<dep>`
  if blocked on a specific dependency (named); `n/a` if round did not
  target a blocker.

- `mission_relevance` — single sentence connecting the round's work
  back to the program.md Goal. Forbidden phrases: "exploring", "learning
  more", "investigating", "trying" — these are exploration-disguising
  phrases. If the round is genuinely exploration, set `exploration_round:
  true` and explain in selection_reason what bounded question is being
  answered.

  **v2.16 trace requirement (commit-gate check 8 extension)**: when
  rule #16 Program Contract Gate is in effect (i.e., program.md has a
  `## Takeaway` section + round-0 was confirmed), `mission_relevance`
  MUST contain ≥1 verbatim or paraphrased phrase from
  `Takeaway.Validated_by` (the round-0 declared validation source).
  Paraphrase requires the verbatim original phrase cited inline,
  e.g., `mission_relevance: "advances scanner.py replay-determinism
  (Takeaway.Validated_by: 'WS replay produces byte-identical fills')"`.
  Quote-grep mechanism, same as rule #8 fuzzy-ground. Untraceable
  mission_relevance → check 8 fails → revert. This closes the gap
  where mission_relevance could be a vibe ("this serves the goal
  somehow") rather than a specific contract trace ("this advances the
  Validated_by criterion declared at round-0").

- `candidate_routes` — ARRAY OF ≥2 entries. The mutator MUST generate
  at least 2 distinct routes per round and document them, even if one
  is obviously chosen. Single-route rounds are commit-gate fail. Routes
  unselected this round are mineable by future rounds via reject-pool
  mining (Frame-break Protocol step 1). `est_metric_delta` may be
  `"unknown"` ONLY for exploration rounds.

- `selected_route_id` — id of chosen route (must match an entry in
  candidate_routes).

- `selection_reason` — must reference at least one unpicked route's
  trade-off by id (e.g., "route-b est cheaper but smaller delta;
  route-c blocked on integration we don't have"). "Picked highest est
  delta" alone is insufficient — must explain why the alternatives
  were rejected.

- `exploration_round` — boolean. `true` allows null metric_delta and
  `unknown` est_metric_delta in candidate_routes, but commit-gate check
  10 limits consecutive exploration rounds to 2.

**Why this rule exists**: see "v2.15 Rationale" subsection in rule #6.
Briefly: codex 56-round PM dogfood (2026-05-02) showed that without a
per-round goal-anchor, attacks become self-justifying ("this passed all
attack classes" → commit) regardless of mission progress. Mission Thread
makes goal-relevance a structural per-round artifact, not a vibe.

**Empirical anchor (2026-05-02 PM trading-internal codex 56-round dogfood)**:
adversary closed clean across 7 attack classes for rounds 30-56 yet
mission metric (live-flip readiness) was identical at round 56 vs round
30. v2.14 had no mechanism to flag this — every commit was gate-clean.
v2.15 rule #14 + commit-gate check 10 reverts those rounds.

## 15. Evidence Class enum in adversary header (v2.15)

Every `adversary.txt` (and `peer-A.txt` / `peer-B.txt`) header block
MUST include an `evidence_class:` line with value in the v15 whitelist
(see rule #11 schema for full enum).

**Why**: prior versions did not require evidence-class disambiguation,
so a round could pass attack-class checks based on theoretical analysis
of code while claiming the result holds for live production. This is
the v2.14 cron-vs-WS confusion class: paper-fill evidence and live-fill
evidence both score `n/a` on attack class "race / TOCTOU" but for
materially different reasons. v2.15 forces per-round evidence-layer
declaration so the adversary's `n/a` claims are scoped to the layer
actually exercised.

**Validation**: commit-gate check 9 verifies the field is present and
in whitelist. Cross-class evidence claims (e.g., adversary marks
`evidence_class: theoretical` then asserts `n/a-this-target` on a class
that requires runtime observation like `race / TOCTOU`) are surfaced by
the round's own attack list — no separate gate, but reviewers can
grep for `evidence_class: theoretical` + `n/a-this-target` on
runtime-only classes and flag for re-run with `dry_run` or `live`.

**Picking the right class**:

- `theoretical` — code/spec read; no execution. Most cheap, weakest
  evidence. Acceptable for early-round scaffolding.
- `paper` — computation runs but no real-world commit (e.g., paper-trade
  the strategy on synthetic prices, no exchange order placed).
- `replay` — historical real-world data replayed through pipeline.
  Catches data-shape bugs `paper` misses; misses real-time latency.
- `settled` — observed against a settled real-world outcome (e.g.,
  market resolved, ground truth available).
- `dry_run` — system-level dry-run with full pipeline (real connections,
  real timing) but no commit (e.g., trade signal sent to fake broker).
- `live` — observed against live production system. Strongest evidence;
  also riskiest. Reserve for final ship rounds.

Choose the strongest class ACTUALLY exercised this round. Inflating
the class (claiming `live` when only `paper` ran) is silent
fabrication; rule #11's nonce-friction defense applies.

## 16. Program Contract Gate (v2.16) — round-0 authoring + confirmation

Before round 1 hypothesizes anything, the loop runs a Round-0 Program
Contract Gate. Without this gate, fuzzy or shallow program.md leaks
the upstream cause that v2.15's Mission Thread cannot fix from below
(every paraphrase of a fuzzy goal is more fuzz). Rule #16 enforces:
hard checklist + Takeaway-as-derived-contract + measured baseline +
file-gated program-adversary + content hash + TTY-aware confirmation.

The protocol below is mandatory. Skipping any step = round 1 refuses
to start (`status: gate-failed-terminal`).

### A. Hard checklist (binary, fast-fail)

Computed before adversary spawn or eval call. Refuse start on any
failure.

- **Goal**: one line, ≤200 chars. MUST contain a measurable noun
  (whitelist: `number | percentage | sharpe | recall | runtime |
  file-count | pass-rate | precision | latency | throughput | bytes |
  count`). Forbidden as standalone Goal verbs (no measurable noun
  attached): `improve | better | investigate | explore | study |
  examine | analyze`. Truly unspecified-metric tasks belong in
  `ce-brainstorm`, NOT abelian.
- **Target**: list of paths. Each path's parent directory MUST exist.
  Each path MUST either (a) exist (file or directory), OR (b) include
  an explicit `create:` marker (e.g., `Target: docs/new-design.md
  create:`) declaring the path will be created. Inside-repo check
  required (no `..` escape, no absolute paths outside repo root).
- **Eval**: shell-runnable command (`bash -c <line>` returns 0 with
  numeric stdout) OR `self-judge` mode with `Eval ground:` declared
  per rule #8.
- **Metric**: `<name>: <baseline> <direction> <tolerance>`. Direction
  ∈ `{min, max}`. **Tolerance** required (v2.16) — defaults by metric
  type when omitted: `pass-rate / file-count / count` → `exact (0)`;
  `float / runtime` → `epsilon = max(1e-9, 0.01 × |baseline|)`; noisy
  benchmarks → `repeated_median (5 runs)`. Tolerance enables baseline
  validation in step C without rejecting legitimate measurement noise.
- **Strategy**: ≥2 axes (chains C>1 and co-research depend on
  diversity; single-axis means use `unilateral` mode and a different
  tool, not abelian).
- **Attack Classes**: ≥1 named library from {default, doc-class,
  research-class, audit-class, decision-class} OR ≥1 custom domain
  extension.
- **Takeaway section** (NEW v2.16, see B below): present with all 3
  required fields populated.

### B. Takeaway = derived contract (3 fields, not parallel truth)

```
## Takeaway
- Success looks like: <observable end-state, ≤2 lines>
- Validated by: <eval/metric/artifact, MUST be grep-able / runnable /
  countable per rule #8 fuzzy-ground criterion 4>
- Constraints: <≤2 lines>
```

**Quote-grep + semantic linkage** (combines round-1 and round-2 codex
review):

- `Success looks like` MUST: (a) cite a verbatim or paraphrased phrase
  from `Goal` (paraphrase requires verbatim original cited inline);
  AND (b) include the Metric `name` AND `direction` keywords.
- `Validated by` MUST: (a) cite a verbatim or paraphrased phrase from
  `Eval` or `Metric`; AND (b) be grep-able (a literal pattern in a
  named file), runnable (a shell command), or countable (a measurable
  count). Aesthetic / "feels right" / "reader can follow" =
  rejected (same protocol as v2.14 doc-task cross-attack criterion 4).
- `Constraints` MUST cite ≥1 actual prohibition from program.md
  `## Constraints` section verbatim or paraphrased.

Quote-grep alone is theatre (codex round-2 MAJOR-2: "Goal: optimize
speedup → Takeaway: speedup achieved" passes lexically but means
nothing). Quote-grep + semantic linkage is structural. Gate fails
on any field violating either component.

**Notably absent**: `Estimated horizon`, `Estimated cost`. These were
in the round-1 draft and were cut per codex round-1 attack 6 — they
re-introduce v2.9-removed cap-thinking through the back door. Cost
shape (C×L×M, adversary mode, "mechanism-converge; not a cap") is
printed as informational summary in step F, but not committed as
program.md contract.

### C. Round-0 baseline eval (close v2.15 metric_delta integrity)

If Eval is shell-runnable, the loop runs it ONCE at round-0 against
the unmutated baseline working tree. Output → `$RUN_DIR/round-0/eval.txt`.
Compare parsed value against `Metric.baseline` within `Metric.tolerance`:

- Match → store `state.round_0.baseline_eval.matches_declared = true`,
  proceed.
- Mismatch (beyond tolerance) → refuse start with concrete error
  (declared baseline 0.80, measured 0.31 at tolerance 0.01); user
  either fixes program.md baseline OR re-runs with `--accept-measured-baseline`
  (overwrites Metric.baseline in program.md, requires re-confirmation).

If Eval is `self-judge`, the round-0 baseline runs the frozen rubric
once on the unmutated state → store judge artifact at
`$RUN_DIR/round-0/eval.txt` (with rule #8 fuzzy-ground discipline).

Round-0 baseline closes the v2.15 gap where `metric_delta > 0` (rule
#2 check 10) was poisoned by a declarative baseline that didn't match
reality.

### D. Round-0 program-adversary (rule #1 + #11 inherited)

Independent of `--adversary` flag, round-0 ALWAYS spawns dissect
(cheap universal sanity, ~$0.10) — cross-model adversary diversity
matters per-round, not at round-0 binary gate. Per-round `--adversary=codex|both`
choice is preserved for rounds 1+.

Spawn: `Agent(general-purpose) running Skill('dissect')` against
program.md as input. Attack classes locked to the program-contract
set: `{c1-scope-drift, c2-hidden-assumption, c3-definition-elasticity,
c4-authority-by-citation, d4-scope-creep}`. These five are the
program-contract-integrity classes:

- c1: does the doc claim/proposal exceed Goal? (scope drift)
- c2: what unstated logical premise must hold for this contract to
  work? (hidden assumption)
- c3: does "metric" mean different things in Goal / Metric / Eval /
  Takeaway? (definition elasticity)
- c4: does Takeaway.Validated_by reference files / commands / claims
  that exist? (authority-by-citation)
- d4: does the proposed action stretch beyond stated decision boundary?
  (scope creep)

Output: `$RUN_DIR/round-0/program-adversary.txt`. Header (rule #11
inherited verbatim):

```
ABELIAN-ADV-v1
run_id: <state.run_id>
round: 0
peer: program-gate
nonce: <state.round_0.adversary_nonce>
started_at: <ISO 8601 with milliseconds>
verdict: <single-line verdict>
evidence_class: theoretical
---
<attack content begins; criterion-4 form per v2.14 doc-task>
```

Severity grades:
- BLOCKER → refuse start.
- MAJOR → print to stderr + write to escalations.md, allow start.
- MINOR → write to escalations.md, allow start.

Invalid output (header missing OR criterion-4 violation) → respawn
with explicit "criterion-4 violation, retry" prompt. After 2 respawn
failures → refuse start with `gate-failed-terminal` status.

### E. Program contract hash

After A–D pass, normalize and hash the program-contract sections:

```
Goal | Task class | Target | Eval | Eval ground | Metric |
Constraints | Strategy | Cells | Attack Classes | Takeaway
```

`History` excluded (auto-populated by loop; not part of contract).

Normalization: strip leading/trailing whitespace per section, collapse
multi-blank-lines, lower-case section header markers. Hash:
`sha256(normalized_concat)`. Store in
`state.round_0.program_contract_hash`.

**Per-round refresh** (rule #3 extension): when the loop re-cats
program.md at round-N step 0, recompute the hash and compare to
`state.round_0.program_contract_hash`. Mismatch →
`state.status = "contract-drift-stopped"` (NOT ordinary
`drift-stopped`) + `state.round_0.reconfirmation_required = true`.
Resolution paths:

- New run with new RUN_ID and new hash, OR
- `--reconfirm-gate` flag re-runs full round-0 (steps A–F),
  prints new takeaway + new estimated cost, awaits new "go".
  Stores new hash, sets `reconfirmation_required = false`. Loop
  resumes from round 1 of the same RUN_ID with the new contract.

Hash overhead per round: ~1ms over ~11 sections. Documented as
load-bearing per rule #3 extension; users should expect it in audit
trails.

### F. Confirmation gate (TTY-aware, single flag)

After A–E pass, the loop prints to stderr:

```
=== abelian round-0 program contract gate PASSED ===

Takeaway:
  Success looks like: <verbatim from Takeaway>
  Validated by: <verbatim>
  Constraints: <verbatim>

Baseline eval: <value> (matches declared, tolerance <tol>)
Program-adversary: <verdict> (BLOCKER 0 / MAJOR <n> / MINOR <n>)
Contract hash: sha256:<first 12 chars>...

Cost shape (informational, NOT a cap):
  Mode: <unilateral|co-research>; chains <C>, depth <L>, candidates <M>
  Adversary: <dissect|codex|both>
  Per-round adversary calls: <C × L>
  Termination: mechanism-converge per rule #6 (no rounds/budget cap)

Reply 'go' to launch, 'no' to abort, edit program.md and re-run otherwise.
```

**Behavior by execution context**:

- **Interactive TTY** (`isatty(0)` true AND `isatty(2)` true): wait
  on stdin for "go" / "no" line. **No timeout** — Stephen leaves runs
  unattended. Ctrl-C → `state.status = "interrupted"` + write
  state.json + exit cleanly.
- **Non-interactive** (cron / piped stdin / tmux background): refuse
  start unless `--auto-launch-after-gate` flag explicit. With the
  flag, store `state.round_0.{auto_launched: true, bypass_reason:
  "non-tty + --auto-launch-after-gate"}`. Without, exit with
  `gate-failed-terminal` and informative message ("non-TTY launch
  requires --auto-launch-after-gate; aborting").

Single flag covers both batch-confirm-bypass and non-TTY autostart
(codex round-2 verdict 2: same security event — bypassing human stdin
confirmation after gates pass).

### G. Migration: `--migrate-takeaway` (drafts only, never autostart)

For v2.5–v2.15 program.md missing the Takeaway section, the loop
provides an opt-in migration path:

```
abelian program.md --migrate-takeaway
```

Behavior:

1. Read program.md sections (Goal, Eval, Metric, Constraints).
2. Draft a Takeaway section satisfying B (Success cites Goal +
   Metric name+direction; Validated_by cites Eval/Metric and is
   grep-able / runnable; Constraints cites ≥1 actual prohibition).
3. Write the draft to program.md (in-place edit) + emit a unified
   diff to stdout for user review.
4. **Exit immediately**. Never autostart the loop after migration.
   User reviews + commits + re-runs without `--migrate-takeaway`.

Migration is intentionally narrow (Takeaway only, not other v2.16
fields). Other gaps (no baseline eval, Strategy <2 axes, missing
Eval ground) require manual fix. Reason: automated migration of more
fields = silent fabrication of contract by mutator. Migration is the
place where loud-fail beats quiet-helpful.

### H. state.round_0 schema

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
    "verdict": "<single line from header>",
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

### I. Frame-break Protocol step 4 boundary (rule #16 ↔ Frame-break)

When Frame-break Protocol step 4 (goal re-paraphrase from current
state) is executing, distinguish two outcomes:

- **In-frame re-paraphrase** (default): Takeaway and program-contract
  hash still valid; mutator generates fresh paraphrase from current
  metric vs target gap, allows ≤2 speculative routes
  (`est_metric_delta: "unknown"`). Loop continues normally.
- **Contract invalidity surfaces**: any of the following → abort to
  round-0 with `state.round_0.reconfirmation_required = true`:
  - `metric_delta` direction inverts mid-run (sign change with
    absolute value ≥ baseline_tolerance) → metric no longer measures
    the goal as Takeaway claimed.
  - `Takeaway.Validated_by` stops being grep-able / runnable (e.g.,
    cited file deleted, cited shell command missing).
  - Program-contract hash mismatch surfaces during refresh.

Aborting to round-0 is the correct response to contract invalidity:
the LLM cannot creatively escape a broken contract; only the human
can re-confirm.

### Why this rule is rule #16 and not three rules

Round-1 codex review (Route-1, est_metric_delta +1.6) preferred a
single dense rule over splitting into checklist (#16) + Takeaway (#17)
+ confirmation (#18). Reason: all three are aspects of one semantic
unit ("the program.md contract is sharp + measured + agreed before
round 1 starts"). Splitting would induce rule-number sprawl without
adding clarity; the dense rule matches Occam and stays consistent
with how rules #11 (header block) and #12 (code-review supplemental)
embed multiple sub-mechanisms within one rule.

### Empirical anchor

Codex 56-round trading-internal PM dogfood (2026-05-02) had two
upstream causes that v2.15 partially addressed and rule #16 closes:

1. Per-round goal-anchor didn't propagate (closed by rule #14 Mission
   Thread, v2.15).
2. Cross-layer evidence got muddled (closed by rule #15 Evidence
   Class, v2.15).

But both v2.15 fixes assume program.md itself is sharp at round-0.
If program.md Goal is "improve trading internal" with no Takeaway
contract and a fabricated baseline, every round of v2.15 paraphrases
the fuzz forward. v2.16's rule #16 closes this last upstream cause:
the contract itself is checked, measured, hashed, and human-signed
before any round runs.

The 4-razor history of v2.16 design (TODO.md "v2.16 Razor history")
documents the full reasoning trail: round-1 codex review found 6
issues (2 BLOCKER + 4 MAJOR + 1 MINOR/MAJOR), peer-A response found
6 counter-pushes, round-2 codex review added 3 more MAJORs and
converged. Final spec is the integration of all 12 verified-substantive
findings.
