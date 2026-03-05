#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <aztec-packages-dir>

Runs @aztec/pxe oracle interface compatibility check from:
  yarn-project/pxe

If build artifacts are missing, this script builds @aztec/pxe first.
USAGE
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

repo_dir="$1"
pkg_dir="$repo_dir/yarn-project/pxe"
check_bin="$pkg_dir/dest/bin/check_oracle_version.js"

if [[ ! -d "$pkg_dir" ]]; then
  echo "Error: pxe directory not found: $pkg_dir" >&2
  exit 1
fi

if ! command -v yarn >/dev/null 2>&1; then
  echo "Error: yarn is required to run oracle checks." >&2
  exit 1
fi

pushd "$pkg_dir" >/dev/null

if [[ ! -f "$check_bin" ]]; then
  echo "Build artifacts missing; running: yarn build"
  yarn build
fi

echo "Running oracle compatibility check in $pkg_dir"
yarn check_oracle_version

popd >/dev/null
