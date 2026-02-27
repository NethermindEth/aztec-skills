import fs from "node:fs/promises";
import path from "node:path";

const VALID_OVERWRITE_POLICIES = new Set(["replace", "skip", "abort"]);

async function pathExists(targetPath) {
  try {
    await fs.access(targetPath);
    return true;
  } catch {
    return false;
  }
}

async function syncModesRecursive(sourceDir, destDir) {
  const sourceEntries = await fs.readdir(sourceDir, { withFileTypes: true });

  for (const entry of sourceEntries) {
    const sourcePath = path.join(sourceDir, entry.name);
    const destPath = path.join(destDir, entry.name);
    const sourceStat = await fs.stat(sourcePath);
    const modeBits = sourceStat.mode & 0o777;

    await fs.chmod(destPath, modeBits);

    if (entry.isDirectory()) {
      await syncModesRecursive(sourcePath, destPath);
    }
  }
}

export async function copySkill({ source, dest, overwrite }) {
  if (!VALID_OVERWRITE_POLICIES.has(overwrite)) {
    throw new Error(`Invalid overwrite policy: ${overwrite}`);
  }

  const sourcePath = path.resolve(source);
  const destPath = path.resolve(dest);
  const destinationExists = await pathExists(destPath);

  if (destinationExists && overwrite === "skip") {
    return { status: "skipped", source: sourcePath, dest: destPath };
  }

  if (destinationExists && overwrite === "abort") {
    return { status: "aborted", source: sourcePath, dest: destPath };
  }

  await fs.mkdir(path.dirname(destPath), { recursive: true });

  if (destinationExists && overwrite === "replace") {
    await fs.rm(destPath, { recursive: true, force: true });
  }

  await fs.cp(sourcePath, destPath, {
    recursive: true,
    preserveTimestamps: true,
    force: true,
    errorOnExist: false,
  });

  await syncModesRecursive(sourcePath, destPath);

  return { status: "copied", source: sourcePath, dest: destPath };
}
