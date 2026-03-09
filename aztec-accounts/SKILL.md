---
name: aztec-accounts
description: Use this skill when working with Aztec account implementations and lifecycle flows, including Schnorr/ECDSA/SingleKey account flavors, account abstraction entrypoints, transaction routing, key-store integration, deployment, and wallet reconstruction.
license: Proprietary. LICENSE.txt has complete terms
compatibility: Pinned to aztec-packages v4.1.0-rc.1 (commit 77e5b3ca816702e2cee866aec1a0d6ce997e0ea6).
metadata:
  version_label: v4.1.0-rc.1
  commit_sha: 77e5b3ca816702e2cee866aec1a0d6ce997e0ea6
  source_map: aztec-packages/yarn-project/accounts
---

# Aztec Account Lifecycle and Routing

## Overview

Use this skill for Aztec account implementation and account-lifecycle work.

Primary scope:

- choosing and implementing account flavors (`Schnorr`, `ECDSA`, `SingleKey`)
- deterministic account creation inputs (`secret`, `salt`, signing key/public key)
- deployment via `AccountManager` and wallet account helpers
- reconstructing accounts and wallets from existing material
- account abstraction entrypoints and tx routing behavior
- account self-funded deployment and fee routing
- key-store expectations for key derivation, validation, and app-secret derivation

Out of scope:

- generic contract deployment and app interaction flows that do not depend on account internals (use `aztec-js` or `aztec-deployment`)
- direct PXE debugging beyond account registration/sync expectations (use `aztec-pxe`)
- wallet-provider connectivity or extension transport work (use `aztec-wallet-sdk`)

## Required Repository State

Use the upstream repository and pin:

- Repo: `https://github.com/AztecProtocol/aztec-packages`
- Tag: `v4.1.0-rc.1`
- Commit: `77e5b3ca816702e2cee866aec1a0d6ce997e0ea6`
- Primary roots:
  - `yarn-project/accounts`
  - `yarn-project/entrypoints`
  - `yarn-project/key-store`

Checkout example:

```bash
git clone https://github.com/AztecProtocol/aztec-packages.git
cd aztec-packages
git checkout v4.1.0-rc.1
git status
```

Expected status includes `HEAD detached at v4.1.0-rc.1`.

## Operating Rules

- Treat `secret + salt + account flavor + signing key/public key` as the account identity tuple. Change any of them and the address changes.
- Prefer `Schnorr` for most production use cases, `ECDSA` for Ethereum-style signer integrations, and `SingleKey` only for testing.
- Distinguish the account secret from the signing key:
  - the secret derives the privacy/viewing/nullifier/tagging keys
  - the signing key authorizes authwits for the account contract
- Prefer eager account exports in Node.js. The `lazy` account modules explicitly note they are incompatible with Node.js at this pin.
- Base account contracts in `@aztec/accounts` only define account behavior; actual deploy/recovery lifecycle is wired through `AccountManager` and wallet helpers.
- Reconstruct accounts with the exact same flavor and key material used originally. Recovery is deterministic; it is not an address lookup service.
- When using bare `AccountManager.create(...)`, register the resulting instance/artifact with the wallet/PXE before relying on it for interactions.
- For self-funded deployment, understand that fee execution is wrapped back through the account entrypoint via `AccountEntrypointMetaPaymentMethod`.
- Key stores should gate key access and signatures with explicit user authorization; do not treat PXE as a secure private-key vault.

## Quick Start

```bash
# install core account-related packages
scripts/install_aztec_accounts_deps.sh npm
```

```typescript
import { Fr, GrumpkinScalar } from '@aztec/aztec.js/fields';
import { createAztecNodeClient, waitForNode } from '@aztec/aztec.js/node';
import { EmbeddedWallet } from '@aztec/wallets/embedded';

const node = createAztecNodeClient('http://localhost:8080');
await waitForNode(node);

const wallet = await EmbeddedWallet.create(node);
const accountManager = await wallet.createSchnorrAccount(
  Fr.random(),
  Fr.random(),
  GrumpkinScalar.random(),
);

const deployMethod = await accountManager.getDeployMethod();
await deployMethod.send({ from: existingFundedAccountAddress });
console.log(accountManager.address.toString());
```

## Core Workflows

### 1. Choose the Right Account Flavor

- `SchnorrAccountContract`
  - Grumpkin signing key for auth
  - separate account secret for privacy keys
  - recommended default
- `EcdsaKAccountContract`
  - secp256k1 auth key
  - use for Ethereum-wallet style integrations
- `EcdsaRAccountContract`
  - secp256r1 auth key
  - use when the signer lives on P-256 infrastructure
- `EcdsaRSSHAccountContract`
  - secp256r1 auth via SSH agent signing
  - recovery depends on the same SSH public key identity
- `SingleKeyAccountContract`
  - one Grumpkin key for encryption and auth
  - testing-only; no initializer path

### 2. Compute and Inspect a Deterministic Account Before Deployment

- Use wallet helpers such as `EmbeddedWallet.createSchnorrAccount(...)` or `AccountManager.create(...)`.
- Read the predicted address and public keys from `accountManager.getCompleteAddress()`.
- For Schnorr-only address prediction without wallet setup, use `getSchnorrAccountContractAddress(secret, salt, signingKey?)`.
- Use `accountManager.getInstance()` when you need the contract instance definition before publishing.

### 3. Deploy an Account Contract

- Build the manager through wallet helpers or `AccountManager.create(...)`.
- Call `accountManager.getDeployMethod()`.
- Use an externally funded payer for the simplest flow:
  - `await deployMethod.send({ from: fundedAccountAddress })`
