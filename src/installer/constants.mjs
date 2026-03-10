import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

export const REPO_ROOT = path.resolve(__dirname, '../..')
export const PACKAGE_NAME = 'install-aztec-skills'

const SKILL_NAMES = [
  'aztec-contracts',
  'aztec-deployment',
  'aztec-js',
  'aztec-accounts',
  'aztec-pxe',
  'aztec-wallet-sdk',
  'aztec-testing',
]

export const SKILLS = SKILL_NAMES.map((name) => ({
  name,
  sourceDir: path.join(REPO_ROOT, name),
  skillFile: path.join(REPO_ROOT, name, 'SKILL.md'),
}))
