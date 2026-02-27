#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <project-dir> <npm|yarn|pnpm> [test-script] [node-url]

Runs TypeScript integration tests in a project directory.

Arguments:
  project-dir      Directory containing package.json and test scripts.
  package-manager  npm, yarn, or pnpm.
  test-script      Script name to run (default: test).
  node-url         Optional node URL; if provided, waits for node readiness first.

Examples:
  $0 . npm
  $0 ./yarn-project/end-to-end yarn test http://localhost:8080
  $0 ./app pnpm test:integration https://devnet.aztec-labs.com/
USAGE
}

if [[ $# -lt 2 || $# -gt 4 ]]; then
  usage
  exit 1
fi

project_dir="$1"
pkg_mgr="$2"
test_script="${3:-test}"
node_url="${4:-}"

case "$pkg_mgr" in
  npm|yarn|pnpm) ;;
  *)
    echo "Error: unsupported package manager: $pkg_mgr" >&2
    usage
    exit 1
    ;;
esac

if ! command -v "$pkg_mgr" >/dev/null 2>&1; then
  echo "Error: command not found: $pkg_mgr" >&2
  exit 1
fi

if [[ ! -d "$project_dir" ]]; then
  echo "Error: project directory not found: $project_dir" >&2
  exit 1
fi

if [[ ! -f "$project_dir/package.json" ]]; then
  echo "Error: package.json not found in: $project_dir" >&2
  exit 1
fi

if [[ -n "$node_url" ]]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  wait_script="$script_dir/wait_for_aztec_test_node.sh"

  if [[ ! -x "$wait_script" ]]; then
    echo "Error: expected executable script: $wait_script" >&2
    exit 1
  fi

  "$wait_script" "$node_url"
fi

case "$pkg_mgr" in
  npm)
    cmd=(npm run "$test_script")
    ;;
  yarn)
    cmd=(yarn "$test_script")
    ;;
  pnpm)
    cmd=(pnpm run "$test_script")
    ;;
esac

if [[ -n "$node_url" ]]; then
  echo "Running with NODE_URL=$node_url: ${cmd[*]}"
  (cd "$project_dir" && NODE_URL="$node_url" "${cmd[@]}")
else
  echo "Running: ${cmd[*]}"
  (cd "$project_dir" && "${cmd[@]}")
fi
