# Aztec Deployment Patterns

All patterns assume pin `v4.2.0` (`f8c89cf4345df6c4ca9e66ea9b738e96070abc5a`).

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

const { contract: token } = await TokenContract.deploy(
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

const { txHash } = await MyContract.deployWithOpts(
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
import { ContractInitializationStatus } from "@aztec/aztec.js/wallet";

const metadata = await wallet.getContractMetadata(contractAddress);
const classMeta = metadata.instance
  ? await wallet.getContractClassMetadata(metadata.instance.currentContractClassId)
  : undefined;

if (metadata.initializationStatus !== ContractInitializationStatus.INITIALIZED) {
  throw new Error("Contract is not initialized");
}
if (!metadata.isContractPublished) {
  throw new Error("Contract instance is not publicly deployed");
}
if (classMeta && !classMeta.isContractClassPubliclyRegistered) {
  throw new Error("Contract class is not publicly registered");
}
```

## Pattern 8: Deploy Contract that Initializes Private Storage

Use when the constructor writes to any private slot owned by the instance itself (for example `SinglePrivateImmutable` or `SinglePrivateMutable`). In v4.2.0 PXE enforces capsule/private-state access against the tx's scope list, so the deployment must include the instance's own address in `additionalScopes`. If the contract owns private state, derive contract keys, deploy with public keys, and register the instance with the contract secret key before sending. `DeployAccountMethod` injects the account address automatically; generic `deploy(...)` calls must do it explicitly. For normal sends, precompute with `getInstance({ contractAddressSalt, deployer: from })`; for universal/`NO_FROM` sends, omit `deployer`.

```typescript
import { Fr } from "@aztec/aztec.js/fields";
import { deriveKeys } from "@aztec/aztec.js/keys";
import { MyPrivateStorageContract } from "./artifacts/MyPrivateStorage";

const contractAddressSalt = new Fr(12345);
const contractSecretKey = Fr.random();
const contractPublicKeys = (await deriveKeys(contractSecretKey)).publicKeys;

const deployMethod = MyPrivateStorageContract.deployWithPublicKeys(
  contractPublicKeys,
  wallet,
  ownerAddress,
  initialValue,
);
const instance = await deployMethod.getInstance({
  contractAddressSalt,
  deployer: ownerAddress,
});
await wallet.registerContract(instance, MyPrivateStorageContract.artifact, contractSecretKey);

const { contract } = await deployMethod.send({
  from: ownerAddress,
  contractAddressSalt,
  additionalScopes: [instance.address],
});
```

The same pattern applies to escrow-withdraw style calls that nullify notes owned by a foreign address — include each such address in `additionalScopes`, otherwise PXE rejects the call with `Scope 0x… is not in the allowed scopes list`.

## Pattern 9: Register Contract Deployed by Another Actor

Use when wallet did not deploy the contract but needs to interact with it.

```typescript
const metadata = await wallet.getContractMetadata(contractAddress);
await wallet.registerContract(metadata.instance!, MyContract.artifact);
const contract = await MyContract.at(contractAddress, wallet);
```

If `metadata.instance` is missing, reconstruct from original deployment parameters before registration.
