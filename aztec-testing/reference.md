# Aztec Testing Reference

## Scope and Pin

- Skill: `aztec-testing`
- Version label: `v4.1.3`
- Commit SHA: `e696cf677877d88626834b117a19b7db06bef217`
- Primary source map: `docs/internal_notes/llm_docs_skill_candidates.md`
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

## Pinned Testing Source Corpus

Primary docs:

- `docs/docs-developers/docs/aztec-nr/testing_contracts.md`
- `docs/docs-developers/docs/aztec-js/how_to_test.md`
- `docs/docs-developers/docs/tutorials/testing_governance_rollup_upgrade.md`

Optional generated testing API subset (devnet only):

- `docs/static/aztec-nr-api/devnet/noir_aztec/test/**`
- `docs/static/aztec-nr-api/devnet/std/test/**`

Primary code fanout used by testing docs:

- `docs/examples/ts/aztecjs_testing/index.ts`
- `docs/examples/ts/aztecjs_connection/index.ts`
- `yarn-project/end-to-end/src/composed/e2e_local_network_example.test.ts`
- `yarn-project/end-to-end/src/composed/docs_examples.test.ts`
- `noir-projects/aztec-nr/aztec/src/test/helpers/test_environment.nr`
- `noir-projects/aztec-nr/aztec/src/test/helpers/test_environment/test/**`
- `noir-projects/noir-contracts/contracts/app/token_contract/src/test/**`
- `yarn-project/end-to-end/src/e2e_authwit.test.ts`
- `yarn-project/end-to-end/src/e2e_token_contract/transfer_in_private.test.ts`
- `yarn-project/end-to-end/src/e2e_token_contract/transfer_in_public.test.ts`

Remote pinned docs root:

- `https://github.com/AztecProtocol/aztec-packages/tree/v4.1.3/docs`

## TestEnvironment API Map

Source of truth:

- `noir-projects/aztec-nr/aztec/src/test/helpers/test_environment.nr`

### Environment lifecycle

- `TestEnvironment::new()`
- `next_block_number()`
- `last_block_number()`
- `last_block_timestamp()`

### Context creation

- `public_context(...)`
- `public_context_at(addr, ...)`
- `private_context(...)`
- `private_context_at(addr, ...)`
- `private_context_opts(PrivateContextOptions, ...)`
- `utility_context(...)`
- `utility_context_at(addr, ...)`

`PrivateContextOptions` supports:

- `new()`
- `at_anchor_block_number(u32)`
- `at_contract_address(AztecAddress)`

### Block/time control

- `set_next_block_timestamp(timestamp)`
- `advance_next_block_timestamp_by(duration)`
- `mine_block()`
- `mine_block_at(timestamp)`

### Account creation

- `create_light_account()`
- `create_contract_account()`

### Deployment

- `deploy(path)` then one of:
- `.with_private_initializer(caller, initializer_call)`
- `.with_public_initializer(caller, initializer_call)`
- `.without_initializer()`

### Contract call simulation/execution

- `call_private(from, private_call)`
- `view_private(from, private_static_call)`
- `execute_utility(utility_call)`
- `call_public(from, public_call)`
- `call_public_incognito(from, public_call)`
- `view_public(public_static_call)`
- `view_public_incognito(public_static_call)`

### Message/note discovery helpers

- `discover_note(note_message)`
- `discover_note_at(contract_addr, note_message)`

Experimental (not yet public API):

- `discover_event(event_message, recipient)`
- `discover_event_at(contract_addr, event_message, recipient)`

## Authwit Testing Surface

Noir helper module:

- `aztec::test::helpers::authwit`
- `add_private_authwit_from_call`
- `add_public_authwit_from_call`

Noir authwit constraints reflected by tests:

- private authwit requires contract accounts
- delegated caller binding must match authorization message
- replay/duplicate usage fails after nullifier emission
- self-calls must use zero nonce where enforced

TypeScript authwit APIs used in integration tests:

- `wallet.createAuthWit(authorizer, intent)`
- `SetPublicAuthwitContractInteraction.create(wallet, authorizer, intent, true|false)`
- `lookupValidity(wallet, authorizer, intent, witness)`
- `computeInnerAuthWitHash(...)`
- `computeInnerAuthWitHashFromAction(...)`
- `computeAuthWitMessageHash(...)`

