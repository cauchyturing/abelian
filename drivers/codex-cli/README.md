# Abelian — Codex CLI driver

This is the path for **codex CLI–primary** teams. You stay in your codex
session; abelian dispatches both the mutator and the adversary as
separate `codex exec` subprocesses (self×self, same model family,
different prompts at full max-effort).

Mechanism parity with the Claude Code primary path is ~99%. The only
difference is dispatch vocabulary: Claude Code uses `Agent + Skill('dissect')`;
this driver uses `codex exec` + the `prompts/dissect.md` template. All 11
INVARIANTS, the 7-check commit-gate, drift detection, nonce header,
pre-files snapshot, and locked compound template apply identically.

## Quickstart

```bash
git clone https://github.com/cauchyturing/abelian.git ~/abelian
cd /your/project
~/abelian/drivers/codex-cli/abelian.sh program.md
```

`program.md` follows the same schema as the Claude Code path — see the top-level
[`README.md`](../../README.md) for the template. The script handles
state.json, INVARIANTS re-read per round, mutator dispatch, eval execution,
adversary dispatch (with nonce header injection), commit-gate, drift, and
scoped revert.

Pass `ABELIAN_ROUNDS=10` to override the default 5 rounds:

```bash
ABELIAN_ROUNDS=10 ~/abelian/drivers/codex-cli/abelian.sh program.md
```

## What this driver does (per round)

```
0. Refresh        — cat INVARIANTS.md && cat state.json (rule #3)
1+2. Mutator      — codex exec -s workspace-write < mutator-prompt
                    (program.md verbatim + state.json + INVARIANTS reminder)
3. Eval           — extract `## Eval` shell command from program.md, run it
4. Adversary      — generate nonce + ISO timestamp; inject into prompts/dissect.md
                    template; codex exec -s workspace-write < adversary-prompt
                    Subagent writes adversary.txt with mandatory ABELIAN-ADV-v1
                    header (nonce + run_id + round + peer + started_at + verdict)
5. Commit-gate    — 7 checks (file exists, nonce match, mtime window, verdict
                    in body, drift, pre-files, eval-state match). All pass →
                    git commit. Any fail → revert.
6. Loop or stop
```

The script is intentionally readable (~290 lines bash + python). Reading it
end-to-end is the fastest way to understand the protocol on the codex side.

## Requirements

- `codex` CLI on PATH (https://github.com/openai/codex)
- `jq` for state.json maintenance
- `python3` for nonce + ISO timestamp generation
- `git` (you must be inside a git repo)
- `.gitignore` covering language ecosystem build artifacts (Python `__pycache__`,
  Node `node_modules`, Rust `target/`, etc.) — the driver warns if these are
  missing because drift check will fail on first untracked artifact.
  See top-level [`SKILL.md` Pre-Flight section](../../SKILL.md).

## Self×self default — no cross-family setup

By default, `abelian.sh` uses **codex for both mutator and adversary**. This
matches Claude Code's `Agent + Skill('dissect')` self×self default. Same
model family, different prompt context per role at full max-effort.

Empirically, [Stephen 2026-04-26 audit-followup-boss-grasp campaign](https://github.com/cauchyturing/abelian/blob/main/SKILL.md#co-research-mode-v26)
showed same-family-different-context beats different-family-same-context
for substantive co-research. So self×self in codex is **not a degraded
mode** — it's the recommended default for codex teams the same way
Claude×Claude is recommended for Claude Code teams.

## Cross-family advanced (NOT shipped — sketch only)

If you want `codex (mutator) + Claude (adversary)` for cross-RLHF-family
priors on high-stakes runs, you build it yourself. Sketch:

1. Install `anthropic` SDK: `pip install anthropic`
2. Write a wrapper `cross-family-adversary.sh` that:
   - Reads the abelian-generated adversary prompt from stdin
   - Calls `anthropic.Messages.create` with the prompt
   - Has a tool-use loop letting Claude write to `adversary.txt`
     (or capture the response text and write the file with the
     `ABELIAN-ADV-v1` header constructed from passed env vars)
   - Verifies the resulting `adversary.txt` has correct nonce + verdict line
3. Override the adversary dispatch in your fork of `abelian.sh`:
   replace `codex exec -s workspace-write < "$ADV_PROMPT"` with
   `bash cross-family-adversary.sh < "$ADV_PROMPT"`

**Honest caveat**: the cross-family wrapper has to faithfully implement the
nonce header protocol (rule #11) and not "shortcut" by having the wrapper
script (= mutator-side code) write `adversary.txt`. Otherwise the nonce
defense degrades — see INVARIANTS.md `## 11` honest scope note. Use a
proper Anthropic tool-use loop where Claude itself emits the file_write
call, not a string-template wrapper.

For most teams this is over-engineering. self×self codex×codex is what
night-shift's Codex review pattern uses too, and it's plenty for >95% of
campaigns.

## Differences vs Claude Code primary

| Aspect | Claude Code primary (your team if Claude-native) | Codex CLI primary (this driver) |
|---|---|---|
| Mutator | Your interactive Claude session, driven by `/abelian program.md` skill invocation | `codex exec -s workspace-write` subprocess per round |
| Adversary | `Agent(general-purpose) + Skill('dissect')` | `codex exec` subprocess + `prompts/dissect.md` template |
| Adversary methodology | Claude reads `dissect` skill from disk | Codex reads `prompts/dissect.md` injected into prompt |
| Cross-family | `--adversary=codex` flag (built-in via Claude Code's MCP) | Build your own (sketch above) |
| Co-research mode | `--mode=co-research --pair=opus,opus + different context` | Two `codex exec` subprocesses with different framing prompts (extend abelian.sh) |
| INVARIANTS rules 1-11 | All hold | All hold |
| state.json schema | Identical | Identical |
| commit-gate 7 checks | Identical | Identical |
| nonce header protocol | Identical | Identical |

The only "lossy" translation point is the dissect-equivalent prompt: Claude
reads it as a Skill file with metadata, codex reads it as inlined prompt
text. Same methodology, same coverage, same outputs.

## Troubleshooting

- **Drift check fails on round 1** — your `.gitignore` is missing build
  artifact patterns. See top-level SKILL.md Pre-Flight.
- **codex exec hangs** — codex CLI may need `--no-interactive` flag or a
  shorter timeout. Check `codex exec --help` for your version.
- **Adversary writes `adversary.txt` to wrong path** — codex executed in
  a different cwd than expected. The `{{OUTPUT_PATH}}` placeholder in the
  prompt should be an absolute path. The driver passes one; verify it's
  absolute via `pwd`-prefixed.
- **Nonce mismatch on commit-gate** — adversary subagent wrote a different
  nonce than the driver generated. Either it ignored the header instructions
  (re-prompt with `system` message: "you MUST copy the nonce verbatim") or
  the driver generated a new nonce mid-flow. Check `state.rounds[-1].adversary_nonce`
  vs the actual file header.

## Why no `gh repo` plugin install

This driver isn't a Claude Code plugin — it's a bash script. There's no
plugin marketplace path for codex CLI. Just `git clone` the abelian repo
and `chmod +x` the script. That's the entire installation.
