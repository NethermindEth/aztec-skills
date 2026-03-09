---
name: aztec-wallet-sdk
description: Use this skill when integrating Aztec wallet connectivity with @aztec/wallet-sdk, including discovery/session flows, secure-channel key exchange, extension handlers, encrypted messaging, and BaseWallet implementations.
license: Proprietary. LICENSE.txt has complete terms
compatibility: Pinned to aztec-packages v4.1.0-rc.1 (commit 77e5b3ca816702e2cee866aec1a0d6ce997e0ea6).
metadata:
  version_label: v4.1.0-rc.1
  commit_sha: 77e5b3ca816702e2cee866aec1a0d6ce997e0ea6
  source_map: aztec-packages/yarn-project/wallet-sdk
---

# Aztec Wallet SDK Integration

## Overview

Use this skill for wallet connectivity and wallet-provider implementation work with `@aztec/wallet-sdk`.

Primary scope:

- dApp wallet discovery with `WalletManager`
- secure channel establishment (`PendingConnection`, key exchange, verification hash)
- extension-specific provider usage (`ExtensionProvider`, `ExtensionWallet`)
- extension relay handlers (`BackgroundConnectionHandler`, `ContentScriptConnectionHandler`)
- encrypted message protocol and session lifecycle handling
- wallet implementation extension via `BaseWallet`

Out of scope:

- Noir/Aztec.nr contract authoring (use `aztec-contracts`)
- contract deployment workflows (use `aztec-deployment`)
- broad Aztec.js app development beyond wallet-connection concerns (use `aztec-js`)

## Required Repository State

Use the upstream repository and pin:

- Repo: `https://github.com/AztecProtocol/aztec-packages`
- Tag: `v4.1.0-rc.1`
- Commit: `77e5b3ca816702e2cee866aec1a0d6ce997e0ea6`
- Source root: `yarn-project/wallet-sdk`

Checkout example:

```bash
git clone https://github.com/AztecProtocol/aztec-packages.git
cd aztec-packages
git checkout v4.1.0-rc.1
git status
```

Expected status includes `HEAD detached at v4.1.0-rc.1`.

## Operating Rules

- Follow the two-phase protocol strictly: discovery first, then key exchange.
- Do not call wallet methods until `PendingConnection.confirm()` succeeds.
- Treat verification-hash comparison as mandatory before confirming a connection.
- Keep extension private keys and derived session keys in background context only.
- Keep content scripts as message relays only; no crypto or session-key state there.
- Handle disconnect control messages (`WalletMessageType.DISCONNECT`) and cleanup all in-flight requests.
- Use explicit `chainInfo` and `appId` on discovery and message flows.
- Respect allow/block list policies when exposing extension wallets.
- For custom wallet implementations, extend `BaseWallet` and implement account lookup and capability behavior explicitly.

## Quick Start

```bash
# Install core SDK deps (choose one package manager)
scripts/install_wallet_sdk_deps.sh npm
```

```typescript
import { Fr } from '@aztec/foundation/fields';
import { WalletManager } from '@aztec/wallet-sdk/manager';
import { hashToEmoji } from '@aztec/wallet-sdk/crypto';

const discovery = WalletManager.configure({
  extensions: { enabled: true },
}).getAvailableWallets({
  chainInfo: { chainId: new Fr(31337), version: new Fr(1) },
  appId: 'my-dapp',
  timeout: 60000,
});

for await (const provider of discovery.wallets) {
  const pending = await provider.establishSecureChannel('my-dapp');
  console.log('Verify:', hashToEmoji(pending.verificationHash));
  const wallet = await pending.confirm();
  const accounts = await wallet.getAccounts();
  console.log(accounts);
}
```

## Core Workflows

### 1. Discover Wallet Providers (dApp Side)

- Configure manager with `WalletManager.configure({ extensions: { enabled: true } })`.
- Start discovery with `getAvailableWallets({ chainInfo, appId, timeout, onWalletDiscovered? })`.
- Consume discovered providers using either:
- async iteration via `discovery.wallets`
- callback via `onWalletDiscovered`
- Cancel discovery on route/network changes via `discovery.cancel()`.

### 2. Establish and Verify Secure Channel

- Call `provider.establishSecureChannel(appId)`.
- Display `pending.verificationHash` using `hashToEmoji(...)`.
- Require user confirmation that wallet UI and dApp UI match.
- Call `pending.confirm()` only after user confirmation.
- Call `pending.cancel()` if verification fails.

### 3. Use Low-Level Extension Provider (When Needed)

- Use `ExtensionProvider.discoverWallets(chainInfo, options)` when bypassing manager abstractions.
- Handle `DiscoveredWallet` entries through `onWalletDiscovered` callback.
- Promote a discovered wallet to connected state with `discovered.establishSecureChannel()`.
- Enforce key exchange timeout handling and retry policy.

### 4. Implement Extension Wallet Transport

Background script:

