---
name: aztec-pxe
description: Use this skill when implementing or debugging direct PXE workflows in TypeScript, including private execution lifecycle, note discovery/synchronization, sender/recipient tagging, private events, scopes, and oracle/debug checks.
license: Proprietary. LICENSE.txt has complete terms
compatibility: Pinned to aztec-packages v4.0.0-devnet.2-patch.1 (commit 1dbe894364c0d179d2f6443b47887766bbf51343).
metadata:
  version_label: v4.0.0-devnet.2-patch.1
  commit_sha: 1dbe894364c0d179d2f6443b47887766bbf51343
  source_map: aztec-packages/yarn-project/pxe
---

# PXE Private Execution Operations

## Overview

Use this skill for direct `@aztec/pxe` work.

Primary scope:

- private execution lifecycle (`simulateTx`, `profileTx`, `proveTx`, `simulateUtility`)
- note discovery/synchronization behavior and scope control
- sender/recipient tagging workflows
- private event retrieval and filter handling
- oracle compatibility checks and PXE debug helpers

Out of scope:

- Noir/Aztec.nr contract authoring (use `aztec-contracts`)
- generic Aztec.js app flows that do not need direct PXE control (use `aztec-js`)
- deployment-focused procedures (use `aztec-deployment`)

## Required Repository State

Use the upstream repository and pin:

- Repo: `https://github.com/AztecProtocol/aztec-packages`
- Tag: `v4.0.0-devnet.2-patch.1`
- Commit: `1dbe894364c0d179d2f6443b47887766bbf51343`
- Source root: `yarn-project/pxe`

Checkout example:

```bash
git clone https://github.com/AztecProtocol/aztec-packages.git
cd aztec-packages
git checkout v4.0.0-devnet.2-patch.1
git status
```

Expected status includes `HEAD detached at v4.0.0-devnet.2-patch.1`.

## Operating Rules

- Treat PXE as a serialized execution environment: high-level jobs are queued and run one-at-a-time.
- Always pass explicit `scopes` unless intentionally using `'ALL_SCOPES'`.
- Register recipient accounts with `registerAccount(...)` before expecting note or private event visibility.
- Register counterpart senders with `registerSender(...)` when syncing tagged logs across peers.
- Use `simulateTx` before `proveTx`; only prove after simulation and sync checks pass.
- For private events, `filter.scopes` must be non-empty and block range follows `[fromBlock, toBlock)`.
- Use `debug.getNotes(...)` only for diagnostics; prefer contract utility functions for production reads.
- If oracle interface changes, run oracle version checks before trusting cross-version simulations.

## Quick Start

```bash
# install dependencies in your app
scripts/install_pxe_deps.sh npm

# check node reachability + optional pxe source path validation
scripts/preflight_pxe.sh http://localhost:8080 /path/to/aztec-packages/yarn-project/pxe
```

```typescript
import { createAztecNodeClient, waitForNode } from '@aztec/aztec.js/node';
import { createPXE, getPXEConfig } from '@aztec/pxe/server';

const node = createAztecNodeClient('http://localhost:8080');
await waitForNode(node);

const pxe = await createPXE(node, getPXEConfig(), {
  loggerActorLabel: 'app-pxe',
});
```

## Core Workflows

### 1. Boot PXE and Anchor State

- Build node client and wait for JSON-RPC readiness.
- Create PXE via `createPXE(...)` from `@aztec/pxe/server` or `@aztec/pxe/client/lazy`.
- Use `getSyncedBlockHeader()` to confirm the current anchor block before execution.

### 2. Register Accounts, Senders, and Contract Data

- Register account recipients via `registerAccount(secretKey, partialAddress)`.
- Register known counterpart senders via `registerSender(senderAddress)`.
- Register artifacts/instances via `registerContractClass(...)` and `registerContract(...)`.
- Verify registration with `getRegisteredAccounts()`, `getSenders()`, `getContractInstance()`.

### 3. Run Private Execution Lifecycle

