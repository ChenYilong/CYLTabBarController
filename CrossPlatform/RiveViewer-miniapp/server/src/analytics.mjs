import { createHmac, randomBytes } from "node:crypto";
import { mkdir, readdir, readFile, rm, appendFile } from "node:fs/promises";
import path from "node:path";
import { AppError } from "./errors.mjs";

const ANALYTICS_VERSION = 1;
const MAX_BATCH_EVENTS = 20;
const RETENTION_DAYS = 90;
const MAX_SUMMARY_EVENTS = 200_000;
const DAY_MS = 86_400_000;

const EVENT_NAMES = new Set([
  "page_view",
  "page_dwell",
  "file_import",
  "preview_result",
  "upload_result",
  "playback",
  "control_use",
  "share_action",
  "comment_result",
  "version_upload_result",
  "performance_sample",
]);
const SURFACES = new Set(["generic", "jojo", "beta"]);
const PAGES = new Set(["home", "preview"]);
const FORMATS = new Set(["rive", "lottie", "pag"]);
const SIZE_BUCKETS = new Set(["under_1m", "1m_5m", "5m_10m", "10m_30m", "30m_64m"]);
const OUTCOMES = new Set(["success", "failure"]);
const SOURCE_TYPES = new Set(["direct", "internal", "search", "social", "referral", "campaign"]);
const RENDERERS = new Set(["webgl2", "canvas2d", "canvas", "webassembly"]);
const CONTROL_NAMES = new Set([
  "play",
  "pause",
  "reset",
  "speed",
  "fit",
  "quality",
  "renderer",
  "artboard",
  "state_machine",
  "animation",
  "input",
  "canvas",
  "background",
  "audio",
  "file_navigation",
  "timeline_grouping",
]);
const SHARE_ACTIONS = new Set(["copy_link", "download", "send_file"]);
const ERROR_CATEGORIES = new Set([
  "network",
  "timeout",
  "invalid_file",
  "too_large",
  "unsupported",
  "renderer",
  "storage",
  "archived",
  "rate_limited",
  "server",
  "unknown",
]);

const LABELS = {
  surfaces: { generic: "H5 通用版", jojo: "叫叫正式版", beta: "叫叫测试版" },
  formats: { rive: "Rive", lottie: "Lottie", pag: "PAG" },
  devices: { desktop: "桌面", mobile: "手机", tablet: "平板", unknown: "未知" },
  sourceTypes: {
    direct: "直接访问",
    internal: "站内跳转",
    search: "搜索引擎",
    social: "社交平台",
    referral: "外部链接",
    campaign: "活动参数",
  },
  controls: {
    play: "播放",
    pause: "暂停",
    reset: "重播",
    speed: "倍速",
    fit: "完整/铺满",
    quality: "渲染质量",
    renderer: "渲染引擎",
    artboard: "画板",
    state_machine: "状态机",
    animation: "时间轴",
    input: "状态机输入",
    canvas: "画布交互",
    background: "预览背景",
    audio: "声音",
    file_navigation: "切换文件",
    timeline_grouping: "时间轴整理",
  },
  errors: {
    network: "网络异常",
    timeout: "请求超时",
    invalid_file: "文件无效或损坏",
    too_large: "文件超过限制",
    unsupported: "格式不支持",
    renderer: "渲染失败",
    storage: "本地存储失败",
    archived: "文件已归档",
    rate_limited: "操作过于频繁",
    server: "服务端异常",
    unknown: "其他失败",
  },
  sizeBuckets: {
    under_1m: "小于 1 MiB",
    "1m_5m": "1-5 MiB",
    "5m_10m": "5-10 MiB",
    "10m_30m": "10-30 MiB",
    "30m_64m": "30-64 MiB",
  },
};

function safeString(value, limit = 64) {
  if (typeof value !== "string") return "";
  return value.normalize("NFC").trim().slice(0, limit);
}

function enumValue(value, allowed) {
  return allowed.has(value) ? value : undefined;
}

function boundedNumber(value, minimum, maximum) {
  return Number.isFinite(value) ? Math.min(maximum, Math.max(minimum, Number(value))) : undefined;
}

function isoDate(value, fallback) {
  const parsed = Date.parse(value);
  const reference = Date.parse(fallback);
  if (!Number.isFinite(parsed) || Math.abs(parsed - reference) > DAY_MS) return fallback;
  return new Date(parsed).toISOString();
}

