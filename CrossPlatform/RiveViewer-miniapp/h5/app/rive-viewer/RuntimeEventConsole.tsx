import { useEffect, useId, useRef, useState, useSyncExternalStore } from "react";
import type { RiveRuntimeEvent } from "../../lib/runtime-event-log";
import { RuntimeEventLog } from "../../lib/runtime-event-log";
import { Icon } from "./Icon";

const KIND_LABELS: Record<RiveRuntimeEvent["kind"], string> = {
  info: "INFO",
  event: "EVENT",
  play: "PLAY",
  state: "STATE",
};

function formatElapsed(elapsedMs: number): string {
  return `${(Math.max(0, elapsedMs) / 1000).toFixed(2)}s`;
}

function EventLine({ event, latest = false }: { event: RiveRuntimeEvent; latest?: boolean }) {
  return (
    <span className={`runtime-event-line kind-${event.kind} ${latest ? "is-latest" : ""}`}>
      <time>{formatElapsed(event.elapsedMs)}</time>
      <b>{KIND_LABELS[event.kind]}</b>
      <span className="runtime-event-message">
        <strong>{event.label}</strong>
        {event.detail && <small>{event.detail}</small>}
      </span>
    </span>
  );
}

export function RuntimeEventConsole({ log }: { log: RuntimeEventLog }) {
  const [expanded, setExpanded] = useState(false);
  const listId = useId();
  const listRef = useRef<HTMLDivElement>(null);
  const events = useSyncExternalStore(log.subscribe, log.getSnapshot, log.getServerSnapshot);
  const latest = events.at(-1);

  useEffect(() => {
    if (expanded && listRef.current) listRef.current.scrollTop = listRef.current.scrollHeight;
  }, [events, expanded]);

  return (
    <section className={`runtime-event-console ${expanded ? "is-expanded" : ""}`} aria-label="事件控制台">
      <button
        type="button"
        className="runtime-event-summary"
        aria-expanded={expanded}
        aria-controls={listId}
        onClick={() => setExpanded((current) => !current)}
      >
        <span className={`runtime-event-status ${latest ? "has-events" : ""}`} aria-hidden="true" />
        <span className="runtime-event-title">事件</span>
        {latest
          ? <EventLine event={latest} latest />
          : <span className="runtime-event-empty">等待 Rive 事件</span>}
        <span className="runtime-event-count">{events.length} 条</span>
        <Icon name="caret-down" size={17} />
      </button>
      {expanded && (
        <div id={listId} ref={listRef} className="runtime-event-history" aria-label="当前文件的全部事件">
          {events.length
            ? events.map((event) => <EventLine event={event} key={event.id} />)
            : <span className="runtime-event-history-empty">这个文件暂时还没有触发事件。</span>}
        </div>
      )}
    </section>
  );
}
