#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <entry-file.ts> [-- <extra-args...>]

Runs a TypeScript PXE entrypoint with tsx.

Environment:
  NODE_URL     Optional Aztec node URL your script may consume.

Examples:
  $0 ./src/index.ts
  NODE_URL=http://localhost:8080 $0 ./scripts/demo.ts -- --verbose
USAGE
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

entry_file="$1"
shift

if [[ ! -f "$entry_file" ]]; then
  echo "Error: entry file not found: $entry_file" >&2
  exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "Error: npx is required to run tsx." >&2
  exit 1
fi

if [[ "${1:-}" == "--" ]]; then
  shift
fi

echo "Running: npx tsx $entry_file $*"
npx tsx "$entry_file" "$@"
