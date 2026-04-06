# Migration Audit: v4.1.0-rc.2 → 4.2.0-aztecnr-rc.2

**Date:** 2026-04-06
**Current pin:** `v4.1.0-rc.2` (commit `9598e7eff941a151aeff4cf4264327283db39a88`)
**Target release:** `4.2.0-aztecnr-rc.2`
**Source:** `aztec-packages` migration notes + codebase diff

---

## 1. Version Pins (ALL 7 skills)

Every skill has ~10-13 references to `v4.1.0-rc.2` and commit SHA `9598e7eff941a151aeff4cf4264327283db39a88` across `SKILL.md`, `reference.md`, `patterns.md`, and some scripts. **All must be bumped.**

---

## 2. Breaking API Changes by Skill

### aztec-accounts (21 locations)

| Change | Locations | Severity |
|---|---|---|
| `SingleKeyAccountContract` removed | 13 matches in SKILL.md + reference.md | **High** - entire flavor must be removed |
| `AztecAddress.ZERO` as `from` → `NO_FROM` | 1 in reference.md | Medium |
| Deploy `.send()` return type `{ contract, receipt, instance }` | 3 in SKILL.md + patterns.md | Medium |
| `skipClassPublication: true` new restriction | 2 in SKILL.md + reference.md | Medium |
| `getMasterNullifierPublicKey` (nhk rename) | 2 in patterns.md + reference.md | Low - verify |

#### Details

**SingleKeyAccountContract (REMOVED)**
- `SKILL.md` line 3 (frontmatter): remove `SingleKey` from description
- `SKILL.md` line 20: remove `SingleKey` from flavor list
- `SKILL.md` line 60: remove `SingleKey` clause from preference guidance
- `SKILL.md` lines 115-117: remove entire `SingleKeyAccountContract` bullet block
- `SKILL.md` lines 246-247: remove edge case block about `SingleKey`
- `reference.md` lines 44-45: remove `single_key` source anchors
- `reference.md` lines 95-96: remove `@aztec/accounts/single_key` export subpaths
- `reference.md` line 127: remove `SingleKeyAccountContract` from class list
- `reference.md` lines 148-158: remove entire "### SingleKey" flavor map section

**AztecAddress.ZERO → NO_FROM**
- `reference.md` line 298: `AztecAddress.ZERO` → `NO_FROM` (import from `@aztec/aztec.js/account`)

**Deploy .send() return type**
- `SKILL.md` line 94: `await deployMethod.send(...)` — document new return shape `{ contract, receipt, instance }`
- `SKILL.md` line 131: same
- `patterns.md` line 25: same

**skipClassPublication restriction**
- `SKILL.md` lines 133-136: add caveat about restriction when contract has public fns + private initializer
- `reference.md` lines 294-297: same

**getMasterNullifierPublicKey (nhk rename)**
- `patterns.md` line 130: verify `getMasterNullifierPublicKey` still exists
- `reference.md` line 322: same

---

### aztec-contracts (13 locations)

| Change | Locations | Severity |
|---|---|---|
| `#[noinitcheck]` → `#[allow_phase_change]` | 5 in SKILL.md + reference.md | **High** - attribute renamed |
| `#[only_self]` no longer has init checks | 7 in SKILL.md + reference.md + patterns.md | **High** - behavioral change |

#### Details

**#[noinitcheck] → #[allow_phase_change]**
- `SKILL.md` line 140: rename attribute and update description
- `SKILL.md` line 175: rename
- `SKILL.md` line 240: rename
- `reference.md` line 148: rename
- `reference.md` line 229: rename

**#[only_self] no longer has init checks**
- `SKILL.md` line 141: add note about no implicit init check in 4.2.0
- `SKILL.md` line 166: same
- `SKILL.md` line 237: same
- `patterns.md` lines 64, 79: add note on Pattern 3's `#[only_self]` usage
- `reference.md` line 149: update description
- `reference.md` line 180: same
- `reference.md` line 272: same

---

### aztec-deployment (19 locations)

| Change | Locations | Severity |
|---|---|---|
| Deploy `.send()` return type changed | 4 in SKILL.md + reference.md + patterns.md | **High** - code will break |
| `isContractInitialized` → `initializationStatus` enum | 5 in SKILL.md + patterns.md + reference.md | **High** - type changed |
| `skipClassPublication` new restriction | 5 in SKILL.md + reference.md + script | Medium |
| `NO_WAIT` returns `{ txHash, ... }` not bare hash | 3 in SKILL.md + reference.md + patterns.md | **High** - code will break |
| `fpc-public`/`fpc-private` won't work on public nets | 1 in reference.md | Medium |
| `additionalScopes` for private-storage deploys | Gap - not documented yet | Medium |

#### Details

