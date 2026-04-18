---
name: aztec-deployment
description: Use this skill when deploying Aztec smart contracts (not authoring them), including local-network and devnet deployment via aztec-wallet/Aztec.js, fee-payment setup, deterministic addresses, deployment verification, and contract registration workflows.
license: Proprietary. LICENSE.txt has complete terms
compatibility: Pinned to aztec-packages v4.2.0 (commit f8c89cf4345df6c4ca9e66ea9b738e96070abc5a).
metadata:
  version_label: v4.2.0
  commit_sha: f8c89cf4345df6c4ca9e66ea9b738e96070abc5a
  source_map: aztec-packages/docs/internal_notes/llm_docs_skill_candidates.md
---

# Aztec Contract Deployment

## Overview

Use this skill for contract deployment lifecycle work only:

- choosing deployment mode (class registration, instance publication, initialization)
- deploying with `aztec-wallet` (local network or devnet)
- deploying with Aztec.js (`deploy()`, `deployWithOpts()`, deployment options)
- fee payment setup (fee juice or sponsored FPC)
- deterministic deployment (salt / universal deploy)
- deployment verification and post-deploy registration

Out of scope:

- contract implementation/design (use `aztec-contracts`)
- node/sequencer/prover operations

## Required Repository State

Use the upstream repository and pin:

- Repo: `https://github.com/AztecProtocol/aztec-packages`
- Tag: `v4.2.0`
- Commit: `f8c89cf4345df6c4ca9e66ea9b738e96070abc5a`

Checkout example:

```bash
git clone https://github.com/AztecProtocol/aztec-packages.git
cd aztec-packages
git checkout v4.2.0
git status
```

Expected status includes `HEAD detached at v4.2.0`.

## Operating Rules

- Treat deployment as four independent switches: class registration, instance publication, initialization, and wallet registration.
- Never assume a contract is callable after tx inclusion; verify metadata states.
- For contracts with public functions, require class registration + instance publication.
- Use `--payment` explicitly on devnet.
- Use `--no-wait` only when tx tracking and retry logic are in place.
- Keep this skill deployment-only; avoid contract authoring advice here.
- `skipClassPublication: true` (CLI `--no-class-registration`) cannot be used for contracts that combine public functions with a private initializer: v4.2.0 emits a separate public init nullifier via an auto-enqueued public call, which requires the class to be published onchain.
- When deploying a contract that initializes private storage in its constructor (e.g. `SinglePrivateImmutable` / `SinglePrivateMutable`), use contract public keys when the contract owns private state, register the instance with its secret key before send, precompute the instance with the same address inputs the send path will derive (`contractAddressSalt` and `deployer: from`, or no deployer for `universalDeploy`/`NO_FROM`), and pass `additionalScopes: [instance.address]` on the Aztec.js deploy options so PXE scope enforcement permits the constructor's access to the instance's own private slot. `DeployAccountMethod` already injects the account address automatically; custom account deploy flows must preserve that behavior. Cross-contract nullification (e.g. an escrow withdraw tx) likewise requires `additionalScopes` listing every address whose notes are nullified.

## Quick Start

Local network (CLI):

```bash
aztec start --local-network
aztec-wallet import-test-accounts
aztec-wallet deploy token_contract@Token --args accounts:test0 Test TST 18 -f test0 -a token
aztec-wallet get-tx
```

Devnet (CLI, sponsored fees):

```bash
export NODE_URL=https://devnet.aztec-labs.com/
export SPONSORED_FPC_ADDRESS=0x280e5686a148059543f4d0968f9a18cd4992520fcd887444b8689bf2726a1f97

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

## Core Workflows

### 1. Preflight and Environment Selection

Local network:

- start `aztec start --local-network`
- use `aztec-wallet import-test-accounts`
- default fee method is usually `fee_juice`

Devnet:

- set `NODE_URL`
- register sponsored FPC in wallet
- create account with `--payment method=fpc-sponsored,fpc=<fpc-address>`
- expect slower blocks and occasional wait timeouts

### 2. Artifact Selection

Accepted artifact inputs for `aztec-wallet deploy`:

- package selector: `token_contract@Token`
- artifact file path: `./target/my_contract-MyContract.json`

Constructor args must match the selected initializer ABI.

### 3. Standard Deploy (CLI)

Base command:

```bash
aztec-wallet deploy <artifact> \
  --from <account> \
  --args <constructor-args...> \
  --alias <contract-alias>
