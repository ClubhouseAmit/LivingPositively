import assert from "node:assert/strict";
import {createRequire} from "node:module";
import {execFileSync} from "node:child_process";
import {verifyBuildToolchain} from "./verify_build_toolchain.mjs";

const require = createRequire(import.meta.url);
if (process.argv.includes("--managed")) {
  assert.ok(process.env.npm_execpath, "Run managed verification through npm");
  const npmVersion = execFileSync(process.execPath,
    [process.env.npm_execpath, "--version"], {encoding: "utf8"}).trim();
  verifyBuildToolchain(process.versions.node, npmVersion,
    require("../package.json").engines.npm);
  console.log(`Build toolchain verified: Node ${process.versions.node}; npm ${npmVersion}`);
}
const storageRequire = createRequire(require.resolve("@google-cloud/storage"));
const gaxiosPath = storageRequire.resolve("gaxios/package.json");
const gaxios = require(gaxiosPath);
assert.equal(gaxios.version, "6.7.1", "Recheck the UUID override after a Gaxios upgrade");

const gaxiosRequire = createRequire(gaxiosPath);
assert.equal(gaxiosRequire("uuid/package.json").version, "11.1.1");
assert.match(gaxiosRequire("uuid").v4(), /^[0-9a-f-]{36}$/);

const adminFirestore = createRequire(require.resolve("@google-cloud/firestore"));
const googleGax = createRequire(adminFirestore.resolve("google-gax"));
assert.equal(googleGax("@grpc/grpc-js/package.json").version, "1.14.5");

if (!process.argv.includes("--production")) {
  const firestoreRequire = createRequire(require.resolve("@firebase/firestore/package.json"));
  assert.equal(firestoreRequire("@grpc/grpc-js/package.json").version, "1.14.5");
}

console.log("Dependency graph verified: Storage/Gaxios 6.7.1 -> UUID 11.1.1 (CommonJS v4); Firestore -> gRPC 1.14.5");
