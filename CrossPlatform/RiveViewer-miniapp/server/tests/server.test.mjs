import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { createServer } from "node:http";
import { request as httpRequest } from "node:http";
import { mkdtemp, readFile, readdir, rm, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";
import { createRiveHostApp } from "../src/app.mjs";
import { FOREST_IDENTITIES, pickForestIdentity } from "../src/forest-identities.mjs";
import {
  DEFAULT_MAX_TOTAL_BYTES,
  GIBIBYTE,
  loadConfig,
  MAX_FILE_BYTES,
} from "../src/config.mjs";
import { stageRiveStream } from "../src/ingest.mjs";
import { MAX_PAG_FILE_BYTES } from "../src/animation-formats.mjs";

const serverRoot = path.resolve(fileURLToPath(new URL("..", import.meta.url)));
const silentLogger = { error() {}, warn() {}, log() {} };

function makeRive(body = "test-data") {
  return Buffer.from(`RIVE${body}`);
}

function sequenceGenerator(values) {
  let index = 0;
  return () => values[index++] || "zzz";
}

async function listenApp(dataDir, options = {}) {
  const app = await createRiveHostApp({
    dataDir,
    maxTotalBytes: options.maxTotalBytes ?? DEFAULT_MAX_TOTAL_BYTES,
    codeGenerator: options.codeGenerator,
    now: options.now,
    diskFreeProvider: options.diskFreeProvider || (async () => 100 * GIBIBYTE),
    analyticsPassword: options.analyticsPassword || "123456",
    analyticsSalt: options.analyticsSalt || "test-analytics-salt-32-characters-long",
    logger: silentLogger,
  });
  const server = createServer(app.handler);
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  server.unref();
  const address = server.address();
  return {
    app,
    server,
    port: address.port,
    async close() {
      server.close();
      await once(server, "close");
    },
  };
}

function call(port, { method = "GET", pathname, headers = {}, body }) {
  return new Promise((resolve, reject) => {
    const payload = body === undefined
      ? null
      : Buffer.isBuffer(body)
        ? body
        : Buffer.from(typeof body === "string" ? body : JSON.stringify(body));
    const request = httpRequest({
      host: "127.0.0.1",
      port,
      method,
      path: pathname,
      headers: {
        ...(payload && headers["Content-Length"] === undefined
          ? { "Content-Length": payload.length }
          : {}),
        ...headers,
      },
    }, (response) => {
      const chunks = [];
      response.on("data", (chunk) => chunks.push(chunk));
      response.on("end", () => {
        const responseBody = Buffer.concat(chunks);
        const contentType = String(response.headers["content-type"] || "");
        let json = null;
        if (contentType.startsWith("application/json") && responseBody.length) {
          json = JSON.parse(responseBody.toString("utf8"));
        }
        resolve({
          status: response.statusCode,
          headers: response.headers,
          body: responseBody,
          json,
        });
      });
    });
    request.on("error", reject);
    request.end(payload || undefined);
  });
}

async function upload(port, filename, bytes, extraHeaders = {}) {
  return call(port, {
    method: "POST",
    pathname: "/api/v1/shares",
    headers: {
      "Content-Type": "application/octet-stream",
      "X-Rive-Filename": encodeURIComponent(filename),
      ...extraHeaders,
    },
    body: bytes,
  });
}

async function uploadVersion(port, code, filename, bytes) {
  return call(port, {
    method: "POST",
    pathname: `/api/v1/shares/${code}/versions`,
    headers: {
      "Content-Type": "application/octet-stream",
      "X-Rive-Filename": encodeURIComponent(filename),
    },
    body: bytes,
  });
}

function makeLottie() {
  return Buffer.from(JSON.stringify({ v: "5.12.0", w: 100, h: 100, fr: 30, ip: 0, op: 60, layers: [] }));
}

function makePag(size = 8) {
  const bytes = Buffer.alloc(Math.max(4, size));
  bytes.write("PAG", 0, "ascii");
  bytes[3] = 1;
  return bytes;
}

async function withTempDir(run) {
  const dataDir = await mkdtemp(path.join(os.tmpdir(), "rive-host-test-"));
  try {
    await run(dataDir);
  } finally {
    await rm(dataDir, { recursive: true, force: true });
  }
}

test("uploads, serves ranges, comments, archives, restores, and persists exact-case codes", async () => {
  await withTempDir(async (dataDir) => {
    const timestamps = [
      "2026-08-22T01:00:00.000Z",
      "2026-08-22T01:01:00.000Z",
      "2026-08-22T01:02:00.000Z",
      "2026-08-22T01:03:00.000Z",
      "2026-08-22T01:04:00.000Z",
    ];
    const instance = await listenApp(dataDir, {
      codeGenerator: sequenceGenerator(["Aa0", "Aa0", "aA0", "Bb1"]),
      now: () => timestamps.shift() || "2026-08-22T02:00:00.000Z",
    });

    let response = await call(instance.port, { pathname: "/healthz" });
    assert.equal(response.status, 200);
    assert.deepEqual(response.json, { ok: true });

    response = await call(instance.port, { pathname: "/api/v1/shares?status=active" });
    assert.deepEqual(response.json, { items: [] });

    const firstBytes = makeRive("first-payload");
    response = await upload(instance.port, "动效 测试.riv", firstBytes, {
      "X-Rive-Example": "true",
    });
    assert.equal(response.status, 201);
    assert.equal(response.json.item.code, "Aa0");
    assert.equal(response.json.item.filename, "动效 测试.riv");
    assert.equal(response.json.item.size, firstBytes.length);
    assert.equal(response.json.item.isExample, false);
    assert.equal(response.json.item.status, "active");
    assert.equal(response.json.item.commentCount, 0);
    assert.match(response.json.item.sha256, /^[0-9a-f]{64}$/);
    assert.equal(response.json.item.etag, `"sha256-${response.json.item.sha256}"`);
    const firstUpload = response.json.item;

    response = await upload(instance.port, "同内容副本.riv", firstBytes);
    assert.equal(response.status, 201);
    assert.equal(response.json.item.code, "aA0");
    assert.equal((await readdir(path.join(dataDir, "files"))).length, 2);

    response = await call(instance.port, {
      pathname: "/api/v1/shares/Aa0/file",
    });
    assert.equal(response.status, 200);
    assert.deepEqual(response.body, firstBytes);
    assert.equal(Number(response.headers["content-length"]), firstBytes.length);
    assert.equal(response.headers.etag, firstUpload.etag);
    assert.equal(response.headers["accept-ranges"], "bytes");
    assert.match(response.headers["content-disposition"], /filename\*=UTF-8''/);
    const firstEtag = response.headers.etag;

    response = await call(instance.port, {
      pathname: "/api/v1/shares/Aa0/file",
      headers: { Range: "bytes=1-3" },
    });
    assert.equal(response.status, 206);
    assert.equal(response.body.toString("ascii"), "IVE");
    assert.equal(response.headers["content-range"], `bytes 1-3/${firstBytes.length}`);

    response = await call(instance.port, {
      pathname: "/api/v1/shares/Aa0/file",
      headers: { Range: "bytes=-4" },
    });
    assert.equal(response.status, 206);
    assert.deepEqual(response.body, firstBytes.subarray(-4));

    response = await call(instance.port, {
      pathname: "/api/v1/shares/Aa0/file",
      headers: { Range: "bytes=0-1,3-4" },
    });
    assert.equal(response.status, 416);
    assert.equal(response.headers["content-range"], `bytes */${firstBytes.length}`);

    response = await call(instance.port, {
      pathname: "/api/v1/shares/Aa0/file",
      headers: { "If-None-Match": firstEtag },
    });
    assert.equal(response.status, 304);
    assert.equal(response.body.length, 0);

    response = await call(instance.port, {
      method: "HEAD",
      pathname: "/api/v1/shares/Aa0/file",
    });
    assert.equal(response.status, 200);
    assert.equal(response.body.length, 0);
    assert.equal(Number(response.headers["content-length"]), firstBytes.length);

    const visitorId = "visitor-Aa0-forest-0001";
    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Aa0/comments",
      headers: { "Content-Type": "application/json" },
      body: { visitorId, body: "  这里是 <b>纯文本</b>  " },
    });
    const expectedIdentity = pickForestIdentity(`visitor:${visitorId}`);
    assert.equal(response.status, 201);
    assert.equal(response.json.item.nickname, expectedIdentity.nickname);
    assert.equal(response.json.item.avatar, expectedIdentity.avatar);
    assert.equal(response.json.item.body, "这里是 <b>纯文本</b>");
    assert.equal(response.json.item.status, "active");
    assert.equal(response.json.item.archivedAt, null);
    const commentId = response.json.item.id;

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Aa0/archive",
    });
    assert.equal(response.status, 400);
    assert.equal(response.json.error.code, "missing_action_header");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Aa0/archive",
      headers: { "X-Rive-Action": "archive" },
    });
    assert.equal(response.status, 200);
    assert.equal(response.json.item.status, "archived");
    assert.equal(response.json.item.commentCount, 1);

    response = await call(instance.port, {
      pathname: "/api/v1/shares/Aa0/file",
    });
    assert.equal(response.status, 410);
    assert.equal(response.json.error.code, "share_archived");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Aa0/comments",
      headers: { "Content-Type": "application/json" },
      body: { body: "归档后评论" },
    });
    assert.equal(response.status, 409);
    assert.equal(response.json.error.code, "share_archived");

    response = await call(instance.port, { pathname: "/api/v1/shares?status=active" });
    assert.deepEqual(response.json.items.map((item) => item.code), ["aA0"]);
    response = await call(instance.port, { pathname: "/api/v1/shares?status=archived" });
    assert.equal(response.json.items[0].code, "Aa0");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Aa0/restore",
      headers: { "X-Rive-Action": "restore" },
    });
    assert.equal(response.status, 200);
    assert.equal(response.json.item.code, "Aa0");
    assert.equal(response.json.item.status, "active");
    assert.equal(response.json.item.archivedAt, null);
    assert.equal(response.json.item.commentCount, 1);

    response = await call(instance.port, {
      pathname: "/api/v1/shares/Aa0/file",
    });
    assert.equal(response.status, 200);
    assert.deepEqual(response.body, firstBytes);

    const secondBytes = makeRive("second");
    response = await upload(instance.port, "Second.RIV", secondBytes, {
      "X-Rive-Example": "false",
    });
    assert.equal(response.status, 201);
    assert.equal(response.json.item.code, "Bb1");
    assert.equal(response.json.item.isExample, false);

    response = await call(instance.port, { pathname: "/api/v1/shares/AA0" });
    assert.equal(response.status, 404);

    const state = JSON.parse(await readFile(path.join(dataDir, "state.json"), "utf8"));
    assert.equal(state.version, 1);
    assert.equal(state.shares.length, 3);
    assert.equal(state.shares[0].comments[0].id, commentId);
    const storedFiles = await readdir(path.join(dataDir, "files"));
    assert.equal(storedFiles.length, 3);
    assert.equal(storedFiles.every((name) => /^[0-9a-f-]{36}\.riv$/.test(name)), true);
    assert.equal((await readdir(dataDir)).some((name) => name.startsWith(".state-")), false);

    await instance.close();
    const restarted = await listenApp(dataDir);
    response = await call(restarted.port, { pathname: "/api/v1/shares/Aa0" });
    assert.equal(response.status, 200);
    assert.equal(response.json.item.commentCount, 1);
    response = await call(restarted.port, { pathname: "/api/v1/shares/Aa0/comments" });
    assert.equal(response.json.items[0].id, commentId);
    assert.equal(response.json.items[0].status, "active");
    assert.equal(response.json.items[0].archivedAt, null);
    await restarted.close();
  });
});

