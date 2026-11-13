import { randomInt, randomUUID } from "node:crypto";
import * as fs from "node:fs/promises";
import path from "node:path";
import { assertDataDirOutsideRelease, MIN_FREE_BYTES, SERVER_ROOT } from "./config.mjs";
import { AppError } from "./errors.mjs";
import { isForestAvatar, pickForestIdentity } from "./forest-identities.mjs";

const STATE_VERSION = 1;
const BASE62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
const CODE_PATTERN = /^[0-9A-Za-z]{3}$/;
const STORAGE_NAME_PATTERN = /^[0-9a-f-]{36}\.riv$/;
const VERSION_ID_PATTERN = /^[0-9a-f-]{36}$/;
const MAX_SHARES = 10_000;
const MAX_VERSIONS_PER_SHARE = 100;
const MAX_COMMENTS_PER_SHARE = 500;
const MAX_TOTAL_COMMENTS = 5_000;
const RESERVED_CODES = new Set(["api"]);
const MAX_CUSTOM_AVATAR_DATA_URL_LENGTH = 16_407;
const WEBP_DATA_URL_PATTERN = /^data:image\/webp;base64,[0-9A-Za-z+/]+={0,2}$/;

function emptyState() {
  return { version: STATE_VERSION, shares: [] };
}

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function normalizeLegacyState(state) {
  let changed = false;
  if (!state || !Array.isArray(state.shares)) return { state, changed };

  for (const share of state.shares) {
    if (!Object.hasOwn(share, "customName")) {
      share.customName = null;
      changed = true;
    }
    if (!Object.hasOwn(share, "format")) {
      share.format = "rive";
      changed = true;
    }
    if (!Object.hasOwn(share, "versions")) {
      const versionId = String(share.storageName || "").replace(/\.riv$/i, "");
      share.versions = [{
        id: versionId,
        name: "版本 1",
        storageName: share.storageName,
        filename: share.filename,
        format: share.format,
        size: share.size,
        sha256: share.sha256,
        etag: share.etag,
        createdAt: share.createdAt,
      }];
      share.currentVersionId = versionId;
      changed = true;
    } else if (!Object.hasOwn(share, "currentVersionId") && share.versions.length) {
      share.currentVersionId = share.versions.at(-1).id;
      changed = true;
    }
    for (const version of share.versions) {
      if (!Object.hasOwn(version, "format")) {
        version.format = share.format;
        changed = true;
      }
    }
    if (!Array.isArray(share?.comments)) continue;
    for (const comment of share.comments) {
      if (!comment || typeof comment !== "object" || Array.isArray(comment)) continue;
      if (!Object.hasOwn(comment, "status")) {
        comment.status = "active";
        changed = true;
      }
      if (!Object.hasOwn(comment, "archivedAt")) {
        comment.archivedAt = null;
        changed = true;
      }
      if (!Object.hasOwn(comment, "avatar")) {
        const identity = pickForestIdentity(`legacy:${comment.nickname || comment.id || "comment"}`);
        comment.avatar = identity.avatar;
        if (!comment.nickname || comment.nickname === "匿名") comment.nickname = identity.nickname;
        changed = true;
      }
      if (!Object.hasOwn(comment, "versionId")) {
        comment.versionId = share.currentVersionId;
        changed = true;
      }
    }
  }
  return { state, changed };
}

function publicVersion(version) {
  return {
    id: version.id,
    name: version.name,
    filename: version.filename,
    format: version.format,
    size: version.size,
    sha256: version.sha256,
    etag: version.etag,
    createdAt: version.createdAt,
  };
}

function publicMetadata(share, { includeVersions = false } = {}) {
  const metadata = {
    code: share.code,
    filename: share.filename,
    customName: share.customName,
    format: share.format,
    size: share.size,
    sha256: share.sha256,
    etag: share.etag,
    isExample: share.isExample,
    status: share.status,
    createdAt: share.createdAt,
    archivedAt: share.archivedAt,
    commentCount: share.comments.length,
    versionCount: share.versions.length,
    currentVersionId: share.currentVersionId,
  };
  if (includeVersions) metadata.versions = share.versions.map(publicVersion);
  return metadata;
}

