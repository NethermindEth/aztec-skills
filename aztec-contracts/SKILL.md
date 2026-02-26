---
name: aztec-contracts
description: Noir and Aztec.nr smart-contract authoring, architecture, compilation, and contract tutorial guidance for pinned devnet v4.0.0-devnet.2-patch.1. Use when tasks involve contract design, writing Aztec.nr code, interpreting Aztec.nr API docs, mapping docs to repo examples, or building contracts-focused reference corpora from a pinned aztec-packages checkout or bundled reference inventories.
---

# Aztec Contracts

Handle contract-focused Aztec workflows for the pinned release only.
Keep commands and procedures CLI-agnostic so they work in Codex, Claude, Gemini, or other coding-agent CLIs.

## Required Inputs

- Read [references/source-map.md](references/source-map.md) first.
- Prefer a local checkout of `aztec-packages` when available.
- Use `docs/internal_notes/llm_docs_skill_candidates.md` from that checkout as the upstream candidate-source note.
- If no checkout is available, use bundled files under `references/full-docs/`.

## Workflow

1. Verify pin before producing guidance:
- `version_label: v4.0.0-devnet.2-patch.1`
- `commit_sha: 1dbe894364c0d179d2f6443b47887766bbf51343`
2. Load contract docs and APIs from the source-map scopes only.
3. Exclude nightly and versioned-doc trees listed in `references/source-map.md`.
4. Resolve ambiguity by preferring:
- docs in `docs/docs-developers/docs/aztec-nr/**`
- generated devnet API docs in `docs/static/aztec-nr-api/devnet/**`
- pinned code fanout examples listed in `references/source-map.md`
5. When creating corpus chunks, include:
- `version_label`
- `commit_sha`
- `source_path`
- `skill_name`

## Build Full Reference Index

Run:

```bash
scripts/build_corpus.sh /path/to/aztec-packages
```

This command:
- verifies the pinned commit (or fails unless `AZTEC_ALLOW_UNPINNED=1`)
- writes corpus metadata under `references/corpus/`
- writes concrete path inventories under `references/full-docs/`

If `/path/to/aztec-packages` is omitted, the script tries:
- `AZTEC_REPO_ROOT` (if set)
- current working directory (if it looks like `aztec-packages`)
- sibling path `../aztec-packages` relative to this skill repo

## Bundled Resources

- `references/source-map.md`: pinned source-doc and code fanout inventory.
- `references/full-docs-reference.md`: navigation for generated concrete file inventories.
- `scripts/build_corpus.sh`: pin-aware corpus and full-reference index generator.
