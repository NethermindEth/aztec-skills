# PXE Reference

## Scope and Pin

- Skill: `aztec-pxe`
- Version label: `v4.2.0`
- Commit SHA: `f8c89cf4345df6c4ca9e66ea9b738e96070abc5a`
- Primary source map: `yarn-project/pxe`
- Upstream repo: `https://github.com/AztecProtocol/aztec-packages`

## Required Checkout State

```bash
git clone https://github.com/AztecProtocol/aztec-packages.git
cd aztec-packages
git checkout v4.2.0
git status
git rev-parse HEAD
```

Expected:

- `HEAD detached at v4.2.0`
- `f8c89cf4345df6c4ca9e66ea9b738e96070abc5a`

## Primary Source Anchors

- `yarn-project/pxe/README.md`
- `yarn-project/pxe/src/**`

Key roots used by this skill:

- `src/pxe.ts`
- `src/notes_filter.ts`
- `src/block_synchronizer/**`
- `src/contract_sync/**`
- `src/notes/**`
- `src/events/**`
- `src/tagging/**`
- `src/contract_function_simulator/oracle/**`
- `src/debug/pxe_debug_utils.ts`
- `src/entrypoints/server/**`
- `src/entrypoints/client/lazy/**`
- `src/entrypoints/pxe_creation_options.ts`

## Package Entrypoints and Exports

From `yarn-project/pxe/package.json`:

- `@aztec/pxe/server`
- `@aztec/pxe/client/lazy`
- `@aztec/pxe/client/bundle`
- `@aztec/pxe/simulator`
- `@aztec/pxe/config`

Server/client entrypoints re-export:

- `PXE` class and related types from `src/pxe.ts`
- access scope and note filter types
- config helpers and storage exports
- `createPXE(...)` helpers from entrypoint `utils.ts`
- `ORACLE_VERSION` constant from `src/oracle_version.ts`
- `PXECreationOptions` from `src/entrypoints/pxe_creation_options.ts`

## Public PXE API Map (`src/pxe.ts`)

Core reads/registration:

- `getSyncedBlockHeader()`
- `getContractInstance(address)`
- `getContractArtifact(classId)`
- `registerAccount(secretKey, partialAddress)`
- `registerSender(sender)` / `getSenders()` / `removeSender(sender)`
- `getRegisteredAccounts()`
- `registerContractClass(artifact)`
- `registerContract({ instance, artifact? })`
- `updateContract(contractAddress, artifact)`
- `getContracts()`

Execution lifecycle:

- `simulateTx(txRequest, opts: SimulateTxOpts)` → `Promise<TxSimulationResult>`
  - `opts.simulatePublic: boolean`
  - `opts.skipTxValidation?: boolean`
  - `opts.skipFeeEnforcement?: boolean`
  - `opts.skipKernels?: boolean`
  - `opts.scopes: AztecAddress[]` (required; `'ALL_SCOPES'` no longer accepted)
  - `opts.overrides?: SimulationOverrides` — inject simulation-time contract instances/artifacts (requires `skipKernels: true`)
- `profileTx(txRequest, opts: ProfileTxOpts)` → `Promise<TxProfileResult>`
  - `opts.profileMode: 'full' | 'execution-steps' | 'gates'`
  - `opts.skipProofGeneration?: boolean` (default: `true`)
  - `opts.scopes: AztecAddress[]` (required; `'ALL_SCOPES'` no longer accepted)
  - result: `{ executionSteps: PrivateExecutionStep[], stats: { timings: ProvingTimings, nodeRPCCalls } }`
- `proveTx(txRequest, scopes: AztecAddress[])` → `Promise<TxProvingResult>`
  - result: `{ privateExecutionResult, publicInputs: PrivateKernelTailCircuitPublicInputs, chonkProof }`
  - `publicInputs` is non-optional
- `executeUtility(call: FunctionCall, opts: ExecuteUtilityOpts)` → `Promise<UtilityExecutionResult>`
  - `opts.authwits?: AuthWitness[]`
  - `opts.scopes: AztecAddress[]` (required; `'ALL_SCOPES'` no longer accepted)
  - result includes raw field outputs plus optional simulation stats

