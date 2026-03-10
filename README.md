# Aztec Skills Installer

`install-aztec-skills` is an interactive installer for Aztec-focused LLM skills.

It installs one or more Aztec skills into Codex and/or Claude skill directories, lets you choose project or user scope per target, handles existing installs with an overwrite prompt, and runs a post-install sanity check.

## Installation

Run with `npx` (recommended):

```bash
npx install-aztec-skills@latest
```

or 

```bash
npx install-aztec-skills@devnet
```

Or pin the exact release:

```bash
npx install-aztec-skills@4.1.0-rc.1-v0.2.0
```

List the published installer releases available to install:

```bash
npx install-aztec-skills@latest list
```

The installer prompts you to:
- Select install target(s): `codex`, `claude`, or both.
- Select which Aztec skills to install.
- Select install scope for each selected target: `project` or `user`.
- If a destination already exists, choose overwrite policy: `replace`, `skip`, or `abort`.

Install locations:
- `codex` + `project`: `.agents/skills`
- `codex` + `user`: `~/.agents/skills`
- `claude` + `project`: `.claude/skills`
- `claude` + `user`: `~/.claude/skills`

After copying, the installer validates each installed skill and prints an install summary table with `PASS`/`FAIL` sanity results.

## Commands

- `install-aztec-skills` or `install-aztec-skills install`: run the interactive installer.
- `install-aztec-skills list`: print published installer versions and dist-tags available to install.

## Skills

This repository currently ships 7 Aztec skills:
- `aztec-contracts`: contract authoring and maintenance in Noir/Aztec.nr (storage, functions, authwit, compile/test/codegen workflows).
- `aztec-deployment`: deployment workflows for local network and devnet, fee/payment setup, registration, and verification.
- `aztec-js`: TypeScript/Aztec.js app flows (connectivity, accounts, deploy/call/send/simulate, fees, authwit, event reads).
- `aztec-accounts`: Aztec account lifecycle and abstraction workflows (account flavors, account deployment/recovery, entrypoint routing, fee routing, and key-store expectations).
- `aztec-pxe`: direct PXE operational workflows (private execution lifecycle, note sync/discovery, tagging, private events, and oracle/debug checks).
- `aztec-wallet-sdk`: wallet connectivity and provider integration with `@aztec/wallet-sdk` (discovery, secure channels, extension handlers, encrypted messaging, and BaseWallet workflows).
- `aztec-testing`: Noir `TestEnvironment` testing and TypeScript integration testing workflows.

Each skill directory includes:
- `SKILL.md` (primary guidance)
- `reference.md` and `patterns.md` (deeper references)
- helper scripts under `scripts/`

## Development

Use Bun for local development.

```bash
bun install
bun run ci
bun run test
```

Useful scripts:
- `bun run check:fix` to auto-apply Biome formatting/lint fixes.
- `bun run typecheck` for strict TypeScript checks over `.mjs` via `checkJs`.
