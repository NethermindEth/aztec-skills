import fs from 'node:fs/promises'
import path from 'node:path'

/**
 * @typedef {{ directoryExists: boolean; skillFileExists: boolean; hasFrontmatter: boolean; hasName: boolean; hasDescription: boolean }} SkillChecks
 */

/**
 * @param {string} markdown
 * @returns {Set<string> | null}
 */
function extractFrontmatterKeys(markdown) {
  const match = markdown.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/)
  if (!match) {
    return null
  }

  const keys = new Set()
  const lines = match[1].split(/\r?\n/)

  for (const line of lines) {
    const keyMatch = line.match(/^([A-Za-z0-9_-]+)\s*:/)
    if (keyMatch) {
      keys.add(keyMatch[1])
    }
  }

  return keys
}

/**
 * @param {string} skillDir
 * @returns {Promise<{ ok: boolean; skillDir: string; skillFile: string; checks: SkillChecks; errors: string[] }>}
 */
export async function checkInstalledSkill(skillDir) {
  const resolvedSkillDir = path.resolve(skillDir)
  const skillFile = path.join(resolvedSkillDir, 'SKILL.md')
  /** @type {string[]} */
  const errors = []
  /** @type {SkillChecks} */
  const checks = {
    directoryExists: false,
    skillFileExists: false,
    hasFrontmatter: false,
    hasName: false,
    hasDescription: false,
  }

  try {
    const dirStat = await fs.stat(resolvedSkillDir)
    checks.directoryExists = dirStat.isDirectory()
  } catch {
    checks.directoryExists = false
  }

  if (!checks.directoryExists) {
    errors.push('Destination skill directory does not exist.')
    return {
      ok: false,
      skillDir: resolvedSkillDir,
      skillFile,
      checks,
      errors,
    }
  }

  try {
    const fileStat = await fs.stat(skillFile)
    checks.skillFileExists = fileStat.isFile()
  } catch {
    checks.skillFileExists = false
  }

  if (!checks.skillFileExists) {
    errors.push('SKILL.md is missing.')
    return {
      ok: false,
      skillDir: resolvedSkillDir,
      skillFile,
      checks,
      errors,
    }
  }

  const content = await fs.readFile(skillFile, 'utf8')
  const frontmatterKeys = extractFrontmatterKeys(content)

  if (!frontmatterKeys) {
    errors.push('SKILL.md frontmatter block is missing or malformed.')
  } else {
    checks.hasFrontmatter = true
    checks.hasName = frontmatterKeys.has('name')
    checks.hasDescription = frontmatterKeys.has('description')

    if (!checks.hasName) {
      errors.push('SKILL.md frontmatter is missing required key: name.')
    }
    if (!checks.hasDescription) {
      errors.push('SKILL.md frontmatter is missing required key: description.')
    }
  }

  return {
    ok: errors.length === 0,
    skillDir: resolvedSkillDir,
    skillFile,
    checks,
    errors,
  }
}
