# Aztec Wallet SDK Reference

## Scope and Pin

- Skill: `aztec-wallet-sdk`
- Version label: `v4.2.0`
- Commit SHA: `f8c89cf4345df6c4ca9e66ea9b738e96070abc5a`
- Primary source map: `yarn-project/wallet-sdk`
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

## Pinned Source Corpus

Primary package root:

- `yarn-project/wallet-sdk/package.json`
- `yarn-project/wallet-sdk/README.md`
- `yarn-project/wallet-sdk/src/**`

Entrypoint modules (`package.json` exports and typedoc entrypoints):

- `src/manager/index.ts`
- `src/extension/provider/index.ts`
- `src/extension/handlers/index.ts`
- `src/base-wallet/index.ts`
- `src/crypto.ts`
- `src/types.ts`

Main implementation files:

- `src/manager/wallet_manager.ts`
- `src/manager/types.ts`
- `src/extension/provider/extension_provider.ts`
- `src/extension/provider/extension_wallet.ts`
- `src/extension/handlers/background_connection_handler.ts`
- `src/extension/handlers/content_script_connection_handler.ts`
- `src/extension/handlers/internal_message_types.ts`
- `src/base-wallet/base_wallet.ts`
- `src/base-wallet/utils.ts`
- `src/base-wallet/base_wallet.test.ts`

## Runtime and Packaging Facts

From pinned `yarn-project/wallet-sdk/package.json`:

- Package name: `@aztec/wallet-sdk`
- Engine: `node >=20.10`
- Module exports:
- `@aztec/wallet-sdk/manager`
- `@aztec/wallet-sdk/extension/provider`
- `@aztec/wallet-sdk/extension/handlers`
- `@aztec/wallet-sdk/base-wallet`
- `@aztec/wallet-sdk/crypto`
- `@aztec/wallet-sdk/types`

## API Surface Map by Module

### `manager`

- class: `WalletManager`
- key method: `WalletManager.configure(config)`
- key method: `manager.getAvailableWallets(options)` → returns `DiscoverySession`
  - `discovery.wallets` — `AsyncIterable<WalletProvider>` (async iterator over discovered wallets)
  - `discovery.done` — `Promise<void>` (resolves when discovery completes or is cancelled)
  - `discovery.cancel()` — abort discovery immediately
- core types:
- `WalletProvider`, `PendingConnection`, `DiscoverySession`
- `DiscoverWalletsOptions`, `WalletManagerConfig`
- `ExtensionWalletConfig`, `WebWalletConfig`
- `WalletProviderType`, `ProviderDisconnectionCallback`

### `extension/provider`

- classes:
- `ExtensionProvider`
- `DiscoveredWallet`
- `ExtensionWallet`
- key interfaces/types:
- `ConnectedWallet`, `DiscoveryOptions`, `DisconnectCallback`
- note: `WalletProvider.isDisconnected(): boolean` — check if provider session ended

### `extension/handlers`

- classes:
- `BackgroundConnectionHandler`
  - `initialize()` — register content-script listener
  - `approveDiscovery(requestId)` / `rejectDiscovery(requestId)`
  - `sendResponse(sessionId, walletResponse)` — encrypt and forward response to dApp tab
  - `terminateSession(sessionId)` / `terminateForTab(tabId)` — close active sessions
  - `clearAll()` — terminate all sessions and pending discoveries
  - `getPendingDiscoveries()` / `getPendingDiscoveryCount()` — inspect pending approvals
  - `getActiveSessions()` / `getSession(sessionId)` — inspect live sessions
  - `getPendingDiscovery(requestId)` — get a specific pending entry
- `ContentScriptConnectionHandler`
  - `start()` — register listeners
  - `closeConnection(sessionId)` / `closeAllConnections()` — clean up MessagePorts
  - `getConnectionCount()` — number of active port connections
- key types:
- `PendingDiscovery`, `ActiveSession`, `DiscoveryStatus`, `BackgroundTransport`
- `BackgroundConnectionConfig`, `BackgroundConnectionCallbacks`
  - `onPendingDiscovery?: (discovery: PendingDiscovery) => void`
  - `onSessionEstablished?: (session: ActiveSession) => void`
  - `onSessionTerminated?: (sessionId: string) => void`
  - `onWalletMessage?: (session: ActiveSession, message: WalletMessage) => void`
  - all callbacks are optional
- `ContentScriptTransport`
- relay protocol types: `MessageOrigin`, `ContentScriptMessage`, `BackgroundMessage`, `MessageSender`

### `crypto`

- interfaces:
- `SecureKeyPair`, `SessionKeys`, `EncryptedPayload`, `ExportedPublicKey`
- key functions:
- `generateKeyPair`, `exportPublicKey`, `importPublicKey`
- `deriveSessionKeys`, `encrypt`, `decrypt`, `hashToEmoji`
- key constants:
- `DEFAULT_EMOJI_GRID_SIZE = 9`

### `types`

- enum: `WalletMessageType`
- protocol shapes:
- `DiscoveryRequest`/`DiscoveryResponse`
- `KeyExchangeRequest`/`KeyExchangeResponse`
- `WalletMessage`/`WalletResponse`
- wallet identity shapes:
- `WalletInfo`, `ConnectedWalletInfo`

### `base-wallet`

