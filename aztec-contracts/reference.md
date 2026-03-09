# Aztec Contracts Reference

## Scope and Pin

- Skill: `aztec-contracts`
- Version label: `v4.1.0-rc.1`
- Commit SHA: `77e5b3ca816702e2cee866aec1a0d6ce997e0ea6`
- Primary source map: `docs/internal_notes/llm_docs_skill_candidates.md`
- Upstream repo: `https://github.com/AztecProtocol/aztec-packages`

## Required Checkout State

```bash
git clone https://github.com/AztecProtocol/aztec-packages.git
cd aztec-packages
git checkout v4.1.0-rc.1
git status
```

Expected state:

- `HEAD detached at v4.1.0-rc.1`
- `git rev-parse HEAD` equals `77e5b3ca816702e2cee866aec1a0d6ce997e0ea6`

## Pinned Source Corpus

Source docs:

- `docs/docs-developers/docs/aztec-nr/**`
- `docs/docs-developers/docs/foundational-topics/contract_creation.md`
- `docs/docs-developers/docs/tutorials/contract_tutorials/**`

Generated API docs (devnet subset):

- `docs/static/aztec-nr-api/devnet/**`

Referenced code fanout:

- `docs/examples/contracts/**`
- `docs/examples/circuits/**`
- `docs/examples/ts/bob_token_contract/**`
- `docs/examples/ts/recursive_verification/**`
- `noir-projects/noir-contracts/contracts/**`
- `noir-projects/aztec-nr/**`
- `noir-projects/noir-protocol-circuits/crates/types/src/abis/**`
- `l1-contracts/src/**`

## Packaging Constraints for This Pin

For generated corpora/chunks derived from this skill, include:

- `version_label: v4.1.0-rc.1`
- `commit_sha: 77e5b3ca816702e2cee866aec1a0d6ce997e0ea6`
- `source_path`
- `skill_name`

Exclude:

- `docs/static/typescript-api/nightly/**`
- `docs/static/aztec-nr-api/nightly/**`
- `docs/developer_versioned_docs/**`
- `docs/network_versioned_docs/**`

## Tooling Matrix

Pinned environment:

- Aztec packages commit: `77e5b3ca816702e2cee866aec1a0d6ce997e0ea6`
- Release label: `v4.1.0-rc.1`

Core commands:

```bash
aztec compile
aztec test
aztec codegen target --outdir artifacts
```

Version check helpers:

```bash
AZTEC_PACKAGES_DIR=/path/to/aztec-packages
git -C "$AZTEC_PACKAGES_DIR" rev-parse HEAD
git -C "$AZTEC_PACKAGES_DIR" describe --tags --always
git -C "$AZTEC_PACKAGES_DIR" status
```

## Contract Layout

Minimal crate shape:

```text
my_contract/
|- Nargo.toml
`- src/
   `- main.nr
```

Rules:

- One Aztec contract per Noir crate.
- `#[aztec]` required.
- External entrypoints stay in contract block.
- Use one `#[storage]` struct with `Storage<Context>`.

Nargo dependency pattern from pinned examples:

```toml
[package]
name = "my_contract"
type = "contract"

[dependencies]
aztec = { path = "../../../../noir-projects/aztec-nr/aztec" }
```

## State Variable Selection

Use this quick matrix:

- `PublicMutable<T, Context>`: mutable public values.
- `PublicImmutable<T, Context>`: write-once shared values.
- `DelayedPublicMutable<T, DELAY, Context>`: public mutable values readable in private, with delayed value changes.
- `Owned<PrivateMutable<...>>`: per-owner private mutable singleton.
- `Owned<PrivateImmutable<...>>`: per-owner private immutable singleton.
- `Owned<PrivateSet<...>>`: per-owner private note collections.
- `SinglePrivateMutable<...>` / `SinglePrivateImmutable<...>`: contract-wide private singleton.
- `Map<K, ...>`: keyed public structures (or nested maps).

Important `DelayedPublicMutable` notes:

- Private reads are possible because writes become effective after delay.
- Choose delay based on threat/privacy model.
- Reading in private can expose timing information via expiration behavior.

## Function and Attribute Matrix

Execution annotations:

- `#[external("private")]`: private execution.
- `#[external("public")]`: public/sequencer execution.
- `#[external("utility")] unconstrained`: offchain utility query path.

