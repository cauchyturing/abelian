---
name: abelian
description: Run Abelian compound iteration loops in Codex using a local checkout of the upstream abelian repo. Use when the user says "abelian", "run abelian", "autoloop", "auto-optimize", "optimize this", "run experiments", "Karpathy loop", or asks Codex to mutate, evaluate, adversarially review, and keep only surviving code changes using a program.md spec.
---

# Abelian

Use this skill as a Codex-discoverable entrypoint for Abelian. Keep the upstream protocol files as the source of truth.

## Locate the Upstream Checkout

Resolve `ABELIAN_HOME` in this order:

1. Use `$ABELIAN_HOME` if it is set.
2. Use the parent repo checkout that contains this skill, resolving symlinks if this skill is installed into `~/.codex/skills/abelian`.
3. Ask the user for the abelian checkout path.

The checkout must contain:

- `SKILL.md`
- `INVARIANTS.md`
- `prompts/dissect.md`

## Preconditions

Before running an Abelian loop, verify the target project has:

- A git repository.
- A `program.md` with Goal, Target, Eval, Metric, Constraints, Strategy, and Attack Classes.
- `.gitignore` entries for generated build/cache artifacts relevant to the target project.
- A deterministic eval command, preferably one that prints a numeric metric.

If a required precondition is missing, stop and tell the user what must be added.

## Codex CLI Invocation

From the target project root:

```bash
export ABELIAN_HOME=/path/to/abelian
codex exec -s workspace-write "$(cat "$ABELIAN_HOME/SKILL.md" "$ABELIAN_HOME/INVARIANTS.md" "$ABELIAN_HOME/prompts/dissect.md")

Run abelian on program.md per the spec above. Maintain state.json under abelian/runs/<RUN_ID>/. Run till mechanism-based converge per INVARIANTS rule #6."
```

Use `--code-review=on` only when the user explicitly asks for Abelian's supplemental Codex review gate or when the work is PR-level/ship-prep and the extra cost is acceptable.

## Installation for Codex Skill Discovery

Codex skill discovery expects `SKILL.md` frontmatter with Codex-compatible fields. Do not symlink the abelian repo root directly into `~/.codex/skills/abelian`; the upstream protocol `SKILL.md` includes driver-specific metadata for other harnesses.

Install this wrapper instead:

```bash
export ABELIAN_HOME=~/abelian
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
ln -s "$ABELIAN_HOME/drivers/codex-cli/skills/abelian" "${CODEX_HOME:-$HOME/.codex}/skills/abelian"
```

Restart Codex after installing so the skill list is reloaded.
