---
name: aztec-contracts
description: Use this skill when creating, editing, testing, debugging, or upgrading Aztec smart contracts in Noir/Aztec.nr, including storage modeling, private/public/utility functions, note delivery, authwit authorization, TestEnvironment tests, and artifact/codegen workflows.
license: Proprietary. LICENSE.txt has complete terms
compatibility: Pinned to aztec-packages v4.1.0-rc.2 (commit 9598e7eff941a151aeff4cf4264327283db39a88).
metadata:
  version_label: v4.1.0-rc.2
  commit_sha: 9598e7eff941a151aeff4cf4264327283db39a88
  source_map: aztec-packages/docs/internal_notes/llm_docs_skill_candidates.md
---

# Aztec Contract Development

## Overview

Use this skill for Aztec.nr contract work inside the pinned `aztec-packages` checkout.

Primary scope:

- Contract structure and storage design
- Private/public/utility function design
- Note and private-event delivery mode selection
- Authwit-protected delegated actions
- Compile, test, codegen, debugging, and upgrade flows

## Required Repository State

Use the upstream repository and pin:

- Repo: `https://github.com/AztecProtocol/aztec-packages`
- Tag: `v4.1.0-rc.2`
- Commit: `9598e7eff941a151aeff4cf4264327283db39a88`

Checkout example:

```bash
git clone https://github.com/AztecProtocol/aztec-packages.git
cd aztec-packages
git checkout v4.1.0-rc.2
git status
```

Expected status includes `HEAD detached at v4.1.0-rc.2`.

## Operating Rules

- Keep implementation aligned with the pinned source set:
- `docs/docs-developers/docs/aztec-nr/**`
- `docs/docs-developers/docs/foundational-topics/contract_creation.md`
- `docs/docs-developers/docs/tutorials/contract_tutorials/**`
- Use GitHub paths when needed:
- `https://github.com/AztecProtocol/aztec-packages/tree/v4.1.0-rc.2/docs/docs-developers/docs/aztec-nr`
- Prefer protocol-correct behavior over stylistic churn.
- Keep function intent explicit: execution domain, state domain, and call path.
- Never leave note/event delivery implicit.
- Keep `SKILL.md` procedural; put deep detail in `reference.md` and `patterns.md`.

## Quick Start

```bash
# from a contract crate
aztec compile
aztec test
aztec codegen target --outdir artifacts
```

Use scripts in `scripts/` for the same flows:

- `scripts/new_contract.sh`
- `scripts/build_contract.sh`
- `scripts/test_contract.sh`
- `scripts/codegen_contract.sh`

## Core Workflows

### 1. Contract Scaffold and Structure

- One contract per Noir crate.
- Apply `#[aztec]` to every contract.
- Keep `#[external(...)]` entrypoints directly in the contract block.
- Define one `#[storage]` struct with `Storage<Context>`.
- Put helper/internal logic in internal functions or modules, not external entrypoints.

Baseline pattern:

```rust
use aztec::macros::aztec;

#[aztec]
pub contract MyContract {
    use aztec::{
        macros::{functions::{external, initializer, view}, storage::storage},
        protocol::address::AztecAddress,
        state_vars::{PublicImmutable, PublicMutable},
    };

    #[storage]
    struct Storage<Context> {
        admin: PublicImmutable<AztecAddress, Context>,
        value: PublicMutable<Field, Context>,
    }

    #[initializer]
    #[external("public")]
    fn constructor(admin: AztecAddress) {
        self.storage.admin.initialize(admin);
        self.storage.value.write(0);
    }

    #[external("public")]
    fn set_value(value: Field) {
        assert(self.msg_sender() == self.storage.admin.read(), "not admin");
        self.storage.value.write(value);
    }

    #[view]
    #[external("public")]
    fn get_value() -> Field {
        self.storage.value.read()
    }
}
```

### 2. State Modeling

- Use `PublicMutable` for mutable public state.
- Use `PublicImmutable` for write-once values readable across contexts.
- Use `DelayedPublicMutable` when private execution must read a public mutable value.
- Use `Owned<PrivateMutable<...>>` and `Owned<PrivateSet<...>>` for per-owner private state.
- Use `SinglePrivateMutable`/`SinglePrivateImmutable` for contract-wide private singleton state.
- Use `Map<K, ...>` for keyed public layouts.

### 3. Function Domain Design

