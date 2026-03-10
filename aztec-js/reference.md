# Aztec.js Reference

## Scope and Pin

- Skill: `aztec-js`
- Version label: `v4.1.0-rc.2`
- Commit SHA: `9598e7eff941a151aeff4cf4264327283db39a88`
- Primary source map: `docs/internal_notes/llm_docs_skill_candidates.md`
- Upstream repo: `https://github.com/AztecProtocol/aztec-packages`

## Required Checkout State

```bash
git clone https://github.com/AztecProtocol/aztec-packages.git
cd aztec-packages
git checkout v4.1.0-rc.2
git status
git rev-parse HEAD
```

Expected:

- `HEAD detached at v4.1.0-rc.2`
- `9598e7eff941a151aeff4cf4264327283db39a88`

## Pinned Source Corpus

Guides and tutorials:

- `docs/docs-developers/docs/aztec-js/**`
- `docs/docs-developers/docs/tutorials/js_tutorials/**`

Generated TypeScript API docs (devnet):

- `docs/static/typescript-api/devnet/accounts.md`
- `docs/static/typescript-api/devnet/aztec.js.md`
- `docs/static/typescript-api/devnet/constants.md`
- `docs/static/typescript-api/devnet/entrypoints.md`
- `docs/static/typescript-api/devnet/foundation.md`
- `docs/static/typescript-api/devnet/llm-summary.txt`
- `docs/static/typescript-api/devnet/pxe.md`
- `docs/static/typescript-api/devnet/stdlib.md`
- `docs/static/typescript-api/devnet/wallet-sdk.md`

Referenced examples and tests:

- `docs/examples/ts/aztecjs_connection/**`
- `docs/examples/ts/aztecjs_advanced/**`
- `docs/examples/ts/aztecjs_authwit/**`
- `docs/examples/ts/aztecjs_testing/**`
- `docs/examples/ts/aztecjs_getting_started/**`
- `docs/examples/ts/token_bridge/**`
- `yarn-project/end-to-end/src/composed/**`
- `yarn-project/end-to-end/src/e2e_deploy_contract/**`

Remote pinned docs root:

- `https://github.com/AztecProtocol/aztec-packages/tree/v4.1.0-rc.2/docs`

## Full API Coverage Matrix

This skill covers all packages present in the pinned devnet API corpus.

| Package doc | Classes | Interfaces | Functions | Types | Enums |
| --- | ---: | ---: | ---: | ---: | ---: |
| `aztec.js.md` | 55 | 10 | 51 | 63 | 4 |
| `accounts.md` | 16 | 1 | 12 | 9 | 0 |
| `pxe.md` | 37 | 12 | 16 | 17 | 1 |
| `entrypoints.md` | 4 | 2 | 1 | 6 | 1 |
| `wallet-sdk.md` | 4 | 14 | 9 | 5 | 1 |
| `stdlib.md` | 283 | 106 | 358 | 228 | 17 |
| `foundation.md` | 76 | 28 | 270 | 60 | 0 |
| `constants.md` | 0 | 0 | 0 | 499 | 1 |
| **Total** | **475** | **173** | **717** | **887** | **25** |

Notes:

- API markdown headers may report a generated package version label differing from the repository pin.
- For this skill, treat the repository pin (`v4.1.0-rc.2`, commit above) as authoritative.

## Package-by-Package Usage Map

### `@aztec/aztec.js` (primary app SDK)

Key domains in this package:

- account wrappers and interfaces
- contract interaction (`Contract`, `ContractFunctionInteraction`, `BatchCall`)
- deploy flows (`DeployMethod`, `DeploySentTx`)
- transaction abstractions (`SentTx`, receipt wait helpers)
- fee payment method implementations
- authwit helpers and interaction wrappers
- node utilities (`createAztecNodeClient`, `waitForNode`)

Preferred subpath imports:

- `@aztec/aztec.js/node`
- `@aztec/aztec.js/contracts`
- `@aztec/aztec.js/wallet`
- `@aztec/aztec.js/fields`
- `@aztec/aztec.js/addresses`
- `@aztec/aztec.js/fee`
- `@aztec/aztec.js/authorization`
- `@aztec/aztec.js/events`
- `@aztec/aztec.js/utils`

### `@aztec/accounts`

Use for account contract implementations and helpers:

- Schnorr variants
- ECDSA variants
- test-account bootstrapping helpers (`getInitialTestAccountsData`)

### `@aztec/pxe`

Use for direct PXE interactions when wallet abstraction is insufficient:

- execution simulation internals
- note/event data providers
- sync and tagging internals
- PXE creation and config

### `@aztec/entrypoints`

Use when customizing entrypoint behavior and tx request construction:

- default and multicall entrypoints
- auth witness provider interface
- request encoding helpers

