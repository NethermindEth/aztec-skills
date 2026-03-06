#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 [node-url] [aztec-packages-dir]

Checks Aztec account development prerequisites:
  - node is installed
  - one package manager is installed (npm/yarn/pnpm)
  - optional Aztec node URL is reachable
  - optional aztec-packages checkout has accounts/entrypoints/key-store roots

Examples:
  $0
  $0 http://localhost:8080
  $0 http://localhost:8080 /path/to/aztec-packages
USAGE
}

if [[ $# -gt 2 ]]; then
  usage
  exit 1
fi

node_url="${1:-}"
repo_dir="${2:-}"

if ! command -v node >/dev/null 2>&1; then
  echo "Error: node is required." >&2
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

if [[ -n "$repo_dir" ]]; then
  for rel in \
    "yarn-project/accounts/README.md" \
    "yarn-project/entrypoints/README.md" \
    "yarn-project/key-store/README.md"
  do
    if [[ ! -f "$repo_dir/$rel" ]]; then
      echo "Error: expected source file not found: $repo_dir/$rel" >&2
      exit 1
    fi
  done

  echo "aztec-packages roots validated: $repo_dir"
fi

echo "Preflight checks completed."
