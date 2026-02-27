#!/usr/bin/env bash
set -euo pipefail

workspace_dir="${1:-.}"
skip_compile="${2:-}"

if ! command -v aztec >/dev/null 2>&1; then
  echo "Error: 'aztec' CLI is required for contract testing." >&2
  exit 1
fi

if [[ "$skip_compile" != "--skip-compile" ]]; then
  (cd "$workspace_dir" && aztec compile)
fi

(cd "$workspace_dir" && aztec test)