**Deploy .send() return type**
- `patterns.md` lines 79-86: `token = await ...send()` needs destructuring `{ contract: token }`
- `SKILL.md` line 161: `const contract = await ...send()` needs `{ contract }`
- `reference.md` line 163: document new return shape
- `reference.md` line 164: same for `deployWithOpts`

**isContractInitialized → initializationStatus**
- `SKILL.md` line 187: `metadata.isContractInitialized` → `metadata.initializationStatus === ContractInitializationStatus.INITIALIZED`
- `SKILL.md` line 200: update prose
- `patterns.md` line 118: `if (!metadata.isContractInitialized)` → enum check
- `reference.md` line 94: update field name
- `reference.md` line 189: update verification runbook

**skipClassPublication restriction**
- `SKILL.md` line 168: add restriction caveat
- `SKILL.md` line 137: CLI `--no-class-registration` — add warning
- `reference.md` line 172: add restriction caveat
- `reference.md` line 117: CLI option — add warning
- `scripts/deploy_contract_wallet.sh` lines 54, 84-86: add guard or warning

**NO_WAIT return type**
- `patterns.md` lines 96-105: `const txHash = await ...send({ wait: NO_WAIT })` → `const { txHash } = ...`
- `SKILL.md` line 171: document return type change
- `reference.md` line 175: document return type change

**fpc-public/fpc-private removed from public networks**
- `reference.md` lines 130-136: remove or caveat `fpc-public` and `fpc-private` from supported methods list

**additionalScopes (gap)**
- Deploy patterns should add guidance about `additionalScopes` for contracts with private storage

---

### aztec-js (30+ locations) — Most impacted

| Change | Locations | Severity |
|---|---|---|
| `.simulate()` returns `{ result, ... }` | 6 in patterns.md + reference.md + SKILL.md | **High** - code will break |
| `.send()` returns `{ receipt, ... }` | 3 in patterns.md + reference.md | **High** - code will break |
| Deploy `.send()` returns `{ contract, receipt, instance }` | 3 in patterns.md + reference.md + SKILL.md | **High** - code will break |
| `NO_WAIT` returns `{ txHash, ... }` | 3 in patterns.md + reference.md + SKILL.md | **High** - code will break |
| `AztecAddress.ZERO` as `from` → `NO_FROM` | 1 in patterns.md | **High** |
| `isContractInitialized` → `initializationStatus` | 3 in patterns.md + reference.md | **High** |
| `getPublicEvents` returns `{ events, maxLogsHit }` not array | 3 in patterns.md + SKILL.md + reference.md | **High** |
| `PrivateFeePaymentMethod`/`PublicFeePaymentMethod` removed | 2 in SKILL.md + reference.md | Medium |
| `BatchCall.send()` return type | 3 in patterns.md + SKILL.md + reference.md | Medium |

#### Details

**.simulate() return type**
- `patterns.md` line 115: `const sim = await ...simulate(...)` → `sim.result` for actual value
- `patterns.md` line 214: `const result = await ...simulate(...)` → `const { result } = ...`
- `patterns.md` line 80: side-effect only simulate — add comment about new return shape
- `reference.md` line 172: document new return type
- `SKILL.md` lines 113, 146: update guidance text

**.send() return type**
- `patterns.md` lines 103-104: `const batchReceipt = await batch.send(...)` → `const { receipt: batchReceipt } = ...`
- `patterns.md` lines 124-127: document new return shape
- `reference.md` line 205: document new return type

**Deploy .send() return type**
- `patterns.md` lines 55-59: `const token = await TokenContract.deploy(...).send(...)` → `const { contract: token } = ...`
- `reference.md` lines 164-165: document new return type
- `SKILL.md` line 102: update guidance

**NO_WAIT return type**
- `patterns.md` lines 82-88: `const txHash = await ...send({ wait: NO_WAIT })` → `const { txHash } = ...`
- `reference.md` line 206: document new return type
- `SKILL.md` lines 62, 106: update guidance

**AztecAddress.ZERO → NO_FROM**
- `patterns.md` line 38: `from: AztecAddress.ZERO` → `from: NO_FROM`

**isContractInitialized → initializationStatus**
- `patterns.md` line 42: `metadata.isContractInitialized` → enum check
- `patterns.md` line 66: same
- `reference.md` line 241: same

**getPublicEvents return type**
- `patterns.md` lines 163-170: `const publicEvents = await getPublicEvents(...)` → `const { events: publicEvents } = ...`
- `SKILL.md` line 121: document `{ events, maxLogsHit }` return
- `reference.md` line 199: document new return type

**PrivateFeePaymentMethod/PublicFeePaymentMethod removed**
- `SKILL.md` line 132: change "deprecated" to **removed**
- `reference.md` line 189: same

