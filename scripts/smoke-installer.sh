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
  "aztec-accounts"
  "aztec-pxe"
  "aztec-wallet-sdk"
  "aztec-testing"
)

SELECTIONS='{"targets":["codex","claude"],"skills":["aztec-contracts","aztec-deployment","aztec-js","aztec-accounts","aztec-pxe","aztec-wallet-sdk","aztec-testing"],"scopes":{"codex":"project","claude":"user"}}'

echo "Running installer smoke test in temporary directories..."
(
  cd "$WORK_DIR"
  HOME="$HOME_DIR" \
    INSTALL_AZTEC_SKILLS_SELECTIONS="$SELECTIONS" \
    node "$REPO_ROOT/bin/install-aztec-skills.mjs"
)

RELEASES_JSON='{"versions":["4.0.0-devnet.2-patch.1-v0.2.0","4.1.0-rc.1-v0.2.0"],"dist-tags":{"latest":"4.1.0-rc.1-v0.2.0","devnet":"4.0.0-devnet.2-patch.1-v0.2.0"}}'
LIST_OUTPUT="$(INSTALL_AZTEC_SKILLS_RELEASES_JSON="$RELEASES_JSON" node "$REPO_ROOT/bin/install-aztec-skills.mjs" list)"

if ! grep -Fq "Available install-aztec-skills releases to install:" <<< "$LIST_OUTPUT"; then
  echo "FAIL: List command did not print the expected header"
  exit 1
fi

if ! grep -Fq "4.1.0-rc.1-v0.2.0" <<< "$LIST_OUTPUT"; then
  echo "FAIL: List command did not print the expected release version"
  exit 1
fi

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
  ["aztec-accounts"]="scripts/preflight_aztec_accounts.sh"
  ["aztec-pxe"]="scripts/preflight_pxe.sh"
  ["aztec-wallet-sdk"]="scripts/preflight_wallet_sdk.sh"
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
