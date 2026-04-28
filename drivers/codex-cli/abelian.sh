#!/usr/bin/env bash
# abelian.sh — Codex CLI driver for the Abelian iteration loop.
#
# Self×self mode default: codex (mutator) + codex (adversary). Same model
# family, different prompts at full max-effort. This matches Claude Code's
# native `Agent + Skill('dissect')` self×self default in spirit and protocol.
# Cross-family adversary (Claude) is NOT shipped here — see the
# README.md "Cross-family advanced" section for the SDK + wrapper sketch.
#
# Implements the v2.8 protocol: state.json source-of-truth, INVARIANTS.md
# re-read per round, file-gated commit (7 checks), drift detection,
# nonce-based adversary header, pre-files snapshot, scoped revert.

set -euo pipefail

# ---------- Sanity check: not in Claude Code ----------
if [ -n "${CLAUDECODE:-}" ] || [ -n "${CLAUDE_CODE:-}" ]; then
  if [ -z "${ABELIAN_FORCE_CODEX_DRIVER:-}" ]; then
    echo "ERROR: detected Claude Code environment. Use the /abelian SKILL.md path instead." >&2
    echo "       (Or set ABELIAN_FORCE_CODEX_DRIVER=1 to override.)" >&2
    exit 1
  fi
fi

# ---------- Args + paths ----------
PROGRAM=${1:-program.md}
ROUNDS=${ABELIAN_ROUNDS:-5}
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ABELIAN_REPO=$(cd "${SCRIPT_DIR}/../.." && pwd)
PROMPT_TEMPLATE="${ABELIAN_REPO}/prompts/dissect.md"
INVARIANTS="${ABELIAN_REPO}/INVARIANTS.md"

[ -f "$PROGRAM" ] || { echo "ERROR: $PROGRAM not found" >&2; exit 1; }
[ -f "$PROMPT_TEMPLATE" ] || { echo "ERROR: $PROMPT_TEMPLATE not found (abelian repo layout broken?)" >&2; exit 1; }
[ -f "$INVARIANTS" ] || { echo "ERROR: $INVARIANTS not found (abelian repo layout broken?)" >&2; exit 1; }

# ---------- Pre-flight (INVARIANTS rule #4 prep) ----------
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "ERROR: not in a git repo" >&2; exit 1; }

if [ -f .gitignore ]; then
  for pat in "__pycache__" "node_modules" "target/"; do
    grep -qF "$pat" .gitignore 2>/dev/null || echo "WARN: .gitignore missing '$pat' — drift check may fail" >&2
  done
else
  echo "WARN: no .gitignore — drift check will fail on first untracked artifact" >&2
fi

command -v jq >/dev/null   || { echo "ERROR: jq required" >&2; exit 1; }
command -v codex >/dev/null || { echo "ERROR: codex CLI required (https://github.com/openai/codex)" >&2; exit 1; }

# ---------- Init run ----------
RUN_ID=$(date +%Y-%m-%d-%H%M)
RUN_DIR="abelian/runs/${RUN_ID}"
mkdir -p "$RUN_DIR"
BASE_COMMIT=$(git rev-parse HEAD)
BRANCH=$(git branch --show-current)

cat > "$RUN_DIR/state.json" <<EOF
{
  "run_id": "$RUN_ID",
  "status": "running",
  "mode": "git",
  "started_at": "$(python3 -c "import datetime; print(datetime.datetime.now().astimezone().isoformat(timespec='seconds'))")",
  "branch": "$BRANCH",
  "expected_head": "$BASE_COMMIT",
  "program_path": "$PROGRAM",
  "shape": {"rounds": $ROUNDS, "chains": 1, "depth": 1, "candidates": 1, "portfolio": 1},
  "adversary_mode": "codex_self",
  "rounds": [],
  "champion": null,
  "portfolio_cells": {},
  "escalations_file": "$RUN_DIR/escalations.md"
}
EOF
touch "$RUN_DIR/escalations.md"
echo "═══════════════════════════════════════════════════════════════"
echo "  ABELIAN run started: RUN_ID=$RUN_ID  ($ROUNDS rounds)"
echo "  Branch: $BRANCH @ $BASE_COMMIT"
echo "  Mode:   codex × codex (self×self, same family)"
echo "═══════════════════════════════════════════════════════════════"

# ---------- Helpers ----------
state_get() { jq -r "$1" "$RUN_DIR/state.json"; }

state_update() {
  jq "$1" "$RUN_DIR/state.json" > "$RUN_DIR/state.json.tmp" \
    && mv "$RUN_DIR/state.json.tmp" "$RUN_DIR/state.json"
}

drift_check() {
  local current_head=$(git rev-parse HEAD)
  local current_branch=$(git branch --show-current)
  local expected_head=$(state_get .expected_head)
  local expected_branch=$(state_get .branch)
  [ "$current_head" = "$expected_head" ]   || { echo "DRIFT: HEAD $current_head != $expected_head" >&2; return 1; }
  [ "$current_branch" = "$expected_branch" ] || { echo "DRIFT: branch $current_branch != $expected_branch" >&2; return 1; }
  local untracked=$(git ls-files --others --exclude-standard | grep -v '^abelian/' || true)
  [ -z "$untracked" ] || { echo "DRIFT: untracked outside abelian/: $untracked" >&2; return 1; }
  return 0
}

