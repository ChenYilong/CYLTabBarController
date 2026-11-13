const COMMENT_TIMELINE_PREFIX = "【时间轴：";
const COMMENT_TIMELINE_SUFFIX = "】";

export type ParsedCommentTimeline = {
  timelineName: string;
  body: string;
};

export type CommentTimelineSegment =
  | { type: "text"; value: string }
  | { type: "timeline"; timelineName: string };

export function formatCommentTimelineMarker(timelineName: string): string {
  const normalizedName = timelineName.replace(/[\r\n]+/g, " ").trim();
  if (!normalizedName) return "";
  const escapedName = normalizedName.replaceAll(COMMENT_TIMELINE_SUFFIX, `${COMMENT_TIMELINE_SUFFIX}${COMMENT_TIMELINE_SUFFIX}`);
  return `${COMMENT_TIMELINE_PREFIX}${escapedName}${COMMENT_TIMELINE_SUFFIX}`;
}

export function formatCommentTimeline(timelineName: string): string {
  const marker = formatCommentTimelineMarker(timelineName);
  return marker ? `${marker} ` : "";
}

export function parseCommentTimelineSegments(body: string): CommentTimelineSegment[] {
  const segments: CommentTimelineSegment[] = [];
  let textStart = 0;
  let searchStart = 0;

  while (searchStart < body.length) {
    const markerStart = body.indexOf(COMMENT_TIMELINE_PREFIX, searchStart);
    if (markerStart < 0) break;

    let timelineName = "";
    let markerEnd = COMMENT_TIMELINE_PREFIX.length + markerStart;
    let closed = false;
    while (markerEnd < body.length) {
      const character = body[markerEnd];
      if (character !== COMMENT_TIMELINE_SUFFIX) {
        timelineName += character;
        markerEnd += 1;
        continue;
      }
      if (body[markerEnd + 1] === COMMENT_TIMELINE_SUFFIX) {
        timelineName += COMMENT_TIMELINE_SUFFIX;
        markerEnd += 2;
        continue;
      }
      closed = true;
      markerEnd += 1;
      break;
    }

    const normalizedName = timelineName.trim();
    if (!closed || !normalizedName) {
      searchStart = markerStart + COMMENT_TIMELINE_PREFIX.length;
      continue;
    }
    if (markerStart > textStart) {
      segments.push({ type: "text", value: body.slice(textStart, markerStart) });
    }
    segments.push({ type: "timeline", timelineName: normalizedName });
    textStart = markerEnd;
    searchStart = markerEnd;
  }

  if (textStart < body.length) {
    segments.push({ type: "text", value: body.slice(textStart) });
  }
  return segments.length ? segments : [{ type: "text", value: body }];
}

export function parseCommentTimeline(body: string): ParsedCommentTimeline {
  if (!body.startsWith(COMMENT_TIMELINE_PREFIX)) return { timelineName: "", body };

  let timelineName = "";
  let index = COMMENT_TIMELINE_PREFIX.length;
  while (index < body.length) {
    const character = body[index];
    if (character !== COMMENT_TIMELINE_SUFFIX) {
      timelineName += character;
      index += 1;
      continue;
    }
    if (body[index + 1] === COMMENT_TIMELINE_SUFFIX) {
      timelineName += COMMENT_TIMELINE_SUFFIX;
      index += 2;
      continue;
    }
    const normalizedName = timelineName.trim();
    if (!normalizedName) return { timelineName: "", body };
    return {
      timelineName: normalizedName,
      body: body.slice(index + 1).replace(/^[\t ]+/, ""),
    };
  }

  return { timelineName: "", body };
}
