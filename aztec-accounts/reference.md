# Aztec Accounts Reference

## Scope and Pin

- Skill: `aztec-accounts`
- Version label: `v4.1.3`
- Commit SHA: `e696cf677877d88626834b117a19b7db06bef217`
- Primary source roots:
  - `yarn-project/accounts`
  - `yarn-project/entrypoints`
  - `yarn-project/key-store`
- Supporting lifecycle wiring:
  - `yarn-project/aztec.js/src/account/**`
  - `yarn-project/aztec.js/src/wallet/account_manager.ts`
  - `yarn-project/aztec.js/src/wallet/deploy_account_method.ts`
  - `yarn-project/aztec.js/src/wallet/account_entrypoint_meta_payment_method.ts`
  - `yarn-project/wallets/src/embedded/embedded_wallet.ts`
- Upstream repo: `https://github.com/AztecProtocol/aztec-packages`

## Required Checkout State

```bash
git clone https://github.com/AztecProtocol/aztec-packages.git
cd aztec-packages
git checkout v4.1.3
git status
git rev-parse HEAD
```

Expected:

- `HEAD detached at v4.1.3`
- `e696cf677877d88626834b117a19b7db06bef217`

## Primary Source Anchors

Accounts:

- `yarn-project/accounts/README.md`
- `yarn-project/accounts/package.json`
- `yarn-project/accounts/src/defaults/account_contract.ts`
- `yarn-project/accounts/src/schnorr/index.ts`
- `yarn-project/accounts/src/schnorr/account_contract.ts`
- `yarn-project/accounts/src/single_key/index.ts`
- `yarn-project/accounts/src/single_key/account_contract.ts`
- `yarn-project/accounts/src/ecdsa/ecdsa_k/index.ts`
- `yarn-project/accounts/src/ecdsa/ecdsa_k/account_contract.ts`
- `yarn-project/accounts/src/ecdsa/ecdsa_r/index.ts`
- `yarn-project/accounts/src/ecdsa/ecdsa_r/account_contract.ts`
- `yarn-project/accounts/src/ecdsa/ssh_ecdsa_r/index.ts`
- `yarn-project/accounts/src/ecdsa/ssh_ecdsa_r/account_contract.ts`
- `yarn-project/accounts/src/testing/index.ts`
- `yarn-project/accounts/src/utils/ssh_agent.ts`

Entrypoints:

- `yarn-project/entrypoints/README.md`
- `yarn-project/entrypoints/package.json`
- `yarn-project/entrypoints/src/interfaces.ts`
- `yarn-project/entrypoints/src/account_entrypoint.ts`
- `yarn-project/entrypoints/src/default_entrypoint.ts`
- `yarn-project/entrypoints/src/default_multi_call_entrypoint.ts`
- `yarn-project/entrypoints/src/encoding.ts`

Key store:

- `yarn-project/key-store/README.md`
- `yarn-project/key-store/package.json`
- `yarn-project/key-store/src/key_store.ts`
- `yarn-project/key-store/src/key_store.test.ts`

Supporting lifecycle files:

- `yarn-project/aztec.js/src/account/account_contract.ts`
- `yarn-project/aztec.js/src/account/account.ts`
- `yarn-project/aztec.js/src/account/account_with_secret_key.ts`
- `yarn-project/aztec.js/src/account/signerless_account.ts`
- `yarn-project/aztec.js/src/wallet/account_manager.ts`
- `yarn-project/aztec.js/src/wallet/deploy_account_method.ts`
- `yarn-project/aztec.js/src/wallet/account_entrypoint_meta_payment_method.ts`
- `yarn-project/wallets/src/embedded/embedded_wallet.ts`

## Runtime and Packaging Facts

From `yarn-project/accounts/package.json`:

- package name: `@aztec/accounts`
- node engine: `>=20.10`
- export subpaths:
  - `@aztec/accounts/defaults`
  - `@aztec/accounts/ecdsa`
  - `@aztec/accounts/ecdsa/lazy`
  - `@aztec/accounts/schnorr`
  - `@aztec/accounts/schnorr/lazy`
  - `@aztec/accounts/single_key`
  - `@aztec/accounts/single_key/lazy`
  - `@aztec/accounts/stub`
  - `@aztec/accounts/stub/lazy`
  - `@aztec/accounts/testing`
  - `@aztec/accounts/testing/lazy`
  - `@aztec/accounts/copy-cat`
  - `@aztec/accounts/copy-cat/lazy`
  - `@aztec/accounts/utils`