- class: `BaseWallet`
- type: `FeeOptions`
- utils:
- `extractOptimizablePublicStaticCalls`
- `simulateViaNode`
- `buildMergedSimulationResult`
- `sendTx(executionPayload, opts)` returns `{ receipt?, txHash?, offchainEffects, offchainMessages }`. Implementations that override `sendTx` must call `extractOffchainOutput(provenTx.getOffchainEffects(), provenTx.publicInputs.constants.anchorBlockHeader.globalVariables.timestamp)` and spread the result — the timestamp argument is required in v4.2.0 (signature: `extractOffchainOutput(effects, anchorBlockTimestamp)`) so that each emitted `OffchainMessage` carries its `anchorBlockTimestamp`.

## Protocol and Security Invariants

- Discovery timeout default: `60000ms` (`ExtensionProvider`).
- Key exchange timeout: `2000ms` (`DiscoveredWallet.establishSecureChannel`).
- Secure channel crypto:
- ECDH P-256 + HKDF-SHA256
- AES-256-GCM encryption for message payloads
- separate HMAC-derived verification hash for user comparison
- Verification UX:
- `hashToEmoji` turns hash bytes into emoji sequence
- default output length `9` emojis (3x3 verification grid)

## Workflow API Cheat Sheet

### dApp discovery and connection

- `WalletManager.configure(config)`
- `const discovery = manager.getAvailableWallets({ chainInfo, appId, timeout, onWalletDiscovered })`
  - `for await (const provider of discovery.wallets) { ... }` — iterate as wallets are approved
  - `await discovery.done` — wait for discovery to finish
  - `discovery.cancel()` — stop early (route change, user navigated away)
- `provider.establishSecureChannel(appId)`
- `pending.confirm()` / `pending.cancel()`
- `provider.disconnect()` / `provider.onDisconnect(cb)` / `provider.isDisconnected()`

### low-level extension provider

- `ExtensionProvider.discoverWallets(chainInfo, options)`
- `DiscoveredWallet.establishSecureChannel()`
- `ExtensionWallet.create(extensionId, port, sharedKey, chainInfo, appId)`
- `extensionWallet.disconnect()`

### extension wallet implementation (extension side)

- `new BackgroundConnectionHandler(config, transport, callbacks)` — callbacks all optional
- `handler.initialize()`
- `handler.approveDiscovery(requestId)` / `handler.rejectDiscovery(requestId)`
- `handler.sendResponse(sessionId, walletResponse)`
- `handler.terminateSession(sessionId)` / `handler.terminateForTab(tabId)` / `handler.clearAll()`
- `handler.getPendingDiscoveries()` / `handler.getPendingDiscoveryCount()`
- `handler.getActiveSessions()` / `handler.getSession(sessionId)` / `handler.getPendingDiscovery(requestId)`
- `new ContentScriptConnectionHandler(transport)`
- `contentHandler.start()`
- `contentHandler.closeConnection(sessionId)` / `contentHandler.closeAllConnections()`
- `contentHandler.getConnectionCount()`

### crypto helpers

- `generateKeyPair()`
- `exportPublicKey(publicKey)` / `importPublicKey(exported)`
- `deriveSessionKeys(ownKeyPair, peerPublicKey, isApp)`
- `encrypt(key, json)` / `decrypt<T>(key, payload)`
- `hashToEmoji(hash, count?)`

### base wallet extension

- extend `BaseWallet`
- implement `getAccountFromAddress(address)` and `getAccounts()`
- use inherited helpers:
- `simulateTx`, `profileTx`, `sendTx`
- `createAuthWit`, `registerContract`, `getPrivateEvents`
- `getContractMetadata`, `getContractClassMetadata`
- note that `getContractMetadata(...)` now returns `initializationStatus: ContractInitializationStatus` (values: `INITIALIZED` / `UNINITIALIZED` / `UNKNOWN`) instead of the boolean `isContractInitialized` field

### EmbeddedWallet PXE options

`EmbeddedWalletOptions` (from `@aztec/wallets/embedded`) now exposes a unified `pxe: EmbeddedWalletPXEOptions` field covering both PXE config overrides and creation dependencies (custom store, prover, simulator). The v4.1.x `pxeConfig` / `pxeOptions` fields are kept for backward compatibility but are marked `@deprecated` in v4.2.0 and scheduled for removal — new code should pass a single `pxe: { …config, loggers?, loggerActorLabel?, proverOrOptions?, store?, simulator? }` object.

### Bypass-entrypoint sends and multicall entrypoint

- `NO_FROM` (from `@aztec/aztec.js/account`) is the v4.2.0 sentinel for routing a call past the account entrypoint — it replaces the v4.1.x `AztecAddress.ZERO` placeholder. `NO_FROM` is routed through `DefaultEntrypoint`, which supports a single private call only.
- For multi-call flows (e.g. account-contract self-deployment that also submits a Fee Juice claim, or app-sponsored FPC patterns), wrap the combined payload with `DefaultMultiCallEntrypoint` + `mergeExecutionPayloads` so `DefaultEntrypoint` can dispatch both calls as a single private payload. This is the pattern `DeployAccountMethod.request(...)` uses for self-deployments.

## Extraction Helpers

Summarize exports from the pinned source tree:

```bash
scripts/summarize_wallet_sdk_exports.sh /path/to/aztec-packages
```

Run wallet-sdk tests in pinned source tree:

```bash
scripts/run_wallet_sdk_tests.sh /path/to/aztec-packages
```
