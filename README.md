# Abelian

> Mutate. Attack. Keep what survives.
>
> A symmetric iteration loop for code: **co-research by default** (two peers each propose + challenge), unilateral as opt-in for known-target verification.
>
> File-gated, drift-checked, anti-compaction.

Abelian is an iteration loop spec consumed directly by LLM agent harnesses ([Claude Code](https://claude.com/claude-code) / OpenAI [Codex CLI](https://github.com/openai/codex) / others). You hand it a `program.md` defining what to optimize, a deterministic `Eval`, and a `Strategy`. The harness mutates, evaluates, attacks, and keeps only what survives — round after round — with structural gates that compaction, fabrication, or drift cannot silently slip past.

```
═══════════════════════════════════════════════════════════════
  Round 4 — cell: memoization (peer-A: dict-cache / peer-B: lazy-init)
═══════════════════════════════════════════════════════════════
  Mutate     → peer-A diff +18 / -3, peer-B diff +24 / -7
  Eval       → A: 2.34 → 0.41 (5.7×), B: 2.34 → 0.38 (6.2×)
  Cross-attack → peer-A finds B's edge-case panic on empty list
                 peer-B finds A's race condition under concurrent calls
  Champion   → B (better eval), with A's empty-list test added
  Confirm    → ✓ 7-check commit-gate passed
  Commit     → def5678
═══════════════════════════════════════════════════════════════
```

## Why

Long-running iteration loops fail in three predictable ways:

1. **Multi-agent collapse** — generator and adversary share priors, agree to stop early, miss the same blind spot.
2. **Compaction** — after R5+ the loop forgets its own rules, fabricates a clean review, commits broken code.
3. **Drift** — the user makes a side commit, or a stale `__pycache__` lands in the working tree, and the loop doesn't notice.

Abelian makes structural bets against all three:

- **Co-research by default**, unilateral by opt-in. Two peers each propose AND challenge each other's mutations, with mutual inspiration between rounds — symmetric peer-attack is the abelian-group property the name borrows from. Empirically validated 2026-04-26: same-family-different-context beats different-family-same-context for substantive co-research; cost is 2× per round but ~1.5× fewer rounds for non-trivial work.
- **File-gated everything.** Adversary output must land on disk with a verified header block (run_id + nonce + timestamp). The commit gate checks 7 conditions; any miss = revert. A compacted agent that "forgot" it skipped the adversary cannot silently fabricate the file — the nonce isn't in its memory.
- **Drift detection before every write.** `expected_head` + branch + dirty-tree match. Mismatch = `drift-stopped`, no further writes, terminal-only summary.
- **Per-round re-read of `INVARIANTS.md`.** The 11 non-negotiable rules live in their own file. Step 0 of every round re-reads them from disk. Conversation memory drifts; the file is truth.
- **Forbidden termination rationales.** "Diminishing returns", "time/tokens running out", "deferred to next session", "foundation in place", "cleaner to ship" — all explicitly refused as stopping reasons. **No `--rounds` cap, no `--budget` cap.** Termination is justified only by mechanism (eval ≥ target / adversary exhausted N=3 / plateau N=3 / mutual KILL N=3 / manual SIGINT).

## Two modes

| | Co-research (default) | Unilateral (`--mode=unilateral`) |
|---|---|---|
| Best for | Discovery, novel design, "where do I start", non-trivial work where any mutation has multiple defensible directions | Verification of known target, ship-prep, audit, regression hardening, single-axis micro-optimization |
| Roles | Two peers each propose AND attack the other's proposal; mutual inspiration between rounds | Generator proposes + implements; adversary attacks (only — no propose, no endorse) |
| Cost / round | 2× | 1× |
| Termination | Goal met, plateau (N=3 no improvement + diversity collapse), mutual KILL deadlock (N=3) | Goal met, adversary exhausted across attack-class checklist (N=3 consecutive clean) |
| Cross-family adversary | `--pair=claude,codex` (Claude Code) / sketch in codex-cli driver | `--adversary=codex` (built-in on Claude Code via MCP) |

Pure self×self (Claude × Claude or codex × codex with different context-framing per peer) is the recommended default. Cross-family adversary is opt-in for high-stakes ship-prep where model-family blind-spot risk matters.

## How it works

For each round:

```
0. Refresh   — cat INVARIANTS.md && cat state.json (rule #3, anti-compaction)
1. Hypothesize — Strategy + state.rounds[] → ONE testable change per peer (co-research) or one mutation (unilateral)
2. Mutate    — pre-files snapshot (rule #5), then apply the change(s)
3. Evaluate  — shell command returns a number (or test-suite pass/fail) per peer's mutation
4. Adversary — co-research: each peer attacks the other's mutation through dissect methodology;
               unilateral: subagent runs dissect on the diff + eval output.
               Output written to round-N/{adversary.txt | peer-A.txt + peer-B.txt} with mandatory
               ABELIAN-ADV-v1 header (rule #11) — nonce verified at commit
5. Confirm   — 7-check commit-gate (rule #2). All pass → git commit. Any fail → revert.
6. Place     — co-research: surviving best-eval mutation = round champion, loser branch preserved
               in portfolio (failed mutations are training data for next round)
7. Record    — state.rounds[N] updated; mutual inspiration step (each peer reads other's mutation
               and attacks for next round's proposal)
8. Adapt     — converge check: goal-met / adversary-exhausted N=3 / plateau N=3 / mutual KILL N=3
               → break; otherwise next round
```

When termination fires, the orchestrator runs a mandatory post-campaign escalation review (asks the adversary "what was deferred?") and writes a locked-template compound doc to `docs/solutions/[category]/[goal-slug]-[date].md`. Future runs on the same target read that doc first — **each run starts where the last one ended**.

## The 11 INVARIANTS

These rules live in `INVARIANTS.md` and are re-read at the start of every round. Skipping any of them is a protocol violation, not an optimization:

1. **Adversary output must be on disk** (not just conversation context)
2. **Commit-gate** — 7 checks: file exists, header nonce matches, mtime in valid window, verdict in body, drift check, pre-files exists, eval value matches state
3. **Per-round refresh** — `cat INVARIANTS.md && cat state.json` from disk
4. **Drift check** — `expected_head` + branch + dirty-tree before any commit/revert
5. **Pre-files snapshot** — `git ls-files` inventory before mutate
6. **Forbidden termination rationales** — 5 stopping-preferences refused as reasons; loop runs till mechanism converge (no rounds/budget cap)
7. **Verbatim Goal/Target/Constraints** in adversary prompts (no paraphrasing)
8. **Self-judge discipline** — schema-grounding required; `--adversary=off` + self-judge hard-refused
9. **Execution gate** — adversary-exhaustion alone is necessary but not sufficient
10. **Production-runtime safety** — cron/supervisor/watchdog file edits need extra discipline
11. **Adversary header block** — mandatory `ABELIAN-ADV-v1` format with nonce + timestamp

Full text in [INVARIANTS.md](INVARIANTS.md).

## Install

Two first-class drivers, both LLM-driven self-orchestration of the same `SKILL.md` spec. **No wrapper scripts** — codex CLI and Claude Code are themselves agent harnesses; they consume the spec directly.

### Claude Code primary

```
/plugin marketplace add cauchyturing/abelian
/plugin install abelian@abelian
```

Or `git clone https://github.com/cauchyturing/abelian.git ~/.claude/skills/abelian`. Restart Claude Code; the skill auto-registers. Invoke: `/abelian program.md`. Details: [`drivers/claude-code/README.md`](drivers/claude-code/README.md).

### Codex CLI primary

```bash
git clone https://github.com/cauchyturing/abelian.git ~/abelian
cd /your/project
codex exec -s workspace-write "$(cat ~/abelian/SKILL.md ~/abelian/INVARIANTS.md ~/abelian/prompts/dissect.md)

Run abelian on program.md per the spec above. Maintain state.json under abelian/runs/<RUN_ID>/. Run till mechanism-based converge per INVARIANTS rule #6."
```

Wrap in a shell function/alias if you'll run it often. Details: [`drivers/codex-cli/README.md`](drivers/codex-cli/README.md).

### Driver compatibility matrix

| | Claude Code primary | Codex CLI primary |
|---|---|---|
| Entry | `/abelian program.md` slash command | `codex exec ... "$(cat SKILL.md INVARIANTS.md prompts/dissect.md) ..."` |
| Orchestrator | Claude main session | Codex main session |
| Mutator | Claude (orchestrator session) | Codex (orchestrator session) |
| Adversary subagent | `Agent(general-purpose) + Skill('dissect')` | Fresh `codex exec` subprocess + inlined `prompts/dissect.md` |
| Cross-family adversary | `--adversary=codex` — orchestrator dispatches `codex exec` subprocess via Bash tool (codex CLI must be installed + auth'd; or codex MCP wrapper if user has one configured) | Sketch only (anthropic SDK + tool-use wrapper — see codex-cli driver README) |
| 11 INVARIANTS | All hold | All hold |
| state.json + nonce header + 7-check commit-gate | Identical | Identical |

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

Then invoke per your driver. **Default mode = co-research** (Strategy axes 1, 2, 3 distributed across two peers with different framing); switch to `--mode=unilateral` for single-axis verification. **Default adversary = self×self** (same family, different prompt context); add `--adversary=codex` (Claude Code) for cross-family priors on high-stakes runs.

Abelian runs **till converge** — no `--rounds` flag, no `--budget` flag. Mechanism-based termination per INVARIANTS rule #6. Manual abort: SIGINT (Ctrl+C).

## When NOT to use

- One-line bug fixes — overhead dominates
- Tasks without a deterministic eval — use a different tool, or write the eval first
- Long-horizon overnight autonomous coding without a defined target — abelian terminates on mechanism convergence, not wall-clock; if you need "8h then stop", use a tool with that semantics
- Continuous in-session iteration without verification gates — abelian's commit-gate is non-negotiable; if you don't want survive-or-revert discipline, use a different loop

Abelian's niche: **bounded campaigns with deterministic eval and strict survive-or-revert discipline, defaulting to co-research for non-trivial mutation discovery**.

## Status

v2.10.2 (2026-04-28). codex CLI subprocess is the canonical path; codex MCP is optional alternative if user has a wrapper.

 Claude Code path with **dissect adversary** smoketested 2026-04-28 (count_duplicate_pairs campaign — full v2.8 protocol exercised). **codex CLI subprocess path** is functional locally (codex CLI installed + auth'd via `~/.codex/auth.json`) but not yet dogfooded against an abelian campaign — first run of `--adversary=codex` will be the smoketest. **codex MCP wrapper path** (optional alternative) is not maintained by abelian; if you have a wrapper configured, the orchestrator may use it. **Codex CLI primary driver** invocation form un-tested by external user — see [TODO.md](TODO.md).

## Contributing

INVARIANTS changes require an empirical anchor — link a concrete failure mode the current rule misses. Speculative tightening is friction without evidence.

New driver paths under `drivers/<name>/` are welcome and should mirror the existing pattern: `README.md` only, with the LLM harness's invocation form. **No wrapper scripts** — both shipped drivers are LLM-driven self-orchestration; new drivers should follow the same shape.

Style: terse, judgment-first prose. Avoid hedging when a concrete claim works.

## Acknowledgments

- The `dissect` skill (vendored in `skills/dissect/`) — Abelian's adversary methodology.
- Andrej Karpathy — the "compound iteration loop" framing.

## License

MIT — see [LICENSE](LICENSE).