Common modifiers:

- `#[view]`: read-only public/private external functions.
- `#[initializer]`: one-time initialization entrypoint(s).
- `#[noinitcheck]`: bypass init guard for explicit pre-init scenarios.
- `#[only_self]`: only callable by same contract address.
- `#[authorize_once("from", "authwit_nonce")]`: authwit + replay protection.

## Message Delivery Decision Matrix

When a state write/event returns a message, delivery is required.

- `MessageDelivery.OFFCHAIN`
- Pros: no blob DA cost, no proving overhead from constrained encryption.
- Cons: sender/app must extract and deliver/process offchain message manually.
- Use when sender is incentivized and offchain channel exists.

- `MessageDelivery.ONCHAIN_UNCONSTRAINED`
- Pros: onchain retrieval without custom delivery infra.
- Cons: pays DA cost without constrained-content guarantees.
- Use when sender is incentivized but offchain delivery infra is unavailable.

- `MessageDelivery.ONCHAIN_CONSTRAINED`
- Pros: strongest available delivery guarantees for untrusted sender settings.
- Cons: higher proving cost and known current tag-constraining limitation.
- Use when sender cannot be trusted.

Known caveat:

- `ONCHAIN_CONSTRAINED` is documented with issue `#14565` (tag constraining limitation).

## Cross-Contract Call Patterns

- `self.call(Other::at(addr).fn(...))`: immediate same-domain call.
- `self.view(...)`: read-only external call.
- `self.enqueue(...)`: private -> public deferred call.
- `self.enqueue_self.public_fn(...)` + `#[only_self]`: guarded private -> public transition.

## TestEnvironment Quick Guide

Core flow:

1. `aztec compile`
2. `aztec test`

Common setup:

```rust
let mut env = TestEnvironment::new();
let owner = env.create_light_account();
let initializer = MyContract::interface().constructor(param1, param2);
let contract_address = env.deploy("MyContract").with_private_initializer(owner, initializer);
```

Invocation helpers:

- `env.call_private(...)`
- `env.call_public(...)`
- `env.view_public(...)`
- `env.execute_utility(...)`

Accounts:

- Light account: faster, no authwit support.
- Contract account: required for authwit testing and richer account features.

## Authwit Checklist

- Add `#[authorize_once("from", "authwit_nonce")]` on delegated actions.
- Use non-zero nonce patterns in tests.
- Test success + replay failure + missing authwit failure.
- Use contract accounts in authwit tests.

## Contract Readiness and Lifecycle

Deployment/readiness checkpoints:

- Class registration
- Instance deployment
- Initializer invocation (unless intentionally skipped)
- Public deployment readiness for public function calls

Notes:

- No initializer + `without_initializer()` means initialized directly at deploy time.
- `#[noinitcheck]` functions can be valid pre-init entrypoints.

## Upgrades Runbook

1. Register/publish new contract class (if public functions exist).
2. Call `ContractInstanceRegistry.update(new_class_id)` through authorized flow.
3. Wait for delay to elapse.
4. Register new artifact with wallet/client.
5. Verify behavior and storage compatibility.

Operational constraints:

- Delay uses `DelayedPublicMutable`; default documented delay is `86400` seconds.
- Minimum update delay documented as `600` seconds.
- Update delay changes also obey delay semantics.

## Debugging and Performance

Debug loop:

```bash
LOG_LEVEL=debug aztec start --local-network
aztec compile
aztec test
```

Performance tools:

```bash
aztec-wallet profile <function_name> -ca <contract_alias> --args [...] -f <account>
noir-profiler gates --artifact-path ./target/<artifact>.json --backend-path bb --output ./target
```

Gate count guidance:

- `< 50k`: excellent
- `50k-200k`: acceptable
- `200k-500k`: consider optimizing
- `> 500k`: optimize before scaling

## Common Failure Modes

- Test failures after edits: forgot recompilation before `aztec test`.
- Invalid public/private bridge: missing `#[only_self]` on enqueued public target.
- Missing notes: message returned but `.deliver(...)` omitted.
- Authwit failures in tests: light accounts used where contract accounts are required.
- Upgrade no-op behavior: delay not elapsed or new artifact not registered.
- Circular import issues: generated interface imported from same source project.
