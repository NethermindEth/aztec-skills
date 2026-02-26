# Aztec Contracts Full Docs Reference

## Table of Contents

- [Overview](#overview)
- [Pinned Source](#pinned-source)
- [Generated Inventories](#generated-inventories)
- [Refresh Command](#refresh-command)

## Overview

Use this file to navigate concrete, repository-resolved path inventories for the `aztec-contracts` skill.
The inventories are generated from the pinned `aztec-packages` checkout and derived from:

- `docs/internal_notes/llm_docs_skill_candidates.md` (contracts section)
- `references/source-map.md` (skill-local pinned map)

## Pinned Source

- `version_label`: `v4.0.0-devnet.2-patch.1`
- `commit_sha`: `1dbe894364c0d179d2f6443b47887766bbf51343`
- Source repository: `aztec-packages`

## Generated Inventories

- `references/full-docs/source-docs.txt`
- `references/full-docs/generated-api-docs.txt`
- `references/full-docs/referenced-code-fanout.txt`
- `references/full-docs/all-included-paths.txt`
- `references/full-docs/excluded-paths.txt`

Use `all-included-paths.txt` when building retrieval corpora.
Use `excluded-paths.txt` as a denylist sanity check.

## Refresh Command

```bash
scripts/build_corpus.sh /path/to/aztec-packages
```

For a non-pinned checkout:

```bash
AZTEC_ALLOW_UNPINNED=1 scripts/build_corpus.sh /path/to/aztec-packages
```