test("accepts self-contained Lottie and PAG, filters legacy lists, and caps PAG at 10 MiB", async () => {
  await withTempDir(async (dataDir) => {
    const instance = await listenApp(dataDir, {
      codeGenerator: sequenceGenerator(["R01", "L01", "P01"]),
    });
    let response = await upload(instance.port, "legacy.riv", makeRive());
    assert.equal(response.status, 201);

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares",
      headers: {
        "Content-Type": "application/octet-stream",
        "X-Animation-Filename": encodeURIComponent("motion.json"),
      },
      body: makeLottie(),
    });
    assert.equal(response.status, 201);
    assert.equal(response.json.item.format, "lottie");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares",
      headers: {
        "Content-Type": "application/octet-stream",
        "X-Animation-Filename": encodeURIComponent("motion.pag"),
      },
      body: makePag(),
    });
    assert.equal(response.status, 201);
    assert.equal(response.json.item.format, "pag");

    response = await call(instance.port, { pathname: "/api/v1/shares?status=active" });
    assert.deepEqual(response.json.items.map((item) => item.format), ["rive"]);
    response = await call(instance.port, {
      pathname: "/api/v1/shares?status=active&formats=rive,lottie,pag",
    });
    assert.equal(response.json.items.length, 3);

    response = await uploadVersion(instance.port, "P01", "wrong.riv", makeRive());
    assert.equal(response.status, 422);
    assert.equal(response.json.error.code, "format_mismatch");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares",
      headers: {
        "Content-Type": "application/octet-stream",
        "X-Animation-Filename": encodeURIComponent("too-large.pag"),
      },
      body: makePag(MAX_PAG_FILE_BYTES + 1),
    });
    assert.equal(response.status, 413);
    assert.equal(response.json.error.message, "PAG 文件不能超过 10 MiB");

    await instance.close();
  });
});

