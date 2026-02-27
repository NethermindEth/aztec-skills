#!/usr/bin/env bash
set -euo pipefail

workspace_dir="${1:-.}"

if ! command -v aztec >/dev/null 2>&1; then
  echo "Error: 'aztec' CLI is required for contract compilation." >&2
  exit 1
fi

if [[ ! -f "$workspace_dir/Nargo.toml" ]]; then
  echo "Warning: Nargo.toml not found at $workspace_dir. Continuing anyway." >&2
fi

(cd "$workspace_dir" && aztec compile)
