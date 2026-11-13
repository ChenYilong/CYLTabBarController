import type { AnimationFormat } from "./animation-format";

export type HostedShareStatus = "active" | "archived";

export type HostedFileVersion = {
  id: string;
  name: string;
  filename: string;
  format: AnimationFormat;
  size: number;
  sha256: string;
  etag: string;
  createdAt: string;
};

export type HostedShare = {
  code: string;
  filename: string;
  customName?: string | null;
  format: AnimationFormat;
  size: number;
  sha256: string;
  etag: string;
  isExample: boolean;
  status: HostedShareStatus;
  createdAt: string;
  archivedAt: string | null;
  commentCount: number;
  versionCount?: number;
  currentVersionId?: string;
  versions?: HostedFileVersion[];
};

export type HostedComment = {
  id: string;
  nickname: string;
  avatar: string;
  avatarDataUrl?: string;
  body: string;
  createdAt: string;
  status: HostedShareStatus;
  archivedAt: string | null;
  versionId?: string;
};

export type HostedCommentIdentity = Pick<HostedComment, "nickname" | "avatar">;
export type HostedCommentAuthorInput = {
  nickname?: string;
  avatarDataUrl?: string;
};

type ItemEnvelope<T> = { item: T };
type ItemsEnvelope<T> = { items: T[] };
type ErrorEnvelope = { error?: { code?: string; message?: string } };

const API_ROOT = "/api/v1";
const RESPONSE_TIMEOUT_MS = 20_000;
const DOWNLOAD_STALL_TIMEOUT_MS = 30_000;

type HostedFileDownloadOptions = {
  signal?: AbortSignal;
  expectedBytes?: number;
  onProgress?: (percent: number) => void;
  versionId?: string;
};

export class HostedApiError extends Error {
  readonly status: number;
  readonly code: string;

  constructor(message: string, status: number, code = "request_failed") {
    super(message);
    this.name = "HostedApiError";
    this.status = status;
    this.code = code;
  }
}

async function fetchResponse(input: RequestInfo | URL, init: RequestInit = {}): Promise<Response> {
  const controller = new AbortController();
  const parentSignal = init.signal;
  let timedOut = false;
  const abortFromParent = () => controller.abort(parentSignal?.reason);
  if (parentSignal?.aborted) abortFromParent();
  else parentSignal?.addEventListener("abort", abortFromParent, { once: true });
  const timeoutId = globalThis.setTimeout(() => {
    timedOut = true;
    controller.abort();
  }, RESPONSE_TIMEOUT_MS);

  try {
    return await fetch(input, { ...init, signal: controller.signal });
  } catch (requestError) {
    if (timedOut) {
      throw new HostedApiError("连接服务器超过 20 秒，请重试", 0, "response_timeout");
    }
    throw requestError;
  } finally {
    globalThis.clearTimeout(timeoutId);
    parentSignal?.removeEventListener("abort", abortFromParent);
  }
}

async function throwResponseError(response: Response): Promise<never> {
  let payload: ErrorEnvelope | null = null;
  try {
    payload = await response.json() as ErrorEnvelope;
  } catch {
    // 非 JSON 错误仍使用稳定的中文回退文案。
  }
  throw new HostedApiError(
    payload?.error?.message || `请求失败 (${response.status})`,
    response.status,
    payload?.error?.code,
  );
}

async function requestJson<T>(path: string, init?: RequestInit): Promise<T> {
  let response: Response;
  try {
    response = await fetchResponse(`${API_ROOT}${path}`, {
      ...init,
      headers: {
        Accept: "application/json",
        ...init?.headers,
      },
    });
  } catch (requestError) {
    if (init?.signal?.aborted || requestError instanceof HostedApiError) throw requestError;
    throw new HostedApiError("连接服务器失败，请检查网络后重试", 0, "network_error");
  }
  if (!response.ok) return throwResponseError(response);
  return response.json() as Promise<T>;
}

export async function listHostedShares(
  status: HostedShareStatus,
  signal?: AbortSignal,
  formats?: AnimationFormat[],
): Promise<HostedShare[]> {
  const formatQuery = formats?.length ? `&formats=${encodeURIComponent(formats.join(","))}` : "";
  const payload = await requestJson<ItemsEnvelope<HostedShare>>(
    `/shares?status=${encodeURIComponent(status)}${formatQuery}`,
    { signal },
  );
  return payload.items;
}