function validateState(state) {
  if (!state || state.version !== STATE_VERSION || !Array.isArray(state.shares)) {
    throw new Error("state.json 结构或版本无效");
  }
  if (state.shares.length > MAX_SHARES) {
    throw new Error("state.json 的分享数量超过上限");
  }
  const codes = new Set();
  const storageNames = new Set();
  let totalComments = 0;
  for (const share of state.shares) {
    if (!CODE_PATTERN.test(share?.code || "") || codes.has(share.code)) {
      throw new Error("state.json 包含无效或重复的分享码");
    }
    codes.add(share.code);
    if (
      typeof share.filename !== "string"
      || (share.customName !== null && (
        typeof share.customName !== "string"
        || !share.customName.trim()
        || [...share.customName].length > 120
        || /[\u0000-\u001f\u007f]/.test(share.customName)
      ))
      || !["rive", "lottie", "pag"].includes(share.format)
      || !Number.isSafeInteger(share.size)
      || share.size < 4
      || !/^[0-9a-f]{64}$/.test(share.sha256 || "")
      || !STORAGE_NAME_PATTERN.test(share.storageName || "")
      || share.etag !== `"sha256-${share.sha256}"`
      || typeof share.isExample !== "boolean"
      || !["active", "archived"].includes(share.status)
      || typeof share.createdAt !== "string"
      || (share.archivedAt !== null && typeof share.archivedAt !== "string")
      || !Array.isArray(share.versions)
      || share.versions.length < 1
      || share.versions.length > MAX_VERSIONS_PER_SHARE
      || !VERSION_ID_PATTERN.test(share.currentVersionId || "")
      || !Array.isArray(share.comments)
    ) {
      throw new Error(`state.json 中分享 ${share.code} 的字段无效`);
    }
    const versionIds = new Set();
    for (const version of share.versions) {
      if (
        !VERSION_ID_PATTERN.test(version?.id || "")
        || versionIds.has(version.id)
        || typeof version.name !== "string"
        || [...version.name].length < 1
        || [...version.name].length > 40
        || typeof version.filename !== "string"
        || version.format !== share.format
        || !Number.isSafeInteger(version.size)
        || version.size < 4
        || !/^[0-9a-f]{64}$/.test(version.sha256 || "")
        || !STORAGE_NAME_PATTERN.test(version.storageName || "")
        || storageNames.has(version.storageName)
        || version.etag !== `"sha256-${version.sha256}"`
        || typeof version.createdAt !== "string"
      ) {
        throw new Error(`state.json 中分享 ${share.code} 的版本无效`);
      }
      versionIds.add(version.id);
      storageNames.add(version.storageName);
    }
    const currentVersion = share.versions.find((version) => version.id === share.currentVersionId);
    if (
      !currentVersion
      || share.storageName !== currentVersion.storageName
      || share.filename !== currentVersion.filename
      || share.size !== currentVersion.size
      || share.sha256 !== currentVersion.sha256
      || share.etag !== currentVersion.etag
    ) {
      throw new Error(`state.json 中分享 ${share.code} 的当前版本无效`);
    }
    if (share.comments.length > MAX_COMMENTS_PER_SHARE) {
      throw new Error(`state.json 中分享 ${share.code} 的评论数量超过上限`);
    }
    totalComments += share.comments.length;
    for (const comment of share.comments) {
      if (
        typeof comment?.id !== "string"
        || typeof comment.nickname !== "string"
        || [...comment.nickname].length < 1
        || [...comment.nickname].length > 12
        || !isForestAvatar(comment.avatar)
        || (comment.avatarDataUrl !== undefined && (
          typeof comment.avatarDataUrl !== "string"
          || comment.avatarDataUrl.length > MAX_CUSTOM_AVATAR_DATA_URL_LENGTH
          || !WEBP_DATA_URL_PATTERN.test(comment.avatarDataUrl)
        ))
        || typeof comment.body !== "string"
        || typeof comment.createdAt !== "string"
        || !versionIds.has(comment.versionId)
        || !["active", "archived"].includes(comment.status)
        || (comment.archivedAt !== null && typeof comment.archivedAt !== "string")
      ) {
        throw new Error(`state.json 中分享 ${share.code} 的评论无效`);
      }
    }
  }
  if (totalComments > MAX_TOTAL_COMMENTS) {
    throw new Error("state.json 的评论总量超过上限");
  }
  return state;
}

async function syncDirectory(directory) {
  let handle;
  try {
    handle = await fs.open(directory, "r");
    await handle.sync();
  } catch (error) {
    if (!["EINVAL", "ENOTSUP", "EBADF"].includes(error?.code)) throw error;
  } finally {
    await handle?.close().catch(() => {});
  }
}

