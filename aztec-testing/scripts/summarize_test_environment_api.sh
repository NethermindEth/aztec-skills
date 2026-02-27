#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <aztec-packages-dir>

Prints a summary of test-related API surfaces from the pinned aztec-packages checkout:
  - public methods in test_environment.nr
  - number of generated devnet HTML docs under noir_aztec/test and std/test
USAGE
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

repo_dir="$1"
test_env_file="$repo_dir/noir-projects/aztec-nr/aztec/src/test/helpers/test_environment.nr"
noir_test_api_dir="$repo_dir/docs/static/aztec-nr-api/devnet/noir_aztec/test"
std_test_api_dir="$repo_dir/docs/static/aztec-nr-api/devnet/std/test"

if [[ ! -f "$test_env_file" ]]; then
  echo "Error: file not found: $test_env_file" >&2
  exit 1
fi

echo "TestEnvironment public method surface"
echo "===================================="
awk '
  /impl PrivateContextOptions \{/ {in_pco=1; next}
  /struct PublicContextOptions \{/ {in_pco=0}
  in_pco && /pub fn / {
    line=$0;
    sub(/^.*pub fn /, "", line);
    sub(/\(.*/, "", line);
    print "PrivateContextOptions::" line;
    pco++;
  }
  /pub unconstrained fn / {
    line=$0;
    sub(/^.*pub unconstrained fn /, "", line);
    sub(/<.*/, "", line);
    sub(/\(.*/, "", line);
    print "TestEnvironment::" line;
    env++;
  }
  END {
    print "------------------------------------";
    print "PrivateContextOptions methods: " pco+0;
    print "TestEnvironment methods: " env+0;
    print "Total methods: " (pco+env)+0;
  }
' "$test_env_file"

echo

echo "Generated devnet testing API docs"
echo "================================="

if [[ -d "$noir_test_api_dir" ]]; then
  noir_count="$(find "$noir_test_api_dir" -type f -name '*.html' | wc -l | tr -d ' ')"
  echo "noir_aztec/test html files: $noir_count"
else
  echo "noir_aztec/test html files: directory not found"
fi

if [[ -d "$std_test_api_dir" ]]; then
  std_count="$(find "$std_test_api_dir" -type f -name '*.html' | wc -l | tr -d ' ')"
  echo "std/test html files: $std_count"
else
  echo "std/test html files: directory not found"
fi
