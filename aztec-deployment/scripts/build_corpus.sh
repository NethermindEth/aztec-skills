#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${1:-$ROOT_DIR/references/corpus}"

mkdir -p "$OUT_DIR"

cat > "$OUT_DIR/manifest.json" <<'JSON'
{
  "skill_name": "aztec-deployment",
  "version_label": "v4.0.0-devnet.2-patch.1",
  "commit_sha": "1dbe894364c0d179d2f6443b47887766bbf51343"
}
JSON

echo "Scaffold manifest created at: $OUT_DIR/manifest.json"
echo "Next: add extracted chunks with source_path metadata under $OUT_DIR."