test("keeps one browser visitor on the same forest nickname and avatar", async () => {
  await withTempDir(async (dataDir) => {
    assert.equal(FOREST_IDENTITIES.length, 32);
    assert.equal(new Set(FOREST_IDENTITIES.map((item) => item.nickname)).size, 32);
    assert.equal(new Set(FOREST_IDENTITIES.map((item) => item.avatar)).size, 32);

    const instance = await listenApp(dataDir, {
      codeGenerator: sequenceGenerator(["Id1", "Id2"]),
    });
    await upload(instance.port, "one.riv", makeRive("identity-one"));
    await upload(instance.port, "two.riv", makeRive("identity-two"));

    const visitorId = "visitor-stable-forest-0001";
    const assigned = await call(instance.port, {
      pathname: `/api/v1/comment-identity?visitorId=${encodeURIComponent(visitorId)}`,
    });
    assert.equal(assigned.status, 200);
    assert.deepEqual(assigned.json.item, pickForestIdentity(`visitor:${visitorId}`));

    const first = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Id1/comments",
      headers: {
        "Content-Type": "application/json",
        "X-Forwarded-For": "198.51.100.10",
        "User-Agent": "Browser One",
      },
      body: { visitorId, body: "第一条" },
    });
    const second = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Id2/comments",
      headers: {
        "Content-Type": "application/json",
        "X-Forwarded-For": "203.0.113.20",
        "User-Agent": "Browser Two",
      },
      body: { visitorId, body: "第二条" },
    });

    assert.equal(first.status, 201);
    assert.equal(second.status, 201);
    assert.equal(second.json.item.nickname, first.json.item.nickname);
    assert.equal(second.json.item.avatar, first.json.item.avatar);
    const compactWebp = Buffer.concat([
      Buffer.from("RIFF"),
      Buffer.from([8, 0, 0, 0]),
      Buffer.from("WEBPVP8 "),
    ]).toString("base64");
    const custom = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Id1/comments",
      headers: { "Content-Type": "application/json" },
      body: {
        visitorId,
        body: "自定义身份",
        nickname: "杨总的小松鼠",
        avatarDataUrl: `data:image/webp;base64,${compactWebp}`,
      },
    });
    assert.equal(custom.status, 201);
    assert.equal(custom.json.item.nickname, "杨总的小松鼠");
    assert.equal(custom.json.item.avatarDataUrl, `data:image/webp;base64,${compactWebp}`);
    assert.equal(custom.json.item.avatar, first.json.item.avatar);
    const firstThread = await call(instance.port, {
      pathname: "/api/v1/shares/Id1/comments",
    });
    const secondThread = await call(instance.port, {
      pathname: "/api/v1/shares/Id2/comments",
    });
    assert.deepEqual(firstThread.json.items.map((item) => item.body), ["第一条", "自定义身份"]);
    assert.deepEqual(secondThread.json.items.map((item) => item.body), ["第二条"]);
    await instance.close();
  });
});