- `#[external("private")]`: private execution and private-state workflows.
- `#[external("public")]`: sequencer-executed public-state workflows.
- `#[external("utility")] unconstrained`: offchain query/helper logic.
- `#[view]`: read-only private/public external functions.
- `#[initializer]`: constructor-like setup.
- `#[noinitcheck]`: only where pre-init calls are explicitly needed.
- `#[only_self]`: public/private functions only callable by the same contract.
- `#[authorize_once("from", "authwit_nonce")]`: delegated actions with replay protection.

### 4. Note/Event Delivery

Whenever a state write or private event returns a message object:

1. Pick delivery mode explicitly.
2. Call `.deliver(...)` or `.deliver_to(...)`.

Delivery selection:

- `MessageDelivery.OFFCHAIN`: cheapest; sender must manually deliver/process offchain messages.
- `MessageDelivery.ONCHAIN_UNCONSTRAINED`: onchain availability, no constrained correctness.
- `MessageDelivery.ONCHAIN_CONSTRAINED`: strongest available guarantees; highest proving cost.

Known caveat in pinned docs/code:

- `ONCHAIN_CONSTRAINED` currently has an acknowledged tag-constraining limitation (issue #14565). Use it when trust assumptions require it, but do not claim perfect guarantees.

### 5. Cross-Contract and Private->Public Flows

- Use `self.call(Other::at(addr).fn(...))` for direct same-domain external calls.
- Use `self.view(...)` for read-only external calls.
- Use `self.enqueue(...)` for private->public deferred execution.
- Use `self.enqueue_self.some_public_fn(...)` plus `#[only_self]` when private logic must safely update public state.
- Do not rely on return values from enqueued public calls in private execution.

### 6. Initialization and Readiness

- Initialization and public deployment are distinct concerns.
- Contracts with public entrypoints usually require class registration plus instance public deployment for public calls.
- Private-only contracts can often operate without public deployment.
- `without_initializer()` plus no `#[initializer]` means initialized-by-design at deploy time.
- `#[noinitcheck]` functions may be callable before initialization.

### 7. Authwit

- Use authwit when acting on behalf of another account/owner.
- Prefer `#[authorize_once]` for straightforward delegated call checks.
- Treat nonce handling as mandatory replay protection.
- Use contract accounts in tests when validating authwit workflows.
- Always include negative-path tests (missing/invalid/cancelled authwit).

### 8. Compile, Test, Codegen

Default sequence:

1. `aztec compile`
2. `aztec test`
3. `aztec codegen target --outdir artifacts` (when TS integration is involved)

Rules:

- Use `aztec test` (not `nargo test`) for Aztec contract behavior.
- Recompile before tests because `aztec test` does not auto-recompile changed contracts.
- Treat `target/*.json` as canonical contract artifacts.

### 9. Upgrades

- Initiate upgrades through `ContractInstanceRegistry.update(new_class_id)`.
- Protect upgrade entrypoints with strict authorization.
- Respect delayed activation semantics (`DelayedPublicMutable`-based delay).
- Preserve storage compatibility across versions.
- Re-register updated artifacts in wallets/clients after delay elapses.

## Tooling / Commands

```bash
# Local network debugging
LOG_LEVEL=debug aztec start --local-network

# Compile and test
aztec compile
aztec test

# Generate TypeScript bindings
aztec codegen target --outdir artifacts

# Profile private flows
aztec-wallet profile <function_name> -ca <contract_alias> --args [...] -f <account>

# Gate count report
noir-profiler gates --artifact-path ./target/<artifact>.json --backend-path bb --output ./target
```

Gate-count guidance in pinned docs:

- `< 50k`: excellent
- `50k-200k`: acceptable
- `200k-500k`: consider optimizing
- `> 500k`: optimize before scaling

## Edge Cases and Failure Handling

- `aztec test` failure after edits: rerun `aztec compile` first.
- Public function callable unexpectedly: confirm `#[only_self]` where private->public enqueueing is expected.
- Note recipient cannot use note: verify delivery mode and delivery call were executed.
- Missing authwit behavior in tests: switch to contract accounts and add authwit helper setup.
- Pre-init behavior mismatch: audit `#[initializer]`, `#[noinitcheck]`, and deployment path.
- Upgrade appears ineffective: verify delay elapsed and new artifact registered in wallet/client.
- Utility function misuse: ensure utility functions are only used for unconstrained/offchain workflows.

## Next Steps / Related Files

- Use `reference.md` for pinned source map, implementation matrix, and troubleshooting checklists.
- Use `patterns.md` for reusable code patterns.
- Use scripts in `scripts/` for scaffold/build/test/codegen flows.
