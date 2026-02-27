#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 [node-url]

Checks local deployment prerequisites:
  - aztec CLI is installed
  - aztec-wallet CLI is installed
  - optional node URL is reachable

Examples:
  $0
  $0 http://localhost:8080
  $0 https://devnet.aztec-labs.com/
USAGE
}

if [[ $# -gt 1 ]]; then
  usage
  exit 1
fi

node_url="${1:-}"

for cmd in aztec aztec-wallet; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command not found: $cmd" >&2
    exit 1
  fi
done

echo "Found required commands:"
echo "  aztec:       $(command -v aztec)"
echo "  aztec-wallet: $(command -v aztec-wallet)"

if [[ -n "$node_url" ]]; then
  if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required to check node reachability." >&2
    exit 1
  fi

  if curl -sS --max-time 8 "$node_url" >/dev/null; then
    echo "Node URL reachable: $node_url"
  else
    echo "Error: failed to reach node URL: $node_url" >&2
    exit 1
  fi
fi

echo "Preflight checks passed."
