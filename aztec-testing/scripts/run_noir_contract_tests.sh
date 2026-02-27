#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <workspace-dir> [--skip-compile]

Runs Aztec Noir contract tests.

Arguments:
  workspace-dir   Contract workspace/crate directory.
  --skip-compile  Skip the aztec compile step.

Examples:
  $0 .
  $0 ./noir-projects/noir-contracts/contracts/app/token_contract
  $0 ./my_contract --skip-compile
USAGE
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

workspace_dir="$1"
skip_compile="${2:-}"

if ! command -v aztec >/dev/null 2>&1; then
  echo "Error: 'aztec' CLI is required." >&2
  exit 1
fi

if [[ ! -d "$workspace_dir" ]]; then
  echo "Error: workspace directory not found: $workspace_dir" >&2
  exit 1
fi

if [[ ! -f "$workspace_dir/Nargo.toml" ]]; then
  echo "Error: Nargo.toml not found in workspace directory: $workspace_dir" >&2
  exit 1
fi

if [[ "$skip_compile" != "" && "$skip_compile" != "--skip-compile" ]]; then
  echo "Error: unknown option: $skip_compile" >&2
  usage
  exit 1
fi

if [[ "$skip_compile" != "--skip-compile" ]]; then
  echo "Compiling contracts in: $workspace_dir"
  (cd "$workspace_dir" && aztec compile)
fi

echo "Running tests in: $workspace_dir"
(cd "$workspace_dir" && aztec test)
