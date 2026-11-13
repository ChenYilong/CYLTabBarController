export type AnimationFormat = "rive" | "lottie" | "pag";

export const SUPPORTED_ANIMATION_ACCEPT = ".riv,.json,.pag,application/json,application/octet-stream";
export const MAX_HOSTED_FILE_BYTES = 64 * 1024 * 1024;
export const MAX_PAG_FILE_BYTES = 10 * 1024 * 1024;

export function animationFormatFromFilename(filename: string): AnimationFormat | null {
  const lower = filename.toLowerCase();
  if (lower.endsWith(".riv")) return "rive";
  if (lower.endsWith(".json")) return "lottie";
  if (lower.endsWith(".pag")) return "pag";
  return null;
}

export function animationFormatLabel(format: AnimationFormat): string {
  if (format === "lottie") return "Lottie";
  if (format === "pag") return "PAG";
  return "Rive";
}

export function maxFileBytesForFormat(format: AnimationFormat): number {
  return format === "pag" ? MAX_PAG_FILE_BYTES : MAX_HOSTED_FILE_BYTES;
}

export function validateAnimationFile(file: Pick<File, "name" | "size">): AnimationFormat {
  const format = animationFormatFromFilename(file.name);
  if (!format) throw new Error("只接受 .riv、.json 和 .pag 文件");
  if (file.size > maxFileBytesForFormat(format)) {
    if (format === "pag") throw new Error(`${file.name} 超过 10 MiB，不支持预览或上传。`);
    throw new Error(`${file.name} 超过 64 MiB，无法上传。`);
  }
  return format;
}

export function normalizeAnimationFormat(
  format: AnimationFormat | undefined,
  filename: string,
): AnimationFormat {
  return format || animationFormatFromFilename(filename) || "rive";
}
