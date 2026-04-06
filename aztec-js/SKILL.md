---
name: aztec-js
description: Use this skill when building TypeScript applications with Aztec.js, including node/PXE connectivity, account lifecycle, contract deployment and interaction, transaction/fee handling, authwit authorization, event reads, and test automation.
license: Proprietary. LICENSE.txt has complete terms
compatibility: Pinned to aztec-packages v4.1.3 (commit e696cf677877d88626834b117a19b7db06bef217).
metadata:
  version_label: v4.1.3
  commit_sha: e696cf677877d88626834b117a19b7db06bef217
  source_map: aztec-packages/docs/internal_notes/llm_docs_skill_candidates.md
---

# Aztec.js Application Development

## Overview

Use this skill for Aztec TypeScript SDK work only.

Primary scope:

- network connection and node readiness
- wallet/account creation, deployment, and registration
- contract deployment and interaction from TypeScript
- transaction send/simulate/profile flows
- fee estimation and fee payment methods
- authwit creation and usage
- public/private event and log reads
- test workflow setup for local-network integration

Out of scope:

- Noir/Aztec.nr contract authoring and architecture
- operator/node/prover infrastructure runbooks

## Required Repository State

Use the upstream repository and pin:

- Repo: `https://github.com/AztecProtocol/aztec-packages`
- Tag: `v4.1.3`
- Commit: `e696cf677877d88626834b117a19b7db06bef217`

Checkout example:

```bash
git clone https://github.com/AztecProtocol/aztec-packages.git
cd aztec-packages
git checkout v4.1.3
git status
```

Expected status includes `HEAD detached at v4.1.3`.

## Operating Rules

- Keep guidance restricted to Aztec.js and related TypeScript SDK packages.
- Prefer subpath imports (for example `@aztec/aztec.js/node`, `@aztec/aztec.js/fields`) over root imports.
- Treat wallet metadata checks as mandatory before first public calls:
- `getContractMetadata(address)`
- `getContractClassMetadata(classId)`
- Use explicit `from` and explicit fee options on tx-producing calls.
- Use `simulate` before `send` when validating behavior or gas risk.
- Use `NO_WAIT` only when tx hash persistence and polling are implemented.
- Keep SKILL instructions procedural; place deep API index in `reference.md`.

## Quick Start

```bash
# Install SDK dependencies (choose one package manager)
npm install @aztec/aztec.js @aztec/accounts @aztec/wallets @aztec/noir-contracts.js
# or: yarn add ...
# or: pnpm add ...
```

```typescript
import { createAztecNodeClient, waitForNode } from "@aztec/aztec.js/node";
import { EmbeddedWallet } from "@aztec/wallets/embedded";

const node = createAztecNodeClient("http://localhost:8080");
await waitForNode(node);
const wallet = await EmbeddedWallet.create(node);
```

## Core Workflows

### 1. Connect and Validate Chain Context

- Create node client via `createAztecNodeClient(nodeUrl)`.
- Wait for readiness with `waitForNode(node)`.
- Read `node.getNodeInfo()` and persist chain/version values.
- Register/fetch accounts in wallet before tx usage.

### 2. Create and Deploy Accounts

- Use `wallet.createSchnorrAccount(secret, salt, signingKey?)`.
- Deploy via account deploy method (`getDeployMethod().send({...})`).
- For first deploy of a new account, use a payer that can fund fees.
- Confirm with `wallet.getContractMetadata(accountAddress)`.

### 3. Deploy and Register Contracts (SDK)

- Generate contract TS bindings from compiled artifacts.
- Deploy with `MyContract.deploy(wallet, ...ctorArgs).send({ from })`. Waited deploys return `{ contract, receipt, ... }`.
- Use deploy options when needed:
- `contractAddressSalt`, `universalDeploy`
- `skipClassPublication`, `skipInstancePublication`, `skipInitialization`
- `wait: NO_WAIT`
- Verify readiness with metadata APIs before public interactions.
- Register externally deployed contracts via `wallet.registerContract(...)`.

