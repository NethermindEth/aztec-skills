# Aztec Testing Patterns

All patterns assume pin `v4.2.0` (`f8c89cf4345df6c4ca9e66ea9b738e96070abc5a`).

## Pattern 1: Reusable Noir Setup Helper

Use this to keep tests concise and deterministic.

```rust
use crate::MyContract;
use aztec::{
    protocol::address::AztecAddress,
    test::helpers::test_environment::TestEnvironment,
};

pub unconstrained fn setup() -> (TestEnvironment, AztecAddress, AztecAddress) {
    let mut env = TestEnvironment::new();
    let owner = env.create_light_account();
    let initializer = MyContract::interface().constructor(owner);
    let contract = env.deploy("MyContract").with_public_initializer(owner, initializer);
    (env, contract, owner)
}
```

## Pattern 2: Noir Call-Type Matrix in One Test

Use this to validate private/public/utility surfaces explicitly.

```rust
#[test]
unconstrained fn test_call_matrix() {
    let (env, contract, owner) = setup();

    env.call_private(owner, MyContract::at(contract).set_private_value(7));
    env.call_public(owner, MyContract::at(contract).set_public_value(11));

    let private_value = env.execute_utility(MyContract::at(contract).get_private_value(owner));
    let public_value = env.view_public(MyContract::at(contract).get_public_value());

    assert_eq(private_value, 7);
    assert_eq(public_value, 11);
}
```

## Pattern 3: Noir Authwit Private Delegation

Use this for delegated private execution tests.

```rust
use aztec::test::helpers::authwit::add_private_authwit_from_call;

#[test]
unconstrained fn private_delegate_happy_path() {
    let mut env = TestEnvironment::new();
    let owner = env.create_contract_account();
    let spender = env.create_contract_account();

    let initializer = Token::interface().constructor(owner, "Token", "TOK", 18);
    let token = env.deploy("Token").with_public_initializer(owner, initializer);

    env.call_private(owner, Token::at(token).mint_to_private(owner, 1000));

    let delegated = Token::at(token).transfer_in_private(owner, spender, 100, 1);
    add_private_authwit_from_call(env, owner, spender, delegated);
    env.call_private(spender, delegated);

    assert_eq(env.execute_utility(Token::at(token).balance_of_private(spender)), 100);
}
```

## Pattern 4: Noir Authwit Public Delegation

Use this for delegated public execution tests.

```rust
use aztec::test::helpers::authwit::add_public_authwit_from_call;

#[test]
unconstrained fn public_delegate_happy_path() {
    let mut env = TestEnvironment::new();
    let owner = env.create_contract_account();
    let spender = env.create_contract_account();

    let initializer = Token::interface().constructor(owner, "Token", "TOK", 18);
    let token = env.deploy("Token").with_public_initializer(owner, initializer);

    env.call_public(owner, Token::at(token).mint_to_public(owner, 1000));

    let delegated = Token::at(token).transfer_in_public(owner, spender, 100, 1);
    add_public_authwit_from_call(env, owner, spender, delegated);
    env.call_public(spender, delegated);

    assert_eq(env.view_public(Token::at(token).balance_of_public(spender)), 100);
}
```

## Pattern 5: Noir Failure Assertions

Use this for precise revert checks.

```rust
#[test(should_fail_with = "Balance too low")]
unconstrained fn transfer_fails_when_amount_exceeds_balance() {
    let (env, token, owner) = setup();
    let recipient = owner;

    env.call_private(owner, Token::at(token).transfer(recipient, 999999));
}
```

## Pattern 6: Noir Time-Window Testing

Use this for delay/expiry logic.

```rust
#[test]
unconstrained fn delay_window_behavior() {
    let env = TestEnvironment::new();

    let now = env.last_block_timestamp();
    env.set_next_block_timestamp(now + 60);
    env.mine_block();

    assert_eq(env.last_block_timestamp(), now + 60);
}
```

## Pattern 7: TypeScript Test Harness Setup

Use this in `beforeAll` for integration tests.

```typescript
import { createAztecNodeClient, waitForNode } from "@aztec/aztec.js/node";
import { EmbeddedWallet } from "@aztec/wallets/embedded";
import { registerInitialLocalNetworkAccountsInWallet } from "@aztec/wallets/testing";

const node = createAztecNodeClient("http://localhost:8080");
await waitForNode(node);
const wallet = await EmbeddedWallet.create(node);
const [alice, bob] = await registerInitialLocalNetworkAccountsInWallet(wallet);
```

## Pattern 8: TypeScript Deploy + Simulate + Send

Use this as the default contract integration test shape. `TokenContract.deploy(...)` below does not require `additionalScopes`; contracts that initialize private storage in their constructor need the follow-up private-storage deploy shape.

```typescript
import { TokenContract } from "@aztec/noir-contracts.js/Token";

const { contract: token } = await TokenContract.deploy(wallet, alice, "TestToken", "TST", 18).send({ from: alice });

await token.methods.mint_to_public(alice, 1000n).send({ from: alice });

const { result: balance } = await token.methods.balance_of_public(alice).simulate({ from: alice });
expect(balance).toBe(1000n);
```

For a constructor that writes contract-owned private storage, derive and register contract keys before sending:

```typescript
import { Fr } from "@aztec/aztec.js/fields";
import { deriveKeys } from "@aztec/aztec.js/keys";

const contractSecretKey = Fr.random();
const publicKeys = (await deriveKeys(contractSecretKey)).publicKeys;
const deployMethod = MyPrivateStorageContract.deployWithPublicKeys(publicKeys, wallet, alice, initialValue);
const instance = await deployMethod.getInstance({ deployer: alice });
await wallet.registerContract(instance, MyPrivateStorageContract.artifact, contractSecretKey);

const { contract } = await deployMethod.send({
  from: alice,
  additionalScopes: [instance.address],
});
```

## Pattern 9: TypeScript Private Authwit Delegation

Use this for delegated private action tests.

```typescript
import { Fr } from "@aztec/aztec.js/fields";
import { sendThroughAuthwitProxy } from "./fixtures/authwit_proxy";

const nonce = Fr.random();
const action = token.methods.transfer_in_private(alice, bob, 100n, nonce);
const witness = await wallet.createAuthWit(alice, { caller: proxy.address, action });

await sendThroughAuthwitProxy(proxy, action, {
  from: alice,
  authWitnesses: [witness],
});
```

## Pattern 10: TypeScript Revert Expectation via Simulate

Use this for cheap negative-path assertions.

```typescript
it("reverts when transferring more than balance", async () => {
  const { result: balance } = await token.methods.balance_of_public(alice).simulate({ from: alice });

  await expect(
    token.methods.transfer_in_public(alice, bob, balance + 1n, 0).simulate({ from: alice }),
  ).rejects.toThrow();
});
```