export async function createHostedShare(
  data: ArrayBuffer,
  filename: string,
  onProgress?: (percent: number) => void,
  signal?: AbortSignal,
): Promise<HostedShare> {
  return uploadHostedBinary("/shares", data, filename, onProgress, signal);
}

export async function createHostedVersion(
  code: string,
  data: ArrayBuffer,
  filename: string,
  onProgress?: (percent: number) => void,
  signal?: AbortSignal,
): Promise<HostedShare> {
  return uploadHostedBinary(
    `/shares/${encodeURIComponent(code)}/versions`,
    data,
    filename,
    onProgress,
    signal,
  );
}

function uploadHostedBinary(
  path: string,
  data: ArrayBuffer,
  filename: string,
  onProgress?: (percent: number) => void,
  signal?: AbortSignal,
): Promise<HostedShare> {
  return new Promise((resolve, reject) => {
    const request = new XMLHttpRequest();
    const abort = () => request.abort();
    const finish = () => signal?.removeEventListener("abort", abort);

    if (signal?.aborted) {
      reject(new DOMException("上传已取消", "AbortError"));
      return;
    }

    request.open("POST", `${API_ROOT}${path}`);
    request.timeout = 120_000;
    request.responseType = "json";
    request.setRequestHeader("Accept", "application/json");
    request.setRequestHeader("Content-Type", "application/octet-stream");
    request.setRequestHeader("X-Animation-Filename", encodeURIComponent(filename));
    request.upload.onprogress = (event) => {
      if (!event.lengthComputable || event.total <= 0) return;
      onProgress?.(Math.min(99, Math.max(1, Math.round((event.loaded / event.total) * 100))));
    };
    request.onerror = () => {
      finish();
      reject(new HostedApiError("上传网络连接失败", 0, "network_error"));
    };
    request.ontimeout = () => {
      finish();
      reject(new HostedApiError("上传超时，请检查网络后重试", 0, "upload_timeout"));
    };
    request.onabort = () => {
      finish();
      reject(new DOMException("上传已取消", "AbortError"));
    };
    request.onload = () => {
      finish();
      const payload = request.response as ItemEnvelope<HostedShare> & ErrorEnvelope | null;
      if (request.status >= 200 && request.status < 300 && payload?.item) {
        onProgress?.(100);
        resolve(payload.item);
        return;
      }
      reject(new HostedApiError(
        payload?.error?.message || `请求失败 (${request.status})`,
        request.status,
        payload?.error?.code,
      ));
    };
    signal?.addEventListener("abort", abort, { once: true });
    request.send(data);
  });
}

export async function getHostedShare(code: string, signal?: AbortSignal): Promise<HostedShare> {
  const payload = await requestJson<ItemEnvelope<HostedShare>>(
    `/shares/${encodeURIComponent(code)}`,
    { signal },
  );
  return payload.item;
}

export function hostedFileUrl(code: string, versionId?: string): string {
  const base = `${API_ROOT}/shares/${encodeURIComponent(code)}/file`;
  return versionId ? `${base}?versionId=${encodeURIComponent(versionId)}` : base;
}

function readChunkWithTimeout(
  reader: ReadableStreamDefaultReader<Uint8Array>,
): Promise<ReadableStreamReadResult<Uint8Array>> {
  return new Promise((resolve, reject) => {
    const timeoutId = globalThis.setTimeout(() => {
      reject(new HostedApiError(
        "下载 30 秒没有进展，请检查网络后重试",
        0,
        "download_stalled",
      ));
    }, DOWNLOAD_STALL_TIMEOUT_MS);
    reader.read().then(resolve, reject).finally(() => globalThis.clearTimeout(timeoutId));
  });
}

