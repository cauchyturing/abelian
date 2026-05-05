# Rule #18 enforcement: 3-layer alignment

## Goal
Enforce rule #18 at all 3 layers (generator + schema + gate), reaching pass-rate 5/5 on gap-closure probe script.

## Task class
mixed: doc; code

## Target
INVARIANTS.md
prompts/dissect.md
SKILL.md
scripts/check_rule_18_enforcement.sh create:

## Eval
bash scripts/check_rule_18_enforcement.sh

## Eval ground
(b) commit-gate inputs: rule #2 check 4 + 8 enforcement language
(c) prompt template: prompts/dissect.md verdict format
(d) verbatim audit findings: 5 gaps from 2026-05-04 codex+claude convergence report

## Metric
gap-closure: 0 max

## Constraints
- Don't change rule #1, #6, #11, #14, #15, #16, #17 SEMANTICS — only extend rule #2 with new checks; only refine rule #17 converge predicate (add conjunct, don't remove existing).
- Don't break ABELIAN-ADV-v1 legacy header acceptance (rule #11 deprecation window, INVARIANTS.md:342).
- Don't auto-rewrite program.md from Living-spec step 8 — proposal file only, human review required.
- Eval script is portable POSIX (no bash 4+ assoc arrays); runs on macOS bash 3.2 + Linux bash 5.x.

## Strategy
1. **Generator** (`prompts/dissect.md`): verdict template strict enum (`PROBE-PASS|PROBE-FAIL|CONCEDED|NON-CODIFIABLE-ESCALATED`) + separate `summary:` field for prose; replace L56 `<YOUR ONE-LINE VERDICT>` placeholder + replace L71-74 freeform examples.
2. **Schema** (`INVARIANTS.md` rule #11 + #14): add `grounding` field to both `candidate_routes` (rule #14 schema) AND `alternative_routes` (rule #11 schema) — `grounding: <file:line | command | quoted_text + source>`.
3. **Gate** (`INVARIANTS.md` rule #2): check 4 extends with verdict whitelist regex; check 8 extends with per-route grounding presence check (mission_thread.candidate_routes[i].grounding non-empty).
4. **Predicate** (`INVARIANTS.md` rule #17): converge predicate Pass 1-3 adds `propose_grounding` as 4th conjunct (all candidate_routes have grounding citation).
5. **Skill** (`SKILL.md` Living-spec step 8): replace hardcoded `dispatch codex` with peer-family-aware dispatch — same dispatch pattern as Loop step 4 (Agent for claude, codex exec for codex); OR add explicit "skipped if codex unavailable" guard with stderr notice.

## Cells
- generator-fix
- schema-fix
- gate-fix
- predicate-fix
- skill-fix

## Attack Classes
- default
- doc-class
- audit-class

## Takeaway
- **Success looks like**: gap-closure metric reaches 5/5 on `bash scripts/check_rule_18_enforcement.sh`; pre-existing INVARIANTS rule semantics (#1, #6, #11, #14, #15, #16, #17) preserved verbatim outside the explicit check-extension lines; ABELIAN-ADV-v1 legacy header still accepted per rule #11 deprecation window.
- **Validated by**: `bash scripts/check_rule_18_enforcement.sh` outputs exact integer `5` on stdout (countable); `grep -c "ABELIAN-ADV-v1" INVARIANTS.md` ≥ 1 (legacy still mentioned, runnable); no semantic-rewrite of rule #1/#6/#11/#14/#15/#16/#17 outside extension points (grep-able via `git diff --stat` shows changes confined to Target paths).
- **Constraints**: Rule #1/#6/#11/#14/#15/#16/#17 semantics unchanged outside extension points; ABELIAN-ADV-v1 legacy accept; no auto program.md rewrite from step 8; POSIX shell.
