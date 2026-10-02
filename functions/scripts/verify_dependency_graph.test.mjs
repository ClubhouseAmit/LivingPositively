import assert from "node:assert/strict";
import {mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync} from "node:fs";
import {tmpdir} from "node:os";
import {join, dirname} from "node:path";
import {spawnSync} from "node:child_process";
import {test} from "node:test";
import {verifyBuildToolchain} from "./verify_build_toolchain.mjs";

function fixture(t, uuid = "11.1.1", uuidApi = "exports.v4 = () => '12345678-1234-4234-8234-123456789abc';") {
  const directory = mkdtempSync(join(tmpdir(), "functions-build-graph-"));
  t.after(() => rmSync(directory, {recursive: true, force: true}));
  function file(name, content) {
    const path = join(directory, name);
    mkdirSync(dirname(path), {recursive: true});
    writeFileSync(path, content);
  }
  function pkg(name, version, code = "") {
    file(`node_modules/${name}/package.json`, JSON.stringify({name, version, main: "index.js"}));
    file(`node_modules/${name}/index.js`, code);
  }
  pkg("@google-cloud/storage", "8.2.0");
  pkg("gaxios", "6.7.1");
  pkg("uuid", uuid, uuidApi);
  pkg("@google-cloud/firestore", "8.0.0");
  pkg("google-gax", "5.0.0");
  pkg("@grpc/grpc-js", "1.14.5");
  file("package.json", JSON.stringify({engines: {npm: "11.14.0"}}));
  file("scripts/verify.mjs", readFileSync(new URL("./verify_dependency_graph.mjs", import.meta.url)));
  file("scripts/verify_build_toolchain.mjs",
    readFileSync(new URL("./verify_build_toolchain.mjs", import.meta.url)));
  return {
    file,
    run(args = [], env = {}) {
      return spawnSync(process.execPath, ["scripts/verify.mjs", "--production", ...args], {
        cwd: directory, encoding: "utf8", env: {...process.env, ...env},
      });
    },
    directory,
  };
}

test("accepts a patched production consumer graph without the development SDK", (t) => {
  const result = fixture(t).run();
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /UUID 11\.1\.1 \(CommonJS v4\)/);
});

test("rejects an unpatched UUID from the consuming package", (t) => {
  const result = fixture(t, "9.0.1").run();
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /9\.0\.1/);
});

test("rejects a nested unpatched UUID even when the root UUID is patched", (t) => {
  const graph = fixture(t);
  graph.file("node_modules/gaxios/node_modules/uuid/package.json",
    JSON.stringify({name: "uuid", version: "9.0.1", main: "index.js"}));
  graph.file("node_modules/gaxios/node_modules/uuid/index.js", "");
  const result = graph.run();
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /9\.0\.1/);
});

test("rejects a UUID installation without the CommonJS v4 API", (t) => {
  const result = fixture(t, "11.1.1", "exports.v4 = undefined;").run();
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /not a function/);
});

test("accepts the selected Node and npm regardless of the test host", () => {
  assert.doesNotThrow(() => verifyBuildToolchain("22.23.2", "11.14.0", "11.14.0"));
});

test("rejects an npm different from the manifest selection", () => {
  assert.throws(() => verifyBuildToolchain("22.23.2", "10.9.8", "11.14.0"),
    /Managed build must use the selected npm version/);
});

test("rejects a Node runtime different from the deployment runtime", () => {
  assert.throws(() => verifyBuildToolchain("24.15.0", "11.14.0", "11.14.0"),
    /Managed build must use the deployment Node runtime/);
});

const managedRuntime = Number(process.versions.node.split('.')[0]) === 22;
const managedSkip = managedRuntime ? false : 'Managed CLI integration requires the deployment Node 22 runtime';

test('managed CLI rejects a missing npm executable', (t) => {
  const result = fixture(t).run(['--managed'], {npm_execpath: ''});
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Run managed verification through npm/);
});

test('managed CLI reads npm_execpath and accepts the manifest pin', {skip: managedSkip}, (t) => {
  const graph = fixture(t);
  graph.file('npm-probe.cjs', "console.log('11.14.0');");
  const result = graph.run(['--managed'], {npm_execpath: join(graph.directory, 'npm-probe.cjs')});
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /Build toolchain verified: Node 22\.[\d.]+; npm 11\.14\.0/);
});

test('managed CLI rejects an npm executable that disagrees with engines.npm', {skip: managedSkip}, (t) => {
  const graph = fixture(t);
  graph.file('npm-probe.cjs', "console.log('11.14.0');");
  graph.file('package.json', JSON.stringify({engines: {npm: '11.15.0'}}));
  const result = graph.run(['--managed'], {npm_execpath: join(graph.directory, 'npm-probe.cjs')});
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Managed build must use the selected npm version/);
});
