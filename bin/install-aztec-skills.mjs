#!/usr/bin/env node
import { runInstall } from '../src/installer/run-install.mjs'
import { runList } from '../src/installer/run-list.mjs'

function printUsage() {
  console.log(`Usage:
  install-aztec-skills
  install-aztec-skills install
  install-aztec-skills list
  install-aztec-skills help`)
}

const [command] = process.argv.slice(2)

if (!command || command === 'install') {
  await runInstall()
} else if (command === 'list') {
  await runList()
} else if (command === 'help' || command === '--help' || command === '-h') {
  printUsage()
} else {
  console.error(`Unknown command: ${command}`)
  printUsage()
  process.exitCode = 1
}