- Instantiate `BackgroundConnectionHandler(config, transport, callbacks)`.
- Call `initialize()` once.
- All `BackgroundConnectionCallbacks` fields are optional:
  - `onPendingDiscovery` — queues approval UI for incoming discovery requests.
  - `onSessionEstablished` — notified when key exchange completes and a session is live.
  - `onSessionTerminated` — notified when a session ends (disconnect or tab close).
  - `onWalletMessage` — receives decrypted wallet calls; call `sendResponse` with result.
- On user approval/rejection, call `approveDiscovery(requestId)` or `rejectDiscovery(requestId)`.
- Forward decrypted wallet calls from `onWalletMessage` to wallet backend.
- Return encrypted responses through `sendResponse(sessionId, walletResponse)`.
- Declare `handler` with `let` before defining callbacks that reference it (avoids temporal deadzone).

Content script:

- Instantiate `ContentScriptConnectionHandler(transport)`.
- Call `start()` once.
- Relay discovery, key exchange, encrypted messages, and disconnect notifications.

### 5. Encrypted Protocol and Message Types

- Discovery/control types use `WalletMessageType`:
- `DISCOVERY`
- `DISCOVERY_RESPONSE`
- `KEY_EXCHANGE_REQUEST`
- `KEY_EXCHANGE_RESPONSE`
- `DISCONNECT`
- Use `generateKeyPair`, `exportPublicKey`, `importPublicKey`, `deriveSessionKeys` for key exchange.
- Use `encrypt`/`decrypt` for all post-handshake payloads.
- Keep request correlation by `requestId`/`messageId` and validate `walletId` on responses.

### 6. Build Custom Wallets with `BaseWallet`

- Extend `BaseWallet` for wallet implementations backed by PXE + Aztec node.
- Implement:
- `getAccountFromAddress(address)`
- `getAccounts()`
- Use built-ins for common wallet operations:
- `simulateTx`, `profileTx`, `sendTx`
- `registerContract`, `registerSender`
- `createAuthWit`, `getPrivateEvents`
- `getContractMetadata`, `getContractClassMetadata`
- Override capabilities handling with `requestCapabilities(...)` for external wallets.

### 7. Session Lifecycle and Disconnect Handling

- Register disconnect hooks via `provider.onDisconnect(callback)` — returns an unsubscribe function.
- Check `provider.isDisconnected()` to test current session state without polling.
- On disconnect, clear app state and stop using prior wallet handles.
- Call `provider.disconnect()` on app shutdown or wallet switch.
- In background handler, terminate stale sessions with `terminateSession(...)`/`terminateForTab(...)`/`clearAll()`.

### 8. Test and Validation Flow

- Use wallet-sdk unit tests in `yarn-project/wallet-sdk/src/**/*.test.ts` as behavior references.
- Validate mixed simulation path behavior and private-event decoding patterns from `base_wallet.test.ts`.
- Add integration checks for:
- discovery timeout behavior
- key exchange timeout (`2s` in `DiscoveredWallet`)
- disconnect propagation and in-flight rejection handling

## Tooling / Commands

```bash
# preflight checks (node + package manager + optional node URL + optional source path)
scripts/preflight_wallet_sdk.sh [node-url] [wallet-sdk-dir]

# install wallet-sdk dependencies
scripts/install_wallet_sdk_deps.sh <npm|yarn|pnpm> [version]

# run a TS wallet-sdk example with tsx (tsx must be installed: npm install -D tsx)
scripts/run_wallet_sdk_example.sh <entry-file.ts> [-- <extra-args...>]

# summarize package entrypoints/exports from aztec-packages checkout
scripts/summarize_wallet_sdk_exports.sh <aztec-packages-dir>

# run wallet-sdk package tests from aztec-packages checkout
scripts/run_wallet_sdk_tests.sh <aztec-packages-dir> [test-name-pattern]
```

## Edge Cases and Failure Handling

- Wallet discovery yields no providers:
check user approval path and discovery timeout (default `60000ms`).
- Key exchange fails with timeout:
`DiscoveredWallet.establishSecureChannel()` enforces a `2000ms` timeout; retry from approved discovery state.
- Verification hash mismatch:
cancel the pending connection and do not call `confirm()`.
- Wallet responses ignored unexpectedly:
validate `walletId`, `messageId`, and per-session routing state.
- Calls fail after disconnect:
expected; `ExtensionWallet` rejects in-flight and future calls once disconnected.
- Extension appears in discovery but not manager output:
check `allowList`/`blockList` filtering in manager config.
- `PendingDiscovery.appName` is always `undefined` at this pin:
`DiscoveryRequest` does not carry an `appName` field, so `BackgroundConnectionHandler` never populates it. Do not rely on it for UI labelling; use `appId` and `origin` instead.

## Next Steps / Related Files

- Use `reference.md` for pinned source corpus and API/file map.
- Use `patterns.md` for reusable dApp and extension integration snippets.
- Use `scripts/` for repeatable setup, inspection, and test workflows.