function analyticsDay(iso) {
  return iso.slice(0, 10);
}

function hashIdentifier(salt, kind, value) {
  return createHmac("sha256", salt).update(`${kind}:${value}`).digest("hex").slice(0, 24);
}

function parseClient(userAgent = "") {
  const value = safeString(userAgent, 512);
  const device = /iPad|Tablet/i.test(value)
    ? "tablet"
    : /Mobile|Android|iPhone|Windows Phone/i.test(value)
      ? "mobile"
      : value
        ? "desktop"
        : "unknown";
  const browser = /MicroMessenger/i.test(value)
    ? "微信"
    : /Edg\//i.test(value)
      ? "Edge"
      : /Chrome\//i.test(value) && !/Edg\//i.test(value)
        ? "Chrome"
        : /Safari\//i.test(value) && !/Chrome\//i.test(value)
          ? "Safari"
          : /Firefox\//i.test(value)
            ? "Firefox"
            : "其他";
  const os = /iPhone|iPad|iOS/i.test(value)
    ? "iOS"
    : /Android/i.test(value)
      ? "Android"
      : /Mac OS X|Macintosh/i.test(value)
        ? "macOS"
        : /Windows/i.test(value)
          ? "Windows"
          : /Linux/i.test(value)
            ? "Linux"
            : "其他";
  return { device, browser, os };
}

function normalizeEvent(raw, context) {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    throw new AppError(422, "invalid_analytics_event", "统计事件格式无效");
  }
  const name = enumValue(raw.name, EVENT_NAMES);
  const page = enumValue(raw.page, PAGES);
  const eventId = safeString(raw.id, 80);
  if (!name || !page || !/^[0-9A-Za-z-]{16,80}$/.test(eventId)) {
    throw new AppError(422, "invalid_analytics_event", "统计事件字段无效");
  }
  const properties = raw.properties && typeof raw.properties === "object" && !Array.isArray(raw.properties)
    ? raw.properties
    : {};
  const at = isoDate(raw.at, context.receivedAt);
  const event = {
    version: ANALYTICS_VERSION,
    eventHash: hashIdentifier(context.salt, "event", eventId),
    at,
    receivedAt: context.receivedAt,
    surface: context.surface,
    visitorHash: context.visitorHash,
    sessionHash: context.sessionHash,
    page,
    name,
    device: context.client.device,
    browser: context.client.browser,
    os: context.client.os,
  };

  const format = enumValue(raw.format, FORMATS);
  const fileSizeBucket = enumValue(raw.fileSizeBucket, SIZE_BUCKETS);
  const outcome = enumValue(properties.outcome, OUTCOMES);
  const renderer = enumValue(properties.renderer, RENDERERS);
  const control = enumValue(properties.control, CONTROL_NAMES);
  const action = enumValue(properties.action, SHARE_ACTIONS);
  const errorCategory = enumValue(properties.errorCategory, ERROR_CATEGORIES);
  const sourceType = enumValue(properties.sourceType, SOURCE_TYPES);
  const durationMs = boundedNumber(properties.durationMs, 0, 600_000);
  const visibleMs = boundedNumber(properties.visibleMs, 0, 86_400_000);
  const fps = boundedNumber(properties.fps, 0, 240);
  const count = boundedNumber(properties.count, 1, 100);
  const speed = boundedNumber(properties.speed, 0.1, 16);
  const quality = boundedNumber(properties.quality, 0, 2);
  const sourceHost = safeString(properties.sourceHost, 120).toLowerCase();
  const utmSource = safeString(properties.utmSource, 64);
  const utmCampaign = safeString(properties.utmCampaign, 64);
  const fileCode = safeString(properties.fileCode, 8);

  if (format) event.format = format;
  if (fileSizeBucket) event.fileSizeBucket = fileSizeBucket;
  if (outcome) event.outcome = outcome;
  if (renderer) event.renderer = renderer;
  if (control) event.control = control;
  if (action) event.action = action;
  if (errorCategory) event.errorCategory = errorCategory;
  if (sourceType) event.sourceType = sourceType;
  if (durationMs !== undefined) event.durationMs = Math.round(durationMs);
  if (visibleMs !== undefined) event.visibleMs = Math.round(visibleMs);
  if (fps !== undefined) event.fps = Math.round(fps * 10) / 10;
  if (count !== undefined) event.count = Math.round(count);
  if (speed !== undefined) event.speed = speed;
  if (quality !== undefined) event.quality = Math.round(quality);
  if (sourceHost && /^(?:[a-z0-9-]+\.)*[a-z0-9-]+$/i.test(sourceHost)) event.sourceHost = sourceHost;
  if (utmSource) event.utmSource = utmSource;
  if (utmCampaign) event.utmCampaign = utmCampaign;
  if (
    name === "preview_result"
    && outcome === "failure"
    && context.surface !== "generic"
    && /^[0-9A-Za-z]{3}$/.test(fileCode)
  ) {
    event.fileCode = fileCode;
  }
  if (properties.fit === "contain" || properties.fit === "cover") event.fit = properties.fit;
  if (properties.trigger === "automatic" || properties.trigger === "manual") event.trigger = properties.trigger;
  return event;
}

