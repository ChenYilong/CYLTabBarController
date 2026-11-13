import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { brotliCompress, constants, gzip } from "node:zlib";
import { promisify } from "node:util";

const outputRoot = fileURLToPath(new URL("../dist-static/", import.meta.url));
const compressBrotli = promisify(brotliCompress);
const compressGzip = promisify(gzip);
const compressible = /\.(?:css|html|js|json|svg|wasm)$/;

async function collect(directory) {
  const entries = await fs.readdir(directory, { withFileTypes: true });
  const nested = await Promise.all(entries.map(async (entry) => {
    const target = path.join(directory, entry.name);
    return entry.isDirectory() ? collect(target) : [target];
  }));
  return nested.flat();
}

const files = (await collect(outputRoot)).filter((file) => compressible.test(file));
await Promise.all(files.map(async (file) => {
  const source = await fs.readFile(file);
  if (source.byteLength < 1024) return;
  const [brotli, gzipped] = await Promise.all([
    compressBrotli(source, {
      params: { [constants.BROTLI_PARAM_QUALITY]: 11 },
    }),
    compressGzip(source, { level: 9 }),
  ]);
  await Promise.all([
    fs.writeFile(`${file}.br`, brotli),
    fs.writeFile(`${file}.gz`, gzipped),
  ]);
}));

console.log(`已为 ${files.length} 个静态资源生成 Brotli/Gzip 版本。`);
