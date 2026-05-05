# Abelian — Codex CLI driver

No wrapper script. Codex CLI is itself an LLM agent harness; codex consumes `SKILL.md` + `INVARIANTS.md` directly and orchestrates the loop the same way Claude Code does.

## Invocation

In your project (must be a git repo with `.gitignore` covering build artifacts — see [`SKILL.md` Round-0 Authoring Gate](../../SKILL.md)):

```bash
codex exec -s workspace-write "$(cat ~/abelian/SKILL.md ~/abelian/INVARIANTS.md ~/abelian/prompts/dissect.md)

Run abelian on program.md per the spec above. Maintain state.json under abelian/runs/<RUN_ID>/. Run till mechanism-based converge per INVARIANTS rule #6 (no rounds cap, no budget cap). Default peers = codex × codex with different context-framing at full max-effort; if Codex has no native multi-agent, peer-A and peer-B are fresh codex exec subprocesses (parallel when possible, sequential is acceptable). Abort: Ctrl+C → status=interrupted."
```

Wrap as alias if running often. Prompt is intentionally inlined — codex sees protocol verbatim, no abstraction.

## Codex skill discovery

For Codex environments that scan `~/.agents/skills`, use the installer instead of symlinking the repo root:

```bash
git clone https://github.com/Abel-ai-causality/abelian.git ~/abelian
bash ~/abelian/integrations/codex/install.sh
```

Restart Codex so the skill list reloads.

The repo-root `SKILL.md` is the upstream protocol with harness-specific frontmatter. The installer generates a Codex-compatible `SKILL.md`, copies runtime support files (`INVARIANTS.md`, `prompts/dissect.md`, `agents/openai.yaml`) into `${SKILLS_HOME:-${AGENTS_HOME:-$HOME/.agents}/skills}/.generated/abelian`, then symlinks `${SKILLS_HOME:-${AGENTS_HOME:-$HOME/.agents}/skills}/abelian` to that generated package. Set `SKILLS_HOME=/path/to/.agents/skills` for a repo-local install.

## What codex does

Becomes mutator + orchestrator. Per-round flow lives in [`SKILL.md`](../../SKILL.md) sections "The Loop" / "Round-0 Authoring Gate" / "Frame-break Protocol" — codex executes that spec.

Mechanics: codex maintains `state.json` via `jq`, generates nonces via `python3 -c "import secrets; ..."`, runs git ops directly, dispatches peer subagents via fresh `codex exec` subprocesses (rule #11 nonce header inherited). Parent codex is orchestrator only; it must not synthesize peer artifacts.

Isolation gate: PROPOSE/IMPLEMENT peers may write only their own branch/worktree and `$RUN_DIR/round-N/peer-<slot>/`; CHALLENGE peers may write only `$RUN_DIR/round-N/peer-<slot>.txt`. After each subprocess returns, codex checks the dirty set; any write outside the allowed paths gate-fails that candidate or challenge.

## Code Review supplemental gate

program.md `Code review: on` enables rule #12. Per-round `codex review --uncommitted -c 'model_reasoning_effort="high"'` after peer challenge, before commit-gate. Output to `round-N/codex-review.txt`; commit refused on `[P1]`/`[P2]`. Default off (cost ~doubles per round). If `node` not in PATH, prefix with `bun /path/to/codex`.

## Cross-family peer (advanced)

For Claude peer challenge on high-stakes runs, set program.md `Peer policy: cross-family` and instruct codex to use the anthropic SDK for the Claude peer slot instead of a second `codex exec`. The Claude subagent must use a tool-use loop (file_write tool) to write `peer-<slot>.txt` with the `ABELIAN-PEER-v1` header — main session writing the file directly defeats rule #11's nonce defense.

Most teams skip this — codex × codex with different context-framing per peer is empirically competitive with cross-family pairs.

## Differences vs Claude Code primary

| | Claude Code | Codex CLI |
|---|---|---|
| Entry | `/abelian program.md` | inlined `codex exec` (above) |
| Peer subagent | `Agent(general-purpose)` + `prompts/dissect.md` inlined | fresh `codex exec` subprocess + `prompts/dissect.md` inlined |
| Cross-family | program.md `Peer policy: cross-family` | program.md `Peer policy: cross-family` + anthropic SDK (manual sketch above) |
| State / INVARIANTS / nonce / gate / drift / modes / termination | identical |

Peer challenge methodology lives in `prompts/dissect.md` — same content, different injection.
