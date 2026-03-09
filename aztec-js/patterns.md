# Aztec.js Patterns

All patterns assume pin `v4.1.0-rc.1` (`77e5b3ca816702e2cee866aec1a0d6ce997e0ea6`).

## Pattern 1: Connect + Register Local Accounts

Use for local-network application startup.

```typescript
import { createAztecNodeClient, waitForNode } from "@aztec/aztec.js/node";
import { EmbeddedWallet } from "@aztec/wallets/embedded";
import { getInitialTestAccountsData } from "@aztec/accounts/testing";

const node = createAztecNodeClient("http://localhost:8080");
await waitForNode(node);
const wallet = await EmbeddedWallet.create(node);

const testAccounts = await getInitialTestAccountsData();
const [alice, bob] = await Promise.all(
  testAccounts.slice(0, 2).map(async acct => {
    return (await wallet.createSchnorrAccount(acct.secret, acct.salt, acct.signingKey)).address;
  }),
);
```

## Pattern 2: Create and Deploy a New Account

Use when onboarding a user account.

```typescript
import { Fr } from "@aztec/aztec.js/fields";
import { AztecAddress } from "@aztec/aztec.js/addresses";

const newAccount = await wallet.createSchnorrAccount(Fr.random(), Fr.random());
const deployMethod = await newAccount.getDeployMethod();

await deployMethod.send({
  from: AztecAddress.ZERO,
});

const metadata = await wallet.getContractMetadata(newAccount.address);
if (!metadata.isContractInitialized) {
  throw new Error("Account deployment not initialized");
}
```

## Pattern 3: Deploy Contract with Readiness Verification

Use for production-safe deployment flow.

```typescript
import { TokenContract } from "@aztec/noir-contracts.js/Token";
import { Fr } from "@aztec/aztec.js/fields";

const token = await TokenContract.deploy(wallet, alice, "Token", "TOK", 18).send({
  from: alice,
  contractAddressSalt: Fr.random(),
  universalDeploy: false,
});

const metadata = await wallet.getContractMetadata(token.address);
const classMeta = metadata.instance
  ? await wallet.getContractClassMetadata(metadata.instance.currentContractClassId)
  : undefined;

if (!metadata.isContractInitialized) throw new Error("not initialized");
if (!metadata.isContractPublished) throw new Error("instance not published");
if (classMeta && !classMeta.isContractClassPubliclyRegistered) {
  throw new Error("class not publicly registered");
}
```

## Pattern 4: Simulate, Send, and No-Wait Polling

Use for robust transaction UX.

```typescript
import { NO_WAIT } from "@aztec/aztec.js/contracts";

await token.methods.transfer(bob, 100n).simulate({ from: alice });

const txHash = await token.methods.transfer(bob, 100n).send({
  from: alice,
  wait: NO_WAIT,
});

const receipt = await node.getTxReceipt(txHash);
console.log(receipt.status, receipt.blockNumber, receipt.transactionFee);
```

## Pattern 5: Atomic Multi-Call with `BatchCall`

Use when multiple calls must succeed or fail together.

```typescript
import { BatchCall } from "@aztec/aztec.js/contracts";

const batch = new BatchCall(wallet, [
  token.methods.mint_to_public(alice, 500n),
  token.methods.transfer(bob, 200n),
]);

const batchReceipt = await batch.send({ from: alice });
console.log(batchReceipt.blockNumber);
```

## Pattern 6: Gas Estimation + Supported Payment Method

Use for predictable fee handling with a supported payment flow.

```typescript
import { GasSettings } from "@aztec/stdlib/gas";
import { SponsoredFeePaymentMethod } from "@aztec/aztec.js/fee";

const sim = await token.methods.transfer(bob, 50n).simulate({
  from: alice,
  fee: { estimateGas: true, estimatedGasPadding: 0.2 },
});

const maxFeesPerGas = (await node.getCurrentMinFees()).mul(1.5);
const gasSettings = GasSettings.default({ maxFeesPerGas });
const paymentMethod = new SponsoredFeePaymentMethod(fpcAddress);

await token.methods.transfer(bob, 50n).send({
  from: alice,
  fee: { paymentMethod, gasSettings },
});
```

## Pattern 7: Authwit (Private + Public)

Use when a caller executes an action on behalf of an authorizer.

```typescript
import { Fr } from "@aztec/aztec.js/fields";
import { SetPublicAuthwitContractInteraction } from "@aztec/aztec.js/authorization";

const nonce = Fr.random();
const action = token.methods.transfer_in_private(alice, bob, 100n, nonce);

const witness = await wallet.createAuthWit(alice, {
  caller: bob,
  call: await action.getFunctionCall(),
});
await action.send({ from: bob, authWitnesses: [witness] });

const publicAction = token.methods.transfer_in_public(alice, bob, 100n, nonce);
const setAuthwit = await SetPublicAuthwitContractInteraction.create(
  wallet,
  alice,
  { caller: bob, action: publicAction },
  true,
);
await setAuthwit.send();
await publicAction.send({ from: bob });
```

## Pattern 8: Public and Private Event Reads

Use for indexer-lite app reads.

```typescript
import { getPublicEvents } from "@aztec/aztec.js/events";
import type { PrivateEventFilter } from "@aztec/aztec.js/wallet";

const publicEvents = await getPublicEvents(node, TokenContract.events.Transfer, {
  fromBlock: 1,
  toBlock: 100,
  contractAddress: token.address,
});

const filter: PrivateEventFilter = {
  contractAddress: token.address,
  scopes: [alice],
  fromBlock: 1,
  toBlock: 100,
};
const privateEvents = await wallet.getPrivateEvents(TokenContract.events.Transfer, filter);
```

## Pattern 9: Register Externally Deployed Contract

Use when the wallet did not perform the deployment.

```typescript
import { TokenContract } from "@aztec/noir-contracts.js/Token";

const metadata = await wallet.getContractMetadata(contractAddress);
if (!metadata.instance) {
  throw new Error("missing instance; reconstruct from deployment params first");
}

await wallet.registerContract(metadata.instance, TokenContract.artifact);
const external = await TokenContract.at(contractAddress, wallet);
```

## Pattern 10: Minimal Integration Test Shape

Use for repeatable local-network CI tests.

```typescript
import { createAztecNodeClient, waitForNode } from "@aztec/aztec.js/node";
import { EmbeddedWallet } from "@aztec/wallets/embedded";

let wallet: EmbeddedWallet;

beforeAll(async () => {
  const node = createAztecNodeClient("http://localhost:8080");
  await waitForNode(node);
  wallet = await EmbeddedWallet.create(node);
});

it("simulates before sending", async () => {
  const result = await contract.methods.balance_of_public(alice).simulate({ from: alice });
  expect(result).toBeDefined();
});
```