```

Common options:

- `--init <fn>` to select a non-default initializer
- `--no-init` to skip constructor execution
- `--salt <hex>` for deterministic address
- `--universal` to remove sender from address derivation
- `--no-class-registration` to skip class publication
- `--no-public-deployment` to skip instance publication
- `--no-wait` to return tx hash immediately

### 4. Devnet Sponsored Deployment

For each fee-paying command, include:

```text
--payment method=fpc-sponsored,fpc=<sponsored-fpc-address>
```

Minimal safe sequence:

1. register sponsored FPC in wallet
2. create account with sponsored payment
3. deploy contract with same payment method
4. check tx/receipt status and verify contract metadata

### 5. Aztec.js Deployment

Canonical pattern:

```typescript
const { contract } = await MyContract.deploy(wallet, ...ctorArgs).send({ from });
```

Deployment options in `send(...)` include:

- `contractAddressSalt`
- `universalDeploy`
- `skipClassPublication`
- `skipInstancePublication`
- `skipInitialization`
- `wait` (including `NO_WAIT`)

Waited deploys return `{ contract, receipt, ... }`. `NO_WAIT` deploys return `{ txHash, ... }`.

Advanced:

- `deployWithOpts({ wallet, method: "public_constructor" }, ...args)`
- `deployMethod.getInstance({ contractAddressSalt, deployer })` for predicted address
- `deployMethod.register()` before batching deployment + call

### 6. Verification and Readiness Checks

Use wallet metadata checks after deployment:

```typescript
import { ContractInitializationStatus } from "@aztec/aztec.js/wallet";

const metadata = await wallet.getContractMetadata(contractAddress);
metadata.instance;
metadata.initializationStatus; // ContractInitializationStatus: INITIALIZED | UNINITIALIZED | UNKNOWN
metadata.isContractPublished;
```

Also verify class state:

```typescript
const classMeta = await wallet.getContractClassMetadata(metadata.instance!.currentContractClassId);
classMeta.isContractClassPubliclyRegistered;
```

Interpretation:

- Public calls require `isContractPublished = true`.
- Contracts with init-guarded functions require `metadata.initializationStatus === ContractInitializationStatus.INITIALIZED`. `UNKNOWN` means the instance is not registered in this wallet, so initialization cannot be determined — register the instance first.
- Public-function deployments require class registration.

### 7. External Contract Registration

If contract is deployed by another actor:

1. get metadata from node/wallet
2. register contract instance + artifact in wallet
3. if node cannot provide full instance data, reconstruct from deployment params

### 8. Transaction Handling

- Prefer synchronous waits for critical deploys.
- Use `--no-wait` or `NO_WAIT` only when you persist tx hash and poll receipts.
- On devnet, handle `"Timeout awaiting isMined"` as non-final; poll via `get-tx`/node APIs.

### 9. Local-to-Devnet Migration

- Replace local URL with devnet URL.
- Remove assumptions about pre-funded test accounts.
- Add explicit payment strategy (`--payment ...`) to all tx-producing commands.
- Increase timeout/retry budgets.

## Tooling / Commands

```bash
# Local network
aztec start --local-network
aztec-wallet import-test-accounts

# Deploy
aztec-wallet deploy <artifact-or-package@contract> --from <account> --args <...> -a <alias>

# Devnet fee payment
aztec-wallet register-contract --node-url "$NODE_URL" --alias sponsoredfpc <FPC_ADDRESS> SponsoredFPC --salt 0
aztec-wallet create-account --node-url "$NODE_URL" --alias my-wallet --payment method=fpc-sponsored,fpc=<FPC_ADDRESS>

# Tx inspection
aztec-wallet get-tx
aztec-wallet get-tx <tx-hash>
```

Use scripts in `scripts/` for repeatable flows:

- `scripts/preflight_deploy.sh`
- `scripts/register_sponsored_fpc.sh`
- `scripts/create_devnet_account.sh`
- `scripts/deploy_contract_wallet.sh`
- `scripts/deploy_devnet_contract.sh`

## Edge Cases and Failure Handling

- `Cannot find the leaf for nullifier` during deploy:
likely class publication was skipped for a contract requiring it; rerun without `--no-class-registration`.
- Public function call fails after deployment:
instance is likely not publicly deployed; avoid `--no-public-deployment` for public workflows.
- Deployment reports success but contract is not callable:
check initialization and publication states separately.
- `No transactions are needed to publish or initialize contract ...`:
expected for some private-only/no-initializer combinations under selected options.
- Devnet `Timeout awaiting isMined`:
treat as pending and query tx status by hash.
- Constructor argument mismatch:
check selected initializer (`--init`) and ABI ordering/types.

## Next Steps / Related Files

- Use `reference.md` for deployment-state matrix, command options, and troubleshooting runbooks.
- Use `patterns.md` for copy/paste local/devnet CLI and Aztec.js deployment patterns.
- Use `scripts/` for repeatable preflight and deployment wrappers.
