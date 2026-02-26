# Aztec Deployment Source Map

## Pin Metadata

- `version_label`: `v4.0.0-devnet.2-patch.1`
- `commit_sha`: `1dbe894364c0d179d2f6443b47887766bbf51343`
- `skill_name`: `aztec-deployment`

## App Deployment Docs (Pinned)

- `docs/docs-developers/getting_started_on_local_network.md`
- `docs/docs-developers/getting_started_on_devnet.md`
- `docs/docs-developers/docs/aztec-js/how_to_deploy_contract.md`
- `docs/docs-developers/docs/foundational-topics/contract_creation.md`
- `docs/docs-developers/docs/tutorials/local_network.md`
- `docs/docs/networks.md`

## Operator Deployment Docs (Pinned)

- `docs/docs-operate/operators/index.md`
- `docs/docs-operate/operators/prerequisites.md`
- `docs/docs-operate/operators/setup/blob_storage.md`
- `docs/docs-operate/operators/setup/blob_upload.md`
- `docs/docs-operate/operators/setup/bootnode-operation.md`
- `docs/docs-operate/operators/setup/building-from-source.md`
- `docs/docs-operate/operators/setup/high-availability.md`
- `docs/docs-operate/operators/setup/registering-sequencer.md`
- `docs/docs-operate/operators/setup/running-a-node.md`
- `docs/docs-operate/operators/setup/running-a-prover.md`
- `docs/docs-operate/operators/setup/sequencer-setup.md`
- `docs/docs-operate/operators/setup/staking-provider.md`
- `docs/docs-operate/operators/setup/syncing-best-practices.md`

## Referenced Code Fanout

- `yarn-project/aztec/src/cli/cmds/start_node.ts`
- `yarn-project/aztec/src/cli/cmds/start_prover_node.ts`
- `yarn-project/aztec/src/cli/cmds/start_p2p_bootstrap.ts`
- `yarn-project/aztec/src/cli/aztec_start_options.ts`
- `yarn-project/aztec/src/cli/cli.ts`

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
