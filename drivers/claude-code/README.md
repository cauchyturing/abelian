# Abelian — Claude Code driver

Native Claude Code skill path. Claude reads `SKILL.md` + `INVARIANTS.md` and orchestrates the loop directly via `Agent` tool dispatches.

## Install

```
/plugin marketplace add Abel-ai-causality/abelian
/plugin install abelian@abelian
```

Or clone:

```bash
git clone https://github.com/Abel-ai-causality/abelian.git ~/.claude/skills/abelian
```

Restart Claude Code; the skill auto-registers.

## Invocation

```
/abelian program.md
```

Default mode = **co-research** (two Claude peers each propose + attack via `Agent` calls with different context-framing). Switch to single-axis verification mode with `--mode=unilateral` (mutator + dissect adversary). Add `--adversary=codex` for cross-family priors on high-stakes runs — Claude session uses Bash tool to dispatch `codex exec` subprocess (codex CLI must be installed + auth'd; falls back to dissect with loud notice if codex unavailable).

For ship-prep / PR-level / security-sensitive runs, add `--code-review=on` to enable INVARIANTS rule #12 supplemental gate. Claude session uses Bash to dispatch `codex review --uncommitted` after the dissect/codex adversary call; output to `round-N/codex-review.txt`; commit refused if `[P1]`/`[P2]` markers present. Roughly doubles per-round cost; default off.

Abort: Ctrl+C / interrupt the Claude Code session → `status=interrupted` is written to `state.json`.

## Differences vs Codex CLI primary

Almost none. Both paths are LLM-driven self-orchestration of the same `SKILL.md`. Differences:

- **Adversary dispatch**: Claude Code uses `Agent(general-purpose) + Skill('dissect')`; codex CLI uses `codex exec` subprocess + inlined `prompts/dissect.md`. Same methodology.
- **Cross-family**: Claude Code has `--adversary=codex` built-in via MCP. Codex CLI requires anthropic SDK + a tool-use wrapper (sketch in `../codex-cli/README.md`).
- All else (state.json, INVARIANTS, nonce protocol, commit-gate, drift detection, termination conditions) is identical.

Full execution spec: [`../../SKILL.md`](../../SKILL.md). Full INVARIANTS: [`../../INVARIANTS.md`](../../INVARIANTS.md).
