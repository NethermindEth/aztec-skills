---
name: aztec-deployment
description: Aztec app-level and operator-level deployment runbooks for pinned devnet v4.0.0-devnet.2-patch.1. Use when tasks involve local/devnet startup, contract deployment flows, operator setup, node/prover/bootnode operations, or staking and sequencer configuration guidance.
---

# Aztec Deployment

## Scope

Handle deployment and operations workflows covering both developer app deployment and operator node infrastructure for the pinned devnet release.

## Workflow

1. Read `references/source-map.md` before answering.
2. Keep all guidance pinned to:
- `version_label: v4.0.0-devnet.2-patch.1`
- `commit_sha: 1dbe894364c0d179d2f6443b47887766bbf51343`
3. Pull detailed procedures from `references/` runbook content.
4. Exclude nightly and versioned-doc paths listed in `references/source-map.md`.
5. When packaging extracted chunks, include:
- `version_label`
- `commit_sha`
- `source_path`
- `skill_name`

## Scaffold Files

- `references/source-map.md`: pinned deployment docs and CLI code fanout.
- `scripts/build_corpus.sh`: starter script to create a manifest and prepare a corpus output directory.
