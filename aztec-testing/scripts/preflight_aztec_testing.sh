#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 [node-url]

Checks Aztec contract testing prerequisites:
  - aztec CLI is installed (for Noir tests)
  - node is installed (for TS integration tests)
  - one package manager is installed (npm/yarn/pnpm)
  - optional Aztec node URL is reachable via node_getNodeInfo

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

if ! command -v aztec >/dev/null 2>&1; then
  echo "Error: aztec CLI is required for Noir contract tests." >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "Error: node is required for TypeScript integration tests." >&2
  exit 1
fi

if command -v npm >/dev/null 2>&1; then
  pkg_mgr="npm"
elif command -v yarn >/dev/null 2>&1; then
  pkg_mgr="yarn"
elif command -v pnpm >/dev/null 2>&1; then
  pkg_mgr="pnpm"
else
  echo "Error: one package manager is required (npm, yarn, or pnpm)." >&2
  exit 1
fi

echo "aztec: $(aztec --version | head -n 1)"
echo "node: $(node --version)"
echo "package manager: $pkg_mgr"

if [[ -n "$node_url" ]]; then
  if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required to check node reachability." >&2
    exit 1
  fi

  payload='{"jsonrpc":"2.0","method":"node_getNodeInfo","params":[],"id":1}'
  response="$(curl -sS --max-time 8 -H 'content-type: application/json' -d "$payload" "$node_url" || true)"

  if [[ -z "$response" ]]; then
    echo "Error: failed to reach node URL: $node_url" >&2
    exit 1
  fi

  if [[ "$response" == *'"result"'* ]]; then
    echo "Node JSON-RPC responded successfully: $node_url"
  else
    echo "Warning: endpoint reachable but node_getNodeInfo result missing." >&2
    echo "Response snippet: ${response:0:160}" >&2
  fi
fi

echo "Preflight checks completed."
