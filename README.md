# Abelian

> **Adversarial collaboration on deep, innovative long-horizon iteration with tractable doc and testable metric.**
>
> Two LLM peers each propose AND challenge each other; mutual inspiration between rounds; mechanism-converge termination. Long-horizon scaffolding (file-gate, drift, nonce, anti-compaction) hardens the loop against fabrication, drift, and compaction.

Abelian is an **adversarial collaboration framework** for LLM agent sessions, applied to a specific task profile: deep + innovative + long-horizon iteration whose output is a tractable doc anchored by at least one testable metric.

Kahneman called it *adversarial collaboration*: two parties with opposing intuitions structure their disagreement, share evidence, and converge on a joint statement of where they agree and where they don't. Abelian implements this for LLM dispatch: two peers each propose a mutation toward the declared goal AND attack the other's proposal; mutual inspiration feeds the next round; mechanism-based termination (no rounds cap, no budget cap) prevents the unilateral-review collapse where adversary "agrees to stop".

```
═══════════════════════════════════════════════════════════════
  Round 4 — peer-A: dict-cache / peer-B: lazy-init
═══════════════════════════════════════════════════════════════
  Mutate     → A diff +18 / -3, B diff +24 / -7
  Eval       → A: 2.34 → 0.41 (5.7×), B: 2.34 → 0.38 (6.2×)
  Cross-attack → A finds B's edge-case panic on empty list
                 B finds A's race condition under concurrent calls
  Mutual inspire → R5 A proposes "lazy-cache hybrid" from B's frame
  Champion   → B (better metric), with A's empty-list test added
  Confirm    → ✓ commit-gate passed
  Commit     → def5678
═══════════════════════════════════════════════════════════════
```

## When abelian fits — five properties calibration

| Property | Why required |
|---|---|
| **Deep** | mutation needs real understanding; surface refactors don't justify dual-peer cost |
| **Innovative** | multiple defensible directions exist; cross-attack reveals the shape; if "right answer" is given, just verify |
| **Long-horizon** | convergence at 5+ rounds; mutual inspiration only pays off across rounds |
| **Tractable doc** | output exists as markdown / report / spec / decision-doc / strategy file — peers attack rationale, not just numbers |
| **Testable metric** | at least one quantifiable anchor (eval result, rubric score, sharpe, replication test, P-value) — without it, mechanism convergence has no signal |

**Examples that fit all five**: speedup campaigns at non-obvious algorithm level; alpha-research (sharpe + strategy rationale); paper / decision audit (rubric + review.md); architecture re-design (complexity metric + ADR); ML training recipe search (eval loss + recipe.md).

## When abelian does NOT fit

- **Trivial fix** (typo / rename / single-line) — overhead dominates
- **Code shipping with one obvious approach** — single-axis verify; unilateral review tools cheaper
- **Pure narrative research without testable metric** — mechanism converge needs metric ratchet
- **Pure metric optimization without doc/rationale** — peers can't cross-attack rationale
- **Short single-axis verification** — co-research mutual inspiration pays off only at 5+ rounds; use unilateral mode (`--mode=unilateral`)

## How it works (co-research mode default)

For each round:

```
0. Refresh   — cat INVARIANTS.md && cat state.json (rule #3, anti-compaction)
1. Parallel propose — peer-A and peer-B each generate ONE mutation toward
                      the declared goal, taking different angles (engineered
                      via Strategy axes split + context framing per peer)
2. Parallel implement — each on its own branch
3. Eval both — execution gate + metric ratchet on both peers' artifacts
4. Cross-attack — peer-A attacks peer-B's mutation through the attack-class
                  checklist; peer-B attacks peer-A symmetrically.
                  Output to round-N/peer-{A,B}.txt with mandatory
                  ABELIAN-ADV-v1 header (rule #11) — nonce verified at commit
5. Verification — each attack converts to a probe. Probe pass = attack
                  falsified, mutation survives. Probe fail = mutation reverts
                  on its branch (does NOT take down the campaign)
6. Champion — surviving best-metric mutation = round champion. Loser branch
              preserved (failed mutations train next round)
7. Mutual inspiration — peer-A reads peer-B's mutation + attacks on peer-A;
                        peer-B reads peer-A's mutation + attacks on peer-B.
                        Both feed R+1 propose
8. Converge check — goal-met / mutual-KILL N=3 / plateau+diversity-collapse
                    N=3 → break; otherwise next round
```

