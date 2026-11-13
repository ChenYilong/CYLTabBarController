#!/usr/bin/env node
import { createReadStream } from "node:fs";
import { stat, unlink } from "node:fs/promises";
import path from "node:path";
import { loadConfig, MAX_FILE_BYTES } from "../src/config.mjs";
import { normalizeFilename, stageRiveStream } from "../src/ingest.mjs";
import { ShareStore } from "../src/store.mjs";

const inputPaths = process.argv.slice(2);
if (!inputPaths.length) {
  console.error("用法：npm run seed:examples -- /绝对路径/example.riv [...]");
  process.exitCode = 2;
} else {
  const config = loadConfig();
  const store = await ShareStore.open(config);
  const results = [];

  for (const input of inputPaths) {
    const filePath = path.resolve(input);
    const info = await stat(filePath);
    if (!info.isFile()) throw new Error(`${filePath} 不是文件`);
    if (info.size > MAX_FILE_BYTES) throw new Error(`${filePath} 超过 64 MiB`);
    const { filename } = normalizeFilename(path.basename(filePath));
    const staged = await stageRiveStream(createReadStream(filePath), store.tempDir);
    try {
      const existing = store.findExampleBySha256(staged.sha256);
      if (existing) {
        results.push({ created: false, item: existing });
      } else {
        await store.assertUploadAllowed(staged.size);
        const item = await store.createFromStaged({
          ...staged,
          filename,
          isExample: true,
        });
        results.push({ created: true, item });
      }
    } finally {
      await unlink(staged.tempPath).catch(() => {});
    }
  }

  console.log(JSON.stringify({ items: results }, null, 2));
}
