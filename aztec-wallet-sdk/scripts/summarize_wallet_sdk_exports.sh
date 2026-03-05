#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <aztec-packages-dir>

Summarizes Wallet SDK package exports and typedoc entrypoints from:
  yarn-project/wallet-sdk/package.json

Also prints a lightweight export-declaration count from src/*.ts.
USAGE
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

repo_dir="$1"
pkg_dir="$repo_dir/yarn-project/wallet-sdk"
pkg_json="$pkg_dir/package.json"

if [[ ! -f "$pkg_json" ]]; then
  echo "Error: package.json not found: $pkg_json" >&2
  exit 1
fi

echo "wallet-sdk package: $pkg_json"

node - "$pkg_json" <<'NODE'
const fs = require('node:fs');
const path = process.argv[2];
const pkg = JSON.parse(fs.readFileSync(path, 'utf8'));

console.log(`name: ${pkg.name}`);
console.log(`version: ${pkg.version}`);
console.log(`engines.node: ${pkg.engines?.node ?? 'n/a'}`);

console.log('\nexports:');
for (const [k, v] of Object.entries(pkg.exports ?? {})) {
  console.log(`  ${k} -> ${v}`);
}

console.log('\ntypedoc entryPoints:');
for (const ep of pkg.typedocOptions?.entryPoints ?? []) {
  console.log(`  ${ep}`);
}
NODE

if command -v rg >/dev/null 2>&1; then
  echo
  echo "export declaration counts by source file:"
  while IFS= read -r file; do
    count="$(rg -n '^export ' "$file" | wc -l | tr -d ' ')"
    rel="${file#$pkg_dir/}"
    printf "  %-60s %s\n" "$rel" "$count"
  done < <(find "$pkg_dir/src" -type f -name '*.ts' | sort)
else
  echo "Warning: rg not found, skipping export declaration counts." >&2
fi
