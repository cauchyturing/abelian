# Abelian

Adversarial collaboration loop for deep + innovative + long-horizon LLM iteration. **One skill, one loop, one discipline**: every configured peer (default 2) proposes AND attacks every other peer's proposals. 18 INVARIANTS. Mechanism-converge termination. Goal-authoring is a stage of the same loop (auto-detected from `--mission` flag), not a separate mode.

Output = tractable doc + testable metric. Tasks without testable metric → use `ce-brainstorm`.

```
═══════════════════════════════════════════════════════════════
  Round 4 — peer-A: dict-cache / peer-B: lazy-init
═══════════════════════════════════════════════════════════════
  Mutate     → A diff +18 / -3, B diff +24 / -7
  Eval       → A: 2.34 → 0.41 (5.7×), B: 2.34 → 0.38 (6.2×)
  Cross-attack → A finds B's empty-list panic; B finds A's race
  Mutual inspire → R5 A proposes "lazy-cache hybrid" from B's frame
  Champion   → B (better metric), with A's empty-list test added
  Confirm    → ✓ commit-gate passed → def5678
═══════════════════════════════════════════════════════════════
```

## Fits / doesn't fit

| Fits when | Doesn't fit when |
|---|---|
| 5+ rounds expected (mutual inspiration pays off) | Trivial fix (typo / single-line) |
| Multiple defensible directions exist | One obvious approach (use unilateral review tools) |
| Output is doc + testable anchor | Pure narrative without metric |
| Domain has cross-attack surface | Pure metric without rationale to attack |

Examples: speedup at non-obvious algorithm level, alpha research (sharpe + rationale), audit (rubric + review.md), architecture redesign (complexity metric + ADR), training-recipe search (eval loss + recipe.md).

## Loop (co-research mode default)

