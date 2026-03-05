# Aztec Skills Roadmap (Developer Focus)

This roadmap identifies additional Aztec skills worth adding to this repository, based on a review of:

- `/home/ametel/source/aztec-packages/yarn-project`
- Existing skills in this repo:
  - `aztec-contracts`
  - `aztec-deployment`
  - `aztec-js`
  - `aztec-testing`
  - `aztec-wallet-sdk`

Goal: expand practical coverage for Aztec developers while avoiding overlap with the current skill set.

## Priority 1: Add Next (developer-facing)

### 1. `aztec-pxe` **COMPLETED**
Status:
- Implemented on March 6, 2026.
- Skill path: `/home/ametel/source/aztec-skills/aztec-pxe`

Scope:
- Private execution lifecycle
- Note discovery/synchronization patterns
- Tagging (sender/recipient)
- Private events and oracle/debug workflows

Why:
- PXE is central for private state behavior and one of the most common integration/debug pain points.
- Current skills touch PXE indirectly but do not provide a dedicated operational workflow.

Primary source anchors:
- `/home/ametel/source/aztec-packages/yarn-project/pxe/README.md`
- `/home/ametel/source/aztec-packages/yarn-project/pxe/src`

### 2. `aztec-accounts`
Scope:
- Account flavors (Schnorr, ECDSA, SingleKey)
- Account abstraction entrypoints and transaction routing
- Keystore integration expectations
- Account deployment and wallet reconstruction patterns

Why:
- Accounts are a core developer concern separate from generic Aztec.js usage.
- This area has a distinct API and security model worth isolating into one skill.

Primary source anchors:
- `/home/ametel/source/aztec-packages/yarn-project/accounts/README.md`
- `/home/ametel/source/aztec-packages/yarn-project/entrypoints/README.md`
- `/home/ametel/source/aztec-packages/yarn-project/key-store/README.md`

### 3. `aztec-avm`
Scope:
- Public execution semantics
- AVM gas, memory, state, call model
- Opcode-level debugging and troubleshooting

Why:
- AVM has deep, dedicated docs and is conceptually distinct from contract authoring skill.
- Critical for developers debugging public execution behavior/performance.

Primary source anchors:
- `/home/ametel/source/aztec-packages/yarn-project/simulator/README.md`
- `/home/ametel/source/aztec-packages/yarn-project/simulator/docs/avm/README.md`
- `/home/ametel/source/aztec-packages/yarn-project/simulator/docs/avm/*.md`

### 4. `aztec-cli-localnet`
Scope:
- Local network lifecycle
- CLI workflows across `aztec`, `aztec-cli`, and `aztec-wallet`
- Environment setup and failure recovery paths

Why:
- Developers rely heavily on CLI/localnet for iteration.
- Current deployment/testing skills do not fully capture full localnet operational loops.

Primary source anchors:
- `/home/ametel/source/aztec-packages/yarn-project/aztec/README.md`
- `/home/ametel/source/aztec-packages/yarn-project/cli/README.md`
- `/home/ametel/source/aztec-packages/yarn-project/cli-wallet/README.md`
- `/home/ametel/source/aztec-packages/yarn-project/cli/src/cmds`
- `/home/ametel/source/aztec-packages/yarn-project/cli-wallet/src/cmds`

### 5. `aztec-txe`
Scope:
- TXE session state machine (`TOP_LEVEL`, `PRIVATE`, `PUBLIC`, `UTILITY`)
- Noir foreign call handling and RPC translation
- Deterministic test execution internals

Why:
- TXE is a specialized but high-value developer workflow for deep testing/debugging.
- Not covered by current testing skill at internal architecture depth.

Primary source anchors:
- `/home/ametel/source/aztec-packages/yarn-project/txe/src/txe_session.ts`
- `/home/ametel/source/aztec-packages/yarn-project/txe/src/rpc_translator.ts`
- `/home/ametel/source/aztec-packages/yarn-project/txe/src/index.ts`
- `/home/ametel/source/aztec-packages/yarn-project/txe/package.json`

## Priority 2: Protocol/Infra-Developer Expansion

### 6. `aztec-consensus`
Scope:
- Sequencer timing model (sub-slots, deadlines)
- Block proposal/checkpoint proposal flow
- Validator attestation logic and invariants

Primary source anchors:
- `/home/ametel/source/aztec-packages/yarn-project/sequencer-client/src/sequencer/README.md`
- `/home/ametel/source/aztec-packages/yarn-project/validator-client/README.md`
- `/home/ametel/source/aztec-packages/yarn-project/sequencer-client/README.md`

### 7. `aztec-p2p-txpool`
Scope:
- TxPoolV2 state machine and eviction rules
- Gossipsub peer scoring and tuning
- Batch transaction requester behavior and deadlines

Primary source anchors:
- `/home/ametel/source/aztec-packages/yarn-project/p2p/src/mem_pools/tx_pool_v2/README.md`
- `/home/ametel/source/aztec-packages/yarn-project/p2p/src/services/gossipsub/README.md`
- `/home/ametel/source/aztec-packages/yarn-project/p2p/src/services/reqresp/batch-tx-requester/README.md`
- `/home/ametel/source/aztec-packages/yarn-project/p2p/README.md`

### 8. `aztec-state-sync`
Scope:
- Archiver sync model and reorg handling
- Checkpoint/message syncpoints
- World-state reconciliation/commit-rollback semantics

Primary source anchors:
- `/home/ametel/source/aztec-packages/yarn-project/archiver/README.md`
- `/home/ametel/source/aztec-packages/yarn-project/archiver/src/l1/README.md`
- `/home/ametel/source/aztec-packages/yarn-project/world-state/README.md`

### 9. `aztec-l1-publisher`
Scope:
- L1 contract wrappers and typed boundaries
- L1 transaction lifecycle (send/monitor/speed-up/cancel)
- Blob sourcing and storage strategy for propose txs

Primary source anchors:
- `/home/ametel/source/aztec-packages/yarn-project/ethereum/src/contracts/README.md`
- `/home/ametel/source/aztec-packages/yarn-project/ethereum/src/l1_tx_utils/README.md`
- `/home/ametel/source/aztec-packages/yarn-project/blob-client/README.md`

## Suggested Delivery Sequence

1. `aztec-pxe`
2. `aztec-accounts`
3. `aztec-avm`
4. `aztec-cli-localnet`
5. `aztec-txe`
6. `aztec-consensus`
7. `aztec-p2p-txpool`
8. `aztec-state-sync`
9. `aztec-l1-publisher`

Rationale:
- Start with app-developer impact and day-to-day debugging value.
- Then expand into node/protocol internals for advanced contributors.

## Notes on Overlap and Boundaries

- `aztec-wallet-sdk` already exists and should remain separate from `aztec-js`.
- `aztec-contracts` should stay focused on Noir/Aztec.nr authoring patterns; avoid AVM internals there.
- `aztec-testing` should keep test workflow guidance, while `aztec-txe` can specialize in TXE internals.
- `aztec-deployment` should remain deployment-specific; localnet operational runbooks belong in `aztec-cli-localnet`.