test("keeps file versions on one share and binds comments to the selected version", async () => {
  await withTempDir(async (dataDir) => {
    const timestamps = [
      "2026-08-26T01:00:00.000Z",
      "2026-08-26T01:01:00.000Z",
      "2026-08-26T01:02:00.000Z",
      "2026-08-26T01:03:00.000Z",
    ];
    let instance = await listenApp(dataDir, {
      codeGenerator: sequenceGenerator(["V01"]),
      now: () => timestamps.shift() || "2026-08-26T02:00:00.000Z",
    });

    const firstBytes = makeRive("version-one");
    let response = await upload(instance.port, "demo-v1.riv", firstBytes);
    assert.equal(response.status, 201);
    response = await call(instance.port, { pathname: "/api/v1/shares/V01" });
    assert.equal(response.json.item.versionCount, 1);
    assert.equal(response.json.item.versions[0].name, "版本 1");
    const firstVersionId = response.json.item.currentVersionId;

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/V01/comments",
      headers: { "Content-Type": "application/json" },
      body: { body: "旧版本评论", versionId: firstVersionId },
    });
    assert.equal(response.status, 201);
    assert.equal(response.json.item.versionId, firstVersionId);

    const secondBytes = makeRive("version-two");
    response = await uploadVersion(instance.port, "V01", "demo-v2.riv", secondBytes);
    assert.equal(response.status, 201);
    assert.equal(response.json.item.versionCount, 2);
    assert.equal(response.json.item.filename, "demo-v2.riv");
    assert.deepEqual(response.json.item.versions.map((item) => item.name), ["版本 1", "版本 2"]);
    const secondVersionId = response.json.item.currentVersionId;
    assert.notEqual(secondVersionId, firstVersionId);

    response = await call(instance.port, { pathname: "/api/v1/shares/V01/file" });
    assert.deepEqual(response.body, secondBytes);
    response = await call(instance.port, {
      pathname: `/api/v1/shares/V01/file?versionId=${firstVersionId}`,
    });
    assert.deepEqual(response.body, firstBytes);
    response = await call(instance.port, {
      pathname: "/api/v1/shares/V01/file?versionId=00000000-0000-0000-0000-000000000000",
    });
    assert.equal(response.status, 404);
    assert.equal(response.json.error.code, "version_not_found");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/V01/comments",
      headers: { "Content-Type": "application/json" },
      body: { body: "新版本评论", versionId: secondVersionId },
    });
    assert.equal(response.status, 201);
    response = await call(instance.port, { pathname: "/api/v1/shares/V01/comments" });
    assert.deepEqual(response.json.items.map((item) => item.versionId), [
      firstVersionId,
      secondVersionId,
    ]);

    await instance.close();
    instance = await listenApp(dataDir);
    response = await call(instance.port, { pathname: "/api/v1/shares/V01" });
    assert.equal(response.json.item.versionCount, 2);
    assert.equal(response.json.item.currentVersionId, secondVersionId);
    assert.equal((await readdir(path.join(dataDir, "files"))).length, 2);
    await instance.close();
  });
});

test("archives and restores comments without deleting or reordering them", async () => {
  await withTempDir(async (dataDir) => {
    const timestamps = [
      "2026-08-22T03:00:00.000Z",
      "2026-08-22T03:01:00.000Z",
      "2026-08-22T03:02:00.000Z",
      "2026-08-22T03:03:00.000Z",
      "2026-08-22T03:04:00.000Z",
    ];
    let instance = await listenApp(dataDir, {
      codeGenerator: sequenceGenerator(["Cm1"]),
      now: () => timestamps.shift() || "2026-08-22T04:00:00.000Z",
    });

    let response = await upload(instance.port, "comments.riv", makeRive("comments"));
    assert.equal(response.status, 201);

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Cm1/comments",
      headers: { "Content-Type": "application/json" },
      body: { visitorId: "visitor-commenter-one", body: "第一条" },
    });
    const firstComment = response.json.item;
    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Cm1/comments",
      headers: { "Content-Type": "application/json" },
      body: { visitorId: "visitor-commenter-two", body: "第二条" },
    });
    const secondComment = response.json.item;

    response = await call(instance.port, {
      method: "POST",
      pathname: `/api/v1/shares/Cm1/comments/${firstComment.id}/archive`,
    });
    assert.equal(response.status, 400);
    assert.equal(response.json.error.code, "missing_action_header");

    response = await call(instance.port, {
      method: "POST",
      pathname: `/api/v1/shares/Cm1/comments/${firstComment.id}/archive`,
      headers: { "X-Rive-Action": "restore" },
    });
    assert.equal(response.status, 400);
    assert.equal(response.json.error.code, "missing_action_header");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Cm1/archive",
      headers: { "X-Rive-Action": "archive" },
    });
    assert.equal(response.status, 200);

    response = await call(instance.port, {
      method: "POST",
      pathname: `/api/v1/shares/Cm1/comments/${firstComment.id}/archive`,
      headers: { "X-Rive-Action": "archive" },
    });
    assert.equal(response.status, 200);
    assert.equal(response.json.item.status, "archived");
    assert.equal(response.json.item.archivedAt, "2026-08-22T03:04:00.000Z");
    const archivedAt = response.json.item.archivedAt;

    response = await call(instance.port, {
      method: "POST",
      pathname: `/api/v1/shares/Cm1/comments/${firstComment.id}/archive`,
      headers: { "X-Rive-Action": "archive" },
    });
    assert.equal(response.status, 200);
    assert.equal(response.json.item.archivedAt, archivedAt);

    response = await call(instance.port, { pathname: "/api/v1/shares/Cm1/comments" });
    assert.equal(response.status, 200);
    assert.deepEqual(response.json.items.map((item) => item.id), [
      firstComment.id,
      secondComment.id,
    ]);
    assert.deepEqual(response.json.items.map((item) => item.status), ["archived", "active"]);

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Cm1/comments",
      headers: { "Content-Type": "application/json" },
      body: { body: "归档文件不能新增" },
    });
    assert.equal(response.status, 409);
    assert.equal(response.json.error.code, "share_archived");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Cm1/comments/00000000-0000-0000-0000-000000000000/archive",
      headers: { "X-Rive-Action": "archive" },
    });
    assert.equal(response.status, 404);
    assert.equal(response.json.error.code, "comment_not_found");

    await instance.close();
    instance = await listenApp(dataDir);
    response = await call(instance.port, { pathname: "/api/v1/shares/Cm1/comments" });
    assert.deepEqual(response.json.items.map((item) => item.id), [
      firstComment.id,
      secondComment.id,
    ]);
    assert.equal(response.json.items[0].status, "archived");
    assert.equal(response.json.items[0].archivedAt, archivedAt);

    response = await call(instance.port, {
      method: "POST",
      pathname: `/api/v1/shares/Cm1/comments/${firstComment.id}/restore`,
      headers: { "X-Rive-Action": "restore" },
    });
    assert.equal(response.status, 200);
    assert.equal(response.json.item.status, "active");
    assert.equal(response.json.item.archivedAt, null);

    const state = JSON.parse(await readFile(path.join(dataDir, "state.json"), "utf8"));
    assert.equal(state.shares[0].comments.length, 2);
    assert.deepEqual(state.shares[0].comments.map((item) => item.id), [
      firstComment.id,
      secondComment.id,
    ]);
    await instance.close();
  });
});

