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
-1. Round-0 Program Contract Gate (v2.16, rule #16) — runs ONCE before round 1:
    A. hard checklist (Goal has measurable noun, Target paths exist or have create:, Eval shell-runnable
       or rubric+ground, Metric has baseline+direction+tolerance, Strategy >=2 axes, Attack Classes >=1
       library, Takeaway section present)
    B. Takeaway = derived contract (Success cite Goal+Metric name+direction; Validated_by cite Eval/Metric
       and grep-able/runnable/countable; Constraints cite >=1 actual prohibition)
    C. baseline eval run once at unmutated state -> $RUN_DIR/round-0/eval.txt (validate vs Metric.baseline +/- tolerance)
    D. dissect program-adversary on locked classes {c1,c2,c3,c4,d4} -> $RUN_DIR/round-0/program-adversary.txt with
       ABELIAN-ADV-v1 header (peer: program-gate, evidence_class: theoretical)
    E. sha256 program contract hash over Goal/Task class/Target/Eval/Eval ground/Metric/Constraints/
       Strategy/Cells/Attack Classes/Takeaway -> state.round_0.program_contract_hash
    F. TTY-aware confirmation: interactive stdin go/no (no timeout); non-TTY refuses unless --auto-launch-after-gate
0. Refresh        — re-cat INVARIANTS.md + state.json from disk; recompute program contract hash, mismatch -> contract-drift-stopped
1. Hypothesize    — propose ONE mutation per Strategy axis (or two peer mutations in co-research mode)
2. Mutate         — pre-files snapshot, then apply the mutation(s)
3. Eval           — run program.md `## Eval` shell command, capture metric
4. Adversary      — spawn `codex exec` subprocess(es) with prompts/dissect.md template +
                    fresh nonce + ISO timestamp; subagent writes adversary.txt with
                    mandatory ABELIAN-ADV-v1 header (rule #11), returns verdict line
5. Commit-gate    — 10 always-on + 1 conditional checks (rule #2, v2.15). All pass → git commit. Any fail → revert.
                     Always-on 8/9/10 (v2.15): mission_thread completeness (#14), evidence_class enum (#15), goal-progress required (#14).
6. Place / Record / Adapt + populate state.rounds[N].mission_thread (rule #14: goal_paraphrase fresh, ≥2 candidate_routes, selection_reason citing trade-offs)
7. Frame-break Protocol — if adversary verdict no-attacks OR metric_delta ≤ 0 OR all candidate_routes est_metric_delta ≤ 0:
                     fire 5 mandatory steps (reject-pool mining, attack-class library escalation, peer framing swap if co-research,
                     goal re-paraphrase from current state, cross-peer alternative_routes mining if co-research) BEFORE termination.
                     state.frame_break_count_consecutive increments; resets on any subsequent productive round.
8. Terminate      — when goal-met / no-proposal-after-K-frame-breaks (K=2 default) / mutual-KILL N=3 / interrupted (v2.15)
```

codex maintains state.json via `jq`, generates nonces via `python3 -c "import secrets; ..."`, runs git ops directly, and dispatches adversary subagents via `codex exec`. No wrapper is needed because codex already has shell access to all of this.

## Code Review supplemental gate (`--code-review=on`, v2.11+)

When the orchestrator's prompt enables `--code-review=on` (INVARIANTS rule #12), each round runs an additional `codex review --uncommitted -c 'model_reasoning_effort="high"'` after the adversary call and before the commit-gate. The codex review's `[P1]/[P2]/[P3]` severity output goes to `round-N/codex-review.txt`; commit-gate's conditional check 11 (in v2.15 numbering, formerly check 8 in v2.14) refuses the commit if `[P1]` or `[P2]` markers are present. This is a code-quality layer (codex's built-in review prompt) supplemental to rule #1's domain-specific dissect adversary.

`--code-review` requires the same codex CLI install + auth as `--adversary=codex`. If `node` is not in PATH, prefix with `bun /path/to/codex` per the bun-shim convention. Default off because per-round cost roughly doubles.

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