### `@aztec/wallet-sdk`

Use for browser-extension or wallet-provider integrations:

- wallet discovery
- encrypted channel/session setup
- extension wallet adapters

### `@aztec/stdlib`, `@aztec/foundation`, `@aztec/constants`

Use as protocol and utility layers:

- protocol data types (`Tx`, `L2Block`, `GasSettings`, addresses, selectors)
- crypto/math primitives and serialization
- protocol constants and gas/tree values

## Workflow API Cheat Sheet

### Node and wallet setup

- `createAztecNodeClient(url)`
- `waitForNode(node)`
- `EmbeddedWallet.create(node)` (from `@aztec/wallets/embedded`)

### Accounts

- `wallet.createSchnorrAccount(secret, salt, signingKey?)`
- `accountManager.getDeployMethod().send(opts)`
- `wallet.getAccounts()`

### Contract deployment

- `MyContract.deploy(wallet, ...args).send({ from, ...opts })`
- `MyContract.deployWithOpts({ wallet, method }, ...args).send({ from, ...opts })`
- `deployMethod.getInstance({ contractAddressSalt })`
- `deployMethod.register()` for batched deployment+call flows

### Contract interaction

- `Contract.at(address, artifact, wallet)`
- `contract.methods.fn(...).simulate({ from, ...opts })`
- `contract.methods.fn(...).send({ from, fee, wait })`
- `new BatchCall(wallet, [call1, call2, ...]).send({ from })`

### Metadata and registration

- `wallet.getContractMetadata(address)`
- `wallet.getContractClassMetadata(classId)`
- `wallet.registerContract(instance, artifact, secretKey?)`

### Fees

- `simulate({ fee: { estimateGas: true, estimatedGasPadding } })`
- `GasSettings.default(...)` / `GasSettings.from(...)`
- supported payment methods:
- `SponsoredFeePaymentMethod`
- `FeeJuicePaymentMethodWithClaim`
- avoid `PrivateFeePaymentMethod` and `PublicFeePaymentMethod` for mainnet-targeted flows; both are deprecated upstream.

### Authwit

- `wallet.createAuthWit(authorizer, intentOrHash)`
- `computeInnerAuthWitHash(...)`
- `SetPublicAuthwitContractInteraction.create(...)`

### Events and logs

- `getPublicEvents(node, EventDef, filter)`
- `wallet.getPrivateEvents(EventDef, filter)`
- `aztecNode.getPublicLogs(filter)` for raw fields

### Transaction lifecycle

- waited send: `await method.send({ from })`
- no-wait: `await method.send({ from, wait: NO_WAIT })`
- receipt polling: `node.getTxReceipt(txHash)` or tx wait helpers

## Complete API Extraction Commands

To list all exported symbols by package from pinned docs:

```bash
AZTEC_PACKAGES_DIR=/path/to/aztec-packages
for f in "$AZTEC_PACKAGES_DIR"/docs/static/typescript-api/devnet/*.md; do
  echo "===== $(basename "$f")"
  awk '
    /^## Classes/{sec="classes";next}
    /^## Interfaces/{sec="interfaces";next}
    /^## Functions/{sec="functions";next}
    /^## Types/{sec="types";next}
    /^## Enums/{sec="enums";next}
    /^## /{sec="";next}
    /^### /{if(sec!="") print sec"\t"substr($0,5)}
  ' "$f"
done
```

To recompute package counts:

```bash
scripts/api_surface_summary.sh /path/to/aztec-packages
```

## Readiness and Safety Checks

Before first public call on a deployed contract:

1. `metadata = await wallet.getContractMetadata(contractAddress)`
2. confirm `metadata.instance` exists
3. confirm `metadata.isContractInitialized` when applicable
4. confirm `metadata.isContractPublished` for public calls
5. fetch class metadata and confirm `isContractClassPubliclyRegistered`

Before sending a cost-sensitive transaction:

1. simulate with gas estimation
2. decide payment method
3. set gas settings/padding
4. send and capture tx hash + receipt

## Troubleshooting

`Cannot find the leaf for nullifier` during deploy:

- deployment attempted with class publication skipped where publication is required

Deploy mined but public function fails:

- instance/class readiness not satisfied (`isContractPublished` or class registration)

Simulation works but send fails:

- fee payment, publication, or init constraints only enforced on network path

Authwit mismatch/replay failure:

- caller/action/nonce tuple mismatch or stale public authwit state

Private reads/events unexpectedly empty:

- missing account scopes, sender registration, or incorrect block range

No-wait tx appears lost:

- treat as pending until receipt polling is exhausted with explicit timeout/retry policy

## Distribution Rules

- Keep this skill self-contained for common Aztec.js workflows.
- Prefer remote pinned references over machine-local paths.
- Exclude nightly API docs from generated corpus for this skill.