test("migrates legacy comments without status fields as active", async () => {
  await withTempDir(async (dataDir) => {
    let instance = await listenApp(dataDir, {
      codeGenerator: sequenceGenerator(["Lg1"]),
    });
    let response = await upload(instance.port, "legacy.riv", makeRive("legacy"));
    assert.equal(response.status, 201);
    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Lg1/comments",
      headers: { "Content-Type": "application/json" },
      body: { body: "旧评论" },
    });
    const commentId = response.json.item.id;
    await instance.close();

    const statePath = path.join(dataDir, "state.json");
    const legacyState = JSON.parse(await readFile(statePath, "utf8"));
    delete legacyState.shares[0].versions;
    delete legacyState.shares[0].currentVersionId;
    legacyState.shares[0].comments[0].nickname = "匿名";
    delete legacyState.shares[0].comments[0].avatar;
    delete legacyState.shares[0].comments[0].status;
    delete legacyState.shares[0].comments[0].archivedAt;
    delete legacyState.shares[0].comments[0].versionId;
    await writeFile(statePath, `${JSON.stringify(legacyState, null, 2)}\n`);

    instance = await listenApp(dataDir);
    response = await call(instance.port, { pathname: "/api/v1/shares/Lg1/comments" });
    assert.equal(response.status, 200);
    assert.equal(response.json.items[0].id, commentId);
    assert.equal(response.json.items[0].status, "active");
    assert.equal(response.json.items[0].archivedAt, null);
    assert.notEqual(response.json.items[0].nickname, "匿名");
    assert.equal(typeof response.json.items[0].avatar, "string");

    const migratedState = JSON.parse(await readFile(statePath, "utf8"));
    assert.equal(migratedState.shares[0].comments[0].status, "active");
    assert.equal(migratedState.shares[0].comments[0].archivedAt, null);
    assert.equal(typeof migratedState.shares[0].comments[0].avatar, "string");
    assert.equal(migratedState.shares[0].versions.length, 1);
    assert.equal(migratedState.shares[0].versions[0].name, "版本 1");
    assert.equal(
      migratedState.shares[0].comments[0].versionId,
      migratedState.shares[0].currentVersionId,
    );
    await instance.close();
  });
});

test("rejects invalid uploads and invalid comments with concise JSON errors", async () => {
  await withTempDir(async (dataDir) => {
    const instance = await listenApp(dataDir, {
      codeGenerator: sequenceGenerator(["Ab1"]),
    });

    let response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares",
      headers: {
        "Content-Type": "text/plain",
        "X-Rive-Filename": "test.riv",
      },
      body: makeRive(),
    });
    assert.equal(response.status, 415);
    assert.equal(response.json.error.code, "unsupported_media_type");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares",
      headers: { "Content-Type": "application/octet-stream" },
      body: makeRive(),
    });
    assert.equal(response.status, 400);
    assert.equal(response.json.error.code, "missing_filename");

    response = await upload(instance.port, "not-rive.txt", makeRive());
    assert.equal(response.status, 422);
    assert.equal(response.json.error.code, "invalid_extension");

    response = await upload(instance.port, "bad.riv", Buffer.from("NOPE"));
    assert.equal(response.status, 422);
    assert.equal(response.json.error.code, "invalid_rive");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares",
      headers: {
        "Content-Type": "application/octet-stream",
        "X-Rive-Filename": "%E0%A4%A",
      },
      body: makeRive(),
    });
    assert.equal(response.status, 400);
    assert.equal(response.json.error.code, "invalid_filename");

    response = await upload(instance.port, "../escape.riv", makeRive());
    assert.equal(response.status, 400);
    assert.equal(response.json.error.code, "invalid_filename");

    response = await upload(instance.port, "valid.riv", makeRive());
    assert.equal(response.status, 201);

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Ab1/comments",
      headers: { "Content-Type": "application/json" },
      body: { visitorId: "too-short", body: "反馈" },
    });
    assert.equal(response.status, 422);
    assert.equal(response.json.error.code, "invalid_visitor");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Ab1/comments",
      headers: { "Content-Type": "application/json" },
      body: { body: "字".repeat(1001) },
    });
    assert.equal(response.status, 422);
    assert.equal(response.json.error.code, "invalid_comment");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Ab1/comments",
      headers: { "Content-Type": "application/json" },
      body: { body: "反馈", nickname: "昵".repeat(13) },
    });
    assert.equal(response.status, 422);
    assert.equal(response.json.error.code, "invalid_nickname");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Ab1/comments",
      headers: { "Content-Type": "application/json" },
      body: { body: "反馈", avatarDataUrl: "data:image/png;base64,AAAA" },
    });
    assert.equal(response.status, 422);
    assert.equal(response.json.error.code, "invalid_avatar");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/shares/Ab1/comments",
      headers: { "Content-Type": "text/plain" },
      body: "not-json",
    });
    assert.equal(response.status, 415);

    response = await call(instance.port, { pathname: "/api/v1/shares?status=deleted" });
    assert.equal(response.status, 400);
    assert.deepEqual(Object.keys(response.json), ["error"]);

    await instance.close();
  });
});

test("skips the root-route api reservation when allocating a short code", async () => {
  await withTempDir(async (dataDir) => {
    const instance = await listenApp(dataDir, {
      codeGenerator: sequenceGenerator(["api", "Ab1"]),
    });
    const response = await upload(instance.port, "reserved-code.riv", makeRive("reserved"));
    assert.equal(response.status, 201);
    assert.equal(response.json.item.code, "Ab1");
    await instance.close();
  });
});

