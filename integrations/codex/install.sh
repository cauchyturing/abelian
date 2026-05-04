#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
codex_home="${CODEX_HOME:-$HOME/.codex}"
generated_dir="$codex_home/skills/.generated/abelian"
skill_link="$codex_home/skills/abelian"

required=(
  "$repo_root/SKILL.md"
  "$repo_root/INVARIANTS.md"
  "$repo_root/prompts/dissect.md"
  "$repo_root/integrations/codex/skills/abelian/agents/openai.yaml"
)

for path in "${required[@]}"; do
  if [[ ! -f "$path" ]]; then
    echo "missing required file: $path" >&2
    exit 1
  fi
done

rm -rf "$generated_dir"
mkdir -p "$generated_dir/agents" "$generated_dir/prompts" "$(dirname "$skill_link")"

{
  cat <<'YAML'
---
name: abelian
description: Use when running Abelian, autoloop, auto-optimize, run experiments, optimize this, Karpathy loop, or adversarial mutation campaigns where Codex should mutate, evaluate, peer-review, and keep only surviving changes using a program.md contract.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, Skill
---
YAML
  awk '
    BEGIN { fence_count = 0 }
    /^---$/ && fence_count < 2 { fence_count++; next }
    fence_count >= 2 { print }
  ' "$repo_root/SKILL.md"
} > "$generated_dir/SKILL.md"

cp "$repo_root/INVARIANTS.md" "$generated_dir/INVARIANTS.md"
cp "$repo_root/prompts/dissect.md" "$generated_dir/prompts/dissect.md"
cp "$repo_root/integrations/codex/skills/abelian/agents/openai.yaml" "$generated_dir/agents/openai.yaml"

ln -sfn "$generated_dir" "$skill_link"

cat <<EOF
Installed Abelian Codex skill:
  $skill_link -> $generated_dir

Restart Codex so the skill list reloads.
EOF
