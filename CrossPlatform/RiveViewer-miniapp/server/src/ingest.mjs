import { createHash, randomBytes } from "node:crypto";
import { open, readFile, unlink } from "node:fs/promises";
import path from "node:path";
import {
  animationFormatFromFilename,
  fileTooLargeMessage,
  maxBytesForFormat,
} from "./animation-formats.mjs";
import { AppError } from "./errors.mjs";

const RIVE_MAGIC = Buffer.from("RIVE", "ascii");
const PAG_MAGIC = Buffer.from("PAG", "ascii");

export function normalizeFilename(value) {
  if (typeof value !== "string") {
    throw new AppError(400, "missing_filename", "缺少 X-Animation-Filename");
  }

  const filename = value.normalize("NFC").trim();
  if (!filename) {
    throw new AppError(400, "invalid_filename", "文件名不能为空");
  }
  if ([...filename].length > 255 || Buffer.byteLength(filename, "utf8") > 768) {
    throw new AppError(400, "invalid_filename", "文件名过长");
  }
  if (/[/\\\u0000-\u001f\u007f]/u.test(filename)) {
    throw new AppError(400, "invalid_filename", "文件名包含非法字符");
  }
  return { filename, format: animationFormatFromFilename(filename) };
}

export function decodeFilenameHeader(headerValue) {
  if (Array.isArray(headerValue) || typeof headerValue !== "string") {
    throw new AppError(400, "missing_filename", "缺少 X-Animation-Filename");
  }
  try {
    return normalizeFilename(decodeURIComponent(headerValue));
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(400, "invalid_filename", "X-Animation-Filename 编码无效");
  }
}

function validateLottieDocument(value) {
  if (
    !value
    || typeof value !== "object"
    || Array.isArray(value)
    || !Array.isArray(value.layers)
    || !Number.isFinite(value.fr)
    || !Number.isFinite(value.ip)
    || !Number.isFinite(value.op)
    || !Number.isFinite(value.w)
    || !Number.isFinite(value.h)
  ) {
    throw new AppError(422, "invalid_lottie", "JSON 不是有效的 Lottie 动画");
  }
  const externalImage = Array.isArray(value.assets) && value.assets.some((asset) => (
    asset && typeof asset === "object" && typeof asset.p === "string"
    && !asset.p.startsWith("data:") && asset.e !== 1
  ));
  const externalFont = Array.isArray(value.fonts?.list) && value.fonts.list.some((font) => (
    font && typeof font === "object" && typeof font.fPath === "string" && font.fPath.trim()
  ));
  if (externalImage || externalFont) {
    throw new AppError(422, "external_lottie_asset", "Lottie 暂只支持资源已内嵌的单个 JSON 文件");
  }
}

async function validateStagedFile(tempPath, format, magic) {
  if (format === "rive") {
    if (magic.length < RIVE_MAGIC.length || !magic.subarray(0, RIVE_MAGIC.length).equals(RIVE_MAGIC)) {
      throw new AppError(422, "invalid_rive", "文件头不是有效的 RIVE");
    }
    return;
  }
  if (format === "pag") {
    if (magic.length < 4 || !magic.subarray(0, PAG_MAGIC.length).equals(PAG_MAGIC)) {
      throw new AppError(422, "invalid_pag", "文件头不是有效的 PAG");
    }
    return;
  }
  try {
    validateLottieDocument(JSON.parse(await readFile(tempPath, "utf8")));
  } catch (error) {
    if (error instanceof AppError) throw error;
    throw new AppError(422, "invalid_lottie", "JSON 不是有效的 Lottie 动画");
  }
}

export async function stageAnimationStream(readable, tempDir, format, options = {}) {
  const maxBytes = options.maxBytes ?? maxBytesForFormat(format);
  const tempPath = path.join(
    tempDir,
    `upload-${process.pid}-${Date.now()}-${randomBytes(8).toString("hex")}.tmp`,
  );
  const handle = await open(tempPath, "wx", 0o600);
  const hash = createHash("sha256");
  let size = 0;
  let magic = Buffer.alloc(0);
  let tooLarge = false;

  try {
    for await (const value of readable) {
      const chunk = Buffer.isBuffer(value) ? value : Buffer.from(value);
      if (tooLarge) continue;
      if (size + chunk.length > maxBytes) {
        tooLarge = true;
        continue;
      }
      size += chunk.length;
      hash.update(chunk);
      if (magic.length < RIVE_MAGIC.length) {
        magic = Buffer.concat([magic, chunk.subarray(0, RIVE_MAGIC.length - magic.length)]);
      }
      await handle.writeFile(chunk);
    }
    if (tooLarge) {
      throw new AppError(413, "file_too_large", fileTooLargeMessage(format));
    }
    await handle.sync();
    await handle.close();
    await validateStagedFile(tempPath, format, magic);
    return {
      tempPath,
      size,
      sha256: hash.digest("hex"),
    };
  } catch (error) {
    await handle.close().catch(() => {});
    await unlink(tempPath).catch(() => {});
    throw error;
  } finally {
    await handle.close().catch(() => {});
  }
}

export function stageRiveStream(readable, tempDir, options = {}) {
  return stageAnimationStream(readable, tempDir, "rive", options);
}
