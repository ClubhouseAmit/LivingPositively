import assert from "node:assert/strict";

export function verifyBuildToolchain(nodeVersion, npmVersion, expectedNpm) {
  assert.equal(nodeVersion.split(".")[0], "22",
    "Managed build must use the deployment Node runtime");
  assert.equal(npmVersion, expectedNpm,
    "Managed build must use the selected npm version");
}
