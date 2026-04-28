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

## 2. Commit-gate (7 checks, all must pass before `git commit`)

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

The loop MUST NOT terminate or write a "done" claim if the
load-bearing reason for stopping reduces to ANY of:

- "Diminishing returns" / "remaining work is lower-value"
- "Time remaining is short" / "won't fit before --rounds cap"
- "Deferred to future campaign / TODO / next session"
- "Foundation in place" / "natural stopping point" / "good break here"
- "Cleaner to ship what we have than fold in more"

These are stopping preferences, not goal-fulfillment. Termination is
justified only by:

- **Goal met** — eval ≥ target (unilateral) OR champion ≥ target (co-research)
- **Adversary exhausted across attack classes** + execution gate (rule #9)
- **Plateau + diversity collapse** — N consecutive rounds no eval
  improvement AND candidate edit-distance falling (co-research)
- **Mutual KILL deadlock** — N rounds where every peer attack
  succeeds on both sides (co-research)
- **--rounds cap fired** — handled separately, no rationale needed

The cap path handles its own case. Run another round; do not
predict whether it will finish.

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
- Self-judge MUST verify external schema (file paths, columns, API
  contracts, function signatures) by reading actual source before
  scoring (v2.2 schema-grounding). Self-judge that scored ≥ rubric_max
  without grounding step is auto-rescored to 0 on affected dimensions.
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
---
<attack content begins here>
```

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
