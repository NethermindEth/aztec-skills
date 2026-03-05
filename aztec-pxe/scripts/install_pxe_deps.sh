#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <npm|yarn|pnpm> [version]

Installs core PXE dependencies into the current project.

Arguments:
  package-manager   npm, yarn, or pnpm
  version           Optional package version (example: 4.0.0-devnet.2-patch.1)

Examples:
  $0 npm
  $0 yarn 4.0.0-devnet.2-patch.1
USAGE
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

pkg_mgr="$1"
version="${2:-}"

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

suffix=""
if [[ -n "$version" ]]; then
  suffix="@$version"
fi

packages=(
  "@aztec/pxe${suffix}"
  "@aztec/aztec.js${suffix}"
  "@aztec/accounts${suffix}"
)

case "$pkg_mgr" in
  npm)
    cmd=(npm install "${packages[@]}")
    ;;
  yarn)
    cmd=(yarn add "${packages[@]}")
    ;;
  pnpm)
    cmd=(pnpm add "${packages[@]}")
    ;;
esac

echo "Running: ${cmd[*]}"
"${cmd[@]}"
