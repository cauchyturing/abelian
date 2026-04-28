# Abelian

> Mutate. Attack. Keep what survives.
>
> A symmetric iteration loop for code: verification (one-way) or discovery (peer-attack).
>
> File-gated, drift-checked, anti-compaction.

[![Version](https://img.shields.io/badge/version-2.8.3-blue.svg)](https://github.com/cauchyturing/abelian/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Drivers](https://img.shields.io/badge/drivers-Claude%20Code%20%7C%20Codex%20CLI-orange.svg)](#install)

Abelian is a [Claude Code](https://claude.com/claude-code) skill that turns any LLM session into a disciplined iteration loop. You hand it a `program.md` defining what to optimize, a deterministic `Eval`, and a `Strategy`. It mutates, evaluates, attacks, and keeps only what survives — round after round — with structural gates that compaction, fabrication, or drift cannot silently slip past.

```
═══════════════════════════════════════════════════════════════
  Round 4 / 10 — cell: memoization
═══════════════════════════════════════════════════════════════
  Mutate     → diff +18 / -3
  Eval       → 2.34 → 0.41 (5.7× speedup)
  Adversary  → 1 attack: edge-case empty list panics
  Verify     → regression test added, re-eval 0.43
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

- **Two distinct modes**, picked by phase. *Unilateral* (mutator + adversary) for verification of a known target. *Co-research* (two peers each propose AND challenge) for discovery and novel design — symmetric peer-attack is the abelian-group property the name borrows from.
- **File-gated everything.** Adversary output must land on disk with a verified header block (run_id + nonce + timestamp). The commit gate checks 7 conditions; any miss = revert. A compacted agent that "forgot" it skipped the adversary cannot silently fabricate the file — the nonce isn't in its memory.
- **Drift detection before every write.** `expected_head` + branch + dirty-tree match. Mismatch = `drift-stopped`, no further writes, terminal-only summary. Adopted from [night-shift](https://github.com/ppuliu/night-shift)'s long-horizon discipline.
- **Per-round re-read of `INVARIANTS.md`.** The 11 non-negotiable rules live in their own file. Step 0 of every round re-reads them from disk. Conversation memory drifts; the file is truth.
- **Forbidden termination rationales.** "Diminishing returns", "time remaining", "deferred to next session", "foundation in place", "cleaner to ship" — all explicitly refused as stopping reasons. Termination is justified only by mechanism (eval ≥ target / adversary exhausted / mutual KILL deadlock / cap fired).

## Two modes

| | Unilateral (default) | Co-research (`--mode=co-research`) |
|---|---|---|
| Best for | Verification of known target, ship-prep, audit, regression hardening | Discovery, novel design, "where do I start", research without an obvious target |
| Roles | Generator proposes + implements; adversary attacks | Two peers each propose AND attack the other's proposal |
| Cost / round | 1× | 2× |
| Termination | Goal met, adversary exhausted across attack-class checklist, or `--rounds` cap | Goal met, plateau + diversity collapse, mutual KILL deadlock, or cap |
| Cross-model adversary | `--adversary=codex` opt-in for high stakes | `--pair=claude-opus,codex-latest` for cross-family priors |

Pure Claude (no Codex) works in both modes — that's the default. Codex is opt-in for high-stakes ship-prep where model-family blind-spot risk matters.

## How it works

For each round:

```
0. Refresh   — cat INVARIANTS.md && cat state.json (rule #3, anti-compaction)
1. Hypothesize — Strategy + state.rounds[] → ONE testable change, tagged with cell label
2. Mutate    — pre-files snapshot (rule #5), then apply the change
3. Evaluate  — shell command returns a number (or test-suite pass/fail)
4. Adversary — subagent writes attack list to round-N/adversary.txt with mandatory
               ABELIAN-ADV-v1 header (rule #11) — nonce verified at commit
5. Confirm   — 7-check commit-gate (rule #2). All pass → git commit. Any fail → revert.
6. Place     — replace champion (or per-cell incumbent in portfolio mode)
7. Record    — state.rounds[N] updated; History line appended
8. Adapt     — 5 reverts → shift strategy; diversity collapse → escalate
```

When termination fires, the loop runs a mandatory post-campaign escalation review (asks the adversary "what was deferred?") and writes a locked-template compound doc to `docs/solutions/[category]/[goal-slug]-[date].md`. Future runs on the same target read that doc first — **each run starts where the last one ended**.

## The 11 INVARIANTS

These rules live in `INVARIANTS.md` and are re-read at the start of every round. Skipping any of them is a protocol violation, not an optimization:

1. **Adversary output must be on disk** (not just conversation context)
2. **Commit-gate** — 7 checks: file exists, header nonce matches, mtime in valid window, verdict in body, drift check, pre-files exists, eval value matches state
3. **Per-round refresh** — `cat INVARIANTS.md && cat state.json` from disk
4. **Drift check** — `expected_head` + branch + dirty-tree before any commit/revert
5. **Pre-files snapshot** — `git ls-files` inventory before mutate
6. **Forbidden termination rationales** — 5 stopping-preferences refused as reasons
7. **Verbatim Goal/Target/Constraints** in adversary prompts (no paraphrasing)
8. **Self-judge discipline** — schema-grounding required; `--adversary=off` + self-judge hard-refused
9. **Execution gate** — adversary-exhaustion alone is necessary but not sufficient
10. **Production-runtime safety** — cron/supervisor/watchdog file edits need extra discipline
11. **Adversary header block** — mandatory `ABELIAN-ADV-v1` format with nonce + timestamp

Full text in [INVARIANTS.md](INVARIANTS.md).

## Install

Abelian ships **two first-class drivers**. Pick the one matching your team's primary tool. Mechanism parity is ~99%; the only difference is dispatch vocabulary.

### Claude Code primary (full Claude Code skill)

```
/plugin marketplace add cauchyturing/abelian
/plugin install abelian@abelian
```

Or clone directly:

```bash
git clone https://github.com/cauchyturing/abelian.git ~/.claude/skills/abelian
```

Restart Claude Code; the skill auto-registers. Invoke with `/abelian program.md`.
Details: [`drivers/claude-code/README.md`](drivers/claude-code/README.md).

### Codex CLI primary (bash driver)

```bash
git clone https://github.com/cauchyturing/abelian.git ~/abelian
cd /your/project
~/abelian/drivers/codex-cli/abelian.sh program.md
```

Self×self default (codex × codex). No anthropic SDK install, no cross-family wrapper required. Details: [`drivers/codex-cli/README.md`](drivers/codex-cli/README.md).

### Driver compatibility matrix

| Capability | Claude Code primary | Codex CLI primary |
|---|---|---|
| Mutator | Claude session via `/abelian` skill | `codex exec -s workspace-write` per round |
| Adversary (default) | `Agent + Skill('dissect')` (self×self Claude) | `codex exec` + `prompts/dissect.md` (self×self codex) |
| Cross-family adversary | `--adversary=codex` (built-in via Codex MCP) | Build your own (sketch in driver README) |
| Co-research mode | `--mode=co-research` (built-in) | Two `codex exec` with different framing (extend script) |
| 11 INVARIANTS | All hold | All hold |
| state.json + nonce header + 7-check commit-gate | Identical | Identical |
| Cost | 1 Claude session + dissect subagent calls | 2 codex exec calls per round |

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

Then invoke:

```
/abelian program.md --rounds=10
```

For high-stakes runs add `--adversary=codex` (cross-model adversary) or `--mode=co-research` (peer-attack discovery).

## When NOT to use Abelian

- One-line bug fixes — overhead dominates
- Tasks without a deterministic eval (use a different tool, or write the eval first)
- Long-horizon overnight autonomous coding — use [night-shift](https://github.com/ppuliu/night-shift) instead, which is purpose-built for that
- Continuous in-session iteration without verification gates — use [ralph-loop](https://github.com/.../ralph-loop) instead

Abelian's niche: **bounded campaigns with deterministic eval and strict survive-or-revert discipline**. If your task doesn't fit that shape, a different tool will serve you better.

## Comparison

| | Abelian | night-shift | ralph-loop |
|---|---|---|---|
| Time horizon | Bounded by `--rounds` | 8 h hard cap | Continuous in-session |
| Eval discipline | Required (4-level hierarchy) | Tests pass per task | Optional |
| Adversary | dissect / codex / both / co-research peer | Codex required | Optional |
| Diversity | Portfolio cells (MAP-Elites style) | Linear KR sequence | None |
| File-gated commits | ✓ (v2.8) | ✓ | ✗ |
| Drift detection | ✓ | ✓ | ✗ |
| Anti-compaction | INVARIANTS.md re-read + state.json | INVARIANTS.md re-read + state.json | ✗ |
| Co-research mode | ✓ (v2.6) | ✗ | ✗ |

Use Abelian for *what to keep*. Use night-shift for *what to ship overnight*. Use ralph-loop for *what to keep working on*. They compose; they don't replace each other.

## Project status

Abelian is **v2.8.3 (2026-04-28)**. Functional but young.

| Area | Status |
|---|---|
| Claude Code primary path (SKILL.md) | **Smoketested 2026-04-28** end-to-end on a Python speedup task — full v2.8 protocol exercised (state.json, INVARIANTS reread, nonce header, 7-check commit-gate, drift detection, goal-met termination, locked compound template). [Smoketest writeup](https://github.com/cauchyturing/abelian/tree/main) lives in commit history under run `2026-04-28-0414-r2`. |
| Codex CLI driver (`drivers/codex-cli/abelian.sh`) | **Reference implementation, not yet smoketested.** Implements the full v2.8 protocol via `codex exec` subprocesses but has not been exercised against a real codex CLI run. First user is likely to hit minor issues (sandbox flag names, prompt size, eval extraction edge cases) — please [file an issue](https://github.com/cauchyturing/abelian/issues) or PR. |
| INVARIANTS.md | **Frozen.** 11 rules, all derived from concrete failure modes (Cell 6 silent un-landing, scanner.py WIP cron breakage, atomic-swap silent-fail, dissect R3 attack-class miss). Won't change without a corresponding empirical finding. |
| state.json schema | **Frozen for v2.8.x.** Backwards-compatible fields may be added in v2.9; breaking changes only at v3.0. |
| Plugin marketplace install | Configured in `.claude-plugin/plugin.json`; first-time end-to-end install via `/plugin marketplace add` not yet verified by an external user. |

## Known issues

- **Codex CLI driver smoketest pending** (see Project status above). The bash + python plumbing is correct in design but un-exercised against real codex CLI invocations. See [`TODO.md`](TODO.md) for specific points.
- **`abelian.sh` eval extraction is awk-based** and may break on `program.md` files with multiple `## Eval` blocks or unusual section markers. Single-bash-block eval works.
- **Co-research mode in `abelian.sh`** is documented as "extend the script" but not implemented inline. The Claude Code SKILL.md path supports it natively.
- **Cross-family adversary in `abelian.sh`** is documented as "build your own" with a sketch — no shipped wrapper. Most teams won't need this; codex × codex self×self is the recommended default.
- **`SKILL.md` is 610 lines** — verbose by skill-design standards. Some of it could plausibly move to `references/`. Tracked in TODO but no immediate priority.

## Roadmap

| Version | Theme | When |
|---|---|---|
| v2.8.x | Codex CLI driver hardening (post-smoketest fixes) | As issues land |
| v2.9 | Compound doc auto-generation in `abelian.sh` (currently TODO) + co-research mode in bash driver | Q3 2026 if demand |
| v3.0 | Possibly: unify SKILL.md + drivers/ into a single driver-neutral spec; flip default to co-research per the v2.6 internal note; `INVARIANTS-CORE.md` extracted | Only after empirical track record validates the cost model |

## Contributing

Issues and PRs welcome. A few notes:

- **INVARIANTS changes** require an empirical anchor. If you propose tightening rule #X, link a concrete failure mode or campaign that the current rule misses. Speculative tightening = friction with no evidence.
- **Driver additions** (e.g., a Cursor or Aider driver) are welcome under `drivers/<name>/`. Mirror the codex-cli driver's structure: `README.md` + executable script + adherence to the same v2.8 protocol.
- **Bug fixes** to `abelian.sh` python heredocs or codex sandbox flags get fast-tracked — that script is a reference impl explicitly waiting for first-user feedback.
- **Nominal style**: terse, judgment-first prose. Avoid hedging language ("might", "could", "potentially") when a concrete claim works. Mirror the existing INVARIANTS.md / SKILL.md voice.

For larger discussions (architectural changes, mode unification, name changes), open a GitHub Discussion or DM [@cauchyturing](https://github.com/cauchyturing).

## Acknowledgments

- [@ppuliu](https://github.com/ppuliu) and [night-shift](https://github.com/ppuliu/night-shift) — the file-gate, drift-check, INVARIANTS-reread, and forbidden-termination-rationale patterns are direct borrows; the orthogonal-defenses framing came from comparing the two skills side-by-side.
- The `dissect` skill — Abelian's default adversary is a `dissect` subagent.
- Andrej Karpathy — the "compound iteration loop" framing.

## License

MIT — see [LICENSE](LICENSE).
