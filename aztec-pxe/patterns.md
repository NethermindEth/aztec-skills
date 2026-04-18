# PXE Patterns

All patterns assume pin `v4.2.0` (`f8c89cf4345df6c4ca9e66ea9b738e96070abc5a`).

## Pattern 1: Start PXE and Read Anchor Block

Use for deterministic startup before any private operations.

```typescript
import { createAztecNodeClient, waitForNode } from '@aztec/aztec.js/node';
import { createPXE, getPXEConfig } from '@aztec/pxe/server';

const node = createAztecNodeClient('http://localhost:8080');
await waitForNode(node);

const pxe = await createPXE(node, getPXEConfig(), { loggerActorLabel: 'pxe-main' });
const anchor = await pxe.getSyncedBlockHeader();
console.log('Synced anchor block:', anchor.getBlockNumber());
```

## Pattern 2: Register Recipient + Sender for Tagging

Use before private note/log workflows between peers.

```typescript
import { Fr } from '@aztec/aztec.js/fields';
import { computePartialAddress } from '@aztec/stdlib/contract';

// secretKey and partialAddress must be derived from a real account contract.
// partialAddress is NOT a random Fr — it is computed from the account contract's
// class hash, salt, and initialization hash via computePartialAddress(...).
// Use wallet/account helpers such as wallet.createSchnorrAccount(...) or AccountManager.create(...)
// to derive the real complete address and partial address in practice.
const secretKey: Fr = accountSecretKey;           // from account derivation
const partialAddress = computePartialAddress(instance); // from deployed instance

const complete = await pxe.registerAccount(secretKey, partialAddress);
await pxe.registerSender(counterpartyAddress);

console.log('registered account:', complete.address.toString());
console.log('known senders:', (await pxe.getSenders()).map(s => s.toString()));
```

## Pattern 3: Contract Registration Safety Flow

Use when interacting with already-deployed contracts.

```typescript
await pxe.registerContractClass(artifact);
await pxe.registerContract({ instance, artifact });

const storedInstance = await pxe.getContractInstance(instance.address);
if (!storedInstance) {
  throw new Error('contract instance registration failed');
}
```

## Pattern 4: Private Tx Simulation with Scoped Access

Use to validate private execution with least-privilege scopes.

```typescript
const simulation = await pxe.simulateTx(txRequest, {
  simulatePublic: true,
  skipTxValidation: false,
  skipFeeEnforcement: false,
  scopes: [aliceAddress],
});

console.log(simulation.publicOutput?.gasUsed);
```

## Pattern 5: Profile Then Prove

Use when debugging proving cost/regressions.

```typescript
const profile = await pxe.profileTx(txRequest, {
  profileMode: 'execution-steps',
  skipProofGeneration: true,
  scopes: [aliceAddress],
});

console.log(profile.stats.timings);

const proving = await pxe.proveTx(txRequest, [aliceAddress]);
// publicInputs is non-optional on TxProvingResult — no ?. needed
console.log(proving.publicInputs.toFields().length);
```

## Pattern 6: Utility Execution with Authwits

Use for utility entrypoints and sync-state execution paths.

```typescript
const utility = await pxe.executeUtility(functionCall, {
  authwits: [authWitness],
  scopes: [aliceAddress, bobAddress],
});

console.log(utility.stats.timings.total);
```

## Pattern 7: Private Event Query with Explicit Range

Use when troubleshooting missing private events.

```typescript
const events = await pxe.getPrivateEvents(eventSelector, {
  contractAddress,
  scopes: [aliceAddress],
  fromBlock: 1,
  toBlock: 500,
});

console.log(events.length);
```

## Pattern 8: PXE Debug Sync + Raw Notes Inspection

Use only for diagnostics.

```typescript
await pxe.debug.sync();

const notes = await pxe.debug.getNotes({
  contractAddress,
  owner: aliceAddress,
  scopes: [aliceAddress],
});

console.log('debug notes:', notes.length);
```

## Pattern 9: Graceful Shutdown

Use in tests and worker shutdown paths.

```typescript
try {
  // ... PXE operations
} finally {
  await pxe.stop();
}
```
