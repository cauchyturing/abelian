# Abelian — Claude Code driver

Native skill path. Claude reads `SKILL.md` + `INVARIANTS.md` and orchestrates the loop via `Agent` tool dispatches.

## Install

```
/plugin marketplace add Abel-ai-causality/abelian
/plugin install abelian@abelian
```

Or `git clone https://github.com/Abel-ai-causality/abelian.git ~/.claude/skills/abelian` then restart Claude Code.

## Invocation

```
/abelian program.md                  # sharp contract
/abelian --mission "<text>"          # fuzzy mission
/abelian --mission-file <path>       # fuzzy mission, file
```

Abort: Ctrl+C → `status=interrupted`.

All other behavior (peer pair, search shape, code-review supplemental, etc.) is set in program.md sections OR resolved at TTY-interactive prompts during round-0 / drift events. No CLI flag soup.

Peer dispatch: `Agent(general-purpose)` with `prompts/dissect.md` inlined into the prompt (single source of truth shared with codex-cli driver). v3.0 removed `Skill('dissect')` standalone registration; methodology lives in `prompts/dissect.md` only. Spec: [`../../SKILL.md`](../../SKILL.md) + [`../../INVARIANTS.md`](../../INVARIANTS.md).
