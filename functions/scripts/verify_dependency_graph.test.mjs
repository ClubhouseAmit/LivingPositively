import assert from "node:assert/strict";
import {mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync} from "node:fs";
import {tmpdir} from "node:os";
import {join, dirname} from "node:path";
import {spawnSync} from "node:child_process";
import {test} from "node:test";

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

test("rejects the wrong npm in a managed build", (t) => {
  const graph = fixture(t);
  graph.file("npm.cjs", "console.log('10.9.8');");
  const result = graph.run(["--managed"], {npm_execpath: join(graph.directory, "npm.cjs")});
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Managed build must use the tested npm version/);
});

test("rejects a managed build outside the declared deployment Node runtime", (t) => {
  const graph = fixture(t);
  graph.file("npm.cjs", "console.log('11.14.0');");
  const result = graph.run(["--managed"], {npm_execpath: join(graph.directory, "npm.cjs")});
  if (process.versions.node.split(".")[0] === "22") {
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /Build toolchain verified: Node 22.*npm 11\.14\.0/);
  } else {
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /Managed build must use the deployment Node runtime/);
  }
});