test("enforces staged file size, total storage, and free-disk protection", async () => {
  await withTempDir(async (dataDir) => {
    const tempDir = path.join(dataDir, "stream-test");
    await import("node:fs/promises").then(({ mkdir }) => mkdir(tempDir));
    async function* oversizedStream() {
      yield Buffer.from("RIVE");
      yield Buffer.from("1234");
    }
    await assert.rejects(
      stageRiveStream(oversizedStream(), tempDir, { maxBytes: 7 }),
      (error) => error.code === "file_too_large" && error.status === 413,
    );
    assert.deepEqual(await readdir(tempDir), []);

    const quotaInstance = await listenApp(dataDir, {
      maxTotalBytes: 15,
      codeGenerator: sequenceGenerator(["Q01", "Q02"]),
    });
    let response = await upload(quotaInstance.port, "one.riv", makeRive("1234"));
    assert.equal(response.status, 201);
    response = await upload(quotaInstance.port, "two.riv", makeRive("5678"));
    assert.equal(response.status, 507);
    assert.equal(response.json.error.code, "storage_limit");
    assert.equal((await readdir(path.join(dataDir, "files"))).length, 1);
    await quotaInstance.close();
  });

  await withTempDir(async (dataDir) => {
    const lowDiskInstance = await listenApp(dataDir, {
      diskFreeProvider: async () => 5 * GIBIBYTE,
    });
    const response = await upload(lowDiskInstance.port, "low-disk.riv", makeRive());
    assert.equal(response.status, 507);
    assert.equal(response.json.error.code, "disk_space_low");
    assert.deepEqual(await readdir(path.join(dataDir, "files")), []);
    await lowDiskInstance.close();
  });
});

test("refuses to start when an indexed Rive file is missing", async () => {
  await withTempDir(async (dataDir) => {
    const instance = await listenApp(dataDir, {
      codeGenerator: sequenceGenerator(["M01"]),
    });
    const response = await upload(instance.port, "missing.riv", makeRive("persisted"));
    assert.equal(response.status, 201);
    await instance.close();

    const [storedName] = await readdir(path.join(dataDir, "files"));
    await rm(path.join(dataDir, "files", storedName));
    await assert.rejects(
      createRiveHostApp({
        dataDir,
        maxTotalBytes: DEFAULT_MAX_TOTAL_BYTES,
        diskFreeProvider: async () => 100 * GIBIBYTE,
        analyticsPassword: "123456",
        analyticsSalt: "test-analytics-salt-32-characters-long",
        logger: silentLogger,
      }),
      /文件缺失/,
    );
  });
});

test("collects privacy-safe analytics and returns filterable dashboard metrics", async () => {
  await withTempDir(async (dataDir) => {
    const instance = await listenApp(dataDir, {
      now: () => "2026-08-26T06:00:00.000Z",
      codeGenerator: sequenceGenerator(["Ab1"]),
    });
    let response = await upload(instance.port, "损坏动效.riv", makeRive("broken-preview-fixture"));
    assert.equal(response.status, 201);
    assert.equal(response.json.item.code, "Ab1");
    const baseBatch = {
      version: 1,
      surface: "jojo",
      visitorId: "visitor-analytics-0001",
      sessionId: "session-analytics-0001",
      events: [
        {
          id: "event-page-view-0001",
          name: "page_view",
          at: "2026-08-26T05:59:00.000Z",
          page: "home",
          properties: { sourceType: "campaign", sourceHost: "baidu.com", utmCampaign: "pag-launch" },
        },
        {
          id: "event-preview-ok-0001",
          name: "preview_result",
          at: "2026-08-26T05:59:05.000Z",
          page: "preview",
          format: "rive",
          fileSizeBucket: "1m_5m",
          properties: { outcome: "success", durationMs: 1200, renderer: "webgl2" },
        },
        {
          id: "event-control-use-0001",
          name: "control_use",
          at: "2026-08-26T05:59:10.000Z",
          page: "preview",
          format: "rive",
          properties: { control: "speed", speed: 2 },
        },
        {
          id: "event-preview-fail-0001",
          name: "preview_result",
          at: "2026-08-26T05:59:12.000Z",
          page: "preview",
          format: "rive",
          fileSizeBucket: "1m_5m",
          properties: {
            outcome: "failure",
            durationMs: 900,
            errorCategory: "invalid_file",
            fileCode: "Ab1",
          },
        },
        {
          id: "event-fps-sample-0001",
          name: "performance_sample",
          at: "2026-08-26T05:59:15.000Z",
          page: "preview",
          format: "rive",
          fileSizeBucket: "1m_5m",
          properties: { fps: 58.4, renderer: "webgl2" },
        },
      ],
    };
    response = await call(instance.port, {
      method: "OPTIONS",
      pathname: "/api/v1/analytics/events",
      headers: { Origin: "https://mikeywa.site" },
    });
    assert.equal(response.status, 204);
    assert.equal(response.headers["access-control-allow-origin"], "https://mikeywa.site");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/analytics/events",
      headers: {
        "Content-Type": "text/plain;charset=UTF-8",
        Origin: "https://mikeywa.site",
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X) AppleWebKit Safari/605.1.15",
        "X-Forwarded-For": "203.0.113.42",
      },
      body: baseBatch,
    });
    assert.equal(response.status, 202);
    assert.deepEqual(response.json, { accepted: 5 });
    assert.equal(response.headers["access-control-allow-origin"], "https://mikeywa.site");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/analytics/events",
      headers: { "Content-Type": "application/json", Origin: "https://evil.example" },
      body: baseBatch,
    });
    assert.equal(response.status, 403);
    assert.equal(response.json.error.code, "origin_not_allowed");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/analytics/events",
      headers: { "Content-Type": "application/json" },
      body: baseBatch,
    });
    assert.equal(response.status, 202);

    response = await call(instance.port, {
      pathname: "/api/v1/analytics/summary?days=7&surface=jojo&format=rive",
    });
    assert.equal(response.status, 401);
    assert.equal(response.json.error.code, "analytics_auth_required");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/analytics/auth",
      headers: { "Content-Type": "application/json" },
      body: { password: "000000" },
    });
    assert.equal(response.status, 401);
    assert.equal(response.json.error.code, "invalid_password");

    response = await call(instance.port, {
      method: "POST",
      pathname: "/api/v1/analytics/auth",
      headers: { "Content-Type": "application/json" },
      body: { password: "123456" },
    });
    assert.equal(response.status, 204);
    const sessionCookie = response.headers["set-cookie"][0].split(";", 1)[0];
    assert.match(response.headers["set-cookie"][0], /HttpOnly; Secure; SameSite=Strict/);

    response = await call(instance.port, {
      pathname: "/api/v1/analytics/summary?days=7&surface=jojo&format=rive",
      headers: { Cookie: sessionCookie },
    });
    assert.equal(response.status, 200);
    assert.equal(response.json.item.freshness.eventCount, 5, "重复 event id 应在汇总时去重");
    assert.equal(response.json.item.kpis.sessions, 1);
    assert.equal(response.json.item.kpis.visitors, 1);
    assert.equal(response.json.item.kpis.previews, 1);
    assert.equal(response.json.item.kpis.previewAttempts, 2);
    assert.equal(response.json.item.kpis.previewFailures, 1);
    assert.equal(response.json.item.kpis.activationRate, 1);
    assert.equal(response.json.item.kpis.previewSuccessRate, 0.5);
    assert.equal(response.json.item.kpis.p95LoadMs, 1200);
    assert.equal(response.json.item.kpis.lowFpsRate, 0);
    assert.equal(response.json.item.breakdowns.sources[0].key, "campaign");
    assert.equal(response.json.item.breakdowns.referrers[0].key, "baidu.com");
    assert.equal(response.json.item.breakdowns.campaigns[0].key, "pag-launch");
    assert.equal(response.json.item.breakdowns.controls[0].key, "speed");
    assert.deepEqual(response.json.item.audiencePeriods, [
      { days: 7, visitors: 1, visits: 1 },
      { days: 30, visitors: 1, visits: 1 },
      { days: 90, visitors: 1, visits: 1 },
    ]);
    assert.deepEqual(response.json.item.failedFiles[0], {
      code: "Ab1",
      name: "损坏动效.riv",
      surface: "jojo",
      format: "rive",
      errorCategory: "invalid_file",
      attempts: 1,
      lastFailedAt: "2026-08-26T05:59:12.000Z",
      errorLabel: "文件无效或损坏",
    });

    const analyticsFile = await readFile(path.join(dataDir, "analytics", "2026-08-26.ndjson"), "utf8");
    assert.doesNotMatch(analyticsFile, /203\.0\.113\.42|Mozilla\/5\.0|visitor-analytics|session-analytics/);
    assert.match(analyticsFile, /"browser":"Safari"/);
    assert.match(analyticsFile, /"os":"macOS"/);
    assert.match(analyticsFile, /"visitorHash":"[0-9a-f]{24}"/);
    assert.match(analyticsFile, /"fileCode":"Ab1"/);
    assert.doesNotMatch(analyticsFile, /损坏动效|fileName/);
    await instance.close();
  });
});

