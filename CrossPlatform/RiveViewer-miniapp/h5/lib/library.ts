import {
  normalizeAnimationFormat,
  type AnimationFormat,
} from "./animation-format.ts";
import { hostedShareName } from "./hosted-share-name.ts";

export type LibraryFile = {
  id: string;
  name: string;
  size: number;
  format: AnimationFormat;
  updatedAt: number;
  hostedCode?: string;
  cover?: Blob;
};

type StoredRiveFile = LibraryFile & {
  data: ArrayBuffer;
};

const DB_NAME = import.meta.env?.BASE_URL === "/beta/"
  ? "rive-viewer-h5-beta"
  : "rive-viewer-h5";
type StoredCover = {
  id: string;
  blob: Blob;
};

type StoredRecentHostedFile = {
  id: string;
  hostedCode: string;
  name: string;
  size: number;
  format?: AnimationFormat;
  updatedAt: number;
};

const DB_VERSION = 3;
const STORE_NAME = "files";
const COVER_STORE_NAME = "covers";
const RECENT_HOSTED_STORE_NAME = "recent-hosted";
export const RECENT_HOSTED_LIMIT = 20;

function openDatabase(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);
    request.onupgradeneeded = () => {
      const database = request.result;
      if (!database.objectStoreNames.contains(STORE_NAME)) {
        database.createObjectStore(STORE_NAME, { keyPath: "id" });
      }
      if (!database.objectStoreNames.contains(COVER_STORE_NAME)) {
        database.createObjectStore(COVER_STORE_NAME, { keyPath: "id" });
      }
      if (!database.objectStoreNames.contains(RECENT_HOSTED_STORE_NAME)) {
        database.createObjectStore(RECENT_HOSTED_STORE_NAME, { keyPath: "id" });
      }
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error || new Error("无法打开本地文件库"));
  });
}

function transactionDone(transaction: IDBTransaction): Promise<void> {
  return new Promise((resolve, reject) => {
    transaction.oncomplete = () => resolve();
    transaction.onerror = () => reject(transaction.error || new Error("本地文件操作失败"));
    transaction.onabort = () => reject(transaction.error || new Error("本地文件操作已取消"));
  });
}

function requestResult<T>(request: IDBRequest<T>): Promise<T> {
  return new Promise((resolve, reject) => {
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error || new Error("本地文件操作失败"));
  });
}

export async function listLocalFiles(): Promise<LibraryFile[]> {
  const database = await openDatabase();
  try {
    const transaction = database.transaction(STORE_NAME, "readonly");
    const records = await requestResult(
      transaction.objectStore(STORE_NAME).getAll() as IDBRequest<StoredRiveFile[]>,
    );
    return records
      .map((record) => ({
        id: record.id,
        name: record.name,
        size: record.size,
        format: normalizeAnimationFormat(record.format, record.name),
        updatedAt: record.updatedAt,
      }))
      .sort((left, right) => right.updatedAt - left.updatedAt);
  } finally {
    database.close();
  }
}

export function mergeRecentHostedRecords(
  records: StoredRecentHostedFile[],
  share: { code: string; filename: string; customName?: string | null; size: number; format?: AnimationFormat },
  updatedAt = Date.now(),
  limit = RECENT_HOSTED_LIMIT,
  preserveExistingActivity = false,
): StoredRecentHostedFile[] {
  const code = share.code;
  if (!/^[0-9A-Za-z]{3}$/.test(code) || code.toLowerCase() === "api") {
    return records.slice().sort((left, right) => right.updatedAt - left.updatedAt).slice(0, limit);
  }
  const next: StoredRecentHostedFile = {
    id: `hosted-${code}`,
    hostedCode: code,
    name: hostedShareName(share),
    size: share.size,
    format: normalizeAnimationFormat(share.format, share.filename),
    updatedAt: preserveExistingActivity
      ? records.find((record) => record.hostedCode === code)?.updatedAt || updatedAt
      : updatedAt,
  };
  return [next, ...records.filter((record) => record.hostedCode !== code)]
    .sort((left, right) => right.updatedAt - left.updatedAt)
    .slice(0, limit);
}

function isStoredRecentHostedFile(value: unknown): value is StoredRecentHostedFile {
  if (!value || typeof value !== "object") return false;
  const record = value as Partial<StoredRecentHostedFile>;
  return (
    typeof record.id === "string"
    && typeof record.hostedCode === "string"
    && /^[0-9A-Za-z]{3}$/.test(record.hostedCode)
    && record.hostedCode.toLowerCase() !== "api"
    && record.id === `hosted-${record.hostedCode}`
    && typeof record.name === "string"
    && Number.isSafeInteger(record.size)
    && Number(record.size) >= 4
    && Number.isSafeInteger(record.updatedAt)
    && Number(record.updatedAt) > 0
  );
}

export async function listRecentHostedFiles(): Promise<LibraryFile[]> {
  const database = await openDatabase();
  try {
    const transaction = database.transaction(RECENT_HOSTED_STORE_NAME, "readonly");
    const records = await requestResult(
      transaction.objectStore(RECENT_HOSTED_STORE_NAME).getAll() as IDBRequest<unknown[]>,
    );
    return records
      .filter(isStoredRecentHostedFile)
      .sort((left, right) => right.updatedAt - left.updatedAt)
      .slice(0, RECENT_HOSTED_LIMIT)
      .map((record) => ({
        ...record,
        format: normalizeAnimationFormat(record.format, record.name),
      }));
  } finally {
    database.close();
  }
}

