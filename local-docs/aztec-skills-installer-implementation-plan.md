# Aztec Skills Installer Implementation Plan (Compressing Intent)

Date: February 27, 2026  
Repository: `/home/ametel/source/aztec-skills`  
Based on: `local-docs/aztec-skills-installer-research.md`

## Objective
Implement a distributable CLI so users can run:

```bash
npx install-aztec-skills
```

and interactively:
1. choose install targets: Codex, Claude, or both (checkbox)
2. choose skill subset from the 4 aztec skills (checkbox)
3. install with target-specific paths and run post-install sanity checks

## Ground Rules (from research + spec)
- Source skills are exactly:
  - `aztec-contracts/`
  - `aztec-deployment/`
  - `aztec-js/`
  - `aztec-testing/`
- Each skill directory must be copied recursively, unchanged.
- Script executability must be preserved (`775` currently on all `scripts/*.sh`).
- Required post-install sanity checks per destination skill:
  - destination directory exists
  - `SKILL.md` exists
  - frontmatter includes `name` and `description`
- Target paths from `CUSTOM_SKILL_INSTALL_REQUIREMENTS_SPEC.md`:
  - Codex project: `.agents/skills/`
  - Codex user: `~/.agents/skills/`
  - Claude project: `.claude/skills/`
  - Claude user: `~/.claude/skills/`

## Resolved Product Decisions (User-Confirmed)
- Scope selection is mandatory in the interactive flow: ask `project` or `user` for each selected target.
- Overwrite behavior is prompt-driven so users can update to newer skill versions when desired.
- System-wide install is forbidden in v1: never prompt for or write to `/etc/codex/skills`.

## Proposed File Changes
1. Add [package.json](/home/ametel/source/aztec-skills/package.json)
2. Add executable entrypoint [bin/install-aztec-skills.mjs](/home/ametel/source/aztec-skills/bin/install-aztec-skills.mjs)
3. Add installer modules:
   - [src/installer/constants.mjs](/home/ametel/source/aztec-skills/src/installer/constants.mjs)
   - [src/installer/prompts.mjs](/home/ametel/source/aztec-skills/src/installer/prompts.mjs)
   - [src/installer/paths.mjs](/home/ametel/source/aztec-skills/src/installer/paths.mjs)
   - [src/installer/copy-skill.mjs](/home/ametel/source/aztec-skills/src/installer/copy-skill.mjs)
   - [src/installer/sanity-check.mjs](/home/ametel/source/aztec-skills/src/installer/sanity-check.mjs)
   - [src/installer/run-install.mjs](/home/ametel/source/aztec-skills/src/installer/run-install.mjs)
4. Add minimal tests/smoke checks:
   - [scripts/smoke-installer.sh](/home/ametel/source/aztec-skills/scripts/smoke-installer.sh)

## Step-by-Step Plan

### Step 1: Bootstrap npm CLI package **COMPLETED**
Change:
- Create `package.json` with:
  - `name: "install-aztec-skills"`
  - `bin: { "install-aztec-skills": "bin/install-aztec-skills.mjs" }`
  - runtime dependency for checkbox prompts (`@inquirer/prompts`)
  - `type: "module"`

Concrete snippet target:
- `bin` mapping must expose the same command name users run via `npx`.

Validation:
```bash
node -e "const p=require('./package.json'); console.log(p.name, p.bin['install-aztec-skills'])"
npm pack --dry-run
```
Expected:
- Name/bin values printed correctly
- Pack list includes `bin/` and `src/` files

Failure modes:
- `npx install-aztec-skills` fails with "command not found" if `bin` mapping is wrong.
- package omits runtime files if `files` field is too restrictive.

### Step 2: Add thin executable entrypoint
Change:
- Create `bin/install-aztec-skills.mjs` with shebang and call into `run-install.mjs`.
- Mark executable (`chmod +x`).

Concrete snippet target:
```js
#!/usr/bin/env node
import { runInstall } from '../src/installer/run-install.mjs';
await runInstall();
```

