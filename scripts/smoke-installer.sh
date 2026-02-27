#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
HOME_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$WORK_DIR" "$HOME_DIR"
}
trap cleanup EXIT

SKILLS=(
  "aztec-contracts"
  "aztec-deployment"
  "aztec-js"
  "aztec-testing"
)

SELECTIONS='{"targets":["codex","claude"],"skills":["aztec-contracts","aztec-deployment","aztec-js","aztec-testing"],"scopes":{"codex":"project","claude":"user"}}'

echo "Running installer smoke test in temporary directories..."
(
  cd "$WORK_DIR"
  HOME="$HOME_DIR" \
    INSTALL_AZTEC_SKILLS_SELECTIONS="$SELECTIONS" \
    node "$REPO_ROOT/bin/install-aztec-skills.mjs"
)

for skill in "${SKILLS[@]}"; do
  if [[ ! -f "$WORK_DIR/.agents/skills/$skill/SKILL.md" ]]; then
    echo "FAIL: Missing Codex install SKILL.md for $skill"
    exit 1
  fi

  if [[ ! -f "$HOME_DIR/.claude/skills/$skill/SKILL.md" ]]; then
    echo "FAIL: Missing Claude install SKILL.md for $skill"
    exit 1
  fi
done

declare -A SCRIPT_CHECKS=(
  ["aztec-contracts"]="scripts/build_contract.sh"
  ["aztec-deployment"]="scripts/preflight_deploy.sh"
  ["aztec-js"]="scripts/preflight_aztec_js.sh"
  ["aztec-testing"]="scripts/preflight_aztec_testing.sh"
)

for skill in "${SKILLS[@]}"; do
  codex_script="$WORK_DIR/.agents/skills/$skill/${SCRIPT_CHECKS[$skill]}"
  claude_script="$HOME_DIR/.claude/skills/$skill/${SCRIPT_CHECKS[$skill]}"

  if [[ ! -x "$codex_script" ]]; then
    echo "FAIL: Script is not executable in Codex install: $codex_script"
    exit 1
  fi

  if [[ ! -x "$claude_script" ]]; then
    echo "FAIL: Script is not executable in Claude install: $claude_script"
    exit 1
  fi
done

echo "PASS: Installer smoke test completed successfully."
