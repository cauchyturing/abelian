# Abelian — Claude Code driver

This is the path for **Claude Code–primary** teams. You invoke `/abelian
program.md` from a Claude Code session; the skill's main `SKILL.md`
orchestrates the loop using Claude's `Agent` tool to dispatch adversary
subagents that themselves invoke `Skill('dissect')`.

This is the original / native form of abelian. Everything is Claude.

## Quickstart

Install via Claude Code plugin marketplace:

```
/plugin marketplace add cauchyturing/abelian
/plugin install abelian@abelian
```

Or clone directly:

```bash
git clone https://github.com/cauchyturing/abelian.git ~/.claude/skills/abelian
```

Restart Claude Code. The skill auto-registers. Then in any session:

```
/abelian program.md --rounds=10
```

For high-stakes runs that warrant cross-family priors, add Codex MCP via
your normal MCP server setup, then:

```
/abelian program.md --rounds=10 --adversary=codex
```

(Or `--adversary=both` for union-of-attacks from dissect Claude subagent
AND Codex MCP.)

## What this driver does

The full execution spec is in [`../../SKILL.md`](../../SKILL.md). This
README is just the dispatch summary:

```
Step 0  — Refresh: Read INVARIANTS.md and state.json from disk (rule #3)
Step 1+2 — Mutator: Claude (this session) writes ONE mutation per Strategy
           axis. Pre-files snapshot recorded before any write (rule #5).
Step 3   — Eval:   Run program.md `## Eval` shell command, capture metric
Step 4   — Adversary: spawn `Agent(general-purpose)` running `Skill('dissect')`
           on the diff + eval. Subagent writes adversary.txt with mandatory
           ABELIAN-ADV-v1 header block (rule #11), returns verdict line.
Step 5   — Commit-gate: 7 checks (rule #2). All pass → `git commit`.
           Any fail → `git checkout` + scoped clean. Mark round `gate-failed`.
Step 6+  — Place / Record / Adapt
```

The Claude Code platform handles the `Agent` tool isolation automatically
— each adversary call gets its own context window with the same tool
access (Read/Write/Bash/Grep/etc.) but **no inheritance of the mutator's
conversation**. This is structural prior-split.

## Self×self by default

Default `--adversary=dissect` means Claude (your session) is mutator,
Claude (subagent) running `Skill('dissect')` is adversary. Same RLHF
family, role-split via prompt + isolated context. Empirically validated
2026-04-26 (audit-followup-boss-grasp): same-family-different-context
beats different-family-same-context for substantive co-research; this
self×self default is the recommended config for ~95% of campaigns.

For the remaining 5% (high-stakes ship-prep, P0 audits, model-family
blind-spot risk), `--adversary=codex` opts in to cross-family priors via
Codex MCP.

## Differences vs codex CLI primary

See [`../codex-cli/README.md` "Differences vs Claude Code primary"](../codex-cli/README.md#differences-vs-claude-code-primary)
for the full table. TL;DR: dispatch vocabulary is different (`Agent +
Skill` vs `codex exec`); methodology, INVARIANTS, state.json schema,
commit-gate, nonce protocol all identical.

## Why this driver is the "primary"

Abelian was originally built for Claude Code (under the working name
`autoresearch` v1.0–v2.6). The codex CLI driver was added in v2.8.1 to
let codex-primary teams use the same protocol with zero translation
work. Both drivers are now first-class — neither is degraded — but the
SKILL.md execution spec is written in Claude Code idiom (Agent / Skill
/ MCP) because that's the historical implementation.

If you're reading this and you're on codex CLI, see `../codex-cli/README.md`.
You're not in degraded mode; you're in a parallel first-class path.
