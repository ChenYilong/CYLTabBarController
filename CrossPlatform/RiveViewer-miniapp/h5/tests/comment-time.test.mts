import assert from "node:assert/strict";
import test from "node:test";
import { formatCommentDate } from "../lib/comment-time.ts";

const NOW = Date.parse("2026-08-25T10:00:00.000Z");

test("shows relative comment time during the first week", () => {
  assert.equal(formatCommentDate("2026-08-25T09:59:40.000Z", NOW), "刚刚");
  assert.equal(formatCommentDate("2026-08-25T09:55:00.000Z", NOW), "5分钟前");
  assert.equal(formatCommentDate("2026-08-25T07:00:00.000Z", NOW), "3小时前");
  assert.equal(formatCommentDate("2026-08-22T10:00:00.000Z", NOW), "3天前");
});

test("switches to an absolute date after one week", () => {
  const absolute = formatCommentDate("2026-08-18T10:00:00.000Z", NOW);
  assert.match(absolute, /2026/);
  assert.doesNotMatch(absolute, /天前|小时前|分钟前/);
});
