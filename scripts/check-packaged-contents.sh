#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

SKILLS=(
  "aztec-contracts"
  "aztec-deployment"
  "aztec-js"
  "aztec-pxe"
  "aztec-wallet-sdk"
  "aztec-testing"
)

echo "Checking packaged npm tarball contains skill directories..."
PACK_OUTPUT="$(npm pack --dry-run --json)"
PACKAGED_FILES="$(printf '%s' "$PACK_OUTPUT" | node -e 'let data=""; process.stdin.on("data", c => data += c); process.stdin.on("end", () => { const parsed = JSON.parse(data); const first = Array.isArray(parsed) ? parsed[0] : parsed; if (!first || !Array.isArray(first.files)) { process.exit(1); } for (const file of first.files) { if (file && typeof file.path === "string") { process.stdout.write(file.path + "\n"); } } });')"

for skill in "${SKILLS[@]}"; do
  path="$skill/SKILL.md"
  if ! grep -Fxq "$path" <<< "$PACKAGED_FILES"; then
    echo "FAIL: Missing packaged file: $path"
    exit 1
  fi
done

echo "PASS: npm package contains all expected skills."
