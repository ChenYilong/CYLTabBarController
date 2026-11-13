import { createReadStream } from "node:fs";
import { unlink } from "node:fs/promises";
import { pipeline } from "node:stream/promises";
import {
  fileTooLargeMessage,
  maxBytesForFormat,
  parseFormatFilter,
} from "./animation-formats.mjs";
import { ANALYTICS_ALLOWED_ORIGINS, AnalyticsStore } from "./analytics.mjs";
import { AnalyticsAccess } from "./analytics-auth.mjs";
import { AppError, isAppError } from "./errors.mjs";
import { pickForestIdentity } from "./forest-identities.mjs";
import {
  decodeFilenameHeader,
  stageAnimationStream,
} from "./ingest.mjs";
import { ShareStore } from "./store.mjs";

const CODE_PATH = "([0-9A-Za-z]{3})";
const SHARE_PATTERN = new RegExp(`^/api/v1/shares/${CODE_PATH}$`);
const RENAME_PATTERN = new RegExp(`^/api/v1/shares/${CODE_PATH}/rename$`);
const FILE_PATTERN = new RegExp(`^/api/v1/shares/${CODE_PATH}/file$`);
const VERSIONS_PATTERN = new RegExp(`^/api/v1/shares/${CODE_PATH}/versions$`);
const COMMENTS_PATTERN = new RegExp(`^/api/v1/shares/${CODE_PATH}/comments$`);
const COMMENT_ARCHIVE_PATTERN = new RegExp(
  `^/api/v1/shares/${CODE_PATH}/comments/([^/]+)/archive$`,
);
const COMMENT_RESTORE_PATTERN = new RegExp(
  `^/api/v1/shares/${CODE_PATH}/comments/([^/]+)/restore$`,
);
const COMMENT_IDENTITY_PATH = "/api/v1/comment-identity";
const ANALYTICS_EVENTS_PATH = "/api/v1/analytics/events";
const ANALYTICS_AUTH_PATH = "/api/v1/analytics/auth";
const ANALYTICS_LOGOUT_PATH = "/api/v1/analytics/logout";
const ANALYTICS_SUMMARY_PATH = "/api/v1/analytics/summary";
const ARCHIVE_PATTERN = new RegExp(`^/api/v1/shares/${CODE_PATH}/archive$`);
const RESTORE_PATTERN = new RegExp(`^/api/v1/shares/${CODE_PATH}/restore$`);
const MAX_JSON_BYTES = 32 * 1024;
const MAX_CUSTOM_AVATAR_BYTES = 12 * 1024;
const WEBP_DATA_URL_PREFIX = "data:image/webp;base64,";
const VERSION_ID_PATTERN = /^[0-9a-f-]{36}$/;

function applyCommonHeaders(response) {
  response.setHeader("X-Content-Type-Options", "nosniff");
  response.setHeader("Referrer-Policy", "no-referrer");
}

function sendJson(response, status, value, extraHeaders = {}) {
  const payload = Buffer.from(JSON.stringify(value));
  response.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": payload.length,
    "Cache-Control": "no-store",
    ...extraHeaders,
  });
  response.end(payload);
}

function sendError(response, error) {
  const status = isAppError(error) ? error.status : 500;
  const code = isAppError(error) ? error.code : "internal_error";
  const message = isAppError(error) ? error.message : "服务器内部错误";
  sendJson(response, status, { error: { code, message } });
}

function sendNoContent(response, extraHeaders = {}) {
  response.writeHead(204, {
    "Content-Length": 0,
    "Cache-Control": "no-store",
    ...extraHeaders,
  });
  response.end();
}

function parseContentLength(request) {
  const header = request.headers["content-length"];
  if (header === undefined) return null;
  if (Array.isArray(header) || !/^[0-9]+$/.test(header)) {
    throw new AppError(400, "invalid_content_length", "Content-Length 无效");
  }
  const value = Number(header);
  if (!Number.isSafeInteger(value)) {
    throw new AppError(400, "invalid_content_length", "Content-Length 无效");
  }
  return value;
}