# ---------- The Loop ----------
ROUND=0
while [ $ROUND -lt $ROUNDS ]; do
  ROUND=$((ROUND + 1))
  ROUND_DIR="$RUN_DIR/round-$ROUND"
  mkdir -p "$ROUND_DIR"
  echo
  echo "─── Round $ROUND / $ROUNDS ───"

  # Step 0: Refresh (INVARIANTS rule #3)
  cat "$INVARIANTS" >/dev/null  # re-read from disk; production would inject into mutator context
  cat "$RUN_DIR/state.json" >/dev/null

  # Step 2 (pre-mutate): pre-files snapshot (INVARIANTS rule #5)
  { git ls-files -z; git ls-files -z --others --exclude-standard; } | sort -zu > "$ROUND_DIR/pre-files.txt"

  # Step 1 + 2: Hypothesize + Mutate (codex mutator)
  # Build mutator prompt: program.md verbatim + state.json + INVARIANTS reminder
  MUTATOR_PROMPT="$ROUND_DIR/mutator-prompt.txt"
  python3 - "$PROGRAM" "$RUN_DIR/state.json" "$INVARIANTS" > "$MUTATOR_PROMPT" <<'PYEOF'
import sys, json
program = open(sys.argv[1]).read()
state   = json.load(open(sys.argv[2]))
inv     = open(sys.argv[3]).read()
print(f"""You are the Abelian mutator for round {len(state['rounds'])+1}.

Read the INVARIANTS below; then read the program.md and state.json; then
propose ONE concrete mutation (one idea per round) per the Strategy axes.
Apply the mutation by editing only files declared in program.md `## Target`.
Do NOT edit anything outside Target. Do NOT touch abelian/ artifacts.

After applying the mutation, exit cleanly. The driver will run eval and
adversary review on what you commit to the working tree.

═══ INVARIANTS.md (re-read every round, rule #3) ═══
{inv}

═══ program.md ═══
{program}

═══ state.json (current run state) ═══
{json.dumps(state, indent=2)}
""")
PYEOF

  echo "  [1+2] dispatch codex mutator..."
  codex exec - -s workspace-write -c 'model_reasoning_effort="high"' < "$MUTATOR_PROMPT" \
    > "$ROUND_DIR/mutator-output.log" 2>&1 || true

  # Step 3: Eval
  EVAL_CMD=$(awk '/^## Eval/{flag=1; next} /^## /{flag=0} flag' "$PROGRAM" \
             | awk '/^```bash/{flag=1; next} /^```$/{flag=0} flag' | head -1)
  [ -z "$EVAL_CMD" ] && { echo "ERROR: no Eval bash command in $PROGRAM" >&2; exit 1; }
  echo "  [3]   eval: $EVAL_CMD"
  EVAL_VALUE=$(eval "$EVAL_CMD" 2>&1 | tee "$ROUND_DIR/eval.txt" | tail -1)
  echo "        → $EVAL_VALUE"

  # Step 4: Adversary — gen nonce + dispatch codex adversary
  NONCE=$(python3 -c "import secrets; print(secrets.token_hex(8))")
  STARTED_AT=$(python3 -c "import datetime; print(datetime.datetime.now().astimezone().isoformat(timespec='milliseconds'))")

  state_update "
    .rounds += [{
      \"n\": $ROUND,
      \"cell\": \"auto\",
      \"status\": \"adversary-pending\",
      \"metric_value\": ($EVAL_VALUE | tonumber? // \"$EVAL_VALUE\"),
      \"adversary_file\": \"round-$ROUND/adversary.txt\",
      \"adversary_nonce\": \"$NONCE\",
      \"adversary_started_at\": \"$STARTED_AT\",
      \"pre_files_file\": \"round-$ROUND/pre-files.txt\",
      \"eval_file\": \"round-$ROUND/eval.txt\",
      \"verdict_line\": null,
      \"started_at\": \"$STARTED_AT\"
    }]"

  ADV_PROMPT="$ROUND_DIR/adversary-prompt.txt"
  ADV_OUTPUT="$(pwd)/$ROUND_DIR/adversary.txt"
  CWD=$(pwd)

  ABELIAN_PROGRAM_PATH="$PROGRAM" \
  python3 - "$PROMPT_TEMPLATE" "$RUN_ID" "$ROUND" "$NONCE" "$STARTED_AT" "$ADV_OUTPUT" "$CWD" "$EVAL_VALUE" > "$ADV_PROMPT" <<'PYEOF'
