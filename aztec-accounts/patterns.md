# Aztec Accounts Patterns

All patterns assume pin `v4.1.0-rc.1` (`77e5b3ca816702e2cee866aec1a0d6ce997e0ea6`).

## Pattern 1: Create and Deploy a Schnorr Account

Use when provisioning a new application account with an external payer.

```typescript
import { Fr, GrumpkinScalar } from '@aztec/aztec.js/fields';
import { createAztecNodeClient, waitForNode } from '@aztec/aztec.js/node';
import { EmbeddedWallet } from '@aztec/wallets/embedded';

const node = createAztecNodeClient('http://localhost:8080');
await waitForNode(node);

const wallet = await EmbeddedWallet.create(node);
const secret = Fr.random();
const salt = Fr.random();
const signingKey = GrumpkinScalar.random();

const accountManager = await wallet.createSchnorrAccount(secret, salt, signingKey);
const deployMethod = await accountManager.getDeployMethod();

await deployMethod.send({ from: fundedAccountAddress });

console.log('account:', accountManager.address.toString());
console.log('partial:', (await accountManager.getCompleteAddress()).partialAddress.toString());
```

## Pattern 2: Precompute a Schnorr Account Address

Use when you need the deterministic address before deployment.

```typescript
import { Fr, GrumpkinScalar } from '@aztec/aztec.js/fields';
import { getSchnorrAccountContractAddress } from '@aztec/accounts/schnorr';

const secret = Fr.random();
const salt = Fr.random();
const signingKey = GrumpkinScalar.random();

const address = await getSchnorrAccountContractAddress(secret, salt, signingKey);
console.log(address.toString());
```

## Pattern 3: Reconstruct the Same Schnorr Account in a New Session

Use for deterministic wallet recovery.

```typescript
import { Fr, GrumpkinScalar } from '@aztec/aztec.js/fields';
import { createAztecNodeClient, waitForNode } from '@aztec/aztec.js/node';
import { EmbeddedWallet } from '@aztec/wallets/embedded';

const node = createAztecNodeClient('http://localhost:8080');
await waitForNode(node);

const wallet = await EmbeddedWallet.create(node);

const secret = Fr.fromString(process.env.ACCOUNT_SECRET!);
const salt = Fr.fromString(process.env.ACCOUNT_SALT!);
const signingKey = GrumpkinScalar.fromString(process.env.ACCOUNT_SIGNING_KEY!);

const accountManager = await wallet.createSchnorrAccount(secret, salt, signingKey);
const recovered = await accountManager.getAccount();

console.log(recovered.getAddress().toString());
```

## Pattern 4: Build an ECDSA Account

Use when the signer is secp256k1 or secp256r1 based.

```typescript
import { Fr } from '@aztec/aztec.js/fields';
import { EmbeddedWallet } from '@aztec/wallets/embedded';

const wallet = await EmbeddedWallet.create('http://localhost:8080');
const secret = Fr.random();
const salt = Fr.random();
const secp256k1PrivateKey = Buffer.from(process.env.ECDSA_K_PRIVKEY!, 'hex');
const secp256r1PrivateKey = Buffer.from(process.env.ECDSA_R_PRIVKEY!, 'hex');

const kAccount = await wallet.createECDSAKAccount(secret, salt, secp256k1PrivateKey);
const rAccount = await wallet.createECDSARAccount(secret, salt, secp256r1PrivateKey);

console.log(kAccount.address.toString());
console.log(rAccount.address.toString());
```

## Pattern 5: Lower-Level Reconstruction with `AccountManager`

Use when you want direct control over account contract instantiation.

```typescript
import { AccountManager } from '@aztec/aztec.js/wallet';
import { Fr, GrumpkinScalar } from '@aztec/aztec.js/fields';
import { SchnorrAccountContract } from '@aztec/accounts/schnorr';

const secret = Fr.fromString(process.env.ACCOUNT_SECRET!);
const salt = Fr.fromString(process.env.ACCOUNT_SALT!);
const signingKey = GrumpkinScalar.fromString(process.env.ACCOUNT_SIGNING_KEY!);

const contract = new SchnorrAccountContract(signingKey);
const manager = await AccountManager.create(wallet, secret, contract, salt);

await wallet.registerContract(manager.getInstance(), await contract.getContractArtifact(), secret);

const account = await manager.getAccount();
console.log(account.getAddress().toString());
```

## Pattern 6: KeyStore Add + Validation Request

Use when wiring key validation into PXE-facing flows.

```typescript
import { Fr } from '@aztec/aztec.js/fields';
import { openTmpStore } from '@aztec/kv-store/lmdb-v2';
import { KeyStore } from '@aztec/key-store';

const db = await openTmpStore('accounts-skill-demo');
const keyStore = new KeyStore(db);

const secret = Fr.random();
const partialAddress = Fr.random();
const complete = await keyStore.addAccount(secret, partialAddress);

const nullifierPk = await keyStore.getMasterNullifierPublicKey(complete.address);
const pkHash = await nullifierPk.hash();
const validation = await keyStore.getKeyValidationRequest(pkHash, complete.address);

console.log(complete.address.toString());
console.log(validation.pkM.toString());
```

## Pattern 7: Deterministic Test Accounts

Use for local-network and integration tests.

```typescript
import { getInitialTestAccountsData, generateSchnorrAccounts } from '@aztec/accounts/testing';

const [prefunded] = await getInitialTestAccountsData();
console.log(prefunded.address.toString());

const generated = await generateSchnorrAccounts(2);
console.log(generated.map(account => account.address.toString()));
```