function percentile(values, quantile) {
  if (!values.length) return 0;
  const sorted = [...values].sort((left, right) => left - right);
  return Math.round(sorted[Math.min(sorted.length - 1, Math.ceil(sorted.length * quantile) - 1)]);
}

function ratio(numerator, denominator) {
  return denominator > 0 ? Math.round((numerator / denominator) * 10_000) / 10_000 : 0;
}

function labelFor(group, key) {
  return LABELS[group]?.[key] || key || "未知";
}

function groupRows(events, keyName, labelGroup, predicate = () => true) {
  const groups = new Map();
  for (const event of events) {
    if (!predicate(event)) continue;
    const key = event[keyName];
    if (!key) continue;
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(event);
  }
  return [...groups.entries()].map(([key, rows]) => {
    const sessions = new Set(rows.map((event) => event.sessionHash)).size;
    const attempts = rows.filter((event) => event.name === "preview_result");
    const successes = attempts.filter((event) => event.outcome === "success");
    const performance = rows.filter((event) => event.name === "performance_sample" && Number.isFinite(event.fps));
    return {
      key,
      label: labelFor(labelGroup, key),
      sessions,
      events: rows.length,
      previews: successes.length,
      successRate: ratio(successes.length, attempts.length),
      p95LoadMs: percentile(successes.map((event) => event.durationMs).filter(Number.isFinite), 0.95),
      lowFpsRate: ratio(performance.filter((event) => event.fps < 24).length, performance.length),
    };
  }).sort((left, right) => right.sessions - left.sessions || right.events - left.events);
}

function simpleCountRows(events, keyName, labelGroup, predicate = () => true) {
  const groups = new Map();
  for (const event of events) {
    if (!predicate(event)) continue;
    const key = event[keyName];
    if (!key) continue;
    const current = groups.get(key) || { events: 0, sessions: new Set() };
    current.events += 1;
    current.sessions.add(event.sessionHash);
    groups.set(key, current);
  }
  return [...groups.entries()].map(([key, value]) => ({
    key,
    label: labelFor(labelGroup, key),
    events: value.events,
    sessions: value.sessions.size,
  })).sort((left, right) => right.events - left.events);
}

function selectAnalyticsEvents(events, { days, surface, format, end }) {
  const start = new Date(end.getTime() - (days - 1) * DAY_MS);
  start.setUTCHours(0, 0, 0, 0);
  const timeAndSurface = events.filter((event) => (
    Date.parse(event.at) >= start.getTime()
    && Date.parse(event.at) <= end.getTime()
    && (surface === "all" || event.surface === surface)
  ));
  const formatSessions = format === "all"
    ? null
    : new Set(timeAndSurface.filter((event) => event.format === format).map((event) => event.sessionHash));
  const selected = formatSessions
    ? timeAndSurface.filter((event) => event.format === format || (!event.format && formatSessions.has(event.sessionHash)))
    : timeAndSurface;
  return { selected, start };
}

function audiencePeriod(events, { days, surface, format, end }) {
  const { selected } = selectAnalyticsEvents(events, { days, surface, format, end });
  const pageViews = selected.filter((event) => event.name === "page_view");
  const rows = pageViews.length ? pageViews : selected;
  return {
    days,
    visitors: new Set(rows.map((event) => event.visitorHash)).size,
    visits: new Set(rows.map((event) => event.sessionHash)).size,
  };
}

