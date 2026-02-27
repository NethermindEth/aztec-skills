# Aztec Skills Installer Research (Code-First)

Date: February 27, 2026
Repository: `/home/ametel/source/aztec-skills`

## Goal
Define factual requirements for an installer that can install these skills for Codex, Claude Code, or both, with post-install sanity checks.

## Method (Compressing Truth)
- Read repository files and scripts directly.
- Treat the custom install spec as the target interface contract for Codex/Claude paths.
- Validate findings with shell checks (not assumptions).

## Authoritative Files
- Skill roots:
  - `aztec-contracts/`
  - `aztec-deployment/`
  - `aztec-js/`
  - `aztec-testing/`
- Skill entrypoints:
  - `aztec-contracts/SKILL.md`
  - `aztec-deployment/SKILL.md`
  - `aztec-js/SKILL.md`
  - `aztec-testing/SKILL.md`
- Install path contract:
  - `CUSTOM_SKILL_INSTALL_REQUIREMENTS_SPEC.md`

## Ground Truth Findings (From Code)
1. There are exactly 4 installable skills in this repo.
2. Each skill is a directory with required entry file `SKILL.md`.
3. Each `SKILL.md` includes YAML frontmatter with both `name` and `description`.
4. `name` matches the directory name for all 4 skills.
5. Skills are not single-file assets; each skill includes companion docs (`patterns.md`, `reference.md`, `LICENSE.txt`) and shell helpers in `scripts/`.
6. All script files are executable (`775`), so installer copy must preserve executability.
7. Some scripts call sibling scripts by relative path (example: deployment and testing wrappers), so directory layout must remain intact.

## Codex vs Claude Install Requirements (From Spec Contract)
From `CUSTOM_SKILL_INSTALL_REQUIREMENTS_SPEC.md`:

- Codex discovery paths:
  - Project/repo scope: `.agents/skills/`
  - User scope: `~/.agents/skills`
  - (system scope exists but should not be default for unprivileged installer)

- Claude Code discovery paths:
  - Project scope: `.claude/skills/<skill-name>/SKILL.md`
  - User scope: `~/.claude/skills/<skill-name>/SKILL.md`

Implication: installer must map the same selected skill set into different root folders per target CLI.

## Non-Negotiable Installer Behaviors
1. Interactive target selection with checkbox options: `codex`, `claude` (allow both).
2. Interactive skill selection with checkbox options for all 4 skill directories.
3. Installation copies full skill directory recursively, not only `SKILL.md`.
4. Preserve file modes/executable scripts.
5. Do not mutate skill contents during install.
6. Post-install sanity check per installed skill path:
   - destination directory exists
   - `SKILL.md` exists
   - frontmatter contains `name` and `description`

## Manual Validation Performed
Commands run and observed:

- Skill directory discovery:
  - `find . -maxdepth 1 -mindepth 1 -type d -name 'aztec-*' | sort`
  - Result: `aztec-contracts`, `aztec-deployment`, `aztec-js`, `aztec-testing`

- `SKILL.md` existence:
  - Verified all four `*/SKILL.md` files exist.

- Frontmatter presence (`name`, `description`) and name-directory match:
  - Checked all 4 via `sed` extraction.
  - Result: all PASS.

- Companion files and script references:
  - `rg -o 'scripts/[A-Za-z0-9_./-]+\.sh' <skill>/SKILL.md` and file existence checks.
  - Result: all referenced script paths exist.

- Executable bit:
  - `stat -c '%a %n' <skill>/scripts/*.sh`
  - Result: all scripts are mode `775`.

## Open Risks / Decisions (Not Assumed)
1. Scope prompt granularity: whether installer should ask project vs user scope for each target (spec supports both).
2. Overwrite policy on existing installed skill directories (replace vs skip vs prompt).
3. System scope installs (e.g., `/etc/codex/skills`) likely require elevated permissions and should be excluded unless explicitly requested.

## Minimal Acceptance Checklist
- User can select `codex`, `claude`, or both in one run.
- User can select any subset of the 4 skills in one run.
- Skills are installed under target-specific roots with intact directory contents.
- Sanity check reports per-skill PASS/FAIL after copy.