From `yarn-project/entrypoints/package.json`:

- package name: `@aztec/entrypoints`
- export subpaths:
  - `@aztec/entrypoints/account`
  - `@aztec/entrypoints/default`
  - `@aztec/entrypoints/multicall`
  - `@aztec/entrypoints/interfaces`
  - `@aztec/entrypoints/payload`
  - `@aztec/entrypoints/encoding`

From `yarn-project/key-store/package.json`:

- package name: `@aztec/key-store`
- export: `@aztec/key-store`

## Code-Surface Reality Check

The pinned `yarn-project/accounts/README.md` still documents `getSchnorrAccount(...)` and `getSchnorrWallet(...)`.

The current code-backed surface used by this skill is:

- account contract classes such as `SchnorrAccountContract`, `EcdsaKAccountContract`, `EcdsaRAccountContract`, `SingleKeyAccountContract`
- deterministic address helper `getSchnorrAccountContractAddress(...)`
- lifecycle wiring through:
  - `AccountManager.create(...)`
  - `DeployAccountMethod`
  - embedded-wallet helpers such as `createSchnorrAccount(...)`

Use the code surface above when the README and source diverge.

## Flavor Map

### Schnorr

- `SchnorrAccountContract`
- `SchnorrBaseAccountContract`
- constructor arg: `GrumpkinScalar signingPrivateKey`
- initializer: `constructor(signingPublicKey.x, signingPublicKey.y)`
- auth witness provider: `SchnorrAuthWitnessProvider`
- deterministic address helper:
  - `getSchnorrAccountContractAddress(secret, salt, signingPrivateKey?)`

### SingleKey

- `SingleKeyAccountContract`
- `SingleKeyBaseAccountContract`
- constructor arg: `GrumpkinScalar encryptionPrivateKey`
- initializer: `undefined`
- auth witness includes:
  - account public keys as fields
  - Schnorr signature
  - partial address
- intended for testing only

### ECDSA secp256k1

- `EcdsaKAccountContract`
- `EcdsaKBaseAccountContract`
- constructor arg: `Buffer signingPrivateKey`
- initializer args:
  - first 32 bytes of public key
  - second 32 bytes of public key
- auth witness payload:
  - `r || s`

### ECDSA secp256r1

- `EcdsaRAccountContract`
- `EcdsaRBaseAccountContract`
- constructor arg: `Buffer signingPrivateKey`
- initializer args:
  - first 32 bytes of public key
  - second 32 bytes of public key
- auth witness payload:
  - `r || s`

### ECDSA secp256r1 via SSH agent

- `EcdsaRSSHAccountContract`
- `EcdsaRSSHBaseAccountContract`
- constructor arg: `Buffer signingPublicKey`
- initializer args:
  - first 32 bytes of public key
  - second 32 bytes of public key
- signatures are delegated to SSH agent and normalized to low-S form

## Account Lifecycle Wiring

### `AccountContract` interface (`aztec.js/src/account/account_contract.ts`)

Required methods:

- `getContractArtifact()`
- `getInitializationFunctionAndArgs()`
- `getAccount(completeAddress)`
- `getAuthWitnessProvider(completeAddress)`

Helper:

- `getAccountContractAddress(accountContract, secret, salt)`

### `DefaultAccountContract` (`accounts/src/defaults/account_contract.ts`)

- wraps a `BaseAccount`
- uses `DefaultAccountEntrypoint(completeAddress.address, authWitnessProvider)`
- all standard account flavors in this skill extend this base

### `AccountManager` (`aztec.js/src/wallet/account_manager.ts`)

Core methods:

- `AccountManager.create(wallet, secretKey, accountContract, salt?)`
- `getCompleteAddress()`
- `getSecretKey()`
- `getInstance()`
- `getAccount()`
- `getAccountContract()`
- `getDeployMethod()`
- `hasInitializer()`

Important behavior:

- derives privacy public keys from the secret
- computes contract instance from artifact + constructor args + salt + public keys
- `getDeployMethod()` throws if the account contract has no initializer

### `AccountWithSecretKey` (`aztec.js/src/account/account_with_secret_key.ts`)

- decorates an `Account`
- exposes:
  - `getSecretKey()`
  - `getEncryptionSecret()`
  - `salt`

### Embedded wallet recovery/creation (`wallets/src/embedded/embedded_wallet.ts`)