function failedFileRows(events) {
  const files = new Map();
  for (const event of events) {
    if (event.name !== "preview_result" || event.outcome !== "failure" || !event.fileCode) continue;
    const key = `${event.surface}:${event.fileCode}`;
    const current = files.get(key) || {
      code: event.fileCode,
      surface: event.surface,
      errorCategory: event.errorCategory || "unknown",
      attempts: 0,
      lastFailedAt: event.at,
    };
    current.attempts += 1;
    if (event.at >= current.lastFailedAt) {
      current.lastFailedAt = event.at;
      current.errorCategory = event.errorCategory || current.errorCategory;
    }
    files.set(key, current);
  }
  return [...files.values()]
    .sort((left, right) => right.lastFailedAt.localeCompare(left.lastFailedAt))
    .slice(0, 20)
    .map((row) => ({ ...row, errorLabel: labelFor("errors", row.errorCategory) }));
}

export function summarizeAnalytics(events, { days, surface = "all", format = "all", now }) {
  const end = new Date(now);
  const { selected, start } = selectAnalyticsEvents(events, { days, surface, format, end });
  const sessionIds = new Set(selected.map((event) => event.sessionHash));
  const visitorIds = new Set(selected.map((event) => event.visitorHash));
  const activatedSessions = new Set(selected
    .filter((event) => event.name === "preview_result" && event.outcome === "success")
    .map((event) => event.sessionHash));
  const engagedSessions = new Set(selected
    .filter((event) => ["playback", "control_use", "share_action", "comment_result"].includes(event.name))
    .map((event) => event.sessionHash));
  const collaborationSessions = new Set(selected
    .filter((event) => event.name === "share_action" || (event.name === "comment_result" && event.outcome === "success"))
    .map((event) => event.sessionHash));
  const activatedEngagedSessions = new Set([...engagedSessions].filter((id) => activatedSessions.has(id)));
  const activatedCollaborationSessions = new Set([...collaborationSessions].filter((id) => activatedSessions.has(id)));
  const previewResults = selected.filter((event) => event.name === "preview_result");
  const previewSuccesses = previewResults.filter((event) => event.outcome === "success");
  const previewFailures = previewResults.filter((event) => event.outcome === "failure");
  const previewAttempts = [...previewSuccesses, ...previewFailures];
  const resultEvents = selected.filter((event) => event.name.endsWith("_result"));
  const failedResults = resultEvents.filter((event) => event.outcome === "failure");
  const performance = selected.filter((event) => event.name === "performance_sample" && Number.isFinite(event.fps));
  const dwellMs = selected
    .filter((event) => event.name === "page_dwell" && Number.isFinite(event.visibleMs))
    .reduce((sum, event) => sum + event.visibleMs, 0);
  const visitorDays = new Map();
  for (const event of selected.filter((item) => item.name === "page_view")) {
    if (!visitorDays.has(event.visitorHash)) visitorDays.set(event.visitorHash, new Set());
    visitorDays.get(event.visitorHash).add(analyticsDay(event.at));
  }
  const returningVisitors = [...visitorDays.values()].filter((value) => value.size > 1).length;
  const loadDurations = previewSuccesses.map((event) => event.durationMs).filter(Number.isFinite);

  const trendMap = new Map();
  for (let offset = 0; offset < days; offset += 1) {
    const date = new Date(start.getTime() + offset * DAY_MS).toISOString().slice(0, 10);
    trendMap.set(date, { date, sessions: new Set(), visitors: new Set(), previews: 0, errors: 0, load: [] });
  }
  for (const event of selected) {
    const row = trendMap.get(analyticsDay(event.at));
    if (!row) continue;
    row.sessions.add(event.sessionHash);
    row.visitors.add(event.visitorHash);
    if (event.name === "preview_result" && event.outcome === "success") row.previews += 1;
    if (event.outcome === "failure") row.errors += 1;
    if (event.name === "preview_result" && event.outcome === "success" && Number.isFinite(event.durationMs)) {
      row.load.push(event.durationMs);
    }
  }

  const pageViewSessions = new Set(selected.filter((event) => event.name === "page_view").map((event) => event.sessionHash));
  const visitCount = pageViewSessions.size || sessionIds.size;
  const latestEventAt = selected.reduce((latest, event) => event.at > latest ? event.at : latest, "");
  return {
    window: {
      days,
      from: start.toISOString(),
      to: end.toISOString(),
      surface,
      format,
    },
    freshness: {
      latestEventAt: latestEventAt || null,
      eventCount: selected.length,
      retentionDays: RETENTION_DAYS,
    },
    kpis: {
      sessions: sessionIds.size,
      visitors: visitorIds.size,
      previews: previewSuccesses.length,
      previewAttempts: previewAttempts.length,
      previewFailures: previewFailures.length,
      activationRate: ratio(activatedSessions.size, visitCount),
      previewSuccessRate: ratio(previewSuccesses.length, previewAttempts.length),
      p50LoadMs: percentile(loadDurations, 0.5),
      p95LoadMs: percentile(loadDurations, 0.95),
      engagementRate: ratio(activatedEngagedSessions.size, activatedSessions.size),
      errorRate: ratio(failedResults.length, resultEvents.length),
      lowFpsRate: ratio(performance.filter((event) => event.fps < 24).length, performance.length),
      returningVisitorRate: ratio(returningVisitors, visitorDays.size),
      averageVisibleSeconds: sessionIds.size ? Math.round(dwellMs / sessionIds.size / 1000) : 0,
    },
    trends: [...trendMap.values()].map((row) => ({
      date: row.date,
      sessions: row.sessions.size,
      visitors: row.visitors.size,
      previews: row.previews,
      errors: row.errors,
      averageLoadMs: row.load.length ? Math.round(row.load.reduce((sum, value) => sum + value, 0) / row.load.length) : 0,
    })),
    audiencePeriods: [7, 30, RETENTION_DAYS].map((periodDays) => audiencePeriod(events, {
      days: periodDays,
      surface,
      format,
      end,
    })),
    failedFiles: failedFileRows(selected),
    funnel: [
      { key: "visit", label: "进入工具", sessions: visitCount, rateFromVisit: ratio(visitCount, visitCount) },
      { key: "preview", label: "成功看到首帧", sessions: activatedSessions.size, rateFromVisit: ratio(activatedSessions.size, visitCount) },
      { key: "interact", label: "使用播放或检查控件", sessions: activatedEngagedSessions.size, rateFromVisit: ratio(activatedEngagedSessions.size, visitCount) },
      { key: "collaborate", label: "分享或评论", sessions: activatedCollaborationSessions.size, rateFromVisit: ratio(activatedCollaborationSessions.size, visitCount) },
    ],
    breakdowns: {
      surfaces: groupRows(selected, "surface", "surfaces"),
      formats: groupRows(selected, "format", "formats"),
      devices: simpleCountRows(selected, "device", "devices", (event) => event.name === "page_view"),
      browsers: simpleCountRows(selected, "browser", null, (event) => event.name === "page_view"),
      operatingSystems: simpleCountRows(selected, "os", null, (event) => event.name === "page_view"),
      sources: simpleCountRows(selected, "sourceType", "sourceTypes", (event) => event.name === "page_view"),
      referrers: simpleCountRows(selected, "sourceHost", null, (event) => event.name === "page_view"),
      campaigns: simpleCountRows(selected, "utmCampaign", null, (event) => event.name === "page_view"),
      controls: simpleCountRows(selected, "control", "controls", (event) => event.name === "control_use"),
      sizeBuckets: groupRows(selected, "fileSizeBucket", "sizeBuckets", (event) => event.name === "preview_result" || event.name === "performance_sample"),
      errors: simpleCountRows(selected, "errorCategory", "errors", (event) => event.outcome === "failure"),
    },
  };
}

