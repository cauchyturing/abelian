# Abelian — Codex CLI driver

There is no wrapper script. Codex CLI is itself an LLM agent harness — codex consumes `SKILL.md` + `INVARIANTS.md` directly and orchestrates the loop the same way Claude Code does on the other path.

## Invocation

In your project (must be a git repo with `.gitignore` covering build artifacts — see top-level [`SKILL.md` Pre-Flight section](../../SKILL.md)):

```bash
codex exec -s workspace-write "$(cat ~/abelian/SKILL.md ~/abelian/INVARIANTS.md ~/abelian/prompts/dissect.md)

Run abelian on program.md per the spec above. Maintain state.json under abelian/runs/<RUN_ID>/. Run till mechanism-based converge per INVARIANTS rule #6 (no rounds cap, no budget cap). Default mode = co-research with codex × codex peer pair (different context-framing per peer at full max-effort). Default adversary in unilateral fallback = self×self codex via fresh codex exec subprocesses. Abort: Ctrl+C → status=interrupted."
```

Wrap it in a shell function or alias if you'll run it often. The full prompt is intentionally inlined so codex sees the protocol verbatim — no abstraction layer.

## What codex does

The codex session you just launched becomes the **mutator + orchestrator**. For each round:

```
0. Refresh        — re-cat INVARIANTS.md + state.json from disk
1. Hypothesize    — propose ONE mutation per Strategy axis (or two peer mutations in co-research mode)
2. Mutate         — pre-files snapshot, then apply the mutation(s)
3. Eval           — run program.md `## Eval` shell command, capture metric
4. Adversary      — spawn `codex exec` subprocess(es) with prompts/dissect.md template +
                    fresh nonce + ISO timestamp; subagent writes adversary.txt with
                    mandatory ABELIAN-ADV-v1 header (rule #11), returns verdict line
5. Commit-gate    — 7 checks (rule #2). All pass → git commit. Any fail → revert.
6. Place / Record / Adapt
8. Terminate      — when goal-met / adversary-exhausted N=3 / plateau N=3 / mutual-KILL N=3
```

codex maintains state.json via `jq`, generates nonces via `python3 -c "import secrets; ..."`, runs git ops directly, and dispatches adversary subagents via `codex exec`. No wrapper is needed because codex already has shell access to all of this.

## Cross-family adversary (advanced, not built-in)

If you want a Claude adversary for cross-RLHF-family priors on a high-stakes campaign, install the `anthropic` Python SDK and instruct codex to call it for the adversary step:

```
... in your prompt, add:
"For the adversary call in step 4, instead of `codex exec`, use the anthropic SDK
to call Claude with the prompts/dissect.md template. The Claude subagent must
write adversary.txt with a tool-use loop (file_write tool) so the nonce-defense
holds — main session must not write the file directly."
```

Most teams skip this — codex × codex with different context-framing per peer is empirically validated as competitive with cross-family pairs (per `feedback_coresearch_must_run_r2_to_convergence.md` 2026-04-26).

## Differences vs Claude Code primary

Almost none. Both paths are LLM-driven self-orchestration of the same SKILL.md spec.

| | Claude Code primary | Codex CLI primary |
|---|---|---|
| Entry | `/abelian program.md` slash command | `codex exec -s workspace-write "$(cat SKILL.md INVARIANTS.md prompts/dissect.md) ..."` |
| Adversary subagent | `Agent(general-purpose) + Skill('dissect')` | Fresh `codex exec` subprocess + prompts/dissect.md inlined |
| Cross-family option | `--adversary=codex` flag — orchestrator dispatches `codex exec` subprocess (codex CLI installed + auth'd) | anthropic SDK + manual prompt instruction (sketch above) |
| All else (state.json, INVARIANTS, nonce, gate, drift, modes, termination) | Identical | Identical |

The dissect-style adversary methodology lives in `prompts/dissect.md` — same content for both drivers, different injection mechanism.