- `simulateTx(txRequest, opts)` for private (and optional public) simulation.
  - `opts.overrides?: SimulationOverrides` injects simulation-time contract instances/artifacts (useful for testing).
- `profileTx(txRequest, { profileMode, scopes })` for execution/gate diagnostics.
  - `profileMode` values: `'full'` | `'execution-steps'` | `'gates'`.
- `proveTx(txRequest, scopes)` only after simulation correctness is confirmed.
  - Returns `TxProvingResult`; `publicInputs` is non-optional on the result.
- `simulateUtility(functionCall, { authwits, scopes })` for utility paths and sync-state calls.

### 4. Note Discovery and Synchronization

- PXE sync occurs before simulation/event operations; keep one execution flow per state transition.
- Contract sync is scope-aware; `[]` scopes deny access and skip sync.
- Use `debug.sync()` to force an explicit sync checkpoint when diagnosing stale state.
- Use `debug.getNotes({ contractAddress, owner?, storageSlot?, status?, siloedNullifier?, scopes })` for note-level diagnostics.

### 5. Tagging (Sender / Recipient)

- Sender-side index progression is maintained per directional secret `(sender, recipient, contract)`.
- Recipient-side log loading scans bounded windows of tagging indexes and updates aged/finalized indices.
- Registering sender addresses improves recipient decryption coverage for incoming private logs.
- If tags are reused unexpectedly, inspect pending/finalized index movement and tx inclusion timing.

### 6. Private Events

- Retrieve private events via `getPrivateEvents(eventSelector, filter)`.
- Required filter fields:
- `contractAddress`
- `scopes` (non-empty)
- Optional filters: `txHash`, `fromBlock`, `toBlock` (`toBlock` exclusive).
- If events are missing, ensure account registration, scope inclusion, and anchor sync point.

### 7. Oracle and Debug Workflows

- Verify oracle compatibility with `scripts/check_oracle_version.sh` against your pinned `aztec-packages` checkout.
- Use `utilityLog` outputs and simulation traces (`profileTx`) to localize oracle call failures.
- Treat `PXEDebugUtils` APIs as unstable and diagnostics-only.

### 8. Shutdown and Resource Hygiene

- Call `pxe.stop()` on teardown to end queued jobs cleanly.
- Preserve persistent store state across sessions when reproducing note/tagging issues.

## Tooling / Commands

```bash
# preflight node/package manager/source checks
scripts/preflight_pxe.sh [node-url] [pxe-dir]

# install core PXE dependencies
scripts/install_pxe_deps.sh <npm|yarn|pnpm> [version]

# wait for node JSON-RPC readiness
scripts/wait_for_aztec_node.sh <node-url> [timeout-seconds] [interval-seconds]

# run a TypeScript example via tsx
scripts/run_pxe_example.sh <entry-file.ts> [-- <extra-args...>]

# summarize pxe package exports + method surfaces
scripts/summarize_pxe_surface.sh <aztec-packages-dir>

# run @aztec/pxe package tests
scripts/run_pxe_tests.sh <aztec-packages-dir> [test-path-pattern]

# run oracle interface compatibility check
scripts/check_oracle_version.sh <aztec-packages-dir>
```

## Edge Cases and Failure Handling

- `At least one scope is required to get private events`:
provide non-empty `filter.scopes`.
- Missing private notes/events despite successful tx:
verify recipient account registration and scope membership.
- `Incompatible oracle version` error:
run oracle version check and align Aztec.nr/PXE versions.
- Simulations appear stale after chain changes:
force `debug.sync()` and re-run with fresh anchor block.
- Interleaved requests behave unpredictably:
avoid app-side concurrent PXE operation bursts; serialize user flows.
- Tagging sync does not advance:
verify sender registration and inspect finalized/aged tagging index windows.

## Next Steps / Related Files

- Use `reference.md` for source map and API/file coverage.
- Use `patterns.md` for reusable workflow snippets.
- Use `scripts/` for repeatable diagnostics and verification.
