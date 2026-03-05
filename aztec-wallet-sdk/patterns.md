# Aztec Wallet SDK Patterns

All patterns assume pin `v4.0.0-devnet.2-patch.1` (`1dbe894364c0d179d2f6443b47887766bbf51343`).

## Pattern 1: Stream Wallets with Async Iterator

Use for dApp wallet picker flows.

```typescript
import { Fr } from '@aztec/foundation/fields';
import { WalletManager } from '@aztec/wallet-sdk/manager';

const discovery = WalletManager.configure({
  extensions: { enabled: true },
}).getAvailableWallets({
  chainInfo: { chainId: new Fr(31337), version: new Fr(1) },
  appId: 'my-dapp',
  timeout: 60000,
});

for await (const provider of discovery.wallets) {
  console.log('Discovered wallet:', provider.id, provider.name);
}

await discovery.done;
```

## Pattern 2: Callback-Based Discovery with Early Cancel

Use when UI updates should happen immediately as approvals arrive.

```typescript
import { WalletManager, type WalletProvider } from '@aztec/wallet-sdk/manager';

const providers: WalletProvider[] = [];

const discovery = WalletManager.configure({
  extensions: { enabled: true, blockList: ['blocked-wallet-id'] },
}).getAvailableWallets({
  chainInfo,
  appId: 'my-dapp',
  timeout: 60000,
  onWalletDiscovered: provider => {
    providers.push(provider);
    renderWalletPicker(providers);
  },
});

if (userNavigatedAway) {
  discovery.cancel();
}
```

## Pattern 3: Secure Channel Verification Gate

Use to enforce anti-MITM user verification before wallet use.

```typescript
import { hashToEmoji } from '@aztec/wallet-sdk/crypto';

const pending = await provider.establishSecureChannel('my-dapp');
const emojis = hashToEmoji(pending.verificationHash);

const approved = await showVerificationDialog(emojis);
if (!approved) {
  pending.cancel();
  throw new Error('User rejected verification hash');
}

const wallet = await pending.confirm();
const accounts = await wallet.getAccounts();
console.log(accounts);
```

## Pattern 4: Background Handler Integration

Use in extension service-worker/background script.

```typescript
import {
  BackgroundConnectionHandler,
  type BackgroundConnectionConfig,
  type BackgroundTransport,
  type BackgroundConnectionCallbacks,
} from '@aztec/wallet-sdk/extension/handlers';

const config: BackgroundConnectionConfig = {
  walletId: 'my-wallet',
  walletName: 'My Wallet',
  walletVersion: '1.0.0',
  walletIcon: 'https://example.com/icon.png', // optional
};

const transport: BackgroundTransport = {
  sendToTab: (tabId, message) => browser.tabs.sendMessage(tabId, message),
  addContentListener: listener => browser.runtime.onMessage.addListener(listener),
};

// Declare handler before callbacks so the closure reference is valid.
// All BackgroundConnectionCallbacks fields are optional.
let handler: BackgroundConnectionHandler;

const callbacks: BackgroundConnectionCallbacks = {
  onPendingDiscovery: discovery => queueApproval(discovery),

  onSessionEstablished: session => {
    console.log('Session established:', session.sessionId, 'from', session.origin);
  },

  onSessionTerminated: sessionId => {
    console.log('Session terminated:', sessionId);
  },

  onWalletMessage: async (session, walletMessage) => {
    const response = await walletBackend.handle(walletMessage);
    await handler.sendResponse(session.sessionId, {
      messageId: walletMessage.messageId,
      walletId: config.walletId,
      result: response,
    });
  },
};

handler = new BackgroundConnectionHandler(config, transport, callbacks);
handler.initialize();

function approve(requestId: string) {
  handler.approveDiscovery(requestId);
}

function reject(requestId: string) {
  handler.rejectDiscovery(requestId);
}
```

## Pattern 5: Content Script Relay Setup

Use in extension content script.

```typescript
import {
  ContentScriptConnectionHandler,
  type ContentScriptTransport,
} from '@aztec/wallet-sdk/extension/handlers';

const transport: ContentScriptTransport = {
  sendToBackground: message => browser.runtime.sendMessage(message),
  addBackgroundListener: handler => browser.runtime.onMessage.addListener(handler),
};

const handler = new ContentScriptConnectionHandler(transport);
handler.start();
```

## Pattern 6: Low-Level Provider Flow

Use when manager abstraction is too high-level.

```typescript
import { ExtensionProvider } from '@aztec/wallet-sdk/extension/provider';

const discovered: string[] = [];

await ExtensionProvider.discoverWallets(chainInfo, {
  appId: 'my-dapp',
  timeout: 20000,
  onWalletDiscovered: wallet => {
    discovered.push(wallet.info.id);
  },
});
```

## Pattern 7: Minimal `BaseWallet` Extension

Use for custom wallet implementations backed by PXE and an Aztec node.

```typescript
import { BaseWallet } from '@aztec/wallet-sdk/base-wallet';

class MyWallet extends BaseWallet {
  protected override async getAccountFromAddress(address: AztecAddress): Promise<Account> {
    const account = await loadAccount(address);
    if (!account) throw new Error('Unknown account');
    return account;
  }

  override async getAccounts(): Promise<Aliased<AztecAddress>[]> {
    return getKnownAccounts();
  }
}
```

## Pattern 8: Standalone Crypto Handshake

Use for protocol-level testing and diagnostics.

```typescript
import {
  generateKeyPair,
  exportPublicKey,
  importPublicKey,
  deriveSessionKeys,
  encrypt,
  decrypt,
} from '@aztec/wallet-sdk/crypto';

const appKeys = await generateKeyPair();
const walletKeys = await generateKeyPair();

const appPub = await exportPublicKey(appKeys.publicKey);
const walletPub = await exportPublicKey(walletKeys.publicKey);

const appSession = await deriveSessionKeys(appKeys, await importPublicKey(walletPub), true);
const walletSession = await deriveSessionKeys(walletKeys, await importPublicKey(appPub), false);

if (appSession.verificationHash !== walletSession.verificationHash) {
  throw new Error('Verification hash mismatch');
}

const encrypted = await encrypt(appSession.encryptionKey, JSON.stringify({ ping: true }));
const decrypted = await decrypt<{ ping: boolean }>(walletSession.encryptionKey, encrypted);
console.log(decrypted.ping);
```

## Pattern 9: Provider Disconnect Cleanup

Use to avoid stale wallet handles after extension/session disconnects.

```typescript
const unsubscribe = provider.onDisconnect(() => {
  clearWalletState();
  showReconnectPrompt();
});

await provider.disconnect();
unsubscribe();
```
