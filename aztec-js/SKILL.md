---
name: aztec-js
description: Aztec.js SDK workflows for network setup, account and wallet flows, transactions, reads, authwits, and deployment interactions for pinned devnet v4.0.0-devnet.2-patch.1. Use when tasks require Aztec.js API usage, TypeScript integration patterns, or mapping SDK docs to example code.
---

# Aztec.js

## Scope

Handle Aztec.js SDK implementation tasks, including connection setup, account lifecycle, transaction execution, read/query patterns, authwit workflows, and contract deployment-related SDK usage.

## Workflow

1. Read `references/source-map.md` before answering.
2. Keep all guidance pinned to:
- `version_label: v4.0.0-devnet.2-patch.1`
- `commit_sha: 1dbe894364c0d179d2f6443b47887766bbf51343`
3. Load detailed APIs and patterns from `references/`, especially the devnet TypeScript API subset.
4. Exclude nightly and versioned-doc paths listed in `references/source-map.md`.
5. When packaging extracted chunks, include:
- `version_label`
- `commit_sha`
- `source_path`
- `skill_name`

## Scaffold Files

- `references/source-map.md`: pinned doc and code-source inventory for Aztec.js.
- `scripts/build_corpus.sh`: starter script to create a manifest and prepare a corpus output directory.