When termination fires, post-campaign escalation review writes locked-template compound doc to `docs/solutions/[category]/[goal-slug]-[date].md`. Future runs on same target read this first — **each run starts where the last one ended**.

For tasks that don't need adversarial collaboration (single-axis verification, ship-prep, audit), switch to `--mode=unilateral` — single mutator + single adversary, 1× cost.

## The 13 INVARIANTS (long-horizon LLM scaffolding)

These rules are **scaffolding** — not adversarial-collaboration-specific, but mandatory for any LLM agent loop running >5 rounds. Re-read at start of every round (rule #3 itself).

1. **Adversary output must be on disk** (not just conversation context)
2. **Commit-gate** — 7 checks (8 with `--code-review=on`): file exists, header nonce matches, mtime in valid window, verdict in body, drift check, pre-files exists, eval value matches state, [+ codex-review.txt clean of P1/P2]
3. **Per-round refresh** — `cat INVARIANTS.md && cat state.json` from disk
4. **Drift check** — `expected_head` + branch + dirty-tree before any commit/revert
5. **Pre-files snapshot** — `git ls-files` inventory before mutate (round-level revert tax)
6. **Forbidden termination rationales** — 5 stopping-preferences refused as reasons; loop runs till mechanism converge (no rounds/budget cap)
7. **Verbatim Goal/Target/Constraints** in adversary prompts (no paraphrasing)
8. **Self-judge discipline** — schema-grounding required: concrete (file/column/API/signature) for code; fuzzy-ground via `Eval ground:` declaration + quote-grep gate for doc/research/audit/decision tasks (v2.14). `--adversary=off` + self-judge hard-refused
9. **Execution gate** — adversary-exhaustion alone is necessary but not sufficient
10. **Production-runtime safety** — cron/supervisor/watchdog file edits need extra discipline
11. **Adversary header block** — mandatory `ABELIAN-ADV-v1` format with nonce + timestamp (anti-fabrication friction defense for prompt-inject dispatch)
12. **Code Review supplemental gate** *(opt-in, `--code-review=on`)* — `codex review --uncommitted` as additional code-quality gate; output to `codex-review.txt`; commit refused if `[P1]` or `[P2]` markers present
13. **Self-attack is not adversary** *(v2.12)* — conversation-level "I attacked my own propose" with no spawn / no isolated context / no nonce header is unilateral self-judge (rule #8 degraded mode), not co-research. Empirically validated 17× catch-rate gap (2026-04-29 self-audit dogfood)

Full text in [INVARIANTS.md](INVARIANTS.md).

## Install

Two first-class drivers, both LLM-driven self-orchestration of the same `SKILL.md` spec.

### Claude Code primary

```
/plugin marketplace add Abel-ai-causality/abelian
/plugin install abelian@abelian
```

Or `git clone https://github.com/Abel-ai-causality/abelian.git ~/.claude/skills/abelian`. Restart Claude Code; the skill auto-registers. Invoke: `/abelian program.md`. Details: [`drivers/claude-code/README.md`](drivers/claude-code/README.md).

### Codex CLI primary

```bash
git clone https://github.com/Abel-ai-causality/abelian.git ~/abelian
cd /your/project
codex exec -s workspace-write "$(cat ~/abelian/SKILL.md ~/abelian/INVARIANTS.md ~/abelian/prompts/dissect.md)

Run abelian on program.md per the spec above. Maintain state.json under abelian/runs/<RUN_ID>/. Run till mechanism-based converge per INVARIANTS rule #6."
```

Details: [`drivers/codex-cli/README.md`](drivers/codex-cli/README.md).

## Quick start

Drop a `program.md` into your project root:

```markdown
# Speedup matmul

## Goal
Reduce wall-clock time of matmul(A, B) on N=1000 random matrices.

## Target
- src/matmul.py

## Eval
```bash
python3 bench.py | tail -1
```

## Metric
- name: best_of_5_seconds
- direction: min
- baseline: ~2.0 s
- target: < 0.1 s

## Constraints
- Must satisfy bench.py asserts (correctness contract)
- Pure stdlib (no numpy)

## Strategy
1. Loop reordering (cache locality)
2. Block matrix multiplication
3. Strassen recursion

## Attack Classes
1-7: defaults (auth-surface, fp-numerics, race, version-drift, layout-sensitive, info-leak, error-path)
8. correctness: result must match O(N³) baseline
9. edge-cases: empty matrix, 1×1, non-square
10. fp-precision: don't lose >1e-9 vs baseline
```

Then invoke per your driver. **Default mode = co-research** (Strategy axes 1, 2, 3 distributed across two peers with different framing); switch to `--mode=unilateral` for single-axis verification. **Default adversary = self×self** (same family, different prompt context); add `--adversary=codex` for cross-family priors on high-stakes runs. For ship-prep / PR-level / security-sensitive runs, add `--code-review=on` to enable supplemental code-quality gate (rule #12).

Abelian runs **till converge** — no `--rounds` flag, no `--budget` flag. Mechanism-based termination per INVARIANTS rule #6. Manual abort: SIGINT (Ctrl+C).

## Status

v2.14.0 (2026-04-29). Non-code task readiness — addresses 3 dry-run gaps from doc-task pilot (TODO.md):

- **4 named attack-class libraries** — `research-class` (R1–R6: selection-bias / overfit / regime-shift / look-ahead / target-leakage / replication-failure), `audit-class` (A1–A4), `decision-class` (D1–D4), `doc-class` (C1–C4: scope-drift / hidden-assumption / definition-elasticity / authority-by-citation). New `task:` field in program.md (`code | research | audit | decision | doc | mixed`); non-code tasks must opt in to ≥1 library. Loud-warn on absent field (v2.5 backwards-compat). Namespace discipline reserves `*-class` suffix.
- **Doc-task cross-attack** (Co-Research Mode subsection) — 5-criterion attack form with mandatory falsification statement (`"this is wrong if X, because the doc claims Y"`). X must be grep-able / runnable / countable; aesthetic / tone / rigor X auto-rejected. Closes "peers prefer my style" degeneration on prose targets. Failure-mode escalation dispatches new adversary subagent (preserves rule #13), records `state.rounds[N].coresearch_degraded: true` for provenance.
- **INVARIANTS rule #8 fuzzy-ground extension** — `Eval ground:` declaration in program.md (≥1 of: user-supplied reference doc / canonical repo doc / verbatim initiating user message; Goal-as-ground supplementary only). Quote-grep gate replaces vibes-grounding; untraced rubric dimensions auto-scored 0; contradictions flag round `fuzzy-ground-violation` and revert.
- **Positioning preserved** — removed v1 draft's `unscoreable-fuzzy-ground` + human-acceptance-count escape mid-cross-attack. Tasks with no testable metric stay out of scope (route to ce-brainstorm). The deletion converged independently with peer-B R1 BLOCKERs against rule #6 / #9 collisions.
- **First co-research dogfood on doc-task** — v2.14 itself shipped via the protocol it ships. peer-B R1 (MAJOR-REVISION-REQUIRED, 4 BLOCKERs / 4 MAJORs / 3 MINORs) → v2 (ACCEPT-WITH-FIXES, 1 NEW BLOCKER / 2 NEW MAJORs / 2 NEW MINORs) → commit, all resolved with grep-able evidence in attack files. The `feedback_invented_empirical_anchors_is_a4_strawman.md` lesson came out of this cycle.

v2.13.0 (2026-04-29). Repositioned as **adversarial collaboration framework** (Kahneman-style applied to LLM dispatch); 13 INVARIANTS rules are **shared scaffolding** for long-horizon LLM agent loops; 3 abelian-specific rules (#5 / #10 / #11) are **dispatch-architecture tax** for the LLM-pair-via-prompt-inject choice. Claude Code unilateral path smoketested 2026-04-28 (count_duplicate_pairs).

## Contributing

INVARIANTS changes require an empirical anchor — link a concrete failure mode the current rule misses. Speculative tightening is friction without evidence.

New driver paths under `drivers/<name>/` are welcome and should mirror the existing pattern: `README.md` only, with the LLM harness's invocation form. **No wrapper scripts** — both shipped drivers are LLM-driven self-orchestration; new drivers should follow the same shape.

Style: terse, judgment-first prose. Avoid hedging when a concrete claim works.

## Acknowledgments

- Daniel Kahneman — *adversarial collaboration* methodology
- The `dissect` skill (vendored in `skills/dissect/`) — adversary attack-class methodology
- Andrej Karpathy — "compound iteration loop" framing

## License

MIT — see [LICENSE](LICENSE).
