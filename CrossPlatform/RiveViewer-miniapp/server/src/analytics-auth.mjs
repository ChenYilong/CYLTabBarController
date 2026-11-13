import { createHash, createHmac, randomBytes, timingSafeEqual } from "node:crypto";

export const ANALYTICS_SESSION_COOKIE = "rive_data_session";
export const ANALYTICS_SESSION_MAX_AGE_SECONDS = 12 * 60 * 60;

function nowMilliseconds(now) {
  const value = typeof now === "function" ? now() : Date.now();
  const parsed = typeof value === "number" ? value : Date.parse(value);
  return Number.isFinite(parsed) ? parsed : Date.now();
}

function fixedDigest(value) {
  return createHash("sha256").update(String(value), "utf8").digest();
}

function safeEqual(left, right) {
  return timingSafeEqual(fixedDigest(left), fixedDigest(right));
}

function cookieValue(request, name) {
  const raw = Array.isArray(request.headers.cookie)
    ? request.headers.cookie.join(";")
    : String(request.headers.cookie || "");
  if (!raw || raw.length > 4096) return "";
  for (const pair of raw.split(";")) {
    const separator = pair.indexOf("=");
    if (separator < 1 || pair.slice(0, separator).trim() !== name) continue;
    return pair.slice(separator + 1).trim();
  }
  return "";
}

export class AnalyticsAccess {
  constructor({ password = "", salt = "", now = Date.now } = {}) {
    this.password = password;
    this.now = now;
    this.enabled = /^\d{6}$/.test(password);
    this.signingKey = createHash("sha256")
      .update("rive-data-dashboard-session\0", "utf8")
      .update(salt, "utf8")
      .update("\0", "utf8")
      .update(password, "utf8")
      .digest();
  }

  matchesPassword(candidate) {
    return this.enabled && typeof candidate === "string" && safeEqual(candidate, this.password);
  }

  issueToken() {
    const issuedAt = Math.floor(nowMilliseconds(this.now) / 1000);
    const nonce = randomBytes(16).toString("base64url");
    const payload = `v1.${issuedAt}.${nonce}`;
    const signature = createHmac("sha256", this.signingKey).update(payload).digest("base64url");
    return `${payload}.${signature}`;
  }

  isAuthorized(request) {
    if (!this.enabled) return false;
    const token = cookieValue(request, ANALYTICS_SESSION_COOKIE);
    const match = /^(v1)\.(\d{10})\.([0-9A-Za-z_-]{22})\.([0-9A-Za-z_-]{43})$/.exec(token);
    if (!match) return false;
    const issuedAt = Number(match[2]);
    const current = Math.floor(nowMilliseconds(this.now) / 1000);
    if (issuedAt > current + 60 || current - issuedAt > ANALYTICS_SESSION_MAX_AGE_SECONDS) return false;
    const payload = `${match[1]}.${match[2]}.${match[3]}`;
    const expected = createHmac("sha256", this.signingKey).update(payload).digest("base64url");
    return safeEqual(match[4], expected);
  }

  sessionCookie() {
    return `${ANALYTICS_SESSION_COOKIE}=${this.issueToken()}; Path=/; Max-Age=${ANALYTICS_SESSION_MAX_AGE_SECONDS}; HttpOnly; Secure; SameSite=Strict`;
  }

  clearCookie() {
    return `${ANALYTICS_SESSION_COOKIE}=; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Strict`;
  }
}
