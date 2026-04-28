# Abelian TODO

Tracked at the file/feature level. Issues filed on GitHub will mostly track
items here. Priority ordering: blockers > parity-gaps > polish.

## Blockers (none currently)

## Parity gaps

### `drivers/codex-cli/abelian.sh` — reference impl, smoketest pending

The script implements the full v2.8 protocol but has not been run end-to-end
against a real codex CLI session. Specific points likely to need a first-user
fix:

- **Sandbox flag verification** — `codex exec -s workspace-write` is the
  documented codex CLI sandbox mode for write-allowed execution, but flag
  names have varied across codex CLI versions. First user should:
  ```bash
  codex exec --help | grep -A 2 sandbox
  ```
  and adjust `-s workspace-write` to whatever the current codex CLI version
  expects. Affects both mutator (line ~157) and adversary (line ~213) dispatch.

- **Eval command extraction** — the awk-based extraction at line ~167
  parses `program.md` for the first `## Eval` ... ```bash``` ``` block.
  Edge cases not handled:
  - Multiple `## Eval` blocks (only the first is used; should be sufficient
    but not strictly enforced)
  - Eval commands using `$()` or backticks that require shell-eval semantics
    different from `eval "$EVAL_CMD"` (currently uses `eval`, which expands
    quoted substitutions correctly, but multi-line scripts may break)
  - Eval commands writing to temp files or having side effects beyond
    stdout (eg., `python3 bench.py 2>&1 | tee /tmp/log | tail -1` works,
    but cron-bound evals with their own state need care)

- **Codex prompt size limits** — `program.md` + `state.json` (with
  accumulated rounds) + `git diff` injected into a single prompt may
  exceed codex CLI's per-call prompt budget on long-running campaigns
  (R10+). Mitigations to consider:
  - Pass only the most recent N rounds in state.json instead of full
    history
  - Strip whitespace / formatting from program.md before injection
  - Use codex CLI's session-management features (if available) to
    persist context across rounds

- **Mutator dispatch correctness** — the script assumes `codex exec`
  invoked with workspace-write will produce a single coherent mutation
  per round. If codex bails partway (rate limit, timeout), the working
  tree may have a partial edit. The drift check + commit-gate should
  catch this and revert via `git checkout -- .`, but the mutator's
  output log should be inspected for non-zero exit + partial-write
  warnings.

- **Verdict line extraction** — the script does `grep '^verdict:'` on
  the adversary.txt header to extract the verdict. If the adversary
  writes the header out of order or with inconsistent capitalization,
  this fails. Mitigation: parse via the explicit nonce-header format
  enforcement in commit-gate check #2.

### Co-research mode in `abelian.sh`

The Claude Code SKILL.md path supports `--mode=co-research` natively
(via parallel `Agent()` dispatches with different context-framing).
The bash driver does not implement this — `drivers/codex-cli/README.md`
documents it as "extend the script with two parallel `codex exec` peers".

To add: spawn two `codex exec` subprocesses with peer-A vs peer-B
prompt framings, read their outputs, run cross-attack step (each peer
reads the other's mutation and surfaces attacks), gate accordingly.
~50 lines of bash + the two prompt templates. Q3 2026 if demand.

### Cross-family adversary wrapper

Sketched in `drivers/codex-cli/README.md` "Cross-family advanced" section.
Concrete deliverable would be `drivers/codex-cli/cross-family-adversary.sh`
that:

1. Reads adversary prompt from stdin
2. Calls `anthropic.Messages.create` via Python SDK
3. Loops on tool-use until Claude emits a `file_write` for adversary.txt
   (preserving the nonce-defense — wrapper does NOT write the file
   directly; Claude does, via tool use)
4. Verifies header matches expected nonce + run_id + round + started_at

Estimated ~80 lines Python + ~20 lines bash. Not shipped because most
teams using codex CLI won't add anthropic SDK + a 100-line wrapper for
a 5% fidelity gain.

## Polish

- `SKILL.md` could be split: 600 lines is verbose. Candidates for
  extraction to `references/`:
  - The "Search Shape (C × L × candidates)" detailed table → `references/search-shape.md`
  - "Eval Discipline" full hierarchy → `references/eval-discipline.md`
  - "Co-Research Mode" deep dive → `references/co-research.md`
  Main SKILL.md keeps the loop description + INVARIANTS pointers.
  Defer until v3.0; reduces churn risk in v2.8.x.

- `INVARIANTS.md` rule #4 currently has a paragraph-level inline
  rationale ("the smoketest false-positive 'low.py' instead of 'slow.py'
  confirmed this gotcha 2026-04-28"). This is good context but verbose
  in a rules file. Consider moving rationale to a `INVARIANTS-RATIONALE.md`
  sibling for those who want the why; rule file stays terse.

- `prompts/dissect.md` is good as-is but could include a few example
  attacks per Attack Class to seed adversary subagent thinking. Risk:
  examples bias toward the example, miss novel attacks. Try and see.

- `drivers/claude-code/README.md` is currently 94 lines; could probably
  be 30-40 lines with judicious cuts. Defer.

- The handover banner in SKILL.md matches night-shift's visual style
  (3 horizontal rules, emoji, centered text). Consistent across the
  ecosystem; no change needed.

## Won't fix (decisions, not bugs)

- **No `--push` or `--pr` support.** Abelian deliberately doesn't
  push or open PRs. The user reviews `git log BASE..HEAD` and decides
  what ships. Mirrors night-shift's same decision.

- **No daemon mode.** Abelian is bounded by `--rounds`, not by wall
  clock. If you want overnight autonomy use night-shift; if you want
  continuous work use ralph-loop. Abelian's niche is "bounded campaign
  with strict eval gate".

- **No Discord / Slack notifications.** Out of scope; users can wrap
  the CLI invocation in their own notification infra.

- **No multi-target campaigns in one run.** One `program.md` = one
  Target = one campaign. If you have multiple targets, run multiple
  campaigns. Cross-target portfolio is a v3.0 maybe-feature, not
  promised.