### 4. Send Transactions Safely

- Build calls from `contract.methods.<fn>(...)`.
- Use `.simulate({ from })` for preflight behavior checks; returns `{ result, ... }`.
- Use `.send({ from, fee?, wait? })` for state changes; waited sends return `{ receipt, ... }`, `NO_WAIT` sends return `{ txHash, ... }`.
- For atomic multi-call flows, use `new BatchCall(wallet, [call1, call2, ...])`. Waited `BatchCall.send()` follows the same return shape (`{ receipt, ... }`).
- If using no-wait mode, poll receipt with node APIs.

### 5. Read Data and Events

- Use `simulate` for typed state reads (private/public/utility); `.simulate()` returns `{ result, ... }`, not the raw value.
- Read public events with `getPublicEvents(node, Contract.events.EventName, filter)`. Returns `{ events, maxLogsHit }`.
- Read private events with `wallet.getPrivateEvents(eventDef, filter)`.
- Use raw logs only when ABI-level decoding is not required.

### 6. Fees and Gas Strategy

- Default method: account pays with Fee Juice.
- Estimate gas with `simulate({ fee: { estimateGas: true } })`.
- Use payment-method classes for supported non-default payment:
- `SponsoredFeePaymentMethod`
- `FeeJuicePaymentMethodWithClaim`
- Avoid `PrivateFeePaymentMethod` and `PublicFeePaymentMethod` for mainnet-targeted flows; they are deprecated upstream.
- Set explicit gas settings when reliability matters.

### 7. Authwit

- Private authwit: create witness and include in tx `authWitnesses`.
- Public authwit: register/revoke authorization via `SetPublicAuthwitContractInteraction`.
- Arbitrary intent authwit: hash payload and sign as `IntentInnerHash`.
- Treat nonces as mandatory replay protection.

### 8. Testing

- Use a local network and `EmbeddedWallet`/test wallet adapters.
- Use prefunded local accounts for deterministic test setup.
- Use `.simulate()` for assertions and failure-path checks.
- Use `.send()` for integration behavior and receipt-level assertions.

### 9. API Coverage and Discovery

- This skill covers the full available devnet TypeScript API corpus listed in `reference.md`.
- Package-level surface (classes/interfaces/functions/types/enums) is mapped there.
- Use `scripts/api_surface_summary.sh` to re-generate API section counts from pinned docs.

## Tooling / Commands

```bash
# preflight checks for Aztec.js dev env
scripts/preflight_aztec_js.sh http://localhost:8080

# install SDK packages with selected package manager
scripts/install_aztec_js_deps.sh npm

# wait for node JSON-RPC readiness
scripts/wait_for_aztec_node.sh http://localhost:8080

# summarize full API surface from a pinned aztec-packages checkout
scripts/api_surface_summary.sh /path/to/aztec-packages

# run a TS entrypoint via tsx
scripts/run_ts_example.sh ./src/index.ts
```

## Edge Cases and Failure Handling

- `Cannot find the leaf for nullifier` on deploy:
class publication/instance publication settings likely incompatible with call path.
- Contract deploy tx mined but public calls fail:
check `isContractPublished` and class registration metadata.
- `simulate` succeeds but `send` fails:
network-only checks (publication/init/fees) likely missing.
- `Timeout awaiting isMined` or delayed receipts:
handle as pending; poll by tx hash instead of treating as terminal failure.
- Public authwit seems ignored:
verify public authwit registration tx was mined and nonce/action tuple matches.
- Private event read returns empty unexpectedly:
verify `scopes`, caller registration, and block-range filter.

## Next Steps / Related Files

- Use `reference.md` for full API package coverage and method maps.
- Use `patterns.md` for reusable copy-ready Aztec.js snippets.
- Use `scripts/` for repeatable local workflow helpers.
