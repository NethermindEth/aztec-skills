# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added `CHANGELOG.md` following Keep a Changelog 1.1.0 to document current uncommitted repository changes.
- Added `aztec-contracts/SKILL.md` for Aztec.nr contract authoring workflows pinned to devnet `v4.0.0-devnet.2-patch.1`.
- Added `aztec-contracts/agents/openai.yaml` with interface metadata for the Aztec Contracts skill.
- Added `aztec-contracts/references/source-map.md` with pinned contracts doc/code source inventory and packaging constraints.
- Added `aztec-contracts/scripts/build_corpus.sh` to scaffold corpus manifests for the contracts skill.
- Added `aztec-deployment/SKILL.md` for app/operator deployment workflows pinned to devnet `v4.0.0-devnet.2-patch.1`.
- Added `aztec-deployment/agents/openai.yaml` with interface metadata for the Aztec Deployment skill.
- Added `aztec-deployment/references/source-map.md` with pinned deployment runbook/CLI source inventory and packaging constraints.
- Added `aztec-deployment/scripts/build_corpus.sh` to scaffold corpus manifests for the deployment skill.
- Added `aztec-js/SKILL.md` for Aztec.js SDK workflows pinned to devnet `v4.0.0-devnet.2-patch.1`.
- Added `aztec-js/agents/openai.yaml` with interface metadata for the Aztec.js skill.
- Added `aztec-js/references/source-map.md` with pinned Aztec.js docs/API/code source inventory and packaging constraints.
- Added `aztec-js/scripts/build_corpus.sh` to scaffold corpus manifests for the Aztec.js skill.
- Added `aztec-testing/SKILL.md` for Noir and Aztec.js testing workflows pinned to devnet `v4.0.0-devnet.2-patch.1`.
- Added `aztec-testing/agents/openai.yaml` with interface metadata for the Aztec Testing skill.
- Added `aztec-testing/references/source-map.md` with pinned testing docs/API/code source inventory and packaging constraints.
- Added `aztec-testing/scripts/build_corpus.sh` to scaffold corpus manifests for the testing skill.
- Added `aztec-contracts/references/full-docs-reference.md` as navigation for generated full-docs inventories.
- Added `aztec-contracts/references/corpus/manifest.json` with generated corpus metadata and source counts.
- Added `aztec-contracts/references/full-docs/source-docs.txt` with concrete pinned source-doc file paths.
- Added `aztec-contracts/references/full-docs/generated-api-docs.txt` with concrete pinned devnet API doc file paths.
- Added `aztec-contracts/references/full-docs/referenced-code-fanout.txt` with concrete referenced code file paths.
- Added `aztec-contracts/references/full-docs/all-included-paths.txt` with the combined included corpus path set.
- Added `aztec-contracts/references/full-docs/excluded-paths.txt` with excluded nightly/versioned path inventories.

### Changed

- Changed `aztec-contracts/SKILL.md` to make the workflow portable and CLI-agent agnostic, add bundled-inventory fallback behavior, and document full index generation.
- Changed `aztec-contracts/references/source-map.md` to include candidate-doc/source-repository metadata and concrete full-doc inventory usage instructions.
- Changed `aztec-contracts/scripts/build_corpus.sh` from a scaffold manifest writer to a pin-aware corpus/index generator with repo auto-discovery, include/exclude path extraction, and count-rich manifest output.
