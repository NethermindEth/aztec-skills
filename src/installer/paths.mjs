import path from "node:path";

const SUPPORTED_TARGETS = new Set(["codex", "claude"]);
const SUPPORTED_SCOPES = new Set(["project", "user"]);

export function resolveTargetRoot({ target, scope, cwd, home }) {
  if (!SUPPORTED_TARGETS.has(target)) {
    throw new Error(`Unsupported target: ${target}`);
  }

  if (!SUPPORTED_SCOPES.has(scope)) {
    throw new Error(`Unsupported scope: ${scope}`);
  }

  if (!cwd || !home) {
    throw new Error("Both cwd and home are required.");
  }

  if (target === "codex" && scope === "project") {
    return path.join(cwd, ".agents", "skills");
  }

  if (target === "codex" && scope === "user") {
    return path.join(home, ".agents", "skills");
  }

  if (target === "claude" && scope === "project") {
    return path.join(cwd, ".claude", "skills");
  }

  return path.join(home, ".claude", "skills");
}