**BatchCall.send() return type**
- `patterns.md` lines 96-104: `batchReceipt.blockNumber` → destructure first
- `SKILL.md` line 115: note new return shape
- `reference.md` line 174: document return type change

---

### aztec-pxe (8 locations)

| Change | Locations | Severity |
|---|---|---|
| `ALL_SCOPES` removed from `simulateTx`/`executeUtility`/`profileTx`/`proveTx` | 5 in SKILL.md + reference.md | **High** - API removed |
| `AccessScopes` type rewrite + `src/access_scopes.ts` path | 3 in reference.md + preflight script | **High** |

#### Details

**ALL_SCOPES removed**
- `SKILL.md` line 55: remove `'ALL_SCOPES'` as a valid option
- `reference.md` lines 122-126: rewrite `AccessScopes` type — remove `'ALL_SCOPES'` variant
- `reference.md` lines 87, 92, 99: update `opts.scopes: AccessScopes` to `AztecAddress[]`

**AccessScopes / access_scopes.ts**
- `reference.md` line 34: verify `src/access_scopes.ts` still exists
- `reference.md` lines 122-132: rewrite entire "Access Scopes Semantics" section
- `scripts/preflight_pxe.sh` line 84: verify file path check for `src/access_scopes.ts`

---

### aztec-testing (10+ locations)

| Change | Locations | Severity |
|---|---|---|
| `.simulate()` / `.send()` return type changes | 5 code examples in patterns.md + prose in SKILL.md | **High** - code will break |
| Deploy `.send()` return type | 1 in patterns.md | Medium |

#### Details

**.simulate() / .send() return types**
- `patterns.md` line 150: deploy `.send()` return type — destructure `{ contract: token }`
- `patterns.md` line 154: `.send({ from: alice })` — document new return shape
- `patterns.md` line 156: `.simulate({ from: alice })` — `{ result }` destructuring
- `patterns.md` line 184: same
- `patterns.md` line 187: same
- `SKILL.md` lines 55, 159, 160, 207: update prose references
- `reference.md` lines 205-208: update integration test flow

**Already correct (no changes needed):**
- `execute_utility` (not `simulateUtility`) — already updated
- `protocol::` (not `protocol_types`) — already updated
- `@aztec/wallets` (not `@aztec/test-wallet`) — already updated

---

### aztec-wallet-sdk (3 locations + 1 gap)

| Change | Locations | Severity |
|---|---|---|
| `sendTx()` return type (includes offchain output) | 2 in SKILL.md + reference.md | Medium |
| `extractOffchainOutput` missing from docs | Gap in reference.md | Low |
| `FeeOptions` may have changed shape | 1 in reference.md | Low - verify |

#### Details

**sendTx() return type**
- `SKILL.md` line 161: document new return shape with offchain output
- `reference.md` line 211: same

**extractOffchainOutput (gap)**
- `reference.md` lines 148-150: add `extractOffchainOutput` to base-wallet utils section

**FeeOptions**
- `reference.md` line 146: verify `FeeOptions` type still matches after fee payment method removal

---

## 3. Priority Ranking for Updates

### P0 — Code-breaking changes (patterns will fail at runtime)

1. `.simulate()` / `.send()` / deploy `.send()` return type destructuring (aztec-js, aztec-testing, aztec-deployment)
2. `NO_WAIT` return type `{ txHash }` (aztec-js, aztec-deployment)
3. `ALL_SCOPES` removed (aztec-pxe)
4. `SingleKeyAccountContract` removed (aztec-accounts)
5. `isContractInitialized` → `initializationStatus` enum (aztec-deployment, aztec-js)
6. `AztecAddress.ZERO` → `NO_FROM` (aztec-accounts, aztec-js)

### P1 — Behavioral/naming changes (will cause confusion)

7. `#[noinitcheck]` → `#[allow_phase_change]` (aztec-contracts)
8. `#[only_self]` no longer checks init (aztec-contracts)
9. `getPublicEvents` returns object not array (aztec-js)
10. `skipClassPublication` restriction (aztec-accounts, aztec-deployment)
11. `fpc-public`/`fpc-private` removed from public networks (aztec-deployment)
12. `PrivateFeePaymentMethod`/`PublicFeePaymentMethod` fully removed (aztec-js)

### P2 — Documentation gaps/minor

13. `additionalScopes` not documented (aztec-deployment)
14. `sendTx()` return type (aztec-wallet-sdk)
15. `extractOffchainOutput` gap (aztec-wallet-sdk)
16. `getMasterNullifierPublicKey` nhk rename (aztec-accounts)

---

## 4. Total Impact

- **~75 version pin locations** across all 7 skills need bumping
- **~50 code/documentation locations** need substantive content changes
- **aztec-js** is the most heavily impacted skill (30+ changes)
- **aztec-wallet-sdk** is the least impacted (3 changes + 1 gap)
