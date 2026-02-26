#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_NAME="aztec-contracts"
VERSION_LABEL="v4.0.0-devnet.2-patch.1"
PINNED_COMMIT="1dbe894364c0d179d2f6443b47887766bbf51343"
SOURCE_REPO_NAME="aztec-packages"

REPO_ROOT="${1:-${AZTEC_REPO_ROOT:-}}"
OUT_DIR="${2:-$ROOT_DIR/references/corpus}"
REF_DIR="${3:-$ROOT_DIR/references/full-docs}"
ALLOW_UNPINNED="${AZTEC_ALLOW_UNPINNED:-0}"

if [[ -z "$REPO_ROOT" ]]; then
  if [[ -d "$PWD/.git" && -f "$PWD/docs/internal_notes/llm_docs_skill_candidates.md" ]]; then
    REPO_ROOT="$PWD"
  elif [[ -d "$ROOT_DIR/../$SOURCE_REPO_NAME/.git" ]]; then
    REPO_ROOT="$ROOT_DIR/../$SOURCE_REPO_NAME"
  else
    echo "Could not locate an aztec-packages checkout." >&2
    echo "Pass a path explicitly: scripts/build_corpus.sh /path/to/aztec-packages" >&2
    echo "Or set AZTEC_REPO_ROOT=/path/to/aztec-packages" >&2
    exit 1
  fi
fi

if [[ ! -d "$REPO_ROOT" ]]; then
  echo "Repository path not found: $REPO_ROOT" >&2
  exit 1
fi
if [[ ! -d "$REPO_ROOT/.git" ]]; then
  echo "Expected a git checkout at: $REPO_ROOT" >&2
  exit 1
fi

ACTUAL_COMMIT="$(git -C "$REPO_ROOT" rev-parse HEAD)"
if [[ "$ACTUAL_COMMIT" != "$PINNED_COMMIT" && "$ALLOW_UNPINNED" != "1" ]]; then
  echo "Pinned commit mismatch." >&2
  echo "Expected: $PINNED_COMMIT" >&2
  echo "Actual:   $ACTUAL_COMMIT" >&2
  echo "Set AZTEC_ALLOW_UNPINNED=1 to bypass this check." >&2
  exit 1
fi

mkdir -p "$OUT_DIR" "$REF_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
ALL_FILES="$TMP_DIR/all-files.txt"

git -C "$REPO_ROOT" ls-files | sort > "$ALL_FILES"

filter_paths() {
  local destination="$1"
  shift
  : > "$destination"
  while IFS= read -r relpath; do
    for pattern in "$@"; do
      if [[ "$relpath" == $pattern ]]; then
        printf '%s\n' "$relpath" >> "$destination"
        break
      fi
    done
  done < "$ALL_FILES"
  sort -u -o "$destination" "$destination"
}

SOURCE_DOCS="$REF_DIR/source-docs.txt"
GENERATED_API_DOCS="$REF_DIR/generated-api-docs.txt"
REFERENCED_CODE="$REF_DIR/referenced-code-fanout.txt"
ALL_INCLUDED="$REF_DIR/all-included-paths.txt"
EXCLUDED="$REF_DIR/excluded-paths.txt"

filter_paths "$SOURCE_DOCS" \
  "docs/docs-developers/docs/aztec-nr/*" \
  "docs/docs-developers/docs/foundational-topics/contract_creation.md" \
  "docs/docs-developers/docs/tutorials/contract_tutorials/*"

filter_paths "$GENERATED_API_DOCS" \
  "docs/static/aztec-nr-api/devnet/*"

filter_paths "$REFERENCED_CODE" \
  "docs/examples/contracts/*" \
  "docs/examples/circuits/*" \
  "docs/examples/ts/bob_token_contract/*" \
  "docs/examples/ts/recursive_verification/*" \
  "noir-projects/noir-contracts/contracts/*" \
  "noir-projects/aztec-nr/*" \
  "noir-projects/noir-protocol-circuits/crates/types/src/abis/*" \
  "l1-contracts/src/*"

filter_paths "$EXCLUDED" \
  "docs/static/typescript-api/nightly/*" \
  "docs/static/aztec-nr-api/nightly/*" \
  "docs/developer_versioned_docs/*" \
  "docs/network_versioned_docs/*"

cat "$SOURCE_DOCS" "$GENERATED_API_DOCS" "$REFERENCED_CODE" | sort -u > "$ALL_INCLUDED"

SOURCE_DOCS_COUNT="$(wc -l < "$SOURCE_DOCS" | tr -d ' ')"
GENERATED_API_COUNT="$(wc -l < "$GENERATED_API_DOCS" | tr -d ' ')"
REFERENCED_CODE_COUNT="$(wc -l < "$REFERENCED_CODE" | tr -d ' ')"
ALL_INCLUDED_COUNT="$(wc -l < "$ALL_INCLUDED" | tr -d ' ')"
EXCLUDED_COUNT="$(wc -l < "$EXCLUDED" | tr -d ' ')"
GENERATED_AT_UTC="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat > "$OUT_DIR/manifest.json" <<JSON
{
  "skill_name": "$SKILL_NAME",
  "version_label": "$VERSION_LABEL",
  "commit_sha": "$PINNED_COMMIT",
  "source_repository": "$SOURCE_REPO_NAME",
  "generated_at_utc": "$GENERATED_AT_UTC",
  "resolved_commit_sha": "$ACTUAL_COMMIT",
  "counts": {
    "source_docs": $SOURCE_DOCS_COUNT,
    "generated_api_docs": $GENERATED_API_COUNT,
    "referenced_code_fanout": $REFERENCED_CODE_COUNT,
    "all_included": $ALL_INCLUDED_COUNT,
    "excluded_paths": $EXCLUDED_COUNT
  }
}
JSON

echo "Generated corpus manifest: $OUT_DIR/manifest.json"
echo "Generated full reference inventories under: $REF_DIR"
echo "Resolved repository:   $REPO_ROOT"
echo "Source docs:          $SOURCE_DOCS_COUNT"
echo "Generated API docs:   $GENERATED_API_COUNT"
echo "Referenced code:      $REFERENCED_CODE_COUNT"
echo "All included paths:   $ALL_INCLUDED_COUNT"
echo "Excluded paths:       $EXCLUDED_COUNT"
