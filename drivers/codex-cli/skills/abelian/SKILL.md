---
name: abelian
description: Run Abelian compound iteration loops in Codex using a local checkout of the upstream abelian repo. Use when the user says "abelian", "run abelian", "autoloop", "auto-optimize", "optimize this", "run experiments", "Karpathy loop", or asks Codex to mutate, evaluate, adversarially review, and keep only surviving code changes using a program.md spec.
---

# Abelian — Codex skill discovery wrapper

Codex-discoverable entrypoint. Canonical protocol files live in the upstream `Abel-ai-causality/abelian` checkout; this wrapper resolves the checkout and inlines the spec into a `codex exec` invocation. **Source of truth = `$ABELIAN_HOME/{SKILL.md, INVARIANTS.md, prompts/dissect.md}`.**

## Resolve `ABELIAN_HOME`

In order:

1. Use `$ABELIAN_HOME` if set.
2. Resolve the parent repo of this skill (follow symlinks if installed at `~/.codex/skills/abelian`).
3. Ask the user for the abelian checkout path.

The checkout must contain `SKILL.md`, `INVARIANTS.md`, `prompts/dissect.md`. If any is missing, stop and tell the user.

## Preconditions on the target project

Before invoking the loop, verify:

- It is a git repo.
- `program.md` exists with Goal / Target / Eval / Metric / Constraints / Strategy / Attack Classes.
- `.gitignore` covers generated build/cache artifacts.
- Eval is deterministic and prints a numeric metric.

If any precondition fails, stop and tell the user — do not start the loop.

## Invocation

From the target project root:

```bash
codex exec -s workspace-write "$(cat "$ABELIAN_HOME/SKILL.md" "$ABELIAN_HOME/INVARIANTS.md" "$ABELIAN_HOME/prompts/dissect.md")

Run abelian on program.md per the spec above. Maintain state.json under abelian/runs/<RUN_ID>/. Run till mechanism-based converge per INVARIANTS rule #6 (no rounds cap, no budget cap). Default mode = co-research with codex × codex peer pair (different context-framing per peer at full max-effort). Default adversary in unilateral fallback = self×self codex via fresh codex exec subprocesses. Abort: Ctrl+C → status=interrupted."
```

Use `--code-review=on` only when the user explicitly asks for the supplemental Codex review gate (rule #12) or for ship-prep work.

## Installation

Install instructions and the install-time `ln -s` snippet live in [`drivers/codex-cli/README.md`](../../README.md) under "Codex skill discovery". Don't symlink the repo root in place of this wrapper — the upstream `SKILL.md` is the protocol with harness-specific frontmatter.