Round-0 once: **Program Contract Gate** (rule #16) — checklist + Takeaway + baseline eval + program-peer-challenge + sha256 hash + confirmation.

Per round:
```
0. Refresh    cat INVARIANTS.md && cat state.json (rule #3)
1. Propose    peer-A and peer-B each generate one mutation, different angles
2. Implement  each on its own branch
3. Eval       execution gate + metric ratchet
4. Cross-attack  peer-A → peer-B, peer-B → peer-A
                 round-N/peer-{A,B}.txt with ABELIAN-PEER-v1 header (rule #11)
5. Verify     each attack converts to a probe; fail = revert that branch
6. Champion   best surviving metric wins; loser preserved for inspiration
7. Inspire    each peer reads other's mutation + attacks; feeds R+1
8. Converge?  goal-met / no-proposal-after-K-frame-breaks / mutual-KILL
              if "stuck" (adversary-exhausted OR metric stalled OR all
              candidate_routes ≤0), fire Frame-break Protocol (5-step
              creative escape) BEFORE termination claim
```

Termination → post-campaign escalation review writes compound doc to `docs/solutions/<category>/<goal-slug>-<date>.md`. Future runs read this first.

Single-axis verification (typo fix, single-axis verify, ship-prep against known target) is out of abelian's scope — use a separate review tool. abelian's diversity engine has no value on single-axis tasks.

## INVARIANTS (18)

| # | Rule | Notes |
|---|---|---|
| 1 | Adversary output on disk | not conversation context |
| 2 | Commit-gate (10 always-on + 1 conditional) | peer files / nonce / mtime / verdict / drift / pre-files / eval / mission_thread (#14) / evidence_class (#15) / goal-progress (#14); +codex-review when program.md `Code review: on` |
| 3 | Per-round refresh | cat INVARIANTS.md + state.json |
| 4 | Drift check | expected_head + branch + dirty-tree before any commit/revert. v2.16 distinguishes `contract-drift-stopped` (rule #16 hash mismatch) from ordinary `drift-stopped` |
| 5 | Pre-files snapshot | git ls-files inventory (revert tax) |
| 6 | Forbidden termination rationales | 5 stopping-preferences refused. Valid: `goal-met / no-proposal-after-K-frame-breaks / mutual-KILL / interrupted` |
| 7 | Verbatim Goal/Target/Constraints | in adversary prompts (no paraphrase) |
| 8 | Self-judge discipline | concrete-ground (code) or fuzzy-ground (doc/research/audit/decision) per `Eval ground:`; v3.0 has no off-switch for peer challenge (always required) |
| 9 | Execution gate | adversary-exhaustion alone insufficient |
| 10 | Production-runtime safety | cron/supervisor/watchdog edits need extra discipline |
| 11 | Peer challenge header block | `ABELIAN-PEER-v1` + nonce + timestamp + `evidence_class:`. Peers may add informational `alternative_routes:` after attacks. (v3.0 rename from `ABELIAN-ADV-v1`; legacy double-read during deprecation) |
| 12 | Code Review supplemental gate | opt-in via program.md `Code review: on`; refuse on `[P1]`/`[P2]` |
| 13 | Self-attack is not adversary | conversation-level "I attacked own propose" without spawn = unilateral self-judge (rule #8 degraded), NOT co-research. 17× catch-rate gap (2026-04-29) |
| 14 | Mission Thread per round (v2.15) | 7-field block; goal_paraphrase fresh; ≥2 candidate_routes; selection_reason cites trade-offs; mission_relevance traces Takeaway.Validated_by |
| 15 | Evidence Class enum (v2.15) | adversary header gains `evidence_class:` `theoretical / paper / replay / settled / dry_run / live` |
| 16 | Program Contract Gate (v2.16) | round-0: hard checklist + Takeaway-as-derived-contract + baseline eval + program-peer-challenge + sha256 hash + TTY-aware confirmation. Single-axis triage exits before round-0 (out of abelian's scope) |
| 17 | Goal-Authoring Stage (v2.17, v3.0 fold-in) | `abelian --mission "<text>"`: 5-pass protocol (triage + outcome distillation + metric forge + lever surfacing + Takeaway derivation) compiles fuzzy mission to rule #16-compliant program.md draft. Native answer to OKR's hierarchical decomposition. v3.0 dropped `abelian sharpen` subcommand; goal-authoring is now a stage of the unified loop |
| 18 | Asymmetric peer discipline (v3.0) | PROPOSE mode: innovative + grounded (cite ≥1 file/command/output, no vibes). COUNTER mode: strictly verification-oriented (convert attack to probe, run, return PASS/FAIL or CONCEDED or NON-CODIFIABLE-ESCALATED). Argumentation without falsification target FORBIDDEN in counter |

Full text: [INVARIANTS.md](INVARIANTS.md).

**Frame-break Protocol** (v2.15): 5 mandatory steps when round looks "stuck" — reject-pool mining, attack-class library escalation, peer framing swap (co-research), goal re-paraphrase from current state, cross-peer alternative_routes mining (co-research). Only `no-proposal-after-K-frame-breaks` (default K=2) terminates on exhaustion. Plateau triggers LLM creativity, not loop quit.

## Install

**Claude Code**:
```
/plugin marketplace add Abel-ai-causality/abelian
/plugin install abelian@abelian
```
Or `git clone https://github.com/Abel-ai-causality/abelian.git ~/.claude/skills/abelian` and restart. Invoke: `/abelian program.md`. Details: [drivers/claude-code/README.md](drivers/claude-code/README.md).

**Codex CLI**:
```bash
git clone https://github.com/Abel-ai-causality/abelian.git ~/abelian
cd /your/project
codex exec -s workspace-write "$(cat ~/abelian/SKILL.md ~/abelian/INVARIANTS.md ~/abelian/prompts/dissect.md)

Run abelian on program.md per spec. Maintain state.json under abelian/runs/<RUN_ID>/. Run till mechanism-based converge per INVARIANTS rule #6."
```
Details: [drivers/codex-cli/README.md](drivers/codex-cli/README.md).

**Codex skill discovery**:
```bash
git clone https://github.com/Abel-ai-causality/abelian.git ~/abelian
bash ~/abelian/integrations/codex/install.sh
```
Restart Codex after installing. Do not symlink the repo root into `~/.codex/skills`; the installer generates a Codex-clean skill package from the canonical repo files and symlinks `~/.codex/skills/abelian` to it.

## program.md skeleton

```markdown
# Speedup matmul

## Goal
Reduce wall-clock time of matmul(A, B) on N=1000 random matrices.

## Task class
code

## Target
- src/matmul.py

## Eval
```bash
python3 bench.py | tail -1
```

## Metric
- name: best_of_5_seconds
- direction: min
- baseline: 2.0
- tolerance: 0.05
- target: < 0.1

## Constraints
- Must satisfy bench.py asserts (correctness contract)
- Pure stdlib (no numpy)

## Strategy
1. Loop reordering (cache locality)
2. Block matrix multiplication
3. Strassen recursion

## Attack Classes
- default
- correctness: result must match O(N³) baseline
- edge-cases: empty / 1×1 / non-square
- fp-precision: don't lose >1e-9 vs baseline

## Takeaway
- Success looks like: best_of_5_seconds < 0.1 (Goal: matmul wall-clock; Metric direction: min)
- Validated by: `python3 bench.py | tail -1` returns < 0.1, asserts pass (Eval: bench.py)
- Constraints: pure stdlib, no numpy (Constraints: cited above)
```

Default peers auto-detected from driver (`claude+claude` Claude Code; `codex+codex` codex CLI). Cross-family `claude+codex`, search shape (chains/depth/candidates/portfolio), code-review supplemental — all declared in program.md (no CLI flags). Fuzzy mission: `abelian --mission "<text>"`. Mechanism-based termination per rule #6 (no rounds/budget/wallclock cap). Manual abort: SIGINT. Legacy v2.x flags deprecated → see [MIGRATION.md](MIGRATION.md).

## Version

Current: **v3.0.0** — one skill, one loop, one discipline. See `git log` or GitHub Releases for history.

## Contributing

INVARIANTS changes need an empirical anchor — link a concrete failure mode the rule misses. Speculative tightening is friction without evidence.

New drivers under `drivers/<name>/`: `README.md` only, no wrapper scripts. Both shipped drivers are LLM-driven self-orchestration.

Style: terse, judgment-first. No hedging when a concrete claim works.

## License

MIT — see [LICENSE](LICENSE). Built on Kahneman's *adversarial collaboration*, dissect-style attack-class taxonomy (`prompts/dissect.md`), Karpathy's "compound iteration loop" framing.