export class AnalyticsStore {
  static async open({ dataDir, salt, now = () => new Date().toISOString(), logger = console } = {}) {
    const analyticsDir = path.join(dataDir, "analytics");
    await mkdir(analyticsDir, { recursive: true });
    return new AnalyticsStore({
      analyticsDir,
      salt: salt || randomBytes(32).toString("hex"),
      now,
      logger,
    });
  }

  constructor({ analyticsDir, salt, now, logger }) {
    this.analyticsDir = analyticsDir;
    this.salt = salt;
    this.now = now;
    this.logger = logger;
    this.writeQueue = Promise.resolve();
    this.lastCleanupDay = "";
  }

  currentIso() {
    const value = this.now();
    return new Date(value).toISOString();
  }

  async cleanup(referenceIso = this.currentIso()) {
    const cutoff = Date.parse(referenceIso) - RETENTION_DAYS * DAY_MS;
    const names = await readdir(this.analyticsDir).catch(() => []);
    await Promise.all(names.filter((name) => /^\d{4}-\d{2}-\d{2}\.ndjson$/.test(name)).map(async (name) => {
      if (Date.parse(name.slice(0, 10)) >= cutoff) return;
      await rm(path.join(this.analyticsDir, name), { force: true });
    }));
  }

  async recordBatch(payload, { userAgent = "" } = {}) {
    if (!payload || typeof payload !== "object" || Array.isArray(payload) || payload.version !== ANALYTICS_VERSION) {
      throw new AppError(422, "invalid_analytics_batch", "统计批次格式无效");
    }
    const surface = enumValue(payload.surface, SURFACES);
    if (!surface || !/^[0-9A-Za-z-]{16,80}$/.test(payload.visitorId || "") || !/^[0-9A-Za-z-]{16,80}$/.test(payload.sessionId || "")) {
      throw new AppError(422, "invalid_analytics_batch", "统计批次标识无效");
    }
    if (!Array.isArray(payload.events) || payload.events.length < 1 || payload.events.length > MAX_BATCH_EVENTS) {
      throw new AppError(422, "invalid_analytics_batch", `每批统计事件须为 1 到 ${MAX_BATCH_EVENTS} 条`);
    }
    const receivedAt = this.currentIso();
    const receivedDay = analyticsDay(receivedAt);
    if (this.lastCleanupDay !== receivedDay) {
      await this.cleanup(receivedAt);
      this.lastCleanupDay = receivedDay;
    }
    const context = {
      receivedAt,
      surface,
      visitorHash: hashIdentifier(this.salt, "visitor", payload.visitorId),
      sessionHash: hashIdentifier(this.salt, "session", payload.sessionId),
      client: parseClient(userAgent),
      salt: this.salt,
    };
    const events = payload.events.map((event) => normalizeEvent(event, context));
    const line = `${events.map((event) => JSON.stringify(event)).join("\n")}\n`;
    const filePath = path.join(this.analyticsDir, `${analyticsDay(receivedAt)}.ndjson`);
    this.writeQueue = this.writeQueue.then(() => appendFile(filePath, line, { encoding: "utf8", mode: 0o640 }));
    await this.writeQueue;
    return events.length;
  }