Validation:
```bash
head -n 1 bin/install-aztec-skills.mjs
stat -c '%a %n' bin/install-aztec-skills.mjs
node bin/install-aztec-skills.mjs --help || true
```
Expected:
- Shebang present
- mode includes execute bit
- entrypoint starts without import errors

Failure modes:
- Missing execute bit breaks direct bin execution in some environments.
- Relative import typo crashes before prompt appears.

### Step 3: Encode authoritative skill catalog
Change:
- Add `src/installer/constants.mjs` defining only these four skills and source paths:
  - `aztec-contracts`
  - `aztec-deployment`
  - `aztec-js`
  - `aztec-testing`
- Include absolute resolution from repo root at runtime.

Concrete file references:
- [aztec-contracts/SKILL.md](/home/ametel/source/aztec-skills/aztec-contracts/SKILL.md)
- [aztec-deployment/SKILL.md](/home/ametel/source/aztec-skills/aztec-deployment/SKILL.md)
- [aztec-js/SKILL.md](/home/ametel/source/aztec-skills/aztec-js/SKILL.md)
- [aztec-testing/SKILL.md](/home/ametel/source/aztec-skills/aztec-testing/SKILL.md)

Validation:
```bash
node -e "import('./src/installer/constants.mjs').then(m=>console.log(m.SKILLS.map(s=>s.name).join(',')))"
```
Expected:
- prints exactly: `aztec-contracts,aztec-deployment,aztec-js,aztec-testing`

Failure modes:
- Dynamic filesystem discovery can accidentally include non-skill dirs; keep catalog explicit.

### Step 4: Implement interactive prompts with checkboxes
Change:
- Add `src/installer/prompts.mjs` using checkbox UI for:
  - install targets: Codex and Claude (multi-select)
  - skills: 4 skills (multi-select)
- Add mandatory scope prompt(s): `project` or `user` for each selected target.
- Enforce non-empty selections.

Concrete snippet targets:
- prompt labels must explicitly show `codex` and `claude`.
- skill labels must map 1:1 to constants from Step 3.

Validation:
- Manual run:
```bash
node bin/install-aztec-skills.mjs
```
Expected:
- checkbox UI appears for targets and skills
- selecting both targets works
- scope prompt is shown for each selected target
- empty selection is rejected with clear message

Failure modes:
- Non-interactive CI/TTY-less runs can fail; detect and print actionable error.
- Prompt library mismatch can produce single-select instead of checkbox.

### Step 5: Map selected target+scope to destination roots
Change:
- Add `src/installer/paths.mjs` with pure functions:
  - `resolveTargetRoot({ target, scope, cwd, home })`
- Use contract paths from `CUSTOM_SKILL_INSTALL_REQUIREMENTS_SPEC.md`:
  - Codex project -> `<cwd>/.agents/skills`
  - Codex user -> `<home>/.agents/skills`
  - Claude project -> `<cwd>/.claude/skills`
  - Claude user -> `<home>/.claude/skills`
- Do not implement any system-scope path mapping (`/etc/codex/skills` is explicitly unsupported).

Validation:
```bash
node -e "import('./src/installer/paths.mjs').then(({resolveTargetRoot})=>{const cwd='/tmp/r';const home='/tmp/h';console.log(resolveTargetRoot({target:'codex',scope:'project',cwd,home}));console.log(resolveTargetRoot({target:'claude',scope:'user',cwd,home}));})"
```
Expected:
- `/tmp/r/.agents/skills`
- `/tmp/h/.claude/skills`

Failure modes:
- Incorrect root mapping silently installs skills where tools cannot discover them.
- Home expansion bugs can write under literal `~` path.
- Any path branch that writes under `/etc` violates product requirements.

### Step 6: Implement recursive copy with metadata preservation
Change:
- Add `src/installer/copy-skill.mjs`:
  - create destination parent dirs
  - copy source skill directory recursively
  - preserve mode/timestamps (`fs.cp` with `preserveTimestamps`, then explicit chmod if needed)
- If destination already exists, prompt for overwrite policy in `run-install.mjs`: `replace`, `skip`, `abort`.

Concrete file invariants to preserve:
- scripts such as [aztec-testing/scripts/run_ts_integration_tests.sh](/home/ametel/source/aztec-skills/aztec-testing/scripts/run_ts_integration_tests.sh)
- script modes currently `775`

