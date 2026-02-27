#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <artifact-ref> <from-account> <contract-alias> <sponsored-fpc-address> [constructor-args...]

Deploys a contract on devnet using sponsored fee payment.

Arguments:
  artifact-ref             package@contract or artifact json path.
  from-account             account alias/address to deploy from.
  contract-alias           alias for stored contract.
  sponsored-fpc-address    sponsored FPC contract address.
  constructor-args         constructor args.

Environment:
  NODE_URL                 Devnet URL (default: https://devnet.aztec-labs.com/)
  WAIT_FOR_MINING=0        Adds --no-wait.
USAGE
}

if [[ $# -lt 4 ]]; then
  usage
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
deploy_script="$script_dir/deploy_contract_wallet.sh"

if [[ ! -x "$deploy_script" ]]; then
  echo "Error: expected executable script: $deploy_script" >&2
  exit 1
fi

artifact_ref="$1"
from_account="$2"
contract_alias="$3"
fpc_address="$4"
shift 4

NODE_URL="${NODE_URL:-https://devnet.aztec-labs.com/}" \
PAYMENT="method=fpc-sponsored,fpc=$fpc_address" \
"$deploy_script" "$artifact_ref" "$from_account" "$contract_alias" "$@"
