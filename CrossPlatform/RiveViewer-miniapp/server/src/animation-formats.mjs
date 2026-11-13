import { MAX_FILE_BYTES, MEBIBYTE } from "./config.mjs";
import { AppError } from "./errors.mjs";

export const ANIMATION_FORMATS = ["rive", "lottie", "pag"];
export const MAX_PAG_FILE_BYTES = 10 * MEBIBYTE;

export function animationFormatFromFilename(filename) {
  const lower = filename.toLowerCase();
  if (lower.endsWith(".riv")) return "rive";
  if (lower.endsWith(".json")) return "lottie";
  if (lower.endsWith(".pag")) return "pag";
  throw new AppError(422, "invalid_extension", "只接受 .riv、.json 和 .pag 文件");
}

export function maxBytesForFormat(format) {
  return format === "pag" ? MAX_PAG_FILE_BYTES : MAX_FILE_BYTES;
}

export function fileTooLargeMessage(format) {
  return format === "pag" ? "PAG 文件不能超过 10 MiB" : "文件不能超过 64 MiB";
}

export function parseFormatFilter(value) {
  if (!value) return ["rive"];
  const formats = [...new Set(value.split(",").map((item) => item.trim()).filter(Boolean))];
  if (!formats.length || formats.some((format) => !ANIMATION_FORMATS.includes(format))) {
    throw new AppError(400, "invalid_formats", "formats 包含不支持的文件格式");
  }
  return formats;
}
