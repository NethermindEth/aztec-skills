---
name: aztec-contracts
description: Noir and Aztec.nr smart-contract authoring, architecture, compilation, and tutorial guidance for pinned devnet v4.0.0-devnet.2-patch.1. Use when tasks involve contract design, writing Aztec.nr code, interpreting Aztec.nr API docs, or mapping contract docs to example code in the pinned repo snapshot.
---

# Aztec Contracts

## Scope

Handle contract-facing workflows for Aztec Noir/Aztec.nr, including architecture choices, authoring patterns, compile-time issues, and tutorial-to-code mapping for the pinned devnet release.

## Workflow

1. Read `references/source-map.md` before answering.
2. Keep all guidance pinned to:
- `version_label: v4.0.0-devnet.2-patch.1`
- `commit_sha: 1dbe894364c0d179d2f6443b47887766bbf51343`
3. Pull heavy details from `references/` files, not from this `SKILL.md`.
4. Treat nightly and versioned-doc paths listed in `references/source-map.md` as excluded.
5. When packaging extracted chunks, include:
- `version_label`
- `commit_sha`
- `source_path`
- `skill_name`

## Scaffold Files

- `references/source-map.md`: pinned source-doc and code fanout inventory.
- `scripts/build_corpus.sh`: starter script to create a manifest and prepare a corpus output directory.