test("loads configuration defaults and validates capacity values", () => {
  const config = loadConfig({ RIVE_HOST_DATA_DIR: "/var/lib/rive-host" });
  assert.equal(config.host, "127.0.0.1");
  assert.equal(config.port, 8097);
  assert.equal(config.maxTotalBytes, 5 * GIBIBYTE);
  assert.equal(config.analyticsPassword, "");

  assert.throws(() => loadConfig({}), /RIVE_HOST_DATA_DIR/);
  assert.throws(() => loadConfig({ RIVE_HOST_DATA_DIR: "relative" }), /绝对路径/);
  assert.throws(() => loadConfig({
    RIVE_HOST_DATA_DIR: "/var/lib/rive-host",
    RIVE_HOST_MAX_TOTAL_BYTES: String(MAX_FILE_BYTES - 1),
  }), /超出允许范围/);
  assert.throws(() => loadConfig({
    NODE_ENV: "production",
    RIVE_HOST_DATA_DIR: "/var/lib/rive-host",
  }), /ANALYTICS_SALT/);
  assert.throws(() => loadConfig({
    NODE_ENV: "production",
    RIVE_HOST_DATA_DIR: "/var/lib/rive-host",
    RIVE_HOST_ANALYTICS_SALT: "test-analytics-salt-32-characters-long",
  }), /ANALYTICS_PASSWORD/);
  assert.throws(() => loadConfig({
    RIVE_HOST_DATA_DIR: "/var/lib/rive-host",
    RIVE_HOST_ANALYTICS_PASSWORD: "12345a",
  }), /6 位数字/);
  assert.throws(() => loadConfig({
    RIVE_HOST_DATA_DIR: "/var/lib/rive-host",
    RIVE_HOST_ANALYTICS_SALT: "short",
  }), /至少需要 32/);
});

test("seed script imports examples idempotently and preserves isExample", async () => {
  await withTempDir(async (dataDir) => {
    const fixtureDir = await mkdtemp(path.join(os.tmpdir(), "rive-host-fixture-"));
    const fixturePath = path.join(fixtureDir, "示例.riv");
    await writeFile(fixturePath, makeRive("seed-example"));
    try {
      const scriptPath = path.join(serverRoot, "scripts", "seed-examples.mjs");
      const environment = {
        ...process.env,
        RIVE_HOST_DATA_DIR: dataDir,
      };
      const first = await runProcess(process.execPath, [scriptPath, fixturePath], environment);
      assert.equal(first.code, 0, first.stderr);
      assert.equal(JSON.parse(first.stdout).items[0].created, true);

      const second = await runProcess(process.execPath, [scriptPath, fixturePath], environment);
      assert.equal(second.code, 0, second.stderr);
      assert.equal(JSON.parse(second.stdout).items[0].created, false);

      const instance = await listenApp(dataDir);
      let response = await call(instance.port, { pathname: "/api/v1/shares?status=active" });
      assert.equal(response.json.items.length, 0);
      const code = JSON.parse(first.stdout).items[0].item.code;
      response = await call(instance.port, { pathname: `/api/v1/shares/${code}` });
      assert.equal(response.status, 200);
      assert.equal(response.json.item.isExample, true);
      await instance.close();
    } finally {
      await rm(fixtureDir, { recursive: true, force: true });
    }
  });
});

