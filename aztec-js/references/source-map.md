# Aztec.js Source Map

## Pin Metadata

- `version_label`: `v4.0.0-devnet.2-patch.1`
- `commit_sha`: `1dbe894364c0d179d2f6443b47887766bbf51343`
- `skill_name`: `aztec-js`

## Source Docs (Pinned)

- `docs/docs-developers/docs/aztec-js/**`
- `docs/docs-developers/docs/tutorials/js_tutorials/**`

## Generated API Docs (Devnet Only)

- `docs/static/typescript-api/devnet/accounts.md`
- `docs/static/typescript-api/devnet/aztec.js.md`
- `docs/static/typescript-api/devnet/constants.md`
- `docs/static/typescript-api/devnet/entrypoints.md`
- `docs/static/typescript-api/devnet/foundation.md`
- `docs/static/typescript-api/devnet/llm-summary.txt`
- `docs/static/typescript-api/devnet/pxe.md`
- `docs/static/typescript-api/devnet/stdlib.md`
- `docs/static/typescript-api/devnet/wallet-sdk.md`

## Referenced Code Fanout

- `docs/examples/ts/aztecjs_connection/**`
- `docs/examples/ts/aztecjs_advanced/**`
- `docs/examples/ts/aztecjs_testing/**`
- `docs/examples/ts/aztecjs_getting_started/**`
- `docs/examples/tutorials/token_bridge_contract/**`
- `yarn-project/end-to-end/src/composed/**`
- `yarn-project/end-to-end/src/e2e_deploy_contract/**`

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
