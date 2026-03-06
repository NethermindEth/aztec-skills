#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <aztec-packages-dir> [accounts|entrypoints|key-store]

Runs tests for account-related packages from an aztec-packages checkout.

Arguments:
  aztec-packages-dir   Path to aztec-packages repository root.
  package              Optional package selector. Default runs all three packages.

Examples:
  $0 /path/to/aztec-packages
  $0 /path/to/aztec-packages accounts
USAGE
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

repo_dir="$1"
target="${2:-all}"

if ! command -v yarn >/dev/null 2>&1; then
  echo "Error: yarn is required to run package tests." >&2
  exit 1
fi

case "$target" in
  all)
    packages=("accounts" "entrypoints" "key-store")
    ;;
  accounts|entrypoints|key-store)
    packages=("$target")
    ;;
  *)
    echo "Error: unsupported package selector: $target" >&2
    usage
    exit 1
    ;;
esac

for pkg in "${packages[@]}"; do
  pkg_dir="$repo_dir/yarn-project/$pkg"
  if [[ ! -d "$pkg_dir" ]]; then
    echo "Error: package directory not found: $pkg_dir" >&2
    exit 1
  fi

  pushd "$pkg_dir" >/dev/null
  echo "Running in $pkg_dir: yarn test"
  yarn test
  popd >/dev/null
done
