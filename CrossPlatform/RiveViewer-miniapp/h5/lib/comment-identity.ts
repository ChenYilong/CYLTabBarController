const COMMENT_VISITOR_STORAGE_KEY = "rive-host-comment-visitor-v1";
const COMMENT_AUTHOR_STORAGE_KEY = "rive-host-comment-author-v1";
const VISITOR_ID_PATTERN = /^[0-9A-Za-z-]{16,80}$/;
const WEBP_DATA_URL_PATTERN = /^data:image\/webp;base64,[0-9A-Za-z+/]+={0,2}$/;

export const COMMENT_NICKNAME_LIMIT = 12;
export const COMMENT_AVATAR_EDGE = 64;
const MAX_COMMENT_AVATAR_BYTES = 12 * 1024;

export type LocalCommentAuthor = {
  nickname?: string;
  avatarDataUrl?: string;
};

let memoryVisitorId = "";

function createVisitorId(): string {
  if (typeof globalThis.crypto?.randomUUID === "function") {
    return globalThis.crypto.randomUUID();
  }
  const randomPart = Math.random().toString(36).slice(2);
  return `visitor-${Date.now().toString(36)}-${randomPart}-${randomPart}`.slice(0, 80);
}

export function getCommentVisitorId(): string {
  if (memoryVisitorId) return memoryVisitorId;
  try {
    const stored = window.localStorage.getItem(COMMENT_VISITOR_STORAGE_KEY) || "";
    if (VISITOR_ID_PATTERN.test(stored)) {
      memoryVisitorId = stored;
      return stored;
    }
  } catch {
    // Safari 隐私模式或受限 WebView 仍在当前页面会话内保持稳定。
  }

  memoryVisitorId = createVisitorId();
  try {
    window.localStorage.setItem(COMMENT_VISITOR_STORAGE_KEY, memoryVisitorId);
  } catch {
    // 持久化失败时使用模块内存值，不读取指纹信息。
  }
  return memoryVisitorId;
}

export function limitCommentNickname(value: string): string {
  return Array.from(value.normalize("NFC")).slice(0, COMMENT_NICKNAME_LIMIT).join("");
}

function normalizeLocalCommentAuthor(value: unknown): LocalCommentAuthor {
  if (!value || typeof value !== "object" || Array.isArray(value)) return {};
  const candidate = value as LocalCommentAuthor;
  const nickname = typeof candidate.nickname === "string"
    ? limitCommentNickname(candidate.nickname).trim()
    : "";
  const avatarDataUrl = typeof candidate.avatarDataUrl === "string"
    && candidate.avatarDataUrl.length <= 16_407
    && WEBP_DATA_URL_PATTERN.test(candidate.avatarDataUrl)
    ? candidate.avatarDataUrl
    : "";
  return {
    ...(nickname ? { nickname } : {}),
    ...(avatarDataUrl ? { avatarDataUrl } : {}),
  };
}

export function getLocalCommentAuthor(): LocalCommentAuthor {
  try {
    return normalizeLocalCommentAuthor(JSON.parse(
      window.localStorage.getItem(COMMENT_AUTHOR_STORAGE_KEY) || "null",
    ));
  } catch {
    return {};
  }
}

export function saveLocalCommentAuthor(author: LocalCommentAuthor): LocalCommentAuthor {
  const normalized = normalizeLocalCommentAuthor(author);
  try {
    window.localStorage.setItem(COMMENT_AUTHOR_STORAGE_KEY, JSON.stringify(normalized));
  } catch {
    // 受限 WebView 仍允许当前页面继续使用已压缩头像。
  }
  return normalized;
}

function canvasToWebp(canvas: HTMLCanvasElement, quality: number): Promise<Blob> {
  return new Promise((resolve, reject) => {
    canvas.toBlob((blob) => {
      if (!blob || blob.type !== "image/webp") {
        reject(new Error("当前浏览器无法生成 WebP 头像"));
        return;
      }
      resolve(blob);
    }, "image/webp", quality);
  });
}

function blobToDataUrl(blob: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onerror = () => reject(new Error("头像读取失败"));
    reader.onload = () => resolve(String(reader.result || ""));
    reader.readAsDataURL(blob);
  });
}

export async function compressCommentAvatar(file: File): Promise<string> {
  if (!file.type.startsWith("image/")) throw new Error("请选择图片文件");
  const bitmap = await createImageBitmap(file);
  try {
    const sourceEdge = Math.min(bitmap.width, bitmap.height);
    const sourceX = Math.max(0, (bitmap.width - sourceEdge) / 2);
    const sourceY = Math.max(0, (bitmap.height - sourceEdge) / 2);
    const canvas = document.createElement("canvas");
    canvas.width = COMMENT_AVATAR_EDGE;
    canvas.height = COMMENT_AVATAR_EDGE;
    const context = canvas.getContext("2d");
    if (!context) throw new Error("头像处理失败");
    context.drawImage(
      bitmap,
      sourceX,
      sourceY,
      sourceEdge,
      sourceEdge,
      0,
      0,
      COMMENT_AVATAR_EDGE,
      COMMENT_AVATAR_EDGE,
    );
    let webp = await canvasToWebp(canvas, 0.82);
    if (webp.size > MAX_COMMENT_AVATAR_BYTES) webp = await canvasToWebp(canvas, 0.64);
    if (webp.size > MAX_COMMENT_AVATAR_BYTES) webp = await canvasToWebp(canvas, 0.48);
    if (webp.size > MAX_COMMENT_AVATAR_BYTES) throw new Error("头像压缩后仍过大，请换一张图片");
    return blobToDataUrl(webp);
  } finally {
    bitmap.close();
  }
}
