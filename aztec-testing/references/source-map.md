# Aztec Testing Source Map

## Pin Metadata

- `version_label`: `v4.0.0-devnet.2-patch.1`
- `commit_sha`: `1dbe894364c0d179d2f6443b47887766bbf51343`
- `skill_name`: `aztec-testing`

## Source Docs (Pinned)

- `docs/docs-developers/docs/aztec-js/how_to_test.md`
- `docs/docs-developers/docs/aztec-nr/testing_contracts.md`
- `docs/docs-developers/docs/tutorials/testing_governance_rollup_upgrade.md`

## Optional Generated Testing API (Devnet Only)

- `docs/static/aztec-nr-api/devnet/noir_aztec/test/**`
- `docs/static/aztec-nr-api/devnet/std/test/**`

## Referenced Code Fanout

- `yarn-project/end-to-end/src/composed/e2e_local_network_example.test.ts`
- `yarn-project/end-to-end/src/composed/docs_examples.test.ts`
- `docs/examples/ts/aztecjs_testing/index.ts`
- `docs/examples/ts/aztecjs_connection/index.ts`
- `noir-projects/aztec-nr/aztec/src/test/helpers/test_environment.nr`

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