function runProcess(command, args, environment) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { env: environment });
    const stdout = [];
    const stderr = [];
    child.stdout.on("data", (chunk) => stdout.push(chunk));
    child.stderr.on("data", (chunk) => stderr.push(chunk));
    child.on("error", reject);
    child.on("close", (code) => resolve({
      code,
      stdout: Buffer.concat(stdout).toString("utf8"),
      stderr: Buffer.concat(stderr).toString("utf8"),
    }));
  });
}

test("persists custom names across versions, restart and archive without changing source filenames", async () => {
  await withTempDir(async (dataDir) => {
    let instance = await listenApp(dataDir, { codeGenerator: sequenceGenerator(["Nm1", "Nm2", "Nm3"]) });
    try {
      for (const [index, extension, bytes] of [[1, "riv", makeRive()], [2, "json", makeLottie()], [3, "pag", makePag()]]) {
        const code = `Nm${index}`;
        let response = await upload(instance.port, `原始.${extension}`, bytes);
        assert.equal(response.status, 201);
        assert.equal(response.json.item.customName, null);
        response = await uploadVersion(instance.port, code, `更新.${extension}`, bytes);
        assert.equal(response.status, 201);
        assert.equal(response.json.item.filename, `更新.${extension}`);
        assert.equal(response.json.item.customName, null);
        const previous = response.json.item;
        response = await call(instance.port, {
          method: "POST", pathname: `/api/v1/shares/${code}/rename`,
          headers: { "Content-Type": "application/json", "X-Rive-Action": "rename" },
          body: { name: `  叫叫新名称 ${index}  ` },
        });
        assert.equal(response.status, 200);
        assert.equal(response.json.item.customName, `叫叫新名称 ${index}`);
        assert.equal(response.json.item.filename, previous.filename);
        assert.deepEqual(response.json.item.versions, previous.versions);
        response = await uploadVersion(instance.port, code, `最终.${extension}`, bytes);
        assert.equal(response.status, 201);
        assert.equal(response.json.item.customName, `叫叫新名称 ${index}`);
        assert.equal(response.json.item.filename, `最终.${extension}`);
        const download = await call(instance.port, { pathname: `/api/v1/shares/${code}/file?versionId=${previous.versions[0].id}` });
        assert.deepEqual(download.body, bytes);
        assert.ok(download.headers["content-disposition"].includes(encodeURIComponent(`原始.${extension}`)));
      }
      await instance.close();
      instance = await listenApp(dataDir);
      const listing = await call(instance.port, { pathname: "/api/v1/shares?formats=rive,lottie,pag" });
      assert.deepEqual(listing.json.items.map(item => item.customName).sort(), ["叫叫新名称 1", "叫叫新名称 2", "叫叫新名称 3"]);
      await call(instance.port, { method: "POST", pathname: "/api/v1/shares/Nm1/archive", headers: { "X-Rive-Action": "archive" } });
      const archived = await call(instance.port, { pathname: "/api/v1/shares?status=archived" });
      assert.equal(archived.json.items[0].customName, "叫叫新名称 1");
      const refused = await call(instance.port, {
        method: "POST", pathname: "/api/v1/shares/Nm1/rename", headers: { "Content-Type": "application/json", "X-Rive-Action": "rename" }, body: { name: "不能修改" },
      });
      assert.equal(refused.status, 409);
      await call(instance.port, { method: "POST", pathname: "/api/v1/shares/Nm1/restore", headers: { "X-Rive-Action": "restore" } });
      assert.equal(instance.app.store.get("Nm1").customName, "叫叫新名称 1");
    } finally { await instance.close(); }
  });
});

test("legacy shares stay automatic; explicit same-name rename remains pinned and invalid names do not mutate state", async () => {
  await withTempDir(async (dataDir) => {
    let instance = await listenApp(dataDir, { codeGenerator: sequenceGenerator(["Nm0"]) });
    await upload(instance.port, "original.riv", makeRive());
    await instance.close();
    const statePath = path.join(dataDir, "state.json");
    const state = JSON.parse(await readFile(statePath, "utf8"));
    delete state.shares[0].customName;
    await writeFile(statePath, JSON.stringify(state));
    instance = await listenApp(dataDir);
    try {
      assert.equal(instance.app.store.get("Nm0").customName, null);
      const before = await readFile(statePath, "utf8");
      for (const name of [undefined, null, 42, "", "   ", "x".repeat(121), "line\nbreak", "nul\u0000name"]) {
        const response = await call(instance.port, {
          method: "POST", pathname: "/api/v1/shares/Nm0/rename",
          headers: { "Content-Type": "application/json", "X-Rive-Action": "rename" }, body: { name },
        });
        assert.equal(response.status, 422);
      }
      const withoutHeader = await call(instance.port, {
        method: "POST", pathname: "/api/v1/shares/Nm0/rename", headers: { "Content-Type": "application/json" }, body: { name: "renamed" },
      });
      assert.equal(withoutHeader.status, 400);
      assert.equal(await readFile(statePath, "utf8"), before);
      const rename = await call(instance.port, {
        method: "POST", pathname: "/api/v1/shares/Nm0/rename",
        headers: { "Content-Type": "application/json", "X-Rive-Action": "rename" }, body: { name: "original.riv" },
      });
      assert.equal(rename.status, 200);
      const next = await uploadVersion(instance.port, "Nm0", "next.riv", makeRive("next"));
      assert.equal(next.json.item.customName, "original.riv");
      assert.equal(next.json.item.filename, "next.riv");
    } finally { await instance.close(); }
  });
});
