# Aztec Deployment Patterns

All patterns assume pin `v4.1.0-rc.2` (`9598e7eff941a151aeff4cf4264327283db39a88`).

## Pattern 1: Local Network CLI Deployment

Use for fast deployment feedback loops.

```bash
aztec start --local-network
aztec-wallet import-test-accounts

aztec-wallet deploy token_contract@Token \
  --from test0 \
  --alias token \
  --args accounts:test0 Test TST 18
```

## Pattern 2: Devnet Sponsored Account + Deploy

Use when account has no fee juice and sponsored fees are required.

```bash
NODE_URL=https://devnet.aztec-labs.com/
SPONSORED_FPC_ADDRESS=0x280e5686a148059543f4d0968f9a18cd4992520fcd887444b8689bf2726a1f97

aztec-wallet register-contract \
  --node-url "$NODE_URL" \
  --alias sponsoredfpc \
  "$SPONSORED_FPC_ADDRESS" SponsoredFPC --salt 0

aztec-wallet create-account \
  --node-url "$NODE_URL" \
  --alias my-wallet \
  --payment method=fpc-sponsored,fpc=$SPONSORED_FPC_ADDRESS

aztec-wallet deploy \
  --node-url "$NODE_URL" \
  --from accounts:my-wallet \
  --payment method=fpc-sponsored,fpc=$SPONSORED_FPC_ADDRESS \
  --alias token \
  token_contract@Token \
  --args accounts:my-wallet Token TOK 18 --no-wait
```

## Pattern 3: Deterministic Address with Salt (CLI)

Use when deployment address must be reproducible.

```bash
SALT=0x0000000000000000000000000000000000000000000000000000000000001234

aztec-wallet deploy stateful_test_contract@StatefulTest \
  --from test0 \
  --salt "$SALT" \
  --alias stateful \
  --args accounts:test0 42
```

## Pattern 4: Universal Deployment (CLI)

Use when deployment address should not depend on sender.

```bash
aztec-wallet deploy stateful_test_contract@StatefulTest \
  --from test0 \
  --universal \
  --alias universal_stateful \
  --args accounts:test0 42
```

## Pattern 5: Basic Aztec.js Deployment

Use as default app-side deployment flow.

```typescript
import { TokenContract } from "@aztec/noir-contracts.js/Token";

const token = await TokenContract.deploy(
  wallet,
  ownerAddress,
  "Token",
  "TOK",
  18,
).send({ from: ownerAddress });
```

## Pattern 6: Aztec.js Deployment with Options

Use for custom initializer, no wait, or deterministic address.

```typescript
import { Fr } from "@aztec/aztec.js/fields";
import { NO_WAIT } from "@aztec/aztec.js/contracts";

const txHash = await MyContract.deployWithOpts(
  { wallet, method: "public_constructor" },
  ownerAddress,
  42,
).send({
  from: ownerAddress,
  contractAddressSalt: new Fr(12345),
  universalDeploy: false,
  wait: NO_WAIT,
});
```

## Pattern 7: Verify Deployment Readiness

Use before first public call or app launch.

```typescript
const metadata = await wallet.getContractMetadata(contractAddress);
const classMeta = metadata.instance
  ? await wallet.getContractClassMetadata(metadata.instance.currentContractClassId)
  : undefined;

if (!metadata.isContractInitialized) {
  throw new Error("Contract is not initialized");
}
if (!metadata.isContractPublished) {
  throw new Error("Contract instance is not publicly deployed");
}
if (classMeta && !classMeta.isContractClassPubliclyRegistered) {
  throw new Error("Contract class is not publicly registered");
}
```

## Pattern 8: Register Contract Deployed by Another Actor

Use when wallet did not deploy the contract but needs to interact with it.

```typescript
const metadata = await wallet.getContractMetadata(contractAddress);
await wallet.registerContract(metadata.instance!, MyContract.artifact);
const contract = await MyContract.at(contractAddress, wallet);
```

If `metadata.instance` is missing, reconstruct from original deployment parameters before registration.
