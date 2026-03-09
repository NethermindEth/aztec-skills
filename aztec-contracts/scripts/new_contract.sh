#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE >&2
Usage: $0 <contract-name> [destination-directory] [aztec-nr-path]

Arguments:
  contract-name          Directory name for the new Noir contract crate.
  destination-directory  Parent directory where the crate will be created (default: .)
  aztec-nr-path          Path to aztec-nr dependency (default: AZTEC_NR_PATH or auto-detected sibling ../aztec-packages/noir-projects/aztec-nr/aztec)
USAGE
}

if [[ $# -lt 1 || $# -gt 3 ]]; then
  usage
  exit 1
fi

contract_name="$1"
destination_dir="${2:-.}"
aztec_nr_path="${3:-${AZTEC_NR_PATH:-}}"

if [[ -z "${aztec_nr_path}" ]]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  skill_repo_parent="$(cd "${script_dir}/../../.." && pwd)"

  candidates=(
    "../aztec-packages/noir-projects/aztec-nr/aztec"
    "${skill_repo_parent}/aztec-packages/noir-projects/aztec-nr/aztec"
  )

  for candidate in "${candidates[@]}"; do
    if [[ -d "${candidate}" ]]; then
      aztec_nr_path="${candidate}"
      break
    fi
  done
fi

if [[ ! "$contract_name" =~ ^[A-Za-z][A-Za-z0-9_-]*$ ]]; then
  echo "Error: contract-name must match ^[A-Za-z][A-Za-z0-9_-]*$" >&2
  exit 1
fi

crate_dir="${destination_dir%/}/${contract_name}"
crate_name="$(echo "$contract_name" | tr '[:upper:]-' '[:lower:]_')"

# Convert snake/kebab style into PascalCase for contract type name.
contract_type="$(echo "$contract_name" | sed -E 's/[-_]+/ /g' | awk '{for (i=1;i<=NF;i++){printf toupper(substr($i,1,1)) tolower(substr($i,2))}}')"

if [[ -e "$crate_dir" ]]; then
  echo "Error: destination already exists: $crate_dir" >&2
  exit 1
fi

if [[ ! -d "$aztec_nr_path" ]]; then
  echo "Error: aztec-nr path does not exist: $aztec_nr_path" >&2
  echo "Set AZTEC_NR_PATH or pass the third argument explicitly." >&2
  echo "Expected repository checkout: https://github.com/AztecProtocol/aztec-packages (tag v4.1.0-rc.1)." >&2
  exit 1
fi

# Normalize to an absolute path so generated Nargo.toml works regardless of caller cwd.
aztec_nr_path="$(cd "$aztec_nr_path" && pwd)"

mkdir -p "$crate_dir/src"

cat > "$crate_dir/Nargo.toml" <<EOTOML
[package]
name = "$crate_name"
authors = [""]
compiler_version = ">=0.25.0"
type = "contract"

[dependencies]
aztec = { path = "$aztec_nr_path" }
EOTOML

cat > "$crate_dir/src/main.nr" <<EONR
mod test;

use aztec::macros::aztec;

#[aztec]
pub contract $contract_type {
    use aztec::{
        macros::{functions::{external, initializer, view}, storage::storage},
        protocol::address::AztecAddress,
        state_vars::{PublicImmutable, PublicMutable},
    };

    #[storage]
    struct Storage<Context> {
        admin: PublicImmutable<AztecAddress, Context>,
        value: PublicMutable<Field, Context>,
    }

    #[initializer]
    #[external("public")]
    fn constructor(admin: AztecAddress, initial_value: Field) {
        self.storage.admin.initialize(admin);
        self.storage.value.write(initial_value);
    }

    #[external("public")]
    fn set_value(value: Field) {
        assert(self.msg_sender() == self.storage.admin.read(), "not admin");
        self.storage.value.write(value);
    }

    #[view]
    #[external("public")]
    fn get_value() -> Field {
        self.storage.value.read()
    }
}
EONR

cat > "$crate_dir/src/test.nr" <<EOTEST
use crate::$contract_type;
use aztec::{
    protocol::address::AztecAddress,
    test::helpers::test_environment::TestEnvironment,
};

pub unconstrained fn setup(initial_value: Field) -> (TestEnvironment, AztecAddress, AztecAddress) {
    let mut env = TestEnvironment::new();
    let owner = env.create_light_account();

    let initializer = $contract_type::interface().constructor(owner, initial_value);
    let contract_address = env.deploy("$contract_type").with_public_initializer(owner, initializer);
    (env, contract_address, owner)
}

#[test]
unconstrained fn test_set_value_as_admin() {
    let (mut env, contract_address, owner) = setup(0);

    env.call_public(owner, $contract_type::at(contract_address).set_value(7));
    let value = env.view_public($contract_type::at(contract_address).get_value());
    assert_eq(value, 7);
}
EOTEST

echo "Created Aztec contract crate at: $crate_dir"
echo "Next steps:"
echo "  cd $crate_dir"
echo "  aztec compile"
echo "  aztec test"