## Noir Contract Testing Runbook

### 1. Compile and run

```bash
aztec compile
aztec test
```

Important:

- `aztec test` does not recompile changed contracts.
- Always compile first after contract edits.

### 2. Structure tests for reuse

Recommended shape:

- `src/test.nr` with module imports
- `src/test/utils.nr` for setup/assert helpers
- focused files such as `transfer.nr`, `authwit.nr`, `failure_cases.nr`

### 3. Choose account type intentionally

- fast baseline tests: `create_light_account()`
- authwit/delegation tests: `create_contract_account()`

### 4. Assert both positive and negative behavior

- positive assertions on balances/state transitions
- negative assertions with `should_fail` / `should_fail_with`
- unauthorized, overflow/underflow, missing authwit, wrong caller, replay

### 5. Time-sensitive logic

- use deterministic timestamp operations from `TestEnvironment`
- avoid relying on implicit timestamp movement

## TypeScript Integration Testing Runbook

### 1. Network + wallet setup

Core sequence:

1. `createAztecNodeClient(nodeUrl)`
2. `waitForNode(node)`
3. create wallet (`EmbeddedWallet` or test wallet wrapper)
4. load/register accounts

Account loading approaches:

- local-network friendly: `registerInitialLocalNetworkAccountsInWallet(wallet)`
- explicit test data: `getInitialTestAccountsData()` + `createSchnorrAccount(...)`

### 2. Contract integration test flow

1. deploy contract via generated binding — waited deploys return `{ contract, receipt, ... }`
2. verify baseline state with `.simulate(...)` — returns `{ result, ... }`, use `result` for assertions
3. apply state transition via `.send(...)` — waited sends return `{ receipt, ... }`
4. assert post-state with `.simulate(...)` — destructure `{ result }` for the value
5. include revert expectations with `.simulate(...).rejects`

### 3. Authwit integration test flow

Private:

1. construct action
2. create witness
3. execute with delegated caller and `authWitnesses`
4. assert replay or wrong-caller failure

Public:

1. register authwit in public registry (`SetPublicAuthwitContractInteraction.create(..., true)` then send)
2. execute delegated call
3. cancel authwit (`SetPublicAuthwitContractInteraction.create(..., false)` then send) when needed
4. assert unauthorized behavior after cancellation

## Canonical Testing Snippets (Path Index)

Noir examples:

- setup helpers:
- `noir-projects/noir-contracts/contracts/app/token_contract/src/test/utils.nr`
- private/public/authwit transfer tests:
- `.../transfer.nr`
- `.../transfer_in_private.nr`
- `.../transfer_in_public.nr`
- timestamp behavior tests:
- `noir-projects/aztec-nr/aztec/src/test/helpers/test_environment/test/time.nr`

TypeScript examples:

- docs example harness:
- `docs/examples/ts/aztecjs_testing/index.ts`
- local-network setup + lifecycle example:
- `yarn-project/end-to-end/src/composed/e2e_local_network_example.test.ts`
- docs-focused integration example:
- `yarn-project/end-to-end/src/composed/docs_examples.test.ts`
- authwit e2e:
- `yarn-project/end-to-end/src/e2e_authwit.test.ts`

## Common Failure Signatures

- `Unknown auth witness for message hash ...`
- `unauthorized`
- `Assertion failed: Invalid authwit nonce...`
- `Balance too low`
- arithmetic underflow/overflow messages for amount violations
- `Failed to get a note` when note-discovery setup is missing

## Governance Upgrade Testing (Advanced)

For L1 governance-driven rollup upgrade testing on local network, use:

- `docs/docs-developers/docs/tutorials/testing_governance_rollup_upgrade.md`

Use this path for protocol/governance integration scenarios, not routine contract unit tests.

## Distribution Rules

- Keep this skill self-contained for core Noir + TS test workflows.
- Prefer remote pinned references over machine-local absolute paths.
- Exclude nightly generated docs from derived corpora:
- `docs/static/typescript-api/nightly/**`
- `docs/static/aztec-nr-api/nightly/**`
