#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <aztec-packages-dir> [test-name-pattern]

Runs @aztec/wallet-sdk tests from an aztec-packages checkout.

Arguments:
  aztec-packages-dir   Path to aztec-packages repository root.
  test-name-pattern    Optional Jest testNamePattern filter.

Examples:
  $0 /path/to/aztec-packages
  $0 /path/to/aztec-packages "splits a mixed payload"
USAGE
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

repo_dir="$1"
name_pattern="${2:-}"
pkg_dir="$repo_dir/yarn-project/wallet-sdk"

if [[ ! -d "$pkg_dir" ]]; then
  echo "Error: wallet-sdk directory not found: $pkg_dir" >&2
  exit 1
fi

if ! command -v yarn >/dev/null 2>&1; then
  echo "Error: yarn is required to run wallet-sdk tests." >&2
  exit 1
fi

pushd "$pkg_dir" >/dev/null

cmd=(yarn test)
if [[ -n "$name_pattern" ]]; then
  cmd+=(--testNamePattern "$name_pattern")
fi

echo "Running in $pkg_dir: ${cmd[*]}"
"${cmd[@]}"

popd >/dev/null