Validation:
```bash
tmpdir=$(mktemp -d)
node -e "import('./src/installer/copy-skill.mjs').then(async m=>{await m.copySkill({source:'./aztec-testing',dest:process.argv[1]+'/aztec-testing',overwrite:'replace'});})" "$tmpdir"
stat -c '%a %n' "$tmpdir/aztec-testing/scripts"/*.sh
```
Expected:
- destination contains full tree
- script files retain executable mode

Failure modes:
- Copying only `SKILL.md` breaks referenced scripts/docs.
- Non-preserved modes make helper scripts non-executable.
- Blind overwrite can destroy local user modifications.

### Step 7: Implement post-install sanity checks
Change:
- Add `src/installer/sanity-check.mjs`:
  - assert destination dir exists
  - assert `SKILL.md` exists
  - parse frontmatter keys and require `name`, `description`
  - return structured PASS/FAIL report per skill path

Concrete snippets to validate against:
- frontmatter key examples in [aztec-contracts/SKILL.md:2](/home/ametel/source/aztec-skills/aztec-contracts/SKILL.md:2) and [aztec-contracts/SKILL.md:3](/home/ametel/source/aztec-skills/aztec-contracts/SKILL.md:3)

Validation:
```bash
node -e "import('./src/installer/sanity-check.mjs').then(async m=>{const r=await m.checkInstalledSkill('./aztec-js');console.log(r.ok, r.errors);})"
```
Expected:
- `ok=true` for valid skill dir
- clear error list for invalid dir/file

Failure modes:
- Regex-only frontmatter parsing can mis-detect malformed files; keep checks explicit.
- Installer can report success even when invalid without this step.

### Step 8: Orchestrate install flow and user-facing summary
Change:
- Implement `src/installer/run-install.mjs`:
  - collect prompt answers
  - compute destinations per target/scope and selected skills
  - execute copy operations
  - run sanity checks
  - print table summary with PASS/FAIL and exit code:
    - `0` when all selected installs pass
    - non-zero when any fails

Validation:
```bash
node bin/install-aztec-skills.mjs
echo $? 
```
Expected:
- clear summary for each installed skill+target
- exit code reflects failures

Failure modes:
- Partial failures hidden by always returning `0`.
- Unclear logs make troubleshooting impossible.

### Step 9: Add smoke test script for repeatable validation
Change:
- Add `scripts/smoke-installer.sh` that:
  - creates temp workspace + temp HOME
  - runs installer in test mode (non-interactive input simulation)
  - asserts expected files under:
    - `<tmp-workspace>/.agents/skills/<skill>/SKILL.md`
    - `<tmp-home>/.claude/skills/<skill>/SKILL.md`
  - asserts script executability preserved for one copied script per skill

Validation:
```bash
bash scripts/smoke-installer.sh
```
Expected:
- script exits `0` with pass summary

Failure modes:
- No repeatable smoke test means regressions on paths/modes will slip.

## Validation Matrix (End-to-End)
1. Codex project scope + 1 skill (`aztec-js`)
2. Claude user scope + 2 skills (`aztec-contracts`, `aztec-testing`)
3. Both targets + all 4 skills
4. Existing destination directories with overwrite=`skip`
5. Existing destination directories with overwrite=`replace`
6. Broken install simulation (remove `SKILL.md`) should fail sanity checks and return non-zero
7. Prompt flow does not offer system scope and install code does not write to `/etc/codex/skills`

## Explicit Decisions Locked by This Plan
- Skill list is fixed to the 4 known directories (no auto-discovery in v1).
- Scope is selected explicitly (project/user), per chosen target.
- Overwrite behavior is explicit and user-controlled (`replace|skip|abort`).
- Installer only handles project/user scopes in v1 and must never offer or perform system-wide installs.

## Out of Scope (v1)
- Publishing to npm registry automation/CI release pipeline.
- Windows-specific ACL/perms normalization beyond preserving executable bit semantics where supported.
- Auto-restart or runtime verification inside Codex/Claude sessions.