async function writeJsonAtomic(filePath, state) {
  const directory = path.dirname(filePath);
  const tempPath = path.join(
    directory,
    `.state-${process.pid}-${Date.now()}-${randomUUID()}.tmp`,
  );
  const payload = `${JSON.stringify(state, null, 2)}\n`;
  let handle;
  try {
    handle = await fs.open(tempPath, "wx", 0o600);
    await handle.writeFile(payload, "utf8");
    await handle.sync();
    await handle.close();
    handle = undefined;
    await fs.rename(tempPath, filePath);
    await syncDirectory(directory);
  } catch (error) {
    await handle?.close().catch(() => {});
    await fs.unlink(tempPath).catch(() => {});
    throw error;
  }
}

function generateBase62Code() {
  return Array.from({ length: 3 }, () => BASE62[randomInt(BASE62.length)]).join("");
}

export class ShareStore {
  constructor({
    dataDir,
    maxTotalBytes,
    codeGenerator = generateBase62Code,
    now = () => new Date().toISOString(),
    diskFreeProvider,
    logger = console,
  }) {
    this.dataDir = dataDir;
    this.filesDir = path.join(dataDir, "files");
    this.tempDir = path.join(dataDir, "tmp");
    this.statePath = path.join(dataDir, "state.json");
    this.maxTotalBytes = maxTotalBytes;
    this.codeGenerator = codeGenerator;
    this.now = now;
    this.logger = logger;
    this.diskFreeProvider = diskFreeProvider || (() => this.#readDiskFreeBytes());
    this.state = emptyState();
    this.mutationTail = Promise.resolve();
    this.warnedStatfsUnavailable = false;
  }

  static async open(options) {
    const store = new ShareStore(options);
    await store.#initialize();
    return store;
  }

  async #initialize() {
    await fs.mkdir(this.dataDir, { recursive: true, mode: 0o700 });
    const [realDataDir, realServerRoot] = await Promise.all([
      fs.realpath(this.dataDir),
      fs.realpath(SERVER_ROOT),
    ]);
    assertDataDirOutsideRelease(realDataDir, realServerRoot);
    await Promise.all([
      fs.mkdir(this.filesDir, { recursive: true, mode: 0o700 }),
      fs.mkdir(this.tempDir, { recursive: true, mode: 0o700 }),
    ]);
    await this.#removeStaleTemps();

    let stateNeedsRewrite = false;
    try {
      const normalized = normalizeLegacyState(
        JSON.parse(await fs.readFile(this.statePath, "utf8")),
      );
      this.state = validateState(normalized.state);
      stateNeedsRewrite = normalized.changed;
    } catch (error) {
      if (error?.code !== "ENOENT") throw error;
      this.state = emptyState();
      await writeJsonAtomic(this.statePath, this.state);
    }
    await this.#validateStoredFiles();
    if (stateNeedsRewrite) await writeJsonAtomic(this.statePath, this.state);
  }

