import { checkbox, select } from '@inquirer/prompts'
import { SKILLS } from './constants.mjs'

const VALID_TARGETS = new Set(['codex', 'claude'])
const VALID_SCOPES = new Set(['project', 'user'])
const VALID_SKILLS = new Set(SKILLS.map((skill) => skill.name))
const SELECT_ALL_SKILLS = '__select_all_skills__'
const INSTALLER_BANNER = `
  █████╗  ███████╗ ████████╗ ███████╗  ██████╗
 ██╔══██╗ ╚══███╔╝ ╚══██╔══╝ ██╔════╝ ██╔════╝
 ███████║   ███╔╝     ██║    █████╗   ██║
 ██╔══██║  ███╔╝      ██║    ██╔══╝   ██║
 ██║  ██║ ███████╗    ██║    ███████╗ ╚██████╗
 ╚═╝  ╚═╝ ╚══════╝    ╚═╝    ╚══════╝  ╚═════╝

 ███████╗ ██╗  ██╗ ██╗ ██╗      ██╗      ███████╗
 ██╔════╝ ██║ ██╔╝ ██║ ██║      ██║      ██╔════╝
 ███████╗ █████╔╝  ██║ ██║      ██║      ███████╗
 ╚════██║ ██╔═██╗  ██║ ██║      ██║      ╚════██║
 ███████║ ██║  ██╗ ██║ ███████╗ ███████╗ ███████║
 ╚══════╝ ╚═╝  ╚═╝ ╚═╝ ╚══════╝ ╚══════╝ ╚══════╝
`

/**
 * @typedef {'codex' | 'claude'} Target
 * @typedef {'project' | 'user'} Scope
 * @typedef {{ targets: Target[]; skills: string[]; scopes: Record<string, Scope> }} InstallerSelections
 */

/**
 * @returns {Promise<Target[]>}
 */
export async function promptTargets() {
  return checkbox({
    message: 'Select install targets',
    choices: [
      { name: 'codex', value: 'codex' },
      { name: 'claude', value: 'claude' },
    ],
    validate(value) {
      return value.length > 0 || 'Select at least one target.'
    },
  })
}

/**
 * @returns {Promise<string[]>}
 */
export async function promptSkills() {
  const selectedSkills = await checkbox({
    message: 'Select skills to install',
    choices: [
      { name: 'select all', value: SELECT_ALL_SKILLS },
      ...SKILLS.map((skill) => ({
        name: skill.name,
        value: skill.name,
      })),
    ],
    validate(value) {
      return value.length > 0 || 'Select at least one skill.'
    },
  })

  if (selectedSkills.includes(SELECT_ALL_SKILLS)) {
    return SKILLS.map((skill) => skill.name)
  }

  return selectedSkills
}

/**
 * @param {Target} target
 * @returns {Promise<Scope>}
 */
async function promptScopeForTarget(target) {
  return select({
    message: `Select ${target} install scope`,
    choices: [
      { name: 'project', value: 'project' },
      { name: 'user', value: 'user' },
    ],
    default: 'project',
  })
}

/**
 * @param {Target[]} selectedTargets
 * @returns {Promise<Record<string, Scope>>}
 */
export async function promptScopes(selectedTargets) {
  /** @type {Record<string, Scope>} */
  const scopes = {}
  for (const target of selectedTargets) {
    scopes[target] = await promptScopeForTarget(target)
  }
  return scopes
}

/**
 * @param {unknown} value
 * @param {string} fieldName
 */
function assertNonEmptyArray(value, fieldName) {
  if (!Array.isArray(value) || value.length === 0) {
    throw new Error(`Invalid ${fieldName}: expected non-empty array.`)
  }
}

/**
 * @param {unknown} payload
 */
function validateSelectionsPayload(payload) {
  if (!payload || typeof payload !== 'object') {
    throw new Error('Invalid installer selections payload.')
  }

  const candidate = /** @type {InstallerSelections} */ (payload)

  assertNonEmptyArray(candidate.targets, 'targets')
  assertNonEmptyArray(candidate.skills, 'skills')

  if (!candidate.scopes || typeof candidate.scopes !== 'object') {
    throw new Error('Invalid scopes: expected object.')
  }

  for (const target of candidate.targets) {
    if (!VALID_TARGETS.has(target)) {
      throw new Error(`Invalid target: ${target}`)
    }
    const scope = candidate.scopes[target]
    if (!VALID_SCOPES.has(scope)) {
      throw new Error(`Invalid scope for ${target}: ${scope}`)
    }
  }

  for (const skill of candidate.skills) {
    if (!VALID_SKILLS.has(skill)) {
      throw new Error(`Invalid skill: ${skill}`)
    }
  }
}

/**
 * @param {NodeJS.ProcessEnv} [env]
 * @returns {InstallerSelections | null}
 */
export function getSelectionsFromEnv(env = process.env) {
  const raw = env.INSTALL_AZTEC_SKILLS_SELECTIONS
  if (!raw) {
    return null
  }

  let parsed
  try {
    parsed = JSON.parse(raw)
  } catch (error) {
    const message =
      error instanceof Error ? error.message : 'Unknown JSON parse error.'
    throw new Error(
      `INSTALL_AZTEC_SKILLS_SELECTIONS is not valid JSON: ${message}`,
    )
  }

  validateSelectionsPayload(parsed)
  return /** @type {InstallerSelections} */ (parsed)
}

/**
 * @returns {Promise<InstallerSelections>}
 */
export async function promptInstallSelections() {
  const fromEnv = getSelectionsFromEnv()
  if (fromEnv) {
    return fromEnv
  }

  console.log(INSTALLER_BANNER)
  console.log('Interactive installer for Aztec skills in Codex and Claude.\n')

  const targets = await promptTargets()
  const skills = await promptSkills()
  const scopes = await promptScopes(targets)

  return {
    targets,
    skills,
    scopes,
  }
}
