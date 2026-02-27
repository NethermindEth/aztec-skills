import { checkbox, select } from "@inquirer/prompts";
import { SKILLS } from "./constants.mjs";

const VALID_TARGETS = new Set(["codex", "claude"]);
const VALID_SCOPES = new Set(["project", "user"]);
const VALID_SKILLS = new Set(SKILLS.map((skill) => skill.name));

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

function assertNonEmptyArray(value, fieldName) {
  if (!Array.isArray(value) || value.length === 0) {
    throw new Error(`Invalid ${fieldName}: expected non-empty array.`);
  }
}

function validateSelectionsPayload(payload) {
  if (!payload || typeof payload !== "object") {
    throw new Error("Invalid installer selections payload.");
  }

  assertNonEmptyArray(payload.targets, "targets");
  assertNonEmptyArray(payload.skills, "skills");

  if (!payload.scopes || typeof payload.scopes !== "object") {
    throw new Error("Invalid scopes: expected object.");
  }

  for (const target of payload.targets) {
    if (!VALID_TARGETS.has(target)) {
      throw new Error(`Invalid target: ${target}`);
    }
    const scope = payload.scopes[target];
    if (!VALID_SCOPES.has(scope)) {
      throw new Error(`Invalid scope for ${target}: ${scope}`);
    }
  }

  for (const skill of payload.skills) {
    if (!VALID_SKILLS.has(skill)) {
      throw new Error(`Invalid skill: ${skill}`);
    }
  }
}

export function getSelectionsFromEnv(env = process.env) {
  const raw = env.INSTALL_AZTEC_SKILLS_SELECTIONS;
  if (!raw) {
    return null;
  }

  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unknown JSON parse error.";
    throw new Error(
      `INSTALL_AZTEC_SKILLS_SELECTIONS is not valid JSON: ${message}`
    );
  }

  validateSelectionsPayload(parsed);
  return parsed;
}

export async function promptInstallSelections() {
  const fromEnv = getSelectionsFromEnv();
  if (fromEnv) {
    return fromEnv;
  }

  const targets = await promptTargets();
  const skills = await promptSkills();
  const scopes = await promptScopes(targets);

  return {
    targets,
    skills,
    scopes,
  };
}
