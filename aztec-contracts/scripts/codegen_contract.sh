#!/usr/bin/env bash
set -euo pipefail

workspace_dir="${1:-.}"
out_dir="${2:-artifacts}"

if ! command -v aztec >/dev/null 2>&1; then
  echo "Error: 'aztec' CLI is required for codegen." >&2
  exit 1
fi

(cd "$workspace_dir" && aztec codegen target --outdir "$out_dir")
