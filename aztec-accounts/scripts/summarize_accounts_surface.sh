#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <aztec-packages-dir>

Summarizes account-related package exports and selected source anchors from:
  yarn-project/accounts/package.json
  yarn-project/entrypoints/package.json
  yarn-project/key-store/package.json
USAGE
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

repo_dir="$1"
accounts_pkg="$repo_dir/yarn-project/accounts/package.json"
entrypoints_pkg="$repo_dir/yarn-project/entrypoints/package.json"
key_store_pkg="$repo_dir/yarn-project/key-store/package.json"

for file in "$accounts_pkg" "$entrypoints_pkg" "$key_store_pkg"; do
  if [[ ! -f "$file" ]]; then
    echo "Error: package.json not found: $file" >&2
    exit 1
  fi
done

node - "$accounts_pkg" "$entrypoints_pkg" "$key_store_pkg" <<'NODE'
const fs = require('node:fs');

for (const file of process.argv.slice(2)) {
  const pkg = JSON.parse(fs.readFileSync(file, 'utf8'));
  console.log(`package: ${pkg.name}`);
  console.log(`version: ${pkg.version}`);
  console.log(`node: ${pkg.engines?.node ?? 'n/a'}`);
  console.log('exports:');
  if (typeof pkg.exports === 'string') {
    console.log(`  . -> ${pkg.exports}`);
  } else {
    for (const [k, v] of Object.entries(pkg.exports ?? {})) {
      console.log(`  ${k} -> ${v}`);
    }
  }
  console.log();
}
NODE

if command -v rg >/dev/null 2>&1; then
  echo "selected source anchors:"
  rg -n --no-heading "export class |export async function |export function |export enum |class KeyStore" \
    "$repo_dir/yarn-project/accounts/src" \
    "$repo_dir/yarn-project/entrypoints/src" \
    "$repo_dir/yarn-project/key-store/src" \
    | sed "s#${repo_dir}/##" \
    | sort
else
  echo "Warning: rg not found, skipping source-anchor summary." >&2
fi
