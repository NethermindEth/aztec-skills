# Aztec Skills Installer

`install-aztec-skills` is an interactive installer for Aztec-focused LLM skills.

It installs one or more Aztec skills into Codex and/or Claude skill directories, lets you choose project or user scope per target, handles existing installs with an overwrite prompt, and runs a post-install sanity check.

## Installation

Run with `npx` (recommended):

```bash
npx install-aztec-skills@devnet
```

Or pin the exact release:

```bash
npx install-aztec-skills@4.0.0-devnet.2-patch.1-v0.1.1
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

## Skills

This repository currently ships 4 Aztec skills:
- `aztec-contracts`: contract authoring and maintenance in Noir/Aztec.nr (storage, functions, authwit, compile/test/codegen workflows).
- `aztec-deployment`: deployment workflows for local network and devnet, fee/payment setup, registration, and verification.
- `aztec-js`: TypeScript/Aztec.js app flows (connectivity, accounts, deploy/call/send/simulate, fees, authwit, event reads).
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
