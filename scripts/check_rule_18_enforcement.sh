#!/usr/bin/env bash
# Probe script for rule #18 enforcement campaign.
# Tests 5 gap-closure axes; outputs integer count of axes closed (0-5).
# POSIX-portable; bash 3.2+ compatible (no assoc arrays).

set -u  # do NOT set -e — we want all probes to run even if some fail

# Resolve repo root from script location.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

INVARIANTS="$REPO_ROOT/INVARIANTS.md"
DISSECT="$REPO_ROOT/prompts/dissect.md"
SKILL="$REPO_ROOT/SKILL.md"

PASS=0
FAIL_REASONS=""

# ---------------------------------------------------------------------------
# Axis 1: Generator — prompts/dissect.md verdict template strict enum.
# Pass criterion: verdict line in template uses an enum referencing the rule
# #18 verdict tokens (PROBE-PASS|PROBE-FAIL|CONCEDED|NON-CODIFIABLE-ESCALATED),
# AND the freeform placeholder "<YOUR ONE-LINE VERDICT>" is gone.
# ---------------------------------------------------------------------------
if [ -f "$DISSECT" ]; then
  if ! grep -qF "<YOUR ONE-LINE VERDICT>" "$DISSECT" \
     && grep -q "PROBE-PASS" "$DISSECT" \
     && grep -q "PROBE-FAIL" "$DISSECT" \
     && grep -q "CONCEDED" "$DISSECT" \
     && grep -q "NON-CODIFIABLE-ESCALATED" "$DISSECT"; then
    PASS=$((PASS+1))
  else
    FAIL_REASONS="$FAIL_REASONS
[axis1 generator] dissect.md verdict not strict enum (placeholder still present OR enum tokens missing)"
  fi
else
  FAIL_REASONS="$FAIL_REASONS
[axis1 generator] $DISSECT not found"
fi

# ---------------------------------------------------------------------------
# Axis 2: Schema — INVARIANTS.md candidate_routes (rule #14) AND
# alternative_routes (rule #11) both have a `grounding` field declared in
# their schema documentation.
# Pass criterion: BOTH schemas contain a `grounding` field line.
# ---------------------------------------------------------------------------
if [ -f "$INVARIANTS" ]; then
  # Both schemas in same file; we look for "grounding" appearing within the
  # rule #11 alternative_routes schema block AND within the rule #14
  # candidate_routes schema block. We use line counts as a coarse signal.
  GROUNDING_HITS=$(grep -c '^[[:space:]]*grounding:' "$INVARIANTS" || true)
  if [ "$GROUNDING_HITS" -ge 2 ]; then
    PASS=$((PASS+1))
  else
    FAIL_REASONS="$FAIL_REASONS
[axis2 schema] INVARIANTS.md needs grounding: field in both candidate_routes and alternative_routes schemas (found $GROUNDING_HITS, need ≥2)"
  fi
else
  FAIL_REASONS="$FAIL_REASONS
[axis2 schema] $INVARIANTS not found"
fi

# ---------------------------------------------------------------------------
# Axis 3: Gate — INVARIANTS.md rule #2 commit-gate enforces:
#   (a) verdict whitelist (check 4 extension)
#   (b) per-route grounding (check 8 extension)
# Pass criterion: rule #2 section explicitly mentions verdict whitelist
# (PROBE-PASS|FAIL|CONCEDED|NON-CODIFIABLE-ESCALATED) AND mentions grounding
# enforcement for candidate_routes.
# ---------------------------------------------------------------------------
if [ -f "$INVARIANTS" ]; then
  # Extract rule #2 block (from "## 2." to next "## ").
  RULE2_BLOCK=$(awk '/^## 2\./,/^## 3\./' "$INVARIANTS")
  WHITELIST_OK=0
  GROUNDING_OK=0

  # Whitelist: rule #2 must reference all 4 verdict tokens.
  if echo "$RULE2_BLOCK" | grep -q "PROBE-PASS" \
     && echo "$RULE2_BLOCK" | grep -q "PROBE-FAIL" \
     && echo "$RULE2_BLOCK" | grep -q "CONCEDED" \
     && echo "$RULE2_BLOCK" | grep -q "NON-CODIFIABLE-ESCALATED"; then
    WHITELIST_OK=1
  fi

  # Grounding: rule #2 must reference grounding enforcement for routes.
  if echo "$RULE2_BLOCK" | grep -qi "grounding"; then
    GROUNDING_OK=1
  fi

  if [ "$WHITELIST_OK" -eq 1 ] && [ "$GROUNDING_OK" -eq 1 ]; then
    PASS=$((PASS+1))
  else
    REASON="[axis3 gate] rule #2 commit-gate not enforcing"
    [ "$WHITELIST_OK" -eq 0 ] && REASON="$REASON (verdict whitelist absent)"
    [ "$GROUNDING_OK" -eq 0 ] && REASON="$REASON (grounding check absent)"
    FAIL_REASONS="$FAIL_REASONS
