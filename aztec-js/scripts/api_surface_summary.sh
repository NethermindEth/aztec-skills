#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <aztec-packages-dir>

Summarizes TypeScript API surface counts from:
  docs/static/typescript-api/devnet/*.md

Outputs per-package counts for classes/interfaces/functions/types/enums and totals.
USAGE
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

repo_dir="$1"
api_dir="$repo_dir/docs/static/typescript-api/devnet"

if [[ ! -d "$api_dir" ]]; then
  echo "Error: API docs directory not found: $api_dir" >&2
  exit 1
fi

printf "%-18s %8s %11s %10s %8s %7s\n" "package" "classes" "interfaces" "functions" "types" "enums"
printf "%-18s %8s %11s %10s %8s %7s\n" "------------------" "--------" "-----------" "----------" "--------" "-------"

total_classes=0
total_interfaces=0
total_functions=0
total_types=0
total_enums=0

while IFS= read -r -d '' file; do
  pkg="$(basename "$file" .md)"

  counts="$(awk '
    /^## Classes/{sec="classes";next}
    /^## Interfaces/{sec="interfaces";next}
    /^## Functions/{sec="functions";next}
    /^## Types/{sec="types";next}
    /^## Enums/{sec="enums";next}
    /^## /{sec="";next}
    /^### /{if(sec!="") c[sec]++}
    END {
      printf "%d %d %d %d %d", c["classes"]+0, c["interfaces"]+0, c["functions"]+0, c["types"]+0, c["enums"]+0
    }
  ' "$file")"

  read -r classes interfaces functions types enums <<<"$counts"

  printf "%-18s %8d %11d %10d %8d %7d\n" "$pkg" "$classes" "$interfaces" "$functions" "$types" "$enums"

  total_classes=$((total_classes + classes))
  total_interfaces=$((total_interfaces + interfaces))
  total_functions=$((total_functions + functions))
  total_types=$((total_types + types))
  total_enums=$((total_enums + enums))
done < <(find "$api_dir" -maxdepth 1 -type f -name '*.md' -print0 | sort -z)

printf "%-18s %8s %11s %10s %8s %7s\n" "------------------" "--------" "-----------" "----------" "--------" "-------"
printf "%-18s %8d %11d %10d %8d %7d\n" "TOTAL" "$total_classes" "$total_interfaces" "$total_functions" "$total_types" "$total_enums"