function requireActionHeader(request, expected) {
  const value = request.headers["x-rive-action"];
  if (Array.isArray(value) || value !== expected) {
    throw new AppError(400, "missing_action_header", "缺少有效的操作确认标记");
  }
}

async function readJson(request, {
  acceptedTypes = ["application/json"],
  unsupportedMessage = "请求必须使用 application/json",
} = {}) {
  const type = String(request.headers["content-type"] || "").split(";", 1)[0].trim().toLowerCase();
  if (!acceptedTypes.includes(type)) {
    throw new AppError(415, "unsupported_media_type", unsupportedMessage);
  }
  const declaredLength = parseContentLength(request);
  if (declaredLength !== null && declaredLength > MAX_JSON_BYTES) {
    throw new AppError(413, "json_too_large", "请求内容过大");
  }

  const chunks = [];
  let size = 0;
  let tooLarge = false;
  for await (const value of request) {
    const chunk = Buffer.isBuffer(value) ? value : Buffer.from(value);
    size += chunk.length;
    if (size > MAX_JSON_BYTES) {
      tooLarge = true;
      continue;
    }
    chunks.push(chunk);
  }
  if (tooLarge) throw new AppError(413, "json_too_large", "请求内容过大");
  try {
    const parsed = JSON.parse(Buffer.concat(chunks).toString("utf8"));
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error();
    return parsed;
  } catch {
    throw new AppError(400, "invalid_json", "JSON 内容无效");
  }
}

function analyticsOrigin(request) {
  const value = request.headers.origin;
  if (Array.isArray(value)) return "";
  return ANALYTICS_ALLOWED_ORIGINS.has(value) ? value : "";
}

function applyAnalyticsCors(request, response) {
  const origin = analyticsOrigin(request);
  if (!origin) return false;
  response.setHeader("Access-Control-Allow-Origin", origin);
  response.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  response.setHeader("Access-Control-Allow-Headers", "Content-Type");
  response.setHeader("Access-Control-Max-Age", "86400");
  response.setHeader("Vary", "Origin");
  return true;
}

function normalizeHeader(value, limit) {
  return (Array.isArray(value) ? value[0] : String(value || "")).slice(0, limit);
}

function commentIdentitySource(request, payload) {
  if (payload.visitorId !== undefined) {
    if (typeof payload.visitorId !== "string" || !/^[0-9A-Za-z-]{16,80}$/.test(payload.visitorId)) {
      throw new AppError(422, "invalid_visitor", "访问标识无效");
    }
    return `visitor:${payload.visitorId}`;
  }
  const forwarded = normalizeHeader(request.headers["x-forwarded-for"], 128).split(",", 1)[0].trim();
  const address = forwarded || normalizeHeader(request.socket?.remoteAddress, 128);
  const userAgent = normalizeHeader(request.headers["user-agent"], 256);
  return `network:${address}|agent:${userAgent}`;
}

function normalizeCustomNickname(value) {
  if (value === undefined) return null;
  if (typeof value !== "string") {
    throw new AppError(422, "invalid_nickname", "昵称必须是文本");
  }
  const nickname = value.normalize("NFC").trim();
  if (
    [...nickname].length < 1
    || [...nickname].length > 12
    || /[\u0000-\u001f\u007f]/u.test(nickname)
  ) {
    throw new AppError(422, "invalid_nickname", "昵称须为 1 到 12 个字符");
  }
  return nickname;
}

