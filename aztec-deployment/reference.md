# Aztec Deployment Reference

## Scope and Pin

- Skill: `aztec-deployment`
- Version label: `v4.2.0`
- Commit SHA: `f8c89cf4345df6c4ca9e66ea9b738e96070abc5a`
- Primary source map: `docs/internal_notes/llm_docs_skill_candidates.md`
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

## Deployment-Only Source Corpus

Primary docs:

- `docs/docs-developers/getting_started_on_local_network.md`
- `docs/docs-developers/getting_started_on_devnet.md`
- `docs/docs-developers/docs/aztec-js/how_to_deploy_contract.md`
- `docs/docs-developers/docs/aztec-nr/contract_readiness_states.md`
- `docs/docs-developers/docs/foundational-topics/contract_creation.md`
- `docs/docs-developers/docs/tutorials/local_network.md`
- `docs/docs/networks.md`
- `docs/docs-developers/docs/cli/aztec_wallet_cli_reference.md`

Deployment code fanout:

- `docs/examples/ts/aztecjs_advanced/index.ts`
- `docs/examples/ts/aztecjs_connection/index.ts`
- `yarn-project/end-to-end/src/e2e_deploy_contract/deploy_method.test.ts`
- `yarn-project/cli-wallet/src/cmds/deploy.ts`
- `yarn-project/cli-wallet/src/cmds/create_account.ts`
- `yarn-project/cli-wallet/src/cmds/register_contract.ts`
- `yarn-project/aztec.js/src/contract/deploy_method.ts`
- `yarn-project/aztec.js/src/wallet/wallet.ts`

## Network Deployment Profiles

Local network profile:

- Node URL default: `http://localhost:8080`
- Test accounts available via `aztec-wallet import-test-accounts`
- Fast iterations
- Fee/payment flows are simpler

Devnet profile:

- Remote node URL (for example `https://devnet.aztec-labs.com/`)
- No preloaded local test accounts
- Sponsored fee payment is common (`method=fpc-sponsored`)
- Slower block/receipt timing than local network

## Contract Lifecycle (Deployment View)

Deployment toggles:

1. class registration
2. instance publication
3. initialization
4. local wallet registration

Lifecycle meaning:

- Class registration: make public class bytecode available on-chain.
- Instance publication: publish specific contract instance for public execution.
- Initialization: execute initializer (constructor-like logic).
- Wallet registration: make local PXE aware of instance/artifact for interactions.

## Callability Matrix

Minimum readiness to call:

- Private function with `#[noinitcheck]`: address known is enough. (`#[noinitcheck]` is retained in v4.2.0 — do not confuse with the separate `#[allow_phase_change]` phase-check attribute.)
- Private function with init checks: requires initialized contract.
- Public function: requires class registration + instance publication (+ initialization if required by logic).
- `#[only_self]` private functions implicitly skip the init check (as if marked `#[noinitcheck]`) in v4.2.0; any external function invoked during a private initializer must therefore be marked `#[only_self]`.

Operational check data:

- `wallet.getContractMetadata(address)`:
- `instance`
- `initializationStatus: ContractInitializationStatus` — enum: `INITIALIZED` / `UNINITIALIZED` / `UNKNOWN` (imported from `@aztec/aztec.js/wallet`). `UNKNOWN` means the instance is not registered in this wallet so its init state cannot be determined.
- `isContractPublished`
- `isContractUpdated`
- `updatedContractClassId`
- `wallet.getContractClassMetadata(classId)`:
- `isContractClassPubliclyRegistered`
- `isArtifactRegistered`

## `aztec-wallet deploy` Option Map

Base syntax:

```bash
aztec-wallet deploy [artifact] \
  --from <account> \
  --args <constructor args...>
```

Core options:

- `--init <string>`: initializer function name (default `constructor`)
- `--no-init`: skip initialization
- `--salt <hex>`: deterministic deployment salt
- `--universal`: exclude sender from address derivation
- `--no-class-registration`: skip class publication
- `--no-public-deployment`: skip instance publication
- `--no-wait`: return tx hash without waiting
- `--timeout <seconds>`: explicit wait timeout
- `--payment <spec>`: fee payment method and params