import os, sys, subprocess
template = open(sys.argv[1]).read()
program  = open(os.environ["ABELIAN_PROGRAM_PATH"]).read()
diff     = subprocess.run(["git","diff"], capture_output=True, text=True).stdout or "(no diff)"
print(template
  .replace("{{RUN_ID}}",     sys.argv[2])
  .replace("{{ROUND}}",      sys.argv[3])
  .replace("{{PEER}}",       "unilateral")
  .replace("{{NONCE}}",      sys.argv[4])
  .replace("{{STARTED_AT}}", sys.argv[5])
  .replace("{{OUTPUT_PATH}}",sys.argv[6])
  .replace("{{CWD}}",        sys.argv[7])
  .replace("{{EVAL_OUTPUT}}",sys.argv[8])
  .replace("{{PROGRAM_MD}}", program)
  .replace("{{DIFF}}",       diff))
PYEOF

  echo "  [4]   dispatch codex adversary (nonce $NONCE)..."
  codex exec - -s workspace-write -c 'model_reasoning_effort="high"' < "$ADV_PROMPT" \
    > "$ROUND_DIR/adversary-call.log" 2>&1 || true

  # Extract verdict line from adversary.txt header
  if [ -f "$ROUND_DIR/adversary.txt" ]; then
    VERDICT=$(grep '^verdict:' "$ROUND_DIR/adversary.txt" | head -1 | sed 's/^verdict: *//')
  else
    VERDICT="[adversary did not write file]"
  fi
  state_update ".rounds[-1].verdict_line = \"$VERDICT\" | .rounds[-1].status = \"adversary-done\""

  # Step 5: Confirm — 7-check commit-gate (INVARIANTS rule #2)
  echo "  [5]   commit-gate (7 checks)..."
  python3 - "$RUN_DIR" "$ROUND" <<'PYEOF'
import sys, json, subprocess, datetime, pathlib
RD, N = sys.argv[1], int(sys.argv[2])
state = json.load(open(f'{RD}/state.json'))
r = state['rounds'][N-1]
adv = pathlib.Path(f"{RD}/round-{N}/adversary.txt")
prefiles = pathlib.Path(f"{RD}/round-{N}/pre-files.txt")
eval_file = pathlib.Path(f"{RD}/round-{N}/eval.txt")

def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True).stdout

checks = []
checks.append(("adversary.txt non-empty", adv.exists() and adv.stat().st_size > 0, ""))

if adv.exists():
    header = adv.read_text().splitlines()[:8]
    hdr = {l.split(':',1)[0].strip(): l.split(':',1)[1].strip() for l in header[1:7] if ':' in l}
    checks.append(("header.nonce match", hdr.get('nonce') == r['adversary_nonce'], f"got={hdr.get('nonce')}"))
    mtime = datetime.datetime.fromtimestamp(adv.stat().st_mtime).astimezone()
    started = datetime.datetime.fromisoformat(r['adversary_started_at'])
    now = datetime.datetime.now().astimezone()
    checks.append(("mtime in window", started < mtime < now, ""))
    vl = r.get('verdict_line') or ""
    checks.append(("verdict in body", vl in adv.read_text(), ""))
else:
    checks += [("header.nonce match", False, "adv missing"),
               ("mtime in window", False, "adv missing"),
               ("verdict in body", False, "adv missing")]

hd = run(['git','rev-parse','HEAD']).strip()
br = run(['git','branch','--show-current']).strip()
checks.append(("drift", hd == state['expected_head'] and br == state['branch'], ""))
checks.append(("pre-files exists", prefiles.exists() and prefiles.stat().st_size > 0, ""))

ok = True
try:
    ev = float(eval_file.read_text().strip().splitlines()[-1])
    ev_match = abs(ev - r['metric_value']) < 1e-9 if isinstance(r['metric_value'], (int,float)) else True
except Exception:
    ev_match = True  # non-numeric eval; trust state
checks.append(("eval matches state", ev_match, ""))

all_pass = all(c[1] for c in checks)
for name, passed, ev in checks:
    print(f"        [{'✓' if passed else '✗'}] {name}{' ('+ev+')' if ev else ''}")
sys.exit(0 if all_pass else 1)
PYEOF
  GATE=$?

  if [ $GATE -eq 0 ]; then
    git add -A
    git commit -q -m "round-${ROUND}: ${VERDICT}" || true
    NEW_HEAD=$(git rev-parse HEAD)
    state_update ".rounds[-1].status = \"kept\" | .rounds[-1].commit = \"$NEW_HEAD\" | .expected_head = \"$NEW_HEAD\""
    echo "  [✓]   committed: $NEW_HEAD"
  else
    echo "  [✗]   GATE FAIL — revert round $ROUND"
    git checkout -- . 2>/dev/null || true
    state_update ".rounds[-1].status = \"gate-failed\""
  fi
done

# ---------- Termination ----------
state_update ".status = \"cap-fired\" | .ended_at = \"$(python3 -c 'import datetime; print(datetime.datetime.now().astimezone().isoformat(timespec=\"seconds\"))')\""
echo
echo "═══════════════════════════════════════════════════════════════"
echo "  ABELIAN run done: $RUN_DIR"
echo "  Compound doc: docs/solutions/[category]/${RUN_ID}.md (write manually or extend script)"
echo "═══════════════════════════════════════════════════════════════"
