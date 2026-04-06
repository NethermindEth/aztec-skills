---
name: aztec-testing
description: Use this skill when testing Aztec smart contracts, including Noir tests with TestEnvironment and TypeScript integration tests with Aztec.js on local-network/devnet-like setups.
license: Proprietary. LICENSE.txt has complete terms
compatibility: Pinned to aztec-packages v4.1.3 (commit e696cf677877d88626834b117a19b7db06bef217).
metadata:
  version_label: v4.1.3
  commit_sha: e696cf677877d88626834b117a19b7db06bef217
  source_map: aztec-packages/docs/internal_notes/llm_docs_skill_candidates.md
---

# Aztec Contract Testing

## Overview

Use this skill for contract testing only:

- Noir contract tests using `TestEnvironment`
- TypeScript integration tests using `aztec.js`
- failure-path testing and authwit testing
- deterministic time and block progression in tests
- local-network test harness setup and execution

Out of scope:

- contract architecture/authoring decisions (use `aztec-contracts`)
- deployment-only operations (use `aztec-deployment`)
- full app SDK API documentation (use `aztec-js`)

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

- For Noir contract tests, always run `aztec test` (not `nargo test`).
- Re-run `aztec compile` before `aztec test` after contract changes.
- Use `create_contract_account()` whenever authwit behavior is under test.
- Use `create_light_account()` for faster non-authwit tests.
- In TypeScript integration tests, call `.simulate()` before `.send()` for safety and clearer failure assertions. Note that `.simulate()` returns `{ result, ... }` — use the `result` field for reads and assertions.
- Treat local-network node readiness as mandatory before test execution.
- Keep tests deterministic:
- avoid hidden inter-test state coupling
- assert both happy path and failure path
- for time-sensitive logic, advance time explicitly

## Quick Start

Noir tests:

```bash
scripts/preflight_aztec_testing.sh
scripts/run_noir_contract_tests.sh /path/to/contract/crate
```

TypeScript integration tests:

```bash
scripts/preflight_aztec_testing.sh http://localhost:8080
scripts/install_aztec_testing_deps.sh npm
scripts/run_ts_integration_tests.sh /path/to/ts-tests npm test http://localhost:8080
```

## Core Workflows

### 1. Noir Test Skeleton with `TestEnvironment`

- Create one `TestEnvironment` per test.
- Encapsulate repeated setup into helper functions (`setup(...)`).
- Deploy contracts through `env.deploy(...).with_*_initializer(...)` or `.without_initializer()`.

Minimal skeleton:

```rust
use crate::MyContract;
use aztec::{
    protocol::address::AztecAddress,
    test::helpers::test_environment::TestEnvironment,
};

pub unconstrained fn setup() -> (TestEnvironment, AztecAddress, AztecAddress) {
    let mut env = TestEnvironment::new();
    let owner = env.create_light_account();
    let initializer = MyContract::interface().constructor(owner);
    let contract = env.deploy("MyContract").with_public_initializer(owner, initializer);
    (env, contract, owner)
}

#[test]
unconstrained fn happy_path() {
    let (env, contract, owner) = setup();
    env.call_public(owner, MyContract::at(contract).set_value(42));
    assert_eq(env.view_public(MyContract::at(contract).get_value()), 42);
}
```

### 2. Noir Call-Type Coverage

Use the right call primitive for each assertion:

- `env.call_private(...)` for private state transitions
- `env.call_public(...)` for public state transitions
- `env.view_private(...)`/`env.view_public(...)` for static reads
- `env.execute_utility(...)` for unconstrained utility reads

### 3. Noir Authwit Tests

- Use contract accounts for authwit tests.
- Use authwit helpers:
- `add_private_authwit_from_call`
- `add_public_authwit_from_call`
- Include negative tests:
- missing authwit
- wrong caller
- replay / consumed authorization

### 4. Noir Failure and Revert Tests

- Use `#[test(should_fail)]` for generic failure checks.
- Use `#[test(should_fail_with = "...")]` for exact error matching.
- Add explicit unauthorized and over-limit tests for each sensitive path.

### 5. Noir Time and Block Control

Use `TestEnvironment` time controls for deterministic tests:

- `set_next_block_timestamp(timestamp)`
- `advance_next_block_timestamp_by(duration)`
- `mine_block()` / `mine_block_at(timestamp)`

This is required for lock delays, voting windows, and delayed state behavior.

### 6. TypeScript Integration Harness Setup

- Connect via `createAztecNodeClient(nodeUrl)` and `waitForNode(node)`.
- Create wallet (`EmbeddedWallet` or test wallet wrapper).
- Register/load accounts:
- `registerInitialLocalNetworkAccountsInWallet(wallet)` for local-network prefunded accounts
- or `getInitialTestAccountsData()` + `wallet.createSchnorrAccount(...)`

### 7. TypeScript Contract Integration Tests

- Deploy contracts with generated bindings.
- Assert state with `.simulate(...)`.
- Execute state transitions with `.send(...)`.
- Validate both pre- and post-state around each tx.

### 8. TypeScript Authwit Integration Tests

Private authwit patterns:

- build action method call
- create witness with `wallet.createAuthWit(...)`
- execute delegated call with `authWitnesses`
- assert replay failure

Public authwit patterns:

- register authorization with `SetPublicAuthwitContractInteraction.create(..., true)` and send it
- execute delegated action
- optionally cancel with `SetPublicAuthwitContractInteraction.create(..., false)` and send it
- assert unauthorized failure after cancellation

### 9. Governance/Protocol Upgrade Test Scenarios

For advanced local-network integration tests requiring governance timing and proposal state transitions, use the pinned governance testing tutorial in `reference.md`. Keep this as a dedicated integration track separate from standard contract unit/integration tests.

## Tooling / Commands

```bash
# readiness and environment checks
scripts/preflight_aztec_testing.sh [node-url]
scripts/wait_for_aztec_test_node.sh <node-url> [timeout-seconds] [interval-seconds]

# noir contract tests
scripts/run_noir_contract_tests.sh <workspace-dir> [--skip-compile]

# ts integration test setup and execution
scripts/install_aztec_testing_deps.sh <npm|yarn|pnpm> [version]
scripts/run_ts_integration_tests.sh <project-dir> <npm|yarn|pnpm> [test-script] [node-url]

# test-environment API summary helper
scripts/summarize_test_environment_api.sh <aztec-packages-dir>
```

## Edge Cases and Failure Handling

- Tests pass unexpectedly despite changed contract code:
re-run `aztec compile` before `aztec test`.
- Authwit tests fail with unknown witness/authorization:
verify account type, caller binding, and nonce/replay semantics.
- `.simulate()` succeeds but `.send()` fails in TS:
check fee/payment/publication/network constraints.
- Flaky time-window tests:
set explicit timestamps and mine deterministic blocks.
- Missing private notes/events in Noir tests:
ensure `discover_note(...)`/`discover_note_at(...)` flows are used when required.
- Local network test startup failures:
wait for node readiness and verify `node_getNodeInfo` response before running test suites.

## Next Steps / Related Files

- Use `reference.md` for pinned source corpus and detailed API/test matrices.
- Use `patterns.md` for reusable Noir and TypeScript testing templates.
- Use `scripts/` for repeatable test setup and execution workflows.
