#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <sponsored-fpc-address> [alias] [node-url]

Registers the SponsoredFPC contract in aztec-wallet for sponsored fee payment.

Arguments:
  sponsored-fpc-address  Contract address of SponsoredFPC.
  alias                  Wallet alias to store (default: sponsoredfpc).
  node-url               Optional node URL; can also be set with NODE_URL.
USAGE
}

if [[ $# -lt 1 || $# -gt 3 ]]; then
  usage
  exit 1
fi

if ! command -v aztec-wallet >/dev/null 2>&1; then
  echo "Error: aztec-wallet is required." >&2
  exit 1
fi

fpc_address="$1"
alias_name="${2:-sponsoredfpc}"
node_url="${3:-${NODE_URL:-}}"

cmd=(aztec-wallet register-contract --alias "$alias_name")
if [[ -n "$node_url" ]]; then
  cmd+=(--node-url "$node_url")
fi

cmd+=("$fpc_address" SponsoredFPC --salt 0)

echo "Running: ${cmd[*]}"
"${cmd[@]}"