  async #validateStoredFiles() {
    for (const share of this.state.shares) {
      for (const version of share.versions) {
        const filePath = path.join(this.filesDir, version.storageName);
        let stats;
        try {
          stats = await fs.stat(filePath);
        } catch (error) {
          throw new Error(`分享 ${share.code} 的版本 ${version.name} 文件缺失`, { cause: error });
        }
        if (!stats.isFile() || stats.size !== version.size) {
          throw new Error(`分享 ${share.code} 的版本 ${version.name} 大小与索引不一致`);
        }
      }
    }
  }

  async #removeStaleTemps() {
    const entries = await fs.readdir(this.tempDir, { withFileTypes: true });
    await Promise.all(entries
      .filter((entry) => entry.isFile() && /^upload-.*\.tmp$/.test(entry.name))
      .map((entry) => fs.unlink(path.join(this.tempDir, entry.name)).catch(() => {})));
  }

  async #readDiskFreeBytes() {
    if (typeof fs.statfs !== "function") {
      if (!this.warnedStatfsUnavailable) {
        this.warnedStatfsUnavailable = true;
        this.logger.warn?.("当前 Node 运行时不支持 statfs；继续强制托管总量上限，跳过磁盘余量检查");
      }
      return null;
    }
    const stats = await fs.statfs(this.dataDir);
    return stats.bavail * stats.bsize;
  }

  #totalBytes(state = this.state) {
    return state.shares.reduce((total, share) => (
      total + share.versions.reduce((versionTotal, version) => versionTotal + version.size, 0)
    ), 0);
  }

  async assertUploadAllowed(incomingBytes = 0, state = this.state) {
    if (this.#totalBytes(state) + incomingBytes > this.maxTotalBytes) {
      throw new AppError(507, "storage_limit", "托管文件总量已达到上限");
    }
    const freeBytes = await this.diskFreeProvider();
    if (freeBytes !== null && freeBytes < MIN_FREE_BYTES) {
      throw new AppError(507, "disk_space_low", "服务器磁盘可用空间不足");
    }
  }

  list(status, formats = ["rive"]) {
    return this.state.shares
      .filter((share) => share.status === status && !share.isExample && formats.includes(share.format))
      .slice()
      .sort((left, right) => right.createdAt.localeCompare(left.createdAt))
      .map(publicMetadata);
  }

  get(code) {
    const share = this.state.shares.find((item) => item.code === code);
    return share ? publicMetadata(share, { includeVersions: true }) : null;
  }

  getFile(code, versionId = null) {
    const share = this.state.shares.find((item) => item.code === code);
    if (!share) return null;
    const version = share.versions.find((item) => item.id === (versionId || share.currentVersionId));
    if (!version) return null;
    return {
      metadata: { ...publicMetadata(share), ...publicVersion(version) },
      filePath: path.join(this.filesDir, version.storageName),
    };
  }

  comments(code) {
    const share = this.state.shares.find((item) => item.code === code);
    return share ? clone(share.comments) : null;
  }

  findExampleBySha256(sha256) {
    const share = this.state.shares.find((item) => item.isExample && item.sha256 === sha256);
    return share ? publicMetadata(share) : null;
  }

  async createFromStaged({ tempPath, filename, format = "rive", size, sha256, isExample }) {
    return this.#enqueue(async () => {
      if (this.state.shares.length >= MAX_SHARES) {
        throw new AppError(507, "share_limit", "托管文件数量已达到上限");
      }
      await this.assertUploadAllowed(size, this.state);
      let code;
      for (let attempt = 0; attempt < 10_000; attempt += 1) {
        const candidate = this.codeGenerator();
        if (!CODE_PATTERN.test(candidate)) {
          throw new Error("codeGenerator 必须返回三位 Base62 分享码");
        }
        const codeTaken = RESERVED_CODES.has(candidate.toLowerCase())
          || this.state.shares.some((share) => share.code === candidate);
        if (!codeTaken) {
          code = candidate;
          break;
        }
      }
      if (!code) {
        throw new AppError(503, "code_unavailable", "暂时无法生成分享码，请重试");
      }

      const createdAt = this.now();
      const storageName = `${randomUUID()}.riv`;
      const versionId = storageName.slice(0, -4);
      const version = {
        id: versionId,
        name: "版本 1",
        storageName,
        filename,
        format,
        size,
        sha256,
        etag: `"sha256-${sha256}"`,
        createdAt,
      };
      const record = {
        code,
        storageName,
        filename,
        customName: null,
        format,
        size,
        sha256,
        etag: `"sha256-${sha256}"`,
        isExample,
        status: "active",
        createdAt,
        archivedAt: null,
        versions: [version],
        currentVersionId: versionId,
        comments: [],
      };
      const destination = path.join(this.filesDir, storageName);
      await fs.rename(tempPath, destination);
      try {
        await syncDirectory(this.filesDir);
        const nextState = clone(this.state);
        nextState.shares.push(record);
        await writeJsonAtomic(this.statePath, nextState);
        this.state = nextState;
        return publicMetadata(record);
      } catch (error) {
        await fs.unlink(destination).catch(() => {});
        await syncDirectory(this.filesDir).catch(() => {});
        throw error;
      }
    });
  }

  async addVersionFromStaged(code, { tempPath, filename, format = "rive", size, sha256 }) {
    return this.#enqueue(async () => {
      const currentShare = this.state.shares.find((item) => item.code === code);
      if (!currentShare) throw new AppError(404, "share_not_found", "分享不存在");
      if (currentShare.status === "archived") {
        throw new AppError(409, "share_archived", "归档分享不能更新版本");
      }
      if (currentShare.format !== format) {
        throw new AppError(422, "format_mismatch", "新版本必须与当前文件格式一致");
      }
      if (currentShare.versions.length >= MAX_VERSIONS_PER_SHARE) {
        throw new AppError(429, "version_limit", "这个文件的版本数已达上限");
      }
      await this.assertUploadAllowed(size, this.state);

      const createdAt = this.now();
      const versionId = randomUUID();
      const storageName = `${versionId}.riv`;
      const version = {
        id: versionId,
        name: `版本 ${currentShare.versions.length + 1}`,
        storageName,
        filename,
        format,
        size,
        sha256,
        etag: `"sha256-${sha256}"`,
        createdAt,
      };
      const destination = path.join(this.filesDir, storageName);
      await fs.rename(tempPath, destination);
      try {
        await syncDirectory(this.filesDir);
        const nextState = clone(this.state);
        const share = nextState.shares.find((item) => item.code === code);
        share.versions.push(version);
        share.currentVersionId = versionId;
        share.storageName = storageName;
        share.filename = filename;
        share.size = size;
        share.sha256 = sha256;
        share.etag = version.etag;
        await writeJsonAtomic(this.statePath, nextState);
        this.state = nextState;
        return publicMetadata(share, { includeVersions: true });
      } catch (error) {
        await fs.unlink(destination).catch(() => {});
        await syncDirectory(this.filesDir).catch(() => {});
        throw error;
      }
    });
  }

  async rename(code, name) {
    if (typeof name !== "string" || !name.trim() || [...name.trim()].length > 120
      || /[\u0000-\u001f\u007f]/.test(name)) {
      throw new AppError(422, "invalid_name", "名称需为 1–120 个字符，且不能包含换行或控制字符");
    }
    return this.#mutate((state) => {
      const share = state.shares.find((item) => item.code === code);
      if (!share) throw new AppError(404, "share_not_found", "分享不存在");
      if (share.status === "archived") {
        throw new AppError(409, "share_archived", "归档文件需恢复后才能重命名");
      }
      share.customName = name.trim();
      return publicMetadata(share, { includeVersions: true });
    });
  }

  async addComment(code, { nickname, avatar, avatarDataUrl, body, versionId }) {
    return this.#mutate((state) => {
      const share = state.shares.find((item) => item.code === code);
      if (!share) throw new AppError(404, "share_not_found", "分享不存在");
      if (share.status === "archived") {
        throw new AppError(409, "share_archived", "归档分享不能新增评论");
      }
      const targetVersionId = versionId || share.currentVersionId;
      if (!share.versions.some((version) => version.id === targetVersionId)) {
        throw new AppError(422, "invalid_version", "评论对应的文件版本不存在");
      }
      if (share.comments.length >= MAX_COMMENTS_PER_SHARE) {
        throw new AppError(429, "comment_limit", "这个文件的评论数量已达到上限");
      }
      const totalComments = state.shares.reduce((total, item) => total + item.comments.length, 0);
      if (totalComments >= MAX_TOTAL_COMMENTS) {
        throw new AppError(507, "comment_storage_limit", "评论总量已达到上限");
      }
      const comment = {
        id: randomUUID(),
        nickname,
        avatar,
        ...(avatarDataUrl ? { avatarDataUrl } : {}),
        body,
        versionId: targetVersionId,
        createdAt: this.now(),
        status: "active",
        archivedAt: null,
      };
      share.comments.push(comment);
      return clone(comment);
    });
  }

  async archiveComment(code, commentId) {
    return this.#mutate((state) => {
      const share = state.shares.find((item) => item.code === code);
      if (!share) throw new AppError(404, "share_not_found", "分享不存在");
      const comment = share.comments.find((item) => item.id === commentId);
      if (!comment) throw new AppError(404, "comment_not_found", "评论不存在");
      if (comment.status !== "archived") {
        comment.status = "archived";
        comment.archivedAt = this.now();
      }
      return clone(comment);
    });
  }

  async restoreComment(code, commentId) {
    return this.#mutate((state) => {
      const share = state.shares.find((item) => item.code === code);
      if (!share) throw new AppError(404, "share_not_found", "分享不存在");
      const comment = share.comments.find((item) => item.id === commentId);
      if (!comment) throw new AppError(404, "comment_not_found", "评论不存在");
      comment.status = "active";
      comment.archivedAt = null;
      return clone(comment);
    });
  }

  async archive(code) {
    return this.#mutate((state) => {
      const share = state.shares.find((item) => item.code === code);
      if (!share) throw new AppError(404, "share_not_found", "分享不存在");
      if (share.status !== "archived") {
        share.status = "archived";
        share.archivedAt = this.now();
      }
      return publicMetadata(share);
    });
  }

  async restore(code) {
    return this.#mutate((state) => {
      const share = state.shares.find((item) => item.code === code);
      if (!share) throw new AppError(404, "share_not_found", "分享不存在");
      share.status = "active";
      share.archivedAt = null;
      return publicMetadata(share);
    });
  }

  async #mutate(mutator) {
    return this.#enqueue(async () => {
      const nextState = clone(this.state);
      const result = mutator(nextState);
      await writeJsonAtomic(this.statePath, nextState);
      this.state = nextState;
      return result;
    });
  }

  #enqueue(operation) {
    const result = this.mutationTail.then(operation, operation);
    this.mutationTail = result.catch(() => {});
    return result;
  }
}
