import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { select } from "@inquirer/prompts";
import { SKILLS } from "./constants.mjs";
import { copySkill } from "./copy-skill.mjs";
import { resolveTargetRoot } from "./paths.mjs";
import { promptInstallSelections } from "./prompts.mjs";

async function pathExists(targetPath) {
  try {
    await fs.access(targetPath);
    return true;
  } catch {
    return false;
  }
}

async function promptOverwritePolicy({ target, skillName, destPath }) {
  return select({
    message: `${target}/${skillName} exists at ${destPath}. Choose overwrite policy`,
    choices: [
      { name: "replace", value: "replace" },
      { name: "skip", value: "skip" },
      { name: "abort", value: "abort" },
    ],
    default: "replace",
  });
}

export async function runInstall() {
  const selections = await promptInstallSelections();
  const selectedSkills = SKILLS.filter((skill) =>
    selections.skills.includes(skill.name)
  );
  const results = [];

  for (const target of selections.targets) {
    const targetRoot = resolveTargetRoot({
      target,
      scope: selections.scopes[target],
      cwd: process.cwd(),
      home: os.homedir(),
    });

    for (const skill of selectedSkills) {
      const destPath = path.join(targetRoot, skill.name);
      let overwrite = "replace";

      if (await pathExists(destPath)) {
        overwrite = await promptOverwritePolicy({
          target,
          skillName: skill.name,
          destPath,
        });
      }

      if (overwrite === "abort") {
        console.error("Installation aborted by user.");
        process.exitCode = 1;
        return;
      }

      const copyResult = await copySkill({
        source: skill.sourceDir,
        dest: destPath,
        overwrite,
      });

      results.push({
        target,
        scope: selections.scopes[target],
        skill: skill.name,
        status: copyResult.status,
        destination: destPath,
      });
    }
  }

  console.log("\nCopy results:");
  console.log(JSON.stringify(results, null, 2));
}
