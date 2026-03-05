#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <aztec-packages-dir> [test-path-pattern]

Runs @aztec/pxe tests from an aztec-packages checkout.

Arguments:
  aztec-packages-dir   Path to aztec-packages repository root.
  test-path-pattern    Optional Jest testPathPattern filter.

Examples:
  $0 /path/to/aztec-packages
  $0 /path/to/aztec-packages "tagging"
USAGE
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

repo_dir="$1"
test_path_pattern="${2:-}"
pkg_dir="$repo_dir/yarn-project/pxe"

if [[ ! -d "$pkg_dir" ]]; then
  echo "Error: pxe directory not found: $pkg_dir" >&2
  exit 1
fi

if ! command -v yarn >/dev/null 2>&1; then
  echo "Error: yarn is required to run pxe tests." >&2
  exit 1
fi

pushd "$pkg_dir" >/dev/null

cmd=(yarn test)
if [[ -n "$test_path_pattern" ]]; then
  cmd+=(--testPathPattern "$test_path_pattern")
fi

echo "Running in $pkg_dir: ${cmd[*]}"
"${cmd[@]}"

popd >/dev/null