$REASON"
  fi
fi

# ---------------------------------------------------------------------------
# Axis 4: Predicate — INVARIANTS.md rule #17 converge predicate adds
# propose_grounding as 4th conjunct (Pass 1-3).
# Pass criterion: rule #17 mentions propose_grounding (or equivalent
# spelling like "propose-grounding" / "proposal_grounding") in the predicate
# section.
# ---------------------------------------------------------------------------
if [ -f "$INVARIANTS" ]; then
  RULE17_BLOCK=$(awk '/^## 17\./,/^## 18\./' "$INVARIANTS")
  if echo "$RULE17_BLOCK" | grep -qiE 'propose[_-]grounding|proposal[_-]grounding'; then
    PASS=$((PASS+1))
  else
    FAIL_REASONS="$FAIL_REASONS
[axis4 predicate] rule #17 converge predicate missing propose_grounding conjunct"
  fi
fi

# ---------------------------------------------------------------------------
# Axis 5: Skill — SKILL.md Living-spec step 8 has peer-family-aware dispatch
# OR explicit codex-required guard.
# Pass criterion: step 8 region (lines around "Living spec" anchor) does NOT
# unconditionally hardcode "dispatch codex" — must reference either peer
# family / configured peer / Agent fallback / claude+claude case OR have a
# guard clause for codex availability.
# ---------------------------------------------------------------------------
if [ -f "$SKILL" ]; then
  # Extract Living spec block (from "Living spec" line to next blank line + ~30 lines).
  LIVING_SPEC=$(awk '/Living spec/,/^[0-9]+\.\s+\*\*Adapt\*\*|^## /' "$SKILL")

  if [ -z "$LIVING_SPEC" ]; then
    FAIL_REASONS="$FAIL_REASONS
[axis5 skill] Living spec block not found in SKILL.md (WIP step 8 may be absent)"
  else
    # Pass if the block mentions: configured peer / peer family / Agent /
    # claude+claude / OR has a "codex unavailable" / "skip if" guard.
    if echo "$LIVING_SPEC" | grep -qiE 'configured peer|peer.family|Agent\(|claude\+claude|claude\+codex|codex unavailable|skip if|guard|fallback' \
       && ! echo "$LIVING_SPEC" | grep -qE '^\s*dispatch codex with:\s*$'; then
      # The negative check ensures the unconditional "dispatch codex with:" line is gone
      # (replaced with peer-aware language). The positive checks ensure the block
      # references the new mechanism.
      PASS=$((PASS+1))
    else
      FAIL_REASONS="$FAIL_REASONS
[axis5 skill] Living spec step 8 still hardcodes 'dispatch codex' without peer-family awareness or guard"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Output: integer count on stdout; reasons on stderr.
# ---------------------------------------------------------------------------
echo "$PASS"
if [ -n "$FAIL_REASONS" ] && [ "$PASS" -lt 5 ]; then
  echo "Gap-closure progress: $PASS/5" >&2
  echo "Open gaps:$FAIL_REASONS" >&2
fi