Events/debug/lifecycle:

- `getPrivateEvents(eventSelector: EventSelector, filter: PrivateEventFilter)` → `PackedPrivateEvent[]`
- `debug.sync()` — force block sync, blocks until complete
- `debug.getNotes(filter: NotesFilter)` → `Promise<NoteDao[]>` — diagnostics only
  - `NotesFilter`: `{ contractAddress, owner?, storageSlot?, status?, siloedNullifier?, scopes }`
- `stop()` — shut down job queue cleanly

## `PXECreationOptions` (`src/entrypoints/pxe_creation_options.ts`)

Third argument to `createPXE(aztecNode, config, options?)`:

- `loggerActorLabel?: string` — actor label for log output (e.g. `'pxe-0'`, `'pxe-test'`)
- `loggers?: { store?: Logger; pxe?: Logger; prover?: Logger }` — override individual loggers
- `proverOrOptions?: PrivateKernelProver | BBPrivateKernelProverOptions` — custom prover
- `store?: AztecAsyncKVStore` — persistent store; if omitted, an LMDB store is created from config
- `simulator?: CircuitSimulator` — custom circuit simulator

## Access Scopes Semantics

Scopes are now passed as `scopes: AztecAddress[]` directly on the PXE option types (`SimulateTxOpts`, `ProfileTxOpts`, `ExecuteUtilityOpts`). The v4.1.x `AccessScopes` alias (`'ALL_SCOPES' | AztecAddress[]`) and the `src/access_scopes.ts` module were removed in v4.2.0.

- `AztecAddress[]`: only listed accounts' private state and keys are accessible
- `[]`: deny-all (intentionally skip sync and data access)
- To emulate the prior "all scopes" behavior, enumerate registered accounts:

```typescript
const scopes = (await pxe.getRegisteredAccounts()).map(a => a.address);
```

Operational impact:

- scopes affect contract sync coverage and key validation permissions
- private event filter requires non-empty scope list
- capsule operations are scope-enforced at the PXE level: a contract that touches capsules scoped to an address not in the tx's `scopes` list fails with `Scope 0x… is not in the allowed scopes list: [...]`; `AztecAddress::zero()` is always permitted (global scope)
- empty scopes can intentionally skip sync and data access

## Tagging and Sync File Map

Sender-side tagging index progression:

- `src/tagging/sender_sync/sync_sender_tagging_indexes.ts`
- `src/storage/tagging_store/sender_tagging_store.ts`

Recipient-side private log loading:

- `src/tagging/recipient_sync/load_private_logs_for_sender_recipient_pair.ts`
- `src/storage/tagging_store/recipient_tagging_store.ts`

Shared tagging constants and utilities:

- `src/tagging/constants.ts`
- `src/tagging/get_all_logs_by_tags.ts`
- `src/logs/log_service.ts`

## Notes and Private Events Flow

Notes:

- `src/notes/note_service.ts`
- `src/storage/note_store/**`

Private events:

- `src/events/event_service.ts`
- `src/events/private_event_filter_validator.ts`
- `src/storage/private_event_store/**`

`getPrivateEvents` filter constraints:

- `contractAddress`: required
- `scopes`: required and non-empty
- range semantics: `[fromBlock, toBlock)`

## Oracle and Debug Anchors

Oracle versions and handlers:

- `src/oracle_version.ts`
- `src/bin/check_oracle_version.ts`
- `src/contract_function_simulator/oracle/oracle.ts`
- `src/contract_function_simulator/oracle/interfaces.ts`
- `src/contract_function_simulator/oracle/private_execution_oracle.ts`
- `src/contract_function_simulator/oracle/utility_execution_oracle.ts`

Debug helpers:

- `src/debug/pxe_debug_utils.ts`

## Extraction / Verification Commands

Summarize surface from pinned checkout:

```bash
scripts/summarize_pxe_surface.sh /path/to/aztec-packages
```

Run package tests:

```bash
scripts/run_pxe_tests.sh /path/to/aztec-packages
```

Run oracle compatibility check:

```bash
scripts/check_oracle_version.sh /path/to/aztec-packages
```