Payment format:

```text
--payment method=name,asset=address,fpc=address,...
```

Supported method values in this pin:

- `fee_juice`
- `fpc-sponsored`
- `fpc-public` — custom-token FPCs are not on the default public setup allowlist at v4.2.0; this method works only on local/custom networks where the FPC's token pair is whitelisted. It is deprecated for public/mainnet use.
- `fpc-private` — same caveat as `fpc-public`; deprecated for public/mainnet use.

For public/mainnet flows prefer `fee_juice` (after bridging Fee Juice from L1) or a Fee-Juice-only FPC; use `fpc-sponsored` for local/devnet onboarding.

## `aztec-wallet` Deployment Sequences

### Local network

```bash
aztec start --local-network
aztec-wallet import-test-accounts
aztec-wallet deploy token_contract@Token --args accounts:test0 Test TST 18 -f test0 -a token
aztec-wallet get-tx
```

### Devnet (sponsored)

```bash
NODE_URL=https://devnet.aztec-labs.com/
SPONSORED_FPC_ADDRESS=<sponsored-fpc-address>

aztec-wallet register-contract --node-url "$NODE_URL" --alias sponsoredfpc "$SPONSORED_FPC_ADDRESS" SponsoredFPC --salt 0
aztec-wallet create-account --node-url "$NODE_URL" --alias my-wallet --payment method=fpc-sponsored,fpc=$SPONSORED_FPC_ADDRESS
aztec-wallet deploy --node-url "$NODE_URL" --from accounts:my-wallet --payment method=fpc-sponsored,fpc=$SPONSORED_FPC_ADDRESS --alias token token_contract@Token --args accounts:my-wallet Token TOK 18 --no-wait
```

## Aztec.js Deployment Map

Common API:

- `MyContract.deploy(wallet, ...ctorArgs).send({ from })` — waited deploys return `{ contract, receipt, ... }`
- `MyContract.deployWithOpts({ wallet, method: "public_constructor" }, ...args).send({ from })`

Deployment `send(...)` options (from `DeployOptions`):

- `from`
- `fee`
- `contractAddressSalt`
- `universalDeploy`
- `skipClassPublication`
- `skipInstancePublication`
- `skipInitialization`
- `wait` (`NO_WAIT` supported — returns `{ txHash, ... }` instead of `{ contract, receipt, ... }`)

Useful patterns:

- `deployMethod.getInstance({ contractAddressSalt, deployer: from })` before `send({ from, contractAddressSalt })`; omit `deployer` only for universal/`NO_FROM` address computation
- `deployMethod.register()` then batch deploy + first call in same transaction

## Verification Runbook

After each deployment:

1. capture contract address and tx hash
2. fetch tx status/receipt
3. check contract metadata (`initializationStatus === ContractInitializationStatus.INITIALIZED`, `isContractPublished`)
4. check class metadata (`isContractClassPubliclyRegistered`) if public functions exist
5. only then execute public interactions

## Troubleshooting

`Cannot find the leaf for nullifier` during deploy:

- class likely not publicly registered for requested deployment pattern
- remove `--no-class-registration` or publish class first

`No transactions are needed to publish or initialize contract ...`:

- deploy options selected no publication/init work (expected for some private-only/no-init contracts)

Public call fails but deploy tx mined:

- instance may not be publicly deployed
- check `isContractPublished`

Devnet timeout (`Timeout awaiting isMined`):

- treat as pending not failed
- query by tx hash and retry polling

Unknown initializer/function:

- incorrect `--init` or `deployWithOpts(...method...)` value

Address mismatch when registering external contract:

- reconstruction inputs (salt, deployer, constructor args, method) do not match original deployment

## Distribution Rules

- Keep this skill self-contained for common deploy flows.
- Use remote references only when needed:
- `https://github.com/AztecProtocol/aztec-packages/tree/v4.2.0`
- Avoid local machine absolute paths.
