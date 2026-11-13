const MINUTE_MS = 60_000;
const HOUR_MS = 60 * MINUTE_MS;
const DAY_MS = 24 * HOUR_MS;
const WEEK_MS = 7 * DAY_MS;

export function formatCommentAbsoluteDate(value: string | null): string {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return new Intl.DateTimeFormat("zh-CN", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  }).format(date);
}

export function formatCommentDate(value: string | null, now = Date.now()): string {
  if (!value) return "";
  const timestamp = new Date(value).getTime();
  if (!Number.isFinite(timestamp)) return value;
  const elapsed = Math.max(0, now - timestamp);
  if (elapsed < MINUTE_MS) return "刚刚";
  if (elapsed < HOUR_MS) return `${Math.floor(elapsed / MINUTE_MS)}分钟前`;
  if (elapsed < DAY_MS) return `${Math.floor(elapsed / HOUR_MS)}小时前`;
  if (elapsed < WEEK_MS) return `${Math.floor(elapsed / DAY_MS)}天前`;
  return formatCommentAbsoluteDate(value);
}
