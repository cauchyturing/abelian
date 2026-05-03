# Abelian — Codex CLI driver

No wrapper script. Codex CLI is itself an LLM agent harness; codex consumes `SKILL.md` + `INVARIANTS.md` directly and orchestrates the loop the same way Claude Code does.

## Invocation

In your project (must be a git repo with `.gitignore` covering build artifacts — see [`SKILL.md` Round-0 Authoring Gate](../../SKILL.md)):

```bash
codex exec -s workspace-write "$(cat ~/abelian/SKILL.md ~/abelian/INVARIANTS.md ~/abelian/prompts/dissect.md)

Run abelian on program.md per the spec above. Maintain state.json under abelian/runs/<RUN_ID>/. Run till mechanism-based converge per INVARIANTS rule #6 (no rounds cap, no budget cap). Default mode = co-research with codex × codex peer pair (different context-framing per peer at full max-effort). Default adversary in unilateral fallback = self×self codex via fresh codex exec subprocesses. Abort: Ctrl+C → status=interrupted."
```

Wrap as alias if running often. Prompt is intentionally inlined — codex sees protocol verbatim, no abstraction.

## What codex does

Becomes mutator + orchestrator. Per-round flow lives in [`SKILL.md`](../../SKILL.md) sections "The Loop" / "Round-0 Authoring Gate" / "Frame-break Protocol" — codex executes that spec.

Mechanics: codex maintains `state.json` via `jq`, generates nonces via `python3 -c "import secrets; ..."`, runs git ops directly, dispatches adversary subagents via fresh `codex exec` subprocess (rule #11 nonce header inherited).

## Code Review supplemental gate

program.md `Code review: on` enables rule #12. Per-round `codex review --uncommitted -c 'model_reasoning_effort="high"'` after peer challenge, before commit-gate. Output to `round-N/codex-review.txt`; commit refused on `[P1]`/`[P2]`. Default off (cost ~doubles per round). If `node` not in PATH, prefix with `bun /path/to/codex`.

## Cross-family adversary (advanced)

For Claude adversary on high-stakes runs, instruct codex to use anthropic SDK for the adversary step instead of `codex exec`. The Claude subagent must use a tool-use loop (file_write tool) to write `adversary.txt` — main session writing the file directly defeats rule #11's nonce defense.

Most teams skip this — codex × codex with different context-framing per peer is empirically competitive with cross-family pairs.

## Differences vs Claude Code primary

| | Claude Code | Codex CLI |
|---|---|---|
| Entry | `/abelian program.md` | inlined `codex exec` (above) |
| Peer subagent | `Agent(general-purpose)` + `prompts/dissect.md` inlined | fresh `codex exec` subprocess + `prompts/dissect.md` inlined |
| Cross-family | `--adversary=codex` (built-in) | anthropic SDK (manual sketch above) |
| State / INVARIANTS / nonce / gate / drift / modes / termination | identical |

Adversary methodology lives in `prompts/dissect.md` — same content, different injection.