  async summary({ days = 30, surface = "all", format = "all" } = {}) {
    if (![7, 30, 90].includes(days)) throw new AppError(400, "invalid_days", "days 必须是 7、30 或 90");
    if (surface !== "all" && !SURFACES.has(surface)) throw new AppError(400, "invalid_surface", "surface 无效");
    if (format !== "all" && !FORMATS.has(format)) throw new AppError(400, "invalid_format", "format 无效");
    await this.writeQueue;
    const end = new Date(this.currentIso());
    const names = [];
    for (let offset = 0; offset < RETENTION_DAYS; offset += 1) {
      names.push(`${new Date(end.getTime() - offset * DAY_MS).toISOString().slice(0, 10)}.ndjson`);
    }
    const events = [];
    const seen = new Set();
    for (const name of names) {
      const content = await readFile(path.join(this.analyticsDir, name), "utf8").catch((error) => {
        if (error?.code === "ENOENT") return "";
        throw error;
      });
      for (const line of content.split("\n")) {
        if (!line || events.length >= MAX_SUMMARY_EVENTS) continue;
        try {
          const event = JSON.parse(line);
          if (!event.eventHash || seen.has(event.eventHash)) continue;
          seen.add(event.eventHash);
          events.push(event);
        } catch (error) {
          this.logger.warn?.("跳过损坏的统计事件", error);
        }
      }
    }
    const summary = summarizeAnalytics(events, { days, surface, format, now: end.toISOString() });
    summary.freshness.truncated = events.length >= MAX_SUMMARY_EVENTS;
    return summary;
  }
}

export const ANALYTICS_ALLOWED_ORIGINS = new Set([
  "https://mikeywa.site",
  "https://www.mikeywa.site",
  "https://rive.mikeywa.site",
]);
