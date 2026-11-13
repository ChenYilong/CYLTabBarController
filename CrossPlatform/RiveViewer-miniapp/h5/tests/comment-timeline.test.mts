import assert from "node:assert/strict";
import test from "node:test";
import {
  formatCommentTimeline,
  formatCommentTimelineMarker,
  parseCommentTimeline,
  parseCommentTimelineSegments,
} from "../lib/comment-timeline.ts";

test("stores the selected timeline as an editable comment prefix", () => {
  assert.equal(formatCommentTimeline("idol"), "【时间轴：idol】 ");
  assert.equal(formatCommentTimeline("映"), "【时间轴：映】 ");
  assert.equal(formatCommentTimeline(""), "");
});

test("parses a timeline prefix without changing ordinary comments", () => {
  assert.deepEqual(parseCommentTimeline("【时间轴：idol】 这里需要调整"), {
    timelineName: "idol",
    body: "这里需要调整",
  });
  assert.deepEqual(parseCommentTimeline("普通评论"), {
    timelineName: "",
    body: "普通评论",
  });
});

test("round-trips custom timeline names containing the suffix character", () => {
  const prefix = formatCommentTimeline("开场】开场");
  assert.deepEqual(parseCommentTimeline(`${prefix}确认一下`), {
    timelineName: "开场】开场",
    body: "确认一下",
  });
});

test("parses multiple timeline markers at arbitrary text positions", () => {
  const first = formatCommentTimelineMarker("映");
  const second = formatCommentTimelineMarker("idol");
  assert.deepEqual(parseCommentTimelineSegments(`开头 ${first} 中间 ${second} 结尾`), [
    { type: "text", value: "开头 " },
    { type: "timeline", timelineName: "映" },
    { type: "text", value: " 中间 " },
    { type: "timeline", timelineName: "idol" },
    { type: "text", value: " 结尾" },
  ]);
});

test("keeps escaped suffixes and malformed markers as ordinary text", () => {
  const escaped = formatCommentTimelineMarker("开场】备用");
  assert.deepEqual(parseCommentTimelineSegments(`A${escaped}B【时间轴：未闭合`), [
    { type: "text", value: "A" },
    { type: "timeline", timelineName: "开场】备用" },
    { type: "text", value: "B【时间轴：未闭合" },
  ]);
});
