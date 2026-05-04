# Abelian INVARIANTS — read at start of every round

These rules are NON-NEGOTIABLE. Context compaction is not an excuse.
"Time efficiency" is not an excuse. "Trivial round" is not an excuse.
"Self-judge eval is small" is not an excuse.

If you are an LLM running this loop and you find yourself rationalizing
why a rule below "doesn't apply this time" — that is the exact failure
mode the rule exists to catch. Stop and re-read.

## 1. Peer challenge output must be on disk

Each round's peer-challenge calls write `$RUN_DIR/round-N/peer-A.txt`
+ `peer-B.txt` BEFORE the calls return. Empty file = peer challenge
was not actually run. Conversation-only peer output is invalid and
fails commit-gate (rule #2).

**v3.0 unification**: prior versions (v2.x) had a unilateral mode that
wrote a single `$RUN_DIR/round-N/adversary.txt` file. v3.0 unifies on
the two-peer file layout (`peer-A.txt` + `peer-B.txt`); the
`adversary.txt` filename is legacy-readable for archived v2.x runs but
no longer produced. See Migration section.

## 2. Commit-gate (10 always-on checks + 1 conditional, all must pass before `git commit`)

1. `$RUN_DIR/round-N/peer-A.txt` AND `$RUN_DIR/round-N/peer-B.txt`
   exist and are non-empty.
2. Each file starts with the standard peer challenge header block
   (rule #11) and its `nonce` field equals
   `state.rounds[N].peer_<slot>_nonce`.
3. Each file's mtime is later than
   `state.rounds[N].peer_<slot>_started_at` and earlier than `now()`.
   (`stat -c %Y peer-<slot>.txt` vs ISO parse.)
4. Each peer's verdict line (recorded in
   `state.rounds[N].peer_<slot>_verdict_line`) appears verbatim in
   the corresponding peer-N.txt body (`grep -qF "$VERDICT" peer-<slot>.txt`).
   For `ABELIAN-PEER-v1` files, the recorded verdict MUST also be one of
   the rule #18 counter-mode whitelist values: `PROBE-PASS`,
   `PROBE-FAIL`, `CONCEDED`, or `NON-CODIFIABLE-ESCALATED`. Legacy
   `ABELIAN-ADV-v1` files remain read-only-accepted during the rule #11
   deprecation window with their archived single-line verdicts. Closes
   the "compacted agent fabricates a clean review" hole while preventing
   freeform verdict drift in new peer output.
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
   from `candidate_routes` by id; every
   `mission_thread.candidate_routes[i].grounding` field is present,
   non-empty, and cites a real anchor: file path + line range, command +
   actual output, or quoted text + source. See rule #14 for schema.
9. **Evidence Class enum (rule #15)** — each `peer-<slot>.txt` header
   block contains `evidence_class:` line and value is in the whitelist
   (`theoretical | paper | replay | settled | dry_run | live`).
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

11. **Code Review supplemental (conditional, rule #12, opt-in via program.md `Code review: on`)** —
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
  hash, OR explicitly re-gates with TTY-prompt walk-through (re-runs
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

**Rationale**: a 56-round PM campaign showed attack-survival as standalone gate produces "attack PASS, mission metric flat" rounds indefinitely. Loop is goal-driven, not attack-defense. Peer challenge mechanisms preserved (rules #1, #7, #11, #13); attack-survival is necessary but not sufficient. Mission Thread (#14) anchors per-round work to goal; Evidence Class (#15) prevents cross-layer evidence confusion; Frame-break Protocol expands the loop's plateau response from "stop" to "creatively break frame".

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

## 11. Peer challenge header block (mandatory format)

Every `peer-A.txt` / `peer-B.txt` (and round-0 `program-peer-challenge.txt` / sharpening pass artifacts) starts with this header, written by the peer itself before attack content:

```
ABELIAN-PEER-v1
run_id: <state.run_id>
round: <N>
peer: peer-A | peer-B | program-gate | sharpen-pass-N
nonce: <state.rounds[N].peer_<slot>_nonce>
started_at: <ISO 8601 with milliseconds>
verdict: <single-line verdict, identical to state.rounds[N].peer_<slot>_verdict_line>
evidence_class: theoretical | paper | replay | settled | dry_run | live
---
<attack content begins here>

[optional] alternative_routes:
  - id: <slug>
    mechanism: <one-line description>
    est_metric_delta: <float | "unknown">
    grounding: <file path + line range | command + actual output | quoted text + source>
    rationale: <why peer would consider this>
```

**evidence_class** (rule #15, REQUIRED): pick strongest class actually exercised. `theoretical` (analysis only) → `paper` (dry compute) → `replay` (historical data) → `settled` (real-world outcome observed) → `dry_run` (full pipeline, no commit) → `live` (production observation). Cross-class inflation = silent fabrication; rule #11 nonce-friction defense applies.

**alternative_routes** (optional): peer may write informational routes after attacks. Non-binding; commit-gate ignores content; readable by next round's mutator for `mission_thread.candidate_routes` (rule #14 reject-pool mining).

**v3.0 header rename**: previously `ABELIAN-ADV-v1` (v2.0-v2.17). Commit-gate accepts BOTH during deprecation window; new peer calls emit only `ABELIAN-PEER-v1`. Legacy support removed after 2 minor versions.

**Orchestrator protocol** (per peer challenge call):

1. Generate fresh `nonce` (`secrets.token_hex(8)`, 16 hex) + `started_at` (ISO ms). Write to `state.rounds[N].peer_<slot>_{nonce, started_at}`.
2. Prompt MUST include those values verbatim with instruction: write `ABELIAN-PEER-v1` header (these EXACT values) as first lines of `$RUN_DIR/round-<N>/peer-<slot>.txt`, then `---`, then attacks. Don't omit. Don't change nonce.
3. After subagent returns, record verdict line in `state.rounds[N].peer_<slot>_verdict_line`. Commit-gate (rule #2) verifies.

**Honest scope**: friction-level defense, not cryptographic. Real value is anti-Threat-1 (compaction oversight): a compacted orchestrator that "forgot" to call peer cannot silently hand-write the file — it must first cat state.json to find the nonce, which triggers rule #3's INVARIANTS re-read reflex, surfacing rule #1 ("actually call peer"). Friction converts silent skip → deliberate sabotage (which is loud + traceable in artifacts).

## 12. Code Review supplemental gate (opt-in, v2.11+)

program.md `Code review: on` enables an additional code-quality review layer that
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

**Commit-gate addition** (rule #2 conditional check 11, when
program.md `Code review: on`):

11. `$RUN_DIR/round-N/codex-review.txt` exists, non-empty, AND contains
    no `[P1]` or `[P2]` severity markers.

**Loop semantics**: night-shift's "fix → re-review → max 10 rounds →
revert" pattern is allowed but optional. Simplest form: a single
review pass; if P1/P2 present, revert immediately and let mutator
propose differently next round. Up to the orchestrator's discretion;
the gate-check itself is binary.

**Graceful degradation** (loud, never silent):
- program.md `Code review: on` + codex CLI unavailable (binary missing OR
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

## 13. Self-challenge is not co-research (v2.12, generalized v3.0)

A peer attacking its own propose in conversation context (no spawn,
no isolated context, no nonce header) is unilateral self-judge (rule #8
degraded mode), NOT co-research (rule #1 + v3.0 single-loop discipline
where each peer challenge runs as a spawned subagent). RLHF prior
overlap = same-prior collapse vector regardless of whether the agent
is "mutator", "adversary", or "peer" — the load-bearing distinction
is **spawned vs in-conversation**, not the role label.

**Empirical anchor**: in a self-audit dogfood, an orchestrator's self-challenge on 5 mutation proposals found 1 obvious issue. A spawned peer-B with `prompts/dissect.md` payload found 17 attacks on the same input, including 4 frame challenges the self-challenger could not see. ~17× catch-rate gap confirms RLHF prior overlap is severe — agent and self-challenger share priors over BOTH "what to mutate" and "how to attack".

**Trigger**: any conversation-level abelian/autoresearch reference
that involves ANY of:

- ≥3 mutation proposals (protocol / architecture / strategy / memory)
- Protocol-level change (INVARIANTS / state.json schema / commit-gate)
- "verdict / done / keep / revert / accept / pareto / trade-off"
  vocabulary applied to mutation evaluation

**Required action when triggered**: spawn dispatched peer (Agent with `prompts/dissect.md` inlined OR codex exec subprocess with same template) writing nonce-headered peer file (rule #11) BEFORE reaching verdict. Self-challenge in conversation context does NOT count.

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


## 14. Mission Thread per round — anchor every round to goal

Every round populates `state.rounds[N].mission_thread` BEFORE commit-gate. Missing/incomplete = commit-gate check 8 fails = revert.

```text
"mission_thread": {
  "goal_paraphrase": str,           // fresh paraphrase, MUST differ from prior round
  "metric_delta": float | null,     // null requires exploration_round=true
  "blocker_status": "removed | partially | blocked_on:<dep> | n/a",
  "mission_relevance": str,         // one sentence; cites Takeaway.Validated_by if rule #16 active
  "candidate_routes": [             // ≥2 entries; single-route = gate-fail
    { "id": str, "mechanism": str, "est_metric_delta": float | "unknown",
      "est_cost": "cheap | medium | expensive", "blocker_chain": str | null,
      grounding: "file path + line range | command + actual output | quoted text + source" }
  ],
  "selected_route_id": str,         // matches a candidate_routes entry
  "selection_reason": str,          // MUST cite ≥1 unpicked route's trade-off by id
  "exploration_round": bool         // true allows null metric_delta + "unknown" est_metric_delta
}
```

**Key gate constraints**:

- `goal_paraphrase` MUST differ from `state.rounds[N-1].mission_thread.goal_paraphrase` (string-equality check). Identical = mutator skipped re-reading program.md → gate-fail. Forces per-round Goal re-read.
- `mission_relevance` forbidden phrases: "exploring / learning more / investigating / trying" without `exploration_round=true`. **Rule #16 trace** (when Takeaway present): MUST contain ≥1 verbatim/paraphrased phrase from `Takeaway.Validated_by`, paraphrase requires verbatim original cited inline. Untraceable → gate-fail.
- `candidate_routes` ≥2 entries; unselected routes mineable by Frame-break Protocol step 1 (reject-pool mining). `est_metric_delta="unknown"` only allowed in exploration rounds.
- `selection_reason` MUST cite at least one unpicked route's trade-off by id ("picked highest est delta" alone insufficient).
- `exploration_round=true` allowed for ≤2 consecutive rounds (rule #2 check 10).

**Why**: without per-round goal-anchor, attacks become self-justifying ("passed all classes → commit") regardless of mission progress. Mission Thread makes goal-relevance a structural per-round artifact. Rule #2 check 10 reverts rounds with `metric_delta=0 AND blocker=n/a AND exploration=false`.

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

## 16. Program Contract Gate — round-0 authoring + confirmation

Before round 1, run hard checklist + Takeaway-as-derived-contract + measured baseline + file-gated program-peer-challenge + content hash + TTY-aware confirmation. Skipping any step → `status: gate-failed-terminal`.

### A. Hard checklist (binary, fast-fail)

- **Goal** (≤200 chars, one line) — MUST contain measurable noun (whitelist: `number | percentage | sharpe | recall | runtime | file-count | pass-rate | precision | latency | throughput | bytes | count`). Standalone process verbs forbidden (`improve | better | investigate | explore | study | examine | analyze`).
- **Target** — paths inside-repo, parent dir exists, each path EITHER exists OR has explicit `create:` marker.
- **Eval** — shell-runnable (`bash -c <line>` → numeric stdout) OR `self-judge` with `Eval ground:` per rule #8.
- **Metric** `<name>: <baseline> <direction> <tolerance>` — direction ∈ {min, max}; tolerance defaults by type (`pass-rate / file-count / count` → exact 0; `float / runtime` → epsilon = max(1e-9, 0.01 × |baseline|); noisy benchmarks → repeated_median 5 runs).
- **Strategy** — ≥2 axes (single-axis missions exit at rule #17 Pass 0 triage).
- **Attack Classes** — ≥1 named library or custom extension.
- **Takeaway** section present, see B.

### B. Takeaway = derived contract (3 fields)

```
## Takeaway
- Success looks like: <observable end-state, ≤2 lines>
- Validated by: <eval/metric/artifact, grep-able / runnable / countable>
- Constraints: <≤2 lines>
```

**Quote-grep + semantic linkage** (both required, not just quote-grep — the latter alone is theatre):
- `Success looks like` cites Goal phrase verbatim/paraphrased AND includes Metric `name` + `direction` keywords.
- `Validated by` cites Eval/Metric phrase AND is grep-able (literal pattern in named file) / runnable (shell command) / countable. Aesthetic / "feels right" / "reader can follow" → rejected per v2.14 doc-task criterion 4.
- `Constraints` cites ≥1 actual prohibition from program.md `## Constraints` verbatim/paraphrased.

`Estimated horizon` / `Estimated cost` deliberately absent — they re-introduce v2.9-removed cap-thinking. Cost shape (C×L×M, peer config) printed informational in F, not committed as contract.

### C. Round-0 baseline eval

Shell-runnable Eval runs ONCE against unmutated tree → `$RUN_DIR/round-0/eval.txt`. Validate parsed value against `Metric.baseline ± Metric.tolerance`. Mismatch → TTY prompt "measured X vs declared Y; accept measured? (y/edit/abort)" (non-TTY: exit `gate-failed-terminal` with edit instructions). Self-judge mode runs frozen rubric once + stores artifact (rule #8 fuzzy-ground).

Closes the v2.15 gap where `metric_delta > 0` (rule #2 check 10) was poisoned by declarative baselines.

### D. Round-0 program-peer-challenge (rule #1 + #11 inherited)

Independent of program.md `Peer policy:` choice, round-0 spawns a single dissect-template peer (~$0.10) — cross-family diversity matters per-round, not at round-0 binary gate. Locked attack classes: `{c1-scope-drift, c2-hidden-assumption, c3-definition-elasticity, c4-authority-by-citation, d4-scope-creep}` (program-contract integrity set).

Output: `$RUN_DIR/round-0/program-peer-challenge.txt` with rule #11 ABELIAN-PEER-v1 header (`peer: program-gate`, `evidence_class: theoretical`). Severity: BLOCKER → refuse start; MAJOR → stderr + escalations.md; MINOR → escalations.md only. Invalid output (header missing OR criterion-4 violation) → respawn (max 2) → `gate-failed-terminal`.

### E. Program contract hash

After A-D pass, sha256 over normalized sections: `Goal | Task class | Target | Eval | Eval ground | Metric | Constraints | Strategy | Cells | Attack Classes | Takeaway`. `History` excluded. Stored in `state.round_0.program_contract_hash`.

**Per-round refresh** (rule #3 extension): re-cat program.md, recompute hash, compare. Mismatch → `state.status = "contract-drift-stopped"` (distinct from rule #4 `drift-stopped`) + `reconfirmation_required = true`. Resolution: new RUN_ID OR re-invoke `abelian program.md` → TTY prompt walks through fresh round-0 with new hash.

### F. Confirmation gate (TTY-aware, single flag)

After A-E pass, print stderr summary (Takeaway + baseline eval + peer-challenge verdict + contract hash + cost shape) and:
- **Interactive TTY**: wait stdin "go"/"no" — no timeout. Ctrl-C → `interrupted`.
- **Non-TTY**: exit `gate-failed-terminal` with the printed summary so user can review and re-invoke (no auto-launch — peer-challenge cost requires explicit human go).

### G. Takeaway migration (TTY prompt; never autostart)

v2.x program.md missing `## Takeaway` → checklist fails → TTY prompt "draft Takeaway from Goal/Eval/Metric/Constraints? (y/n)". On `y`: drafts Takeaway satisfying B → emits unified diff → exits (user reviews + commits + re-invokes). Never autostart. Other v2.x gaps (no baseline, Strategy <2 axes, missing Eval ground) require manual fix — automated migration of more fields = silent fabrication.

### H. state.round_0 schema

```json
"round_0": {
  "checklist_passed": bool,
  "checklist_failures": [str],
  "baseline_eval": { "value": float, "file": str, "tolerance": float, "matches_declared": bool },
  "program_peer_challenge": { "file": str, "verdict": str, "evidence_class": "theoretical",
                              "blockers": int, "majors": int, "minors": int,
                              "peer_nonce": str, "peer_started_at": iso },
  "takeaway": { "success_looks_like": str, "validated_by": str, "constraints": str },
  "program_contract_hash": "sha256:...",
  "user_confirmed_at": iso | null,
  "auto_launched": bool,
  "bypass_reason": str | null,
  "reconfirmation_required": bool
}
```

### I. Frame-break Protocol step 4 boundary

Step 4 (goal re-paraphrase from current state):
- **In-frame** (default): contract still valid; mutator paraphrases from current metric vs target gap; allows ≤2 speculative routes.
- **Contract invalidity** → abort to round-0 + `reconfirmation_required = true` when ANY of: metric_delta sign inverts (≥ baseline_tolerance) / Takeaway.Validated_by no-longer-runnable / contract-hash mismatch surfaces. LLM cannot creatively escape broken contract — only human re-confirms.

### Empirical anchor

A 56-round PM campaign closed peer-clean across attack classes while mission metric stayed flat. Rule #14 + #15 fix per-round drift but assume program.md is sharp at round-0. Rule #16 closes the upstream cause.

## 17. Goal-Authoring Stage (opt-in)

Compiles fuzzy mission to rule #16-compliant program.md draft via per-field adversarial cycles. Recursive application of rule #1 + #11 + #18 propose+attack+converge to goal-authoring itself. After sharpening produces draft, rule #16 round-0 gate runs unchanged.

### Trigger

- `abelian --mission "<text>"` (string, explicit) | `abelian --mission-file <path>` (file)
- File auto-detect: existing file lacking `## Goal` → orchestrator prompts user (yes/no)
- Bare strings to `abelian` NEVER auto-classified (typo-as-mission risk)

### 5-pass protocol

| # | Output | Cost | Locked attack classes | Converge predicate |
|---|---|---|---|---|
| 0 — Triage | classification | ~$0.05 | n/a | classification commits |
| 1 — Outcome Distillation + Grounding | observable end-state + ≥1 ground citation | ~$0.5 | c1, c2 | attack_survival + mission_traceability + rule_16_composability + propose_grounding (Goal clause) |
| 2 — Metric Forge + Runnable Eval | metric + runnable Eval shell + dry-run-parse | ~$0.5 | c3, c4 | + Eval parses to number AND cited files/commands exist |
| 3 — Lever + Constraint | ≥2 Strategy axes + Constraints (Pass 3 attack byproduct) | ~$0.5 | d4, c1 | + ≥2 surviving axes |
| 4 — Takeaway Derivation | mechanical compose Takeaway 3 fields per rule #16 B | $0 | n/a (mechanical_validator) | source_coverage + rule_16_B_quote_grep + semantic_linkage |

**Triage outcomes**: `sharp` (exit, "write program.md directly") | `fuzzy-but-grounded` (proceed) | `fuzzy-ungrounded` (exit, "route to ce-brainstorm") | `single-axis` (exit, "use a separate review tool — abelian's diversity engine has no value here").

**Per-pass artifacts**: `$RUN_DIR/sharpening/pass-N/{peer-A.md, peer-B.md, peer-A.txt, peer-B.txt, converged.md}` with rule #11 ABELIAN-PEER-v1 header (`peer: sharpen-pass-N`, `evidence_class: theoretical`).

### Bounded reconnaissance

Reads ONLY: fuzzy mission text + optional `Target hint:` paths in mission-file + top-3-noun keyword grep (≤1 grep per noun) + last 200 lines session history. Forbidden: full repo TODOs, CLAUDE.md, full git log. Each entry → trace.json `reconnaissance[]` with `{command, hit_count, selected_excerpt_path, selected_excerpt_text, citation_type: user_message | target_hint | grep_hit | session_tail}`.

### Mechanical converge predicate (Pass 1-3)

4 conditions, all required:
- `attack_survival` — no BLOCKER from peer challenges
- `mission_traceability` — surviving candidate contains ≥1 verbatim/paraphrased phrase from fuzzy mission text
- `rule_16_composability` — surviving fields satisfy rule #16 hard-checklist clause for that field
- `propose_grounding` — every candidate route / proposal surfaced by Pass 1-3 cites a grounding anchor (file path + line range, command + actual output, or quoted text + source)

Pass 4 substitutes `mechanical_validator_passed` (3 conditions: source_coverage + rule_16_B_quote_grep + semantic_linkage). Pass 4 fails → route back to Pass 2 with c3-definition-elasticity input. Pass 1-3 mutual-KILL after 2 retries → re-run Pass 0 triage; abort if re-triage outputs `fuzzy-ungrounded`.

### Composition + rule #16 takeover

Draft assembled from passes (Goal from Pass 1, Eval from Pass 2, Strategy + Constraints from Pass 3, Takeaway from Pass 4). `Eval ground:` always includes (d) verbatim fuzzy_mission. Draft → rule #16 round-0 gate runs as if user wrote it; Pass 2's pre-validated Eval command closes the `TBD-measure-at-round-0` placeholder.

### state.sharpening schema (top-level)

```json
"sharpening": {
  "fuzzy_mission_verbatim": str,
  "triage_classification": "sharp | fuzzy-but-grounded | fuzzy-ungrounded | single-axis",
  "started_at": iso,
  "passes": [{ "n": int, "name": str, "converged_to": str, "files": [str], "user_intervention": null }],
  "program_md_draft_path": str,
  "trace_json_path": str,
  "recommended_peer_policy": "same-family | cross-family"
}
```

### trace.json schema (audit trail)

Per-pass `artifact_integrity`: `{path, sha256, nonce, started_at, verdict_line, model_or_peer, retry_count}`. Pass 2 adds `eval_dry_run_parse`: `{command, exit_code, stdout_tail, parsed_value}`. Top-level: `fuzzy_mission_verbatim`, `triage`, `reconnaissance[]`, `passes[]`, `program_md_path`, `recommended_peer_policy`. Full schema verified against rule #18's CHALLENGE-mode falsification form.

### Cost

~$1.65-2.15 per fuzzy mission ($1.55 sharpening + $0.10 round-0 program-peer-challenge). ROI: 100× on a single multi-round-fuzz catch.


## 18. Asymmetric peer discipline — innovative-grounded propose, strictly-verification-oriented counter

Every peer operates in two modes per round/pass; conflating them collapses loop quality.

### PROPOSE mode: innovative AND grounded

When generating mutations, candidate routes, outcomes, metrics, levers, or alternative_routes:
- **Innovative** — novel framings / mechanism enumeration / cross-domain analogues. Safe-incremental restatements of prior round ("extend X with...", "refine the existing...", "polish the current...") FORBIDDEN unless `exploration_round=true` AND ≥1 speculative route (`est_metric_delta: "unknown"` per rule #14).
- **Grounded** — every proposal cites ≥1 anchor: file path + line range, command + actual output, or quoted user/spec/doc text with source. No vibes, no fabricated specifics, no authority-by-citation without citation existing (c4 generalized).

Commit-gate (rule #2 check 8) extends: any `mission_thread.candidate_routes` entry lacking grounding citation OR using safe-incremental phrasing without exploration_round=true → check fails → revert.

### COUNTER mode: strictly verification-oriented

When attacked on own mutation, response options are STRICTLY limited to:

1. **Convert attack to probe + run** — regression test / benchmark / rubric criterion / shell command / grep pattern from attack's "this is wrong if X" form. Run. PASS → mutation survives attack. FAIL → mutation reverts on its branch.
2. **Concede + revert** — accept without probe; mutation reverts. State logs `attacks_conceded`.
3. **Mark non_codifiable + escalation_required** — attack genuinely cannot become a probe (purely qualitative). Mutation reverts; human reviews post-campaign. Counter cannot survive without falsifiable verification.

**Forbidden in COUNTER**: "I disagree because..." without probe / "the attack misunderstands..." without grep-able rebuttal / "this was already addressed" without line/commit cite / any argumentation that doesn't produce binary attack-falsified-or-mutation-reverts outcome.

**Verdict line** in counter response: `PROBE-PASS | PROBE-FAIL | CONCEDED | NON-CODIFIABLE-ESCALATED`.

### Why asymmetric

PROPOSE without innovation collapses to "extend last round". PROPOSE without grounding fabricates. COUNTER without strict verification becomes argumentation — peer talks attack down, mutation lands, identified failure mode unaddressed. Be expansive when generating, strict when defending.

### Empirical anchor

A 56-round PM campaign had counter-mode arguments landing without probes (mutations passed gate, mission metric flat) AND >75% of `candidate_routes` were safe-incremental restatements. Rule #18 makes both patterns gate-fail.

### Prompt template embedding

Both drivers (Claude Code Agent + codex CLI subprocess) embed in peer prompts:

```
PROPOSE: ≥2 candidate_routes. Each cites ≥1 file/command/output.
         Safe-incremental forbidden unless exploration_round=true with
         ≥1 speculative route (est_metric_delta: "unknown").

COUNTER: respond via (a) probe + run + PASS/FAIL — preferred,
         (b) concede + revert, OR (c) non_codifiable + escalation_required.
         Argumentation FORBIDDEN. Verdict: PROBE-PASS | PROBE-FAIL | CONCEDED | NON-CODIFIABLE-ESCALATED.
```

Rule #11 nonce-header friction defense applies.