export async function rememberRecentHostedFile(
  share: { code: string; filename: string; customName?: string | null; size: number; format?: AnimationFormat },
  updatedAt = Date.now(),
  preserveExistingActivity = false,
): Promise<LibraryFile | null> {
  const database = await openDatabase();
  try {
    const readTransaction = database.transaction(RECENT_HOSTED_STORE_NAME, "readonly");
    const stored = await requestResult(
      readTransaction.objectStore(RECENT_HOSTED_STORE_NAME).getAll() as IDBRequest<unknown[]>,
    );
    const records = stored.filter(isStoredRecentHostedFile);
    const nextRecords = mergeRecentHostedRecords(
      records,
      share,
      updatedAt,
      RECENT_HOSTED_LIMIT,
      preserveExistingActivity,
    );
    const record = nextRecords.find((item) => item.hostedCode === share.code);
    if (!record) return null;

    const keepIds = new Set(nextRecords.map((item) => item.id));
    const writeTransaction = database.transaction(RECENT_HOSTED_STORE_NAME, "readwrite");
    const store = writeTransaction.objectStore(RECENT_HOSTED_STORE_NAME);
    store.put(record);
    records.forEach((item) => {
      if (!keepIds.has(item.id)) store.delete(item.id);
    });
    await transactionDone(writeTransaction);
    return {
      ...record,
      format: normalizeAnimationFormat(record.format, record.name),
    };
  } finally {
    database.close();
  }
}

export async function attachLibraryCovers(files: LibraryFile[]): Promise<LibraryFile[]> {
  const database = await openDatabase();
  try {
    const transaction = database.transaction(COVER_STORE_NAME, "readonly");
    const covers = await requestResult(
      transaction.objectStore(COVER_STORE_NAME).getAll() as IDBRequest<StoredCover[]>,
    );
    const coverMap = new Map(covers.map((cover) => [cover.id, cover.blob]));
    return files.map((file) => ({ ...file, cover: coverMap.get(file.id) }));
  } finally {
    database.close();
  }
}

export async function saveLibraryCover(id: string, blob: Blob): Promise<void> {
  const database = await openDatabase();
  try {
    const transaction = database.transaction(COVER_STORE_NAME, "readwrite");
    await requestResult(transaction.objectStore(COVER_STORE_NAME).put({ id, blob }));
  } finally {
    database.close();
  }
}

export async function saveLocalFile(file: File): Promise<LibraryFile> {
  const data = await file.arrayBuffer();
  const record: StoredRiveFile = {
    id: `local-${crypto.randomUUID()}`,
    name: file.name,
    size: file.size,
    format: normalizeAnimationFormat(undefined, file.name),
    updatedAt: Date.now(),
    data,
  };
  const database = await openDatabase();
  try {
    const transaction = database.transaction(STORE_NAME, "readwrite");
    await requestResult(transaction.objectStore(STORE_NAME).put(record));
    return {
      id: record.id,
      name: record.name,
      size: record.size,
      format: record.format,
      updatedAt: record.updatedAt,
    };
  } finally {
    database.close();
  }
}

export async function readLibraryFile(file: LibraryFile): Promise<ArrayBuffer> {
  if (file.hostedCode) throw new Error("公开文件需要从分享链接打开");
  const database = await openDatabase();
  try {
    const transaction = database.transaction(STORE_NAME, "readonly");
    const record = await requestResult(
      transaction.objectStore(STORE_NAME).get(file.id) as IDBRequest<StoredRiveFile | undefined>,
    );
    if (!record?.data) throw new Error("本地文件不存在，可能已被浏览器清理");
    return record.data;
  } finally {
    database.close();
  }
}

export async function touchLocalFile(id: string, updatedAt = Date.now()): Promise<void> {
  const database = await openDatabase();
  try {
    const transaction = database.transaction(STORE_NAME, "readwrite");
    const store = transaction.objectStore(STORE_NAME);
    const record = await requestResult(
      store.get(id) as IDBRequest<StoredRiveFile | undefined>,
    );
    if (!record) return;
    await requestResult(store.put({ ...record, updatedAt }));
  } finally {
    database.close();
  }
}

export async function deleteLocalFile(id: string): Promise<void> {
  const database = await openDatabase();
  try {
    const transaction = database.transaction([STORE_NAME, COVER_STORE_NAME], "readwrite");
    await requestResult(transaction.objectStore(STORE_NAME).delete(id));
    await requestResult(transaction.objectStore(COVER_STORE_NAME).delete(id));
  } finally {
    database.close();
  }
}

export function formatBytes(size: number): string {
  if (size < 1024) return `${size} B`;
  if (size < 1024 * 1024) return `${Math.round(size / 1024)} KB`;
  return `${(size / 1024 / 1024).toFixed(size < 10 * 1024 * 1024 ? 1 : 0)} MB`;
}

export function formatDate(timestamp: number): string {
  return new Intl.DateTimeFormat("zh-CN", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(timestamp);
}
