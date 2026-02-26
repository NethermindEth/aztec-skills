---
name: aztec-testing
description: Aztec contract testing workflows across Noir test environment patterns, Aztec.js integration tests, and governance upgrade testing tutorials for pinned devnet v4.0.0-devnet.2-patch.1. Use when tasks involve writing, debugging, or structuring contract tests and end-to-end scenarios.
---

# Aztec Testing

## Scope

Handle contract and integration testing guidance spanning Aztec.nr test helpers, Aztec.js testing flows, and governance rollup upgrade test workflows in the pinned codebase.

## Workflow

1. Read `references/source-map.md` before answering.
2. Keep all guidance pinned to:
- `version_label: v4.0.0-devnet.2-patch.1`
- `commit_sha: 1dbe894364c0d179d2f6443b47887766bbf51343`
3. Pull test-specific details from `references/` and linked code examples.
4. Exclude nightly and versioned-doc paths listed in `references/source-map.md`.
5. When packaging extracted chunks, include:
- `version_label`
- `commit_sha`
- `source_path`
- `skill_name`

## Scaffold Files

- `references/source-map.md`: pinned testing docs, APIs, and code fanout.
- `scripts/build_corpus.sh`: starter script to create a manifest and prepare a corpus output directory.