Relevant helpers:

- `createSchnorrAccount(secret, salt, signingKey?, alias?)`
- `createECDSARAccount(secret, salt, signingKey, alias?)`
- `createECDSAKAccount(secret, salt, signingKey, alias?)`
- internal `createAccountInternal(...)` registers the instance/artifact with the wallet and PXE

## Entrypoint and Routing Map

### `EntrypointInterface` (`entrypoints/src/interfaces.ts`)

- `createTxExecutionRequest(exec, gasSettings, chainInfo, options?)`
- `wrapExecutionPayload(exec, options?)`

### `DefaultAccountEntrypoint` (`entrypoints/src/account_entrypoint.ts`)

Options type:

- `cancellable?: boolean`
- `txNonce?: Fr`
- `feePaymentMethodOptions: AccountFeePaymentMethodOptions`

Fee routing enum:

- `EXTERNAL = 0`
- `PREEXISTING_FEE_JUICE = 1`
- `FEE_JUICE_WITH_CLAIM = 2`

Behavior:

- encodes app calls through `EncodedAppEntrypointCalls.create(calls, txNonce)`
- hashes entrypoint args
- injects a payload auth witness produced from encoded-call hash
- sets `origin` to the account contract address

### `DefaultEntrypoint` (`entrypoints/src/default_entrypoint.ts`)

- supports exactly one private call
- rejects public entrypoints
- rejects multi-call payloads

### `DefaultMultiCallEntrypoint` (`entrypoints/src/default_multi_call_entrypoint.ts`)

- wraps multiple private/public app calls through protocol multicall entrypoint
- default address: `ProtocolContractAddress.MultiCallEntrypoint`
- used by `SignerlessAccount`

### Deployment fee routing

`DeployAccountMethod` (`aztec.js/src/wallet/deploy_account_method.ts`):

- always forces `universalDeployment: true`
- defaults:
  - `skipClassPublication: true`
  - `skipInstancePublication: true`
  - `skipInitialization: false`
- if `from`/deployer is `AztecAddress.ZERO`, self-funding path is enabled

`AccountEntrypointMetaPaymentMethod` (`aztec.js/src/wallet/account_entrypoint_meta_payment_method.ts`):

- wraps a fee payment method back through the account entrypoint being deployed
- computes `AccountFeePaymentMethodOptions` automatically from the wrapped payload

## KeyStore API Map

From `key-store/src/key_store.ts`:

- class: `KeyStore`
- schema version: `KeyStore.SCHEMA_VERSION = 1`

Core account methods:

- `createAccount()`
- `addAccount(sk, partialAddress)`
- `getAccounts()`
- `hasAccount(account)`

Validation and secret-derivation methods:

- `getKeyValidationRequest(pkMHash, contractAddress)`
- `getMasterNullifierPublicKey(account)`
- `getMasterIncomingViewingPublicKey(account)`
- `getMasterOutgoingViewingPublicKey(account)`
- `getMasterTaggingPublicKey(account)`
- `getMasterIncomingViewingSecretKey(account)`
- `getAppOutgoingViewingSecretKey(account, app)`
- `getMasterSecretKey(pkM)`
- `accountHasKey(account, pkMHash)`
- `getKeyPrefixAndAccount(value)`

Storage layout note:

- keys are persisted under per-account suffixes such as:
  - `-ivsk_m`
  - `-ovsk_m`
  - `-tsk_m`
  - `-nhk_m`
  - `-npk_m`
  - `-ivpk_m`
  - `-ovpk_m`
  - `-tpk_m`

## Testing Helpers

From `accounts/src/testing/index.ts`:

- `getInitialTestAccountsData()`
- `generateSchnorrAccounts(numberOfAccounts)`
- exported constants:
  - `INITIAL_TEST_ACCOUNT_SALTS`
  - `INITIAL_TEST_ENCRYPTION_KEYS`
  - `INITIAL_TEST_SECRET_KEYS`
  - `INITIAL_TEST_SIGNING_KEYS`

## Extraction / Verification Commands

Summarize the pinned account surface:

```bash
scripts/summarize_accounts_surface.sh /path/to/aztec-packages
```

Run the relevant package tests:

```bash
scripts/run_accounts_tests.sh /path/to/aztec-packages
scripts/run_accounts_tests.sh /path/to/aztec-packages accounts
scripts/run_accounts_tests.sh /path/to/aztec-packages key-store
```