- Account deployments force `universalDeployment: true`.
- At this pin, deploy-account defaults also bias toward:
  - `skipClassPublication: true`
  - `skipInstancePublication: true`
  - `skipInitialization: false`
- If the account is self-funding, `DeployAccountMethod` routes fee execution through `AccountEntrypointMetaPaymentMethod`.

### 4. Reconstruct an Existing Account or Wallet

- Recovery is deterministic:
  - same secret
  - same salt
  - same account flavor
  - same signing key or signing public key material
- Embedded wallet pattern:
  - recreate the wallet
  - call the same `createSchnorrAccount(...)`, `createECDSAKAccount(...)`, or `createECDSARAccount(...)`
  - the wallet re-registers the account contract instance/artifact and rebuilds the same address
- Lower-level pattern:
  - instantiate the account contract class directly
  - call `AccountManager.create(wallet, secret, contract, salt)`
  - register the instance/artifact with the wallet or PXE
  - call `getAccount()` for the runtime account object

### 5. Understand Account Abstraction Routing

- `DefaultAccountContract` wires a `BaseAccount` around `DefaultAccountEntrypoint`.
- `DefaultAccountEntrypoint`:
  - encodes app calls into an account `entrypoint(...)` payload
  - injects auth witnesses for the encoded call hash
  - applies tx options such as `cancellable`, `txNonce`, and fee-routing mode
- `DefaultEntrypoint`:
  - direct single-call private entrypoint
  - rejects multi-call payloads
- `DefaultMultiCallEntrypoint`:
  - wraps multiple calls through the protocol multicall entrypoint
  - used by `SignerlessAccount`
- Use the account entrypoint whenever the account contract must authorize or fee-route the action.

### 6. Fee Routing Semantics

- `AccountFeePaymentMethodOptions` controls how the account entrypoint treats fees:
  - `EXTERNAL`
  - `PREEXISTING_FEE_JUICE`
  - `FEE_JUICE_WITH_CLAIM`
- `AccountEntrypointMetaPaymentMethod` computes these automatically when self-funding deployment:
  - no inner calls => preexisting Fee Juice
  - inner fee-claim calls => Fee Juice with claim
  - external payer => external
- For self-deployment, deployment payload construction happens before fee payload wrapping so the account contract can exist before paying.

### 7. Key-Store Integration Expectations

- `KeyStore` is a secure input component for PXE, not just a convenience map.
- Core responsibilities:
  - create/add accounts from a secret and partial address
  - persist master secret keys and public keys by account
  - derive app-scoped secrets for kernel validation
  - answer key-validation requests without exposing unnecessary material
- Important methods:
  - `createAccount()`
  - `addAccount(sk, partialAddress)`
  - `getAccounts()` / `hasAccount(account)`
  - `getKeyValidationRequest(pkMHash, contractAddress)`
  - `getMasterIncomingViewingSecretKey(account)`
  - `getAppOutgoingViewingSecretKey(account, app)`
  - `getMasterSecretKey(pkM)`
  - `accountHasKey(account, pkMHash)`
- Key-store UX/security expectation from the package README:
  - prompt before signatures or sensitive key release
  - protect stored secrets with encryption and recovery controls

### 8. Testing and Local-Network Helpers

- `@aztec/accounts/testing` exposes deterministic/local-network-friendly helpers:
  - `getInitialTestAccountsData()`
  - `generateSchnorrAccounts(numberOfAccounts)`
- Use these when you need known account secrets, salts, signing keys, and predicted addresses for tests.

### 9. README vs Code Surface

- The pinned `yarn-project/accounts/README.md` still shows `getSchnorrAccount(...)` and `getSchnorrWallet(...)`.
- The current code surface in this pin is centered on:
  - account contract classes in `@aztec/accounts/*`
  - address helpers such as `getSchnorrAccountContractAddress(...)`
  - lifecycle wiring through wallet helpers and `AccountManager`
- Prefer code-backed patterns from `reference.md` and `patterns.md` over the README snippets when they differ.

## Tooling / Commands

```bash
# preflight node/package-manager checks and optional source-tree validation
scripts/preflight_aztec_accounts.sh [node-url] [aztec-packages-dir]

# install account-related SDK packages
scripts/install_aztec_accounts_deps.sh <npm|yarn|pnpm> [version]

# summarize exports and core source anchors from an aztec-packages checkout
scripts/summarize_accounts_surface.sh <aztec-packages-dir>

# run package tests for accounts, entrypoints, and key-store
scripts/run_accounts_tests.sh <aztec-packages-dir> [accounts|entrypoints|key-store]
```

## Edge Cases and Failure Handling

- Recreated account address does not match expected address:
verify the exact flavor, secret, salt, and signing key/public key used for the original account.
- Account can be computed locally but cannot see notes/events:
the instance/artifact or account registration path was likely not re-established in the wallet/PXE.
- `getDeployMethod()` throws about missing initializer:
that account contract does not expose an initializer path at this pin.
- Self-funded account deployment fails:
inspect the wrapped payment method and resulting `AccountFeePaymentMethodOptions`.
- `SingleKey` used in production-like flows:
replace it with `Schnorr` or `ECDSA`; `SingleKey` is marked testing-only.
- `lazy` account modules fail under Node:
expected at this pin; switch to eager imports.
- SSH-backed ECDSA recovery fails:
confirm the same SSH public-key identity is available to the agent.

## Next Steps / Related Files

- Use `reference.md` for the pinned source map and API/file coverage.
- Use `patterns.md` for reusable deployment and reconstruction snippets.
- Use `scripts/` for repeatable setup, inspection, and test workflows.
