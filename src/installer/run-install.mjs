import { promptInstallSelections } from "./prompts.mjs";

export async function runInstall() {
  const selections = await promptInstallSelections();

  // Temporary Step 4 output until install execution is implemented.
  console.log("\nCollected selections:");
  console.log(JSON.stringify(selections, null, 2));
}
