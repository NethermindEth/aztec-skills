#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <aztec-packages-dir>

Summarizes PXE package entrypoints and high-value method surfaces from:
  yarn-project/pxe/package.json
  yarn-project/pxe/src/pxe.ts
  yarn-project/pxe/src/contract_function_simulator/oracle/*.ts
USAGE
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

repo_dir="$1"
pkg_dir="$repo_dir/yarn-project/pxe"
pkg_json="$pkg_dir/package.json"
pxe_ts="$pkg_dir/src/pxe.ts"
utility_oracle="$pkg_dir/src/contract_function_simulator/oracle/utility_execution_oracle.ts"
private_oracle="$pkg_dir/src/contract_function_simulator/oracle/private_execution_oracle.ts"

for f in "$pkg_json" "$pxe_ts" "$utility_oracle" "$private_oracle"; do
  if [[ ! -f "$f" ]]; then
    echo "Error: missing expected file: $f" >&2
    exit 1
  fi
done

echo "pxe package: $pkg_json"

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
  echo "PXE public methods (src/pxe.ts):"
  rg -n '^\s*public (async )?[A-Za-z0-9_]+\(' "$pxe_ts" | sed -E 's/^([0-9]+):\s*/  line \1: /'

  echo
  echo "Utility oracle methods:"
  rg -n '^\s*public (async )?utility[A-Za-z0-9_]+\(' "$utility_oracle" | sed -E 's/^([0-9]+):\s*/  line \1: /'

  echo
  echo "Private oracle methods:"
  rg -n '^\s*public (async )?private[A-Za-z0-9_]+\(' "$private_oracle" | sed -E 's/^([0-9]+):\s*/  line \1: /'
else
  echo "Warning: rg (ripgrep) not found; skipping method surface extraction." >&2
fi
