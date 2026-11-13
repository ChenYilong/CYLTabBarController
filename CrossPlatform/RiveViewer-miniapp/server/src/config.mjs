import path from "node:path";
import { fileURLToPath } from "node:url";
import { AppError } from "./errors.mjs";

export const MEBIBYTE = 1024 * 1024;
export const GIBIBYTE = 1024 * 1024 * 1024;
export const MAX_FILE_BYTES = 64 * MEBIBYTE;
export const DEFAULT_MAX_TOTAL_BYTES = 5 * GIBIBYTE;
export const MIN_FREE_BYTES = 6 * GIBIBYTE;
export const SERVER_ROOT = path.resolve(fileURLToPath(new URL("..", import.meta.url)));

function parseInteger(value, fallback, label, minimum, maximum = Number.MAX_SAFE_INTEGER) {
  if (value === undefined || value === "") return fallback;
  if (!/^[0-9]+$/.test(value)) {
    throw new Error(`${label} 必须是整数`);
  }
  const parsed = Number(value);
  if (!Number.isSafeInteger(parsed) || parsed < minimum || parsed > maximum) {
    throw new Error(`${label} 超出允许范围`);
  }
  return parsed;
}

export function loadConfig(environment = process.env) {
  const rawDataDir = environment.RIVE_HOST_DATA_DIR;
  if (!rawDataDir) {
    throw new Error("必须设置 RIVE_HOST_DATA_DIR");
  }
  if (!path.isAbsolute(rawDataDir)) {
    throw new Error("RIVE_HOST_DATA_DIR 必须是绝对路径");
  }

  return {
    dataDir: path.resolve(rawDataDir),
    host: environment.RIVE_HOST_HOST || "127.0.0.1",
    port: parseInteger(environment.RIVE_HOST_PORT, 8097, "RIVE_HOST_PORT", 1, 65535),
    maxTotalBytes: parseInteger(
      environment.RIVE_HOST_MAX_TOTAL_BYTES,
      DEFAULT_MAX_TOTAL_BYTES,
      "RIVE_HOST_MAX_TOTAL_BYTES",
      MAX_FILE_BYTES,
    ),
    analyticsSalt: (() => {
      const value = environment.RIVE_HOST_ANALYTICS_SALT || "";
      if (value && value.length < 32) throw new Error("RIVE_HOST_ANALYTICS_SALT 至少需要 32 个字符");
      if (environment.NODE_ENV === "production" && !value) {
        throw new Error("生产环境必须设置 RIVE_HOST_ANALYTICS_SALT");
      }
      return value;
    })(),
    analyticsPassword: (() => {
      const value = environment.RIVE_HOST_ANALYTICS_PASSWORD || "";
      if (value && !/^\d{6}$/.test(value)) {
        throw new Error("RIVE_HOST_ANALYTICS_PASSWORD 必须是 6 位数字");
      }
      if (environment.NODE_ENV === "production" && !value) {
        throw new Error("生产环境必须设置 RIVE_HOST_ANALYTICS_PASSWORD");
      }
      return value;
    })(),
  };
}

export function assertDataDirOutsideRelease(dataDir, realServerRoot = SERVER_ROOT) {
  const relative = path.relative(realServerRoot, dataDir);
  const isInside = relative === "" || (
    relative !== ".."
    && !relative.startsWith(`..${path.sep}`)
    && !path.isAbsolute(relative)
  );
  if (isInside) {
    throw new AppError(
      500,
      "invalid_data_dir",
      "RIVE_HOST_DATA_DIR 不能位于 server 发布目录内",
    );
  }
}
