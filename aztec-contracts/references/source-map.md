# Aztec Contracts Source Map

## Pin Metadata

- `version_label`: `v4.0.0-devnet.2-patch.1`
- `commit_sha`: `1dbe894364c0d179d2f6443b47887766bbf51343`
- `skill_name`: `aztec-contracts`
- `candidate_doc`: `docs/internal_notes/llm_docs_skill_candidates.md`
- `source_repository`: `aztec-packages`

## Source Docs (Pinned)

- `docs/docs-developers/docs/aztec-nr/**`
- `docs/docs-developers/docs/foundational-topics/contract_creation.md`
- `docs/docs-developers/docs/tutorials/contract_tutorials/**`

## Generated API Docs (Devnet Only)

- `docs/static/aztec-nr-api/devnet/**`

## Referenced Code Fanout

- `docs/examples/contracts/**`
- `docs/examples/circuits/**`
- `docs/examples/ts/bob_token_contract/**`
- `docs/examples/ts/recursive_verification/**`
- `noir-projects/noir-contracts/contracts/**`
- `noir-projects/aztec-nr/**`
- `noir-projects/noir-protocol-circuits/crates/types/src/abis/**`
- `l1-contracts/src/**`

## Packaging Constraints

For every extracted reference chunk, include:

- `version_label`
- `commit_sha`
- `source_path`
- `skill_name`

Exclude:

- `docs/static/typescript-api/nightly/**`
- `docs/static/aztec-nr-api/nightly/**`
- `docs/developer_versioned_docs/**`
- `docs/network_versioned_docs/**`

## Concrete File Inventories

Generate concrete path inventories from the pinned repository with:

```bash
scripts/build_corpus.sh /path/to/aztec-packages
```

Then use:

- `references/full-docs/source-docs.txt`
- `references/full-docs/generated-api-docs.txt`
- `references/full-docs/referenced-code-fanout.txt`
- `references/full-docs/all-included-paths.txt`
- `references/full-docs/excluded-paths.txt`