function normalizeCustomAvatar(value) {
  if (value === undefined) return null;
  if (typeof value !== "string" || !value.startsWith(WEBP_DATA_URL_PREFIX)) {
    throw new AppError(422, "invalid_avatar", "头像必须是 WebP 图片");
  }
  const encoded = value.slice(WEBP_DATA_URL_PREFIX.length);
  if (!encoded || encoded.length % 4 !== 0 || !/^[0-9A-Za-z+/]+={0,2}$/.test(encoded)) {
    throw new AppError(422, "invalid_avatar", "头像数据无效");
  }
  const bytes = Buffer.from(encoded, "base64");
  if (
    bytes.length < 16
    || bytes.length > MAX_CUSTOM_AVATAR_BYTES
    || bytes.toString("ascii", 0, 4) !== "RIFF"
    || bytes.toString("ascii", 8, 12) !== "WEBP"
  ) {
    throw new AppError(422, "invalid_avatar", "头像须为 12 KiB 以内的 WebP 图片");
  }
  return `${WEBP_DATA_URL_PREFIX}${encoded}`;
}

function normalizeComment(request, payload) {
  if (typeof payload.body !== "string") {
    throw new AppError(422, "invalid_comment", "评论正文必须是文本");
  }
  const body = payload.body.normalize("NFC").replace(/\r\n?/g, "\n").trim();
  const length = [...body].length;
  if (length < 1 || length > 1000 || /[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/u.test(body)) {
    throw new AppError(422, "invalid_comment", "评论正文须为 1 到 1000 个字符");
  }
  const identity = pickForestIdentity(commentIdentitySource(request, payload));
  const nickname = normalizeCustomNickname(payload.nickname);
  const avatarDataUrl = normalizeCustomAvatar(payload.avatarDataUrl);
  const versionId = payload.versionId === undefined ? null : payload.versionId;
  if (versionId !== null && (typeof versionId !== "string" || !VERSION_ID_PATTERN.test(versionId))) {
    throw new AppError(422, "invalid_version", "评论对应的文件版本无效");
  }
  return {
    ...identity,
    ...(nickname ? { nickname } : {}),
    ...(avatarDataUrl ? { avatarDataUrl } : {}),
    body,
    ...(versionId ? { versionId } : {}),
  };
}

function parseRange(value, size) {
  if (!value) return null;
  const match = /^bytes=(\d*)-(\d*)$/.exec(value.trim());
  if (!match || (!match[1] && !match[2])) return false;

  let start;
  let end;
  if (!match[1]) {
    const suffix = Number(match[2]);
    if (!Number.isSafeInteger(suffix) || suffix <= 0) return false;
    start = Math.max(0, size - suffix);
    end = size - 1;
  } else {
    start = Number(match[1]);
    end = match[2] ? Number(match[2]) : size - 1;
    if (
      !Number.isSafeInteger(start)
      || !Number.isSafeInteger(end)
      || start < 0
      || end < start
      || start >= size
    ) return false;
    end = Math.min(end, size - 1);
  }
  return { start, end };
}

function encodeContentDisposition(filename) {
  const fallback = filename
    .replace(/[^\x20-\x7e]/g, "_")
    .replace(/["\\]/g, "_") || "file.riv";
  const encoded = encodeURIComponent(filename).replace(/[!'()*]/g, (character) => (
    `%${character.charCodeAt(0).toString(16).toUpperCase()}`
  ));
  return `inline; filename="${fallback}"; filename*=UTF-8''${encoded}`;
}

async function sendFile(request, response, file) {
  const { metadata, filePath } = file;
  const rangeHeader = request.headers.range;
  const useRange = !request.headers["if-range"] || request.headers["if-range"] === metadata.etag;
  const range = useRange ? parseRange(Array.isArray(rangeHeader) ? "" : rangeHeader, metadata.size) : null;

  if (range === false) {
    response.writeHead(416, {
      "Content-Range": `bytes */${metadata.size}`,
      "Content-Length": 0,
      ETag: metadata.etag,
      "Accept-Ranges": "bytes",
    });
    response.end();
    return;
  }

  if (!range && request.headers["if-none-match"] === metadata.etag) {
    response.writeHead(304, { ETag: metadata.etag, "Content-Length": 0 });
    response.end();
    return;
  }

  const start = range?.start ?? 0;
  const end = range?.end ?? metadata.size - 1;
  const length = end - start + 1;
  const status = range ? 206 : 200;
  const headers = {
    "Content-Type": "application/octet-stream",
    "Content-Length": length,
    "Content-Disposition": encodeContentDisposition(metadata.filename),
    "Accept-Ranges": "bytes",
    ETag: metadata.etag,
    "Cache-Control": "public, max-age=31536000, immutable",
  };
  if (range) headers["Content-Range"] = `bytes ${start}-${end}/${metadata.size}`;
  response.writeHead(status, headers);
  if (request.method === "HEAD") {
    response.end();
    return;
  }
  await pipeline(createReadStream(filePath, { start, end }), response);
}

export async function createRiveHostApp({
  dataDir,
  maxTotalBytes,
  codeGenerator,
  now,
  diskFreeProvider,
  analyticsSalt,
  analyticsPassword,
  logger = console,
} = {}) {
  const store = await ShareStore.open({
    dataDir,
    maxTotalBytes,
    codeGenerator,
    now,
    diskFreeProvider,
    logger,
  });
  const analyticsStore = await AnalyticsStore.open({
    dataDir,
    salt: analyticsSalt,
    now,
    logger,
  });
  const analyticsAccess = new AnalyticsAccess({
    password: analyticsPassword,
    salt: analyticsSalt,
    now,
  });

  const handler = async (request, response) => {
    applyCommonHeaders(response);
    try {
      const url = new URL(request.url, "http://rive-host.local");
      const { pathname } = url;

      if (request.method === "GET" && pathname === "/healthz") {
        sendJson(response, 200, { ok: true });
        return;
      }

      if (pathname === ANALYTICS_EVENTS_PATH) {
        if (request.method === "OPTIONS") {
          const origin = request.headers.origin;
          if (origin && !applyAnalyticsCors(request, response)) {
            throw new AppError(403, "origin_not_allowed", "当前来源不允许提交统计事件");
          }
          response.writeHead(204, { "Content-Length": 0, "Cache-Control": "no-store" });
          response.end();
          return;
        }
        if (request.method !== "POST") throw new AppError(405, "method_not_allowed", "请求方法不支持");
        const origin = request.headers.origin;
        if (origin && !applyAnalyticsCors(request, response)) {
          throw new AppError(403, "origin_not_allowed", "当前来源不允许提交统计事件");
        }
        const payload = await readJson(request, {
          acceptedTypes: ["application/json", "text/plain"],
          unsupportedMessage: "统计事件必须使用 JSON 或纯文本 JSON",
        });
        const accepted = await analyticsStore.recordBatch(payload, {
          userAgent: normalizeHeader(request.headers["user-agent"], 512),
        });
        sendJson(response, 202, { accepted });
        return;
      }

      if (pathname === ANALYTICS_AUTH_PATH) {
        if (request.method !== "POST") throw new AppError(405, "method_not_allowed", "请求方法不支持");
        if (!analyticsAccess.enabled) {
          throw new AppError(503, "analytics_auth_unavailable", "数据后台访问密码尚未配置");
        }
        const payload = await readJson(request);
        if (!analyticsAccess.matchesPassword(payload.password)) {
          throw new AppError(401, "invalid_password", "访问密码不正确");
        }
        sendNoContent(response, { "Set-Cookie": analyticsAccess.sessionCookie() });
        return;
      }

      if (pathname === ANALYTICS_LOGOUT_PATH) {
        if (request.method !== "POST") throw new AppError(405, "method_not_allowed", "请求方法不支持");
        sendNoContent(response, { "Set-Cookie": analyticsAccess.clearCookie() });
        return;
      }

      if (pathname === ANALYTICS_SUMMARY_PATH) {
        if (request.method !== "GET") throw new AppError(405, "method_not_allowed", "请求方法不支持");
        if (!analyticsAccess.isAuthorized(request)) {
          throw new AppError(401, "analytics_auth_required", "请先输入数据后台访问密码");
        }
        const days = Number(url.searchParams.get("days") || 30);
        const surface = url.searchParams.get("surface") || "all";
        const format = url.searchParams.get("format") || "all";
        const item = await analyticsStore.summary({ days, surface, format });
        item.failedFiles = item.failedFiles.flatMap((row) => {
          const share = store.get(row.code);
          if (!share || share.status !== "active") return [];
          return [{ ...row, name: share.filename, format: share.format }];
        });
        sendJson(response, 200, { item });
        return;
      }

      if (pathname === COMMENT_IDENTITY_PATH) {
        if (request.method !== "GET") throw new AppError(405, "method_not_allowed", "请求方法不支持");
        const visitorId = url.searchParams.get("visitorId");
        if (!visitorId) throw new AppError(422, "invalid_visitor", "访问标识无效");
        sendJson(response, 200, {
          item: pickForestIdentity(commentIdentitySource(request, { visitorId })),
        });
        return;
      }

      if (pathname === "/api/v1/shares") {
        if (request.method === "GET") {
          const status = url.searchParams.get("status") || "active";
          if (!['active', 'archived'].includes(status)) {
            throw new AppError(400, "invalid_status", "status 必须是 active 或 archived");
          }
          const formats = parseFormatFilter(url.searchParams.get("formats"));
          sendJson(response, 200, { items: store.list(status, formats) });
          return;
        }
        if (request.method === "POST") {
          const contentType = String(request.headers["content-type"] || "").split(";", 1)[0].trim().toLowerCase();
          if (contentType !== "application/octet-stream") {
            throw new AppError(415, "unsupported_media_type", "上传必须使用 application/octet-stream");
          }
          const encodedFilename = request.headers["x-animation-filename"]
            ?? request.headers["x-rive-filename"];
          const { filename, format } = decodeFilenameHeader(encodedFilename);
          const declaredLength = parseContentLength(request);
          const maxBytes = maxBytesForFormat(format);
          if (declaredLength !== null && declaredLength > maxBytes) {
            throw new AppError(413, "file_too_large", fileTooLargeMessage(format));
          }
          await store.assertUploadAllowed(declaredLength || 0);

          const staged = await stageAnimationStream(request, store.tempDir, format, { maxBytes });
          try {
            const item = await store.createFromStaged({
              ...staged,
              filename,
              format,
              isExample: false,
            });
            sendJson(response, 201, { item });
          } finally {
            await unlink(staged.tempPath).catch(() => {});
          }
          return;
        }
        throw new AppError(405, "method_not_allowed", "请求方法不支持");
      }

      let match = SHARE_PATTERN.exec(pathname);
      if (match) {
        if (request.method !== "GET") throw new AppError(405, "method_not_allowed", "请求方法不支持");
        const item = store.get(match[1]);
        if (!item) throw new AppError(404, "share_not_found", "分享不存在");
        sendJson(response, 200, { item });
        return;
      }

      match = RENAME_PATTERN.exec(pathname);
      if (match) {
        if (request.method !== "POST") throw new AppError(405, "method_not_allowed", "请求方法不支持");
        requireActionHeader(request, "rename");
        const payload = await readJson(request);
        const item = await store.rename(match[1], payload.name);
        sendJson(response, 200, { item });
        return;
      }

      match = FILE_PATTERN.exec(pathname);
      if (match) {
        if (!['GET', 'HEAD'].includes(request.method)) {
          throw new AppError(405, "method_not_allowed", "请求方法不支持");
        }
        const versionId = url.searchParams.get("versionId");
        if (versionId && !VERSION_ID_PATTERN.test(versionId)) {
          throw new AppError(422, "invalid_version", "文件版本无效");
        }
        const share = store.get(match[1]);
        if (!share) throw new AppError(404, "share_not_found", "分享不存在");
        const file = store.getFile(match[1], versionId);
        if (!file) throw new AppError(404, "version_not_found", "文件版本不存在");
        if (file.metadata.status === "archived") {
          throw new AppError(410, "share_archived", "分享已归档");
        }
        await sendFile(request, response, file);
        return;
      }

      match = VERSIONS_PATTERN.exec(pathname);
      if (match) {
        if (request.method !== "POST") throw new AppError(405, "method_not_allowed", "请求方法不支持");
        const contentType = String(request.headers["content-type"] || "").split(";", 1)[0].trim().toLowerCase();
        if (contentType !== "application/octet-stream") {
          throw new AppError(415, "unsupported_media_type", "上传必须使用 application/octet-stream");
        }
        const encodedFilename = request.headers["x-animation-filename"]
          ?? request.headers["x-rive-filename"];
        const { filename, format } = decodeFilenameHeader(encodedFilename);
        const existingShare = store.get(match[1]);
        if (!existingShare) throw new AppError(404, "share_not_found", "分享不存在");
        if (existingShare.format !== format) {
          throw new AppError(422, "format_mismatch", "新版本必须与当前文件格式一致");
        }
        const declaredLength = parseContentLength(request);
        const maxBytes = maxBytesForFormat(format);
        if (declaredLength !== null && declaredLength > maxBytes) {
          throw new AppError(413, "file_too_large", fileTooLargeMessage(format));
        }
        await store.assertUploadAllowed(declaredLength || 0);

        const staged = await stageAnimationStream(request, store.tempDir, format, { maxBytes });
        try {
          const item = await store.addVersionFromStaged(match[1], {
            ...staged,
            filename,
            format,
          });
          sendJson(response, 201, { item });
        } finally {
          await unlink(staged.tempPath).catch(() => {});
        }
        return;
      }

      match = COMMENTS_PATTERN.exec(pathname);
      if (match) {
        if (request.method === "GET") {
          const items = store.comments(match[1]);
          if (!items) throw new AppError(404, "share_not_found", "分享不存在");
          sendJson(response, 200, { items });
          return;
        }
        if (request.method === "POST") {
          if (!store.get(match[1])) throw new AppError(404, "share_not_found", "分享不存在");
          const item = await store.addComment(match[1], normalizeComment(request, await readJson(request)));
          sendJson(response, 201, { item });
          return;
        }
        throw new AppError(405, "method_not_allowed", "请求方法不支持");
      }

      match = COMMENT_ARCHIVE_PATTERN.exec(pathname);
      if (match) {
        if (request.method !== "POST") throw new AppError(405, "method_not_allowed", "请求方法不支持");
        requireActionHeader(request, "archive");
        sendJson(response, 200, { item: await store.archiveComment(match[1], match[2]) });
        return;
      }

      match = COMMENT_RESTORE_PATTERN.exec(pathname);
      if (match) {
        if (request.method !== "POST") throw new AppError(405, "method_not_allowed", "请求方法不支持");
        requireActionHeader(request, "restore");
        sendJson(response, 200, { item: await store.restoreComment(match[1], match[2]) });
        return;
      }

      match = ARCHIVE_PATTERN.exec(pathname);
      if (match) {
        if (request.method !== "POST") throw new AppError(405, "method_not_allowed", "请求方法不支持");
        requireActionHeader(request, "archive");
        sendJson(response, 200, { item: await store.archive(match[1]) });
        return;
      }

      match = RESTORE_PATTERN.exec(pathname);
      if (match) {
        if (request.method !== "POST") throw new AppError(405, "method_not_allowed", "请求方法不支持");
        requireActionHeader(request, "restore");
        sendJson(response, 200, { item: await store.restore(match[1]) });
        return;
      }

      throw new AppError(404, "not_found", "接口不存在");
    } catch (error) {
      if (response.headersSent) {
        response.destroy(error);
        return;
      }
      if (!isAppError(error)) logger.error?.(error);
      sendError(response, error);
    }
  };

  return { handler, store, analyticsStore };
}
