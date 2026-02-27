# Aztec Contract Patterns

All patterns assume pin `v4.0.0-devnet.2-patch.1` (`1dbe894364c0d179d2f6443b47887766bbf51343`).

## Pattern 1: Minimal Stateful Contract

Use when you need a public mutable value with explicit admin control.

```rust
use aztec::macros::aztec;

#[aztec]
pub contract ConfigStore {
    use aztec::{
        macros::{functions::{external, initializer, view}, storage::storage},
        protocol::address::AztecAddress,
        state_vars::{PublicImmutable, PublicMutable},
    };

    #[storage]
    struct Storage<Context> {
        admin: PublicImmutable<AztecAddress, Context>,
        config: PublicMutable<Field, Context>,
    }

    #[initializer]
    #[external("public")]
    fn constructor(admin: AztecAddress) {
        self.storage.admin.initialize(admin);
        self.storage.config.write(0);
    }

    #[external("public")]
    fn set_config(value: Field) {
        assert(self.msg_sender() == self.storage.admin.read(), "not admin");
        self.storage.config.write(value);
    }

    #[view]
    #[external("public")]
    fn get_config() -> Field {
        self.storage.config.read()
    }
}
```

## Pattern 2: Private Transfer with Explicit Delivery

Use when private note updates are part of business logic.

```rust
#[external("private")]
fn transfer_private(from: AztecAddress, to: AztecAddress, amount: u128) {
    self.storage.balances.at(from).sub(amount).deliver(MessageDelivery.ONCHAIN_CONSTRAINED);
    self.storage.balances.at(to).add(amount).deliver(MessageDelivery.ONCHAIN_CONSTRAINED);
}
```

Delivery guidance:

- Use `ONCHAIN_CONSTRAINED` for untrusted sender scenarios.
- Use `OFFCHAIN` only when sender incentives and delivery channel are explicit.

## Pattern 3: Private-to-Public Bridge with `#[only_self]`

Use when private logic must mutate public state safely.

```rust
#[external("private")]
fn private_to_public(amount: u64) {
    let sender = self.msg_sender();
    self.storage.private_balances.at(sender).sub(amount as u128).deliver(
        MessageDelivery.ONCHAIN_CONSTRAINED,
    );
    self.enqueue_self._credit_public(sender, amount);
}

#[external("public")]
#[only_self]
fn _credit_public(owner: AztecAddress, amount: u64) {
    let current = self.storage.public_balances.at(owner).read();
    self.storage.public_balances.at(owner).write(current + amount);
}
```

## Pattern 4: Delegated Action with Authwit

Use when an action is executed on behalf of `from`.

```rust
#[external("public")]
#[authorize_once("from", "authwit_nonce")]
fn transfer_in_public(from: AztecAddress, to: AztecAddress, amount: u128, authwit_nonce: Field) {
    // authwit verification + nullifier emission handled by macro
    self.internal._debit_public(from, amount);
    self.internal._credit_public(to, amount);
}
```

Testing requirements:

- Use contract accounts.
- Include missing/invalid/replayed authwit tests.

## Pattern 5: Reusable TestEnvironment Setup

Use to avoid repeated deploy/bootstrap code.

```rust
use crate::MyContract;
use aztec::{
    protocol::address::AztecAddress,
    test::helpers::test_environment::TestEnvironment,
};

pub unconstrained fn setup(initial_value: Field) -> (TestEnvironment, AztecAddress, AztecAddress) {
    let mut env = TestEnvironment::new();
    let owner = env.create_light_account();
    let initializer = MyContract::interface().constructor(initial_value, owner);
    let contract_address = env.deploy("MyContract").with_private_initializer(owner, initializer);
    (env, contract_address, owner)
}

#[test]
unconstrained fn test_happy_path() {
    let (mut env, contract_address, owner) = setup(42);
    env.call_private(owner, MyContract::at(contract_address).set_private_value(7));
    let value = env.simulate_utility(MyContract::at(contract_address).get_private_value(owner));
    assert_eq(value, 7);
}
```

## Pattern 6: Upgrade Entry Point

Use when supporting upgradable logic.

```rust
use aztec::protocol::{
    constants::CONTRACT_INSTANCE_REGISTRY_CONTRACT_ADDRESS,
    contract_class_id::ContractClassId,
};
use contract_instance_registry::ContractInstanceRegistry;

#[external("private")]
fn update_to(new_class_id: ContractClassId) {
    assert(self.msg_sender() == self.storage.admin.read(), "not admin");
    self.enqueue(
        ContractInstanceRegistry::at(CONTRACT_INSTANCE_REGISTRY_CONTRACT_ADDRESS)
            .update(new_class_id)
    );
}
```

Safety requirements:

- Strict access control.
- Storage layout compatibility.
- Post-delay artifact registration in clients.
