#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <artifact-ref> <from-account> <contract-alias> [constructor-args...]

Deploys an Aztec contract using aztec-wallet.

Arguments:
  artifact-ref      Contract reference accepted by aztec-wallet deploy:
                    - package@contract (e.g. token_contract@Token)
                    - artifact json path (e.g. ./target/my_contract-MyContract.json)
  from-account      Account alias/address to deploy from.
  contract-alias    Alias to store in aztec-wallet.
  constructor-args  Remaining arguments passed as constructor args.

Environment:
  NODE_URL                    Optional node URL.
  PAYMENT                     Optional payment string for --payment.
  INIT_METHOD                 Initializer name (default: constructor).
  NO_INIT=1                   Skip initialization.
  UNIVERSAL=1                 Use --universal.
  SALT_HEX=<0x...>            Use --salt.
  WAIT_FOR_MINING=0           Add --no-wait.
  NO_CLASS_REGISTRATION=1     Add --no-class-registration. Note (v4.2.0): cannot be combined
                              with public functions + private initializer. The public init
                              nullifier is emitted via an auto-enqueued public call that
                              requires the class to be published onchain.
  NO_PUBLIC_DEPLOYMENT=1      Add --no-public-deployment.
USAGE
}

if [[ $# -lt 3 ]]; then
  usage
  exit 1
fi

if ! command -v aztec-wallet >/dev/null 2>&1; then
  echo "Error: aztec-wallet is required." >&2
  exit 1
fi

artifact_ref="$1"
from_account="$2"
contract_alias="$3"
shift 3
ctor_args=("$@")

node_url="${NODE_URL:-}"
payment="${PAYMENT:-}"
init_method="${INIT_METHOD:-constructor}"
no_init="${NO_INIT:-0}"
universal="${UNIVERSAL:-0}"
salt_hex="${SALT_HEX:-}"
wait_for_mining="${WAIT_FOR_MINING:-1}"
no_class_registration="${NO_CLASS_REGISTRATION:-0}"
no_public_deployment="${NO_PUBLIC_DEPLOYMENT:-0}"

cmd=(aztec-wallet deploy "$artifact_ref" --from "$from_account" --alias "$contract_alias")

if [[ -n "$node_url" ]]; then
  cmd+=(--node-url "$node_url")
fi
if [[ -n "$payment" ]]; then
  cmd+=(--payment "$payment")
fi

if [[ "$no_init" == "1" ]]; then
  cmd+=(--no-init)
else
  cmd+=(--init "$init_method")
fi

if [[ "$universal" == "1" ]]; then
  cmd+=(--universal)
fi

if [[ -n "$salt_hex" ]]; then
  cmd+=(--salt "$salt_hex")
fi

if [[ "$wait_for_mining" == "0" ]]; then
  cmd+=(--no-wait)
fi

if [[ "$no_class_registration" == "1" ]]; then
  # NOTE (v4.2.0): --no-class-registration cannot be combined with contracts that expose
  # public functions alongside a private initializer — the auto-enqueued public call that
  # emits the public init nullifier requires the class to be published onchain.
  cmd+=(--no-class-registration)
fi

if [[ "$no_public_deployment" == "1" ]]; then
  cmd+=(--no-public-deployment)
fi

if [[ ${#ctor_args[@]} -gt 0 ]]; then
  cmd+=(--args "${ctor_args[@]}")
fi

echo "Running: ${cmd[*]}"
"${cmd[@]}"
