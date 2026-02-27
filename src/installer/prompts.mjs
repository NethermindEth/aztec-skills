import { checkbox, select } from "@inquirer/prompts";
import { SKILLS } from "./constants.mjs";

export async function promptTargets() {
  return checkbox({
    message: "Select install targets",
    choices: [
      { name: "codex", value: "codex" },
      { name: "claude", value: "claude" },
    ],
    validate(value) {
      return value.length > 0 || "Select at least one target.";
    },
  });
}

export async function promptSkills() {
  return checkbox({
    message: "Select skills to install",
    choices: SKILLS.map((skill) => ({
      name: skill.name,
      value: skill.name,
    })),
    validate(value) {
      return value.length > 0 || "Select at least one skill.";
    },
  });
}

async function promptScopeForTarget(target) {
  return select({
    message: `Select ${target} install scope`,
    choices: [
      { name: "project", value: "project" },
      { name: "user", value: "user" },
    ],
    default: "project",
  });
}

export async function promptScopes(selectedTargets) {
  const scopes = {};
  for (const target of selectedTargets) {
    scopes[target] = await promptScopeForTarget(target);
  }
  return scopes;
}

export async function promptInstallSelections() {
  const targets = await promptTargets();
  const skills = await promptSkills();
  const scopes = await promptScopes(targets);

  return {
    targets,
    skills,
    scopes,
  };
}
