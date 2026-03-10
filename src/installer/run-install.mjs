import fs from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'
import { select } from '@inquirer/prompts'
import { SKILLS } from './constants.mjs'
import { copySkill } from './copy-skill.mjs'
import { resolveTargetRoot } from './paths.mjs'
import { promptInstallSelections } from './prompts.mjs'
import { checkInstalledSkill } from './sanity-check.mjs'

/**
 * @typedef {'replace' | 'skip' | 'abort'} OverwritePolicy
 * @typedef {'replace' | 'replace-all' | 'skip' | 'abort'} PromptOverwritePolicy
 * @typedef {{ target: string; scope: string; skill: string; copyStatus: 'copied' | 'skipped' | 'aborted' | 'error'; sanityStatus: 'PASS' | 'FAIL'; destination: string; errors: string[] }} InstallResult
 */

/**
 * @param {string} targetPath
 */
async function pathExists(targetPath) {
  try {
    await fs.access(targetPath)
    return true
  } catch {
    return false
  }
}

/**
 * @param {{ target: string; skillName: string; destPath: string }} options
 * @returns {Promise<PromptOverwritePolicy>}
 */
async function promptOverwritePolicy({ target, skillName, destPath }) {
  return select({
    message: `${target}/${skillName} exists at ${destPath}. Choose overwrite policy`,
    choices: [
      { name: 'replace', value: 'replace' },
      { name: 'replace all', value: 'replace-all' },
      { name: 'skip', value: 'skip' },
      { name: 'abort', value: 'abort' },
    ],
    default: 'replace',
  })
}

export async function runInstall() {
  const selections = await promptInstallSelections()
  const selectedSkills = SKILLS.filter((skill) =>
    selections.skills.includes(skill.name),
  )
  /** @type {InstallResult[]} */
  const results = []
  let hasFailures = false
  /** @type {OverwritePolicy | null} */
  let bulkOverwritePolicy = null

  for (const target of selections.targets) {
    const targetRoot = resolveTargetRoot({
      target,
      scope: selections.scopes[target],
      cwd: process.cwd(),
      home: os.homedir(),
    })

    for (const skill of selectedSkills) {
      const destPath = path.join(targetRoot, skill.name)
      /** @type {OverwritePolicy} */
      let overwrite = 'replace'

      if (await pathExists(destPath)) {
        if (bulkOverwritePolicy) {
          overwrite = bulkOverwritePolicy
        } else {
          const promptSelection = await promptOverwritePolicy({
            target,
            skillName: skill.name,
            destPath,
          })

          if (promptSelection === 'replace-all') {
            bulkOverwritePolicy = 'replace'
            overwrite = 'replace'
          } else {
            overwrite = promptSelection
          }
        }
      }

      if (overwrite === 'abort') {
        console.error('Installation aborted by user.')
        process.exitCode = 1
        return
      }

      /** @type {InstallResult} */
      const result = {
        target,
        scope: selections.scopes[target],
        skill: skill.name,
        copyStatus: 'error',
        sanityStatus: 'FAIL',
        destination: destPath,
        errors: [],
      }

      try {
        const copyResult = await copySkill({
          source: skill.sourceDir,
          dest: destPath,
          overwrite,
        })

        result.copyStatus = copyResult.status

        const sanityResult = await checkInstalledSkill(destPath)
        result.sanityStatus = sanityResult.ok ? 'PASS' : 'FAIL'
        result.errors.push(...sanityResult.errors)
      } catch (error) {
        const message =
          error instanceof Error ? error.message : 'Unknown installation error.'
        result.errors.push(message)
      }

      if (result.sanityStatus !== 'PASS') {
        hasFailures = true
      }

      results.push(result)
    }
  }

  console.log('\nInstall summary:')
  console.table(
    results.map((result) => ({
      target: result.target,
      scope: result.scope,
      skill: result.skill,
      copy: result.copyStatus,
      sanity: result.sanityStatus,
      destination: result.destination,
    })),
  )

  if (hasFailures) {
    console.error('\nFailures:')
    for (const result of results) {
      if (result.sanityStatus === 'PASS') {
        continue
      }
      console.error(`- ${result.target}/${result.skill}: ${result.destination}`)
      for (const error of result.errors) {
        console.error(`  - ${error}`)
      }
    }
  }

  process.exitCode = hasFailures ? 1 : 0
}