export async function getHostedFile(
  code: string,
  options: HostedFileDownloadOptions = {},
): Promise<ArrayBuffer> {
  let response: Response;
  try {
    response = await fetchResponse(hostedFileUrl(code, options.versionId), { signal: options.signal });
  } catch (downloadError) {
    if (options.signal?.aborted || downloadError instanceof HostedApiError) throw downloadError;
    throw new HostedApiError("连接服务器失败，请检查网络后重试", 0, "download_network_error");
  }
  if (!response.ok) return throwResponseError(response);

  const headerBytes = Number(response.headers.get("Content-Length"));
  const expectedBytes = Number.isSafeInteger(options.expectedBytes) && Number(options.expectedBytes) > 0
    ? Number(options.expectedBytes)
    : Number.isSafeInteger(headerBytes) && headerBytes > 0
      ? headerBytes
      : 0;
  if (!response.body) {
    const data = await response.arrayBuffer();
    options.onProgress?.(100);
    return data;
  }

  const reader = response.body.getReader();
  const chunks: Uint8Array[] = [];
  let receivedBytes = 0;
  let lastProgress = -1;
  const reportProgress = (complete = false) => {
    if (!options.onProgress) return;
    const percent = complete
      ? 100
      : expectedBytes > 0
        ? Math.min(99, Math.floor((receivedBytes / expectedBytes) * 100))
        : 0;
    if (percent === lastProgress) return;
    lastProgress = percent;
    options.onProgress(percent);
  };
  reportProgress();

  try {
    while (true) {
      const { done, value } = await readChunkWithTimeout(reader);
      if (done) break;
      if (!value?.byteLength) continue;
      chunks.push(value);
      receivedBytes += value.byteLength;
      reportProgress();
    }
  } catch (downloadError) {
    await reader.cancel().catch(() => undefined);
    if (options.signal?.aborted) throw downloadError;
    if (downloadError instanceof HostedApiError) throw downloadError;
    throw new HostedApiError("公开文件下载中断，请重试", 0, "download_interrupted");
  }

  if (expectedBytes > 0 && receivedBytes !== expectedBytes) {
    throw new HostedApiError("公开文件下载不完整，请重试", 0, "download_incomplete");
  }
  const data = new Uint8Array(receivedBytes);
  let offset = 0;
  for (const chunk of chunks) {
    data.set(chunk, offset);
    offset += chunk.byteLength;
  }
  reportProgress(true);
  return data.buffer;
}

export async function listHostedComments(
  code: string,
  signal?: AbortSignal,
): Promise<HostedComment[]> {
  const payload = await requestJson<ItemsEnvelope<HostedComment>>(
    `/shares/${encodeURIComponent(code)}/comments`,
    { signal },
  );
  return payload.items;
}

export async function getHostedCommentIdentity(
  visitorId: string,
  signal?: AbortSignal,
): Promise<HostedCommentIdentity> {
  const payload = await requestJson<ItemEnvelope<HostedCommentIdentity>>(
    `/comment-identity?visitorId=${encodeURIComponent(visitorId)}`,
    { signal },
  );
  return payload.item;
}

export async function createHostedComment(
  code: string,
  input: { visitorId: string; body: string; versionId?: string } & HostedCommentAuthorInput,
  signal?: AbortSignal,
): Promise<HostedComment> {
  const payload = await requestJson<ItemEnvelope<HostedComment>>(
    `/shares/${encodeURIComponent(code)}/comments`,
    {
      method: "POST",
      signal,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(input),
    },
  );
  return payload.item;
}

async function updateHostedCommentStatus(
  code: string,
  commentId: string,
  action: "archive" | "restore",
  signal?: AbortSignal,
): Promise<HostedComment> {
  const payload = await requestJson<ItemEnvelope<HostedComment>>(
    `/shares/${encodeURIComponent(code)}/comments/${encodeURIComponent(commentId)}/${action}`,
    {
      method: "POST",
      signal,
      headers: { "X-Rive-Action": action },
    },
  );
  return payload.item;
}

export function archiveHostedComment(
  code: string,
  commentId: string,
  signal?: AbortSignal,
): Promise<HostedComment> {
  return updateHostedCommentStatus(code, commentId, "archive", signal);
}

export function restoreHostedComment(
  code: string,
  commentId: string,
  signal?: AbortSignal,
): Promise<HostedComment> {
  return updateHostedCommentStatus(code, commentId, "restore", signal);
}

async function updateHostedShareStatus(
  code: string,
  action: "archive" | "restore",
  signal?: AbortSignal,
): Promise<HostedShare> {
  const payload = await requestJson<ItemEnvelope<HostedShare>>(
    `/shares/${encodeURIComponent(code)}/${action}`,
    {
      method: "POST",
      signal,
      headers: { "X-Rive-Action": action },
    },
  );
  return payload.item;
}

export async function renameHostedShare(code: string, name: string): Promise<HostedShare> {
  const payload = await requestJson<ItemEnvelope<HostedShare>>(
    `/shares/${encodeURIComponent(code)}/rename`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Rive-Action": "rename" },
      body: JSON.stringify({ name }),
    },
  );
  return payload.item;
}

export function archiveHostedShare(code: string, signal?: AbortSignal): Promise<HostedShare> {
  return updateHostedShareStatus(code, "archive", signal);
}

export function restoreHostedShare(code: string, signal?: AbortSignal): Promise<HostedShare> {
  return updateHostedShareStatus(code, "restore", signal);
}
