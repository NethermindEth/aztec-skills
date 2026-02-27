#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <account-alias> <sponsored-fpc-address> [node-url]

Creates an account configured to use sponsored fee payments.

Arguments:
  account-alias           Alias for the new account (e.g. my-wallet).
  sponsored-fpc-address   SponsoredFPC contract address.
  node-url                Optional node URL; can also be set with NODE_URL.

Environment:
  WAIT_FOR_MINING=0       Adds --no-wait when set to 0.
USAGE
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage
  exit 1
fi

if ! command -v aztec-wallet >/dev/null 2>&1; then
  echo "Error: aztec-wallet is required." >&2
  exit 1
fi

alias_name="$1"
fpc_address="$2"
node_url="${3:-${NODE_URL:-}}"
wait_for_mining="${WAIT_FOR_MINING:-1}"

cmd=(aztec-wallet create-account --alias "$alias_name" --payment "method=fpc-sponsored,fpc=$fpc_address")
if [[ -n "$node_url" ]]; then
  cmd+=(--node-url "$node_url")
fi
if [[ "$wait_for_mining" == "0" ]]; then
  cmd+=(--no-wait)
fi

echo "Running: ${cmd[*]}"
"${cmd[@]}"
