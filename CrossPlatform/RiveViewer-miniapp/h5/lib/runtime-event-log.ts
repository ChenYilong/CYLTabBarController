import policy from "../../shared/rive-policy.json";

export type RiveRuntimeEventKind = "info" | "event" | "play" | "state";

export type RiveRuntimeEvent = {
  id: number;
  elapsedMs: number;
  kind: RiveRuntimeEventKind;
  label: string;
  detail: string;
};

const EMPTY_EVENTS: readonly RiveRuntimeEvent[] = [];

export class RuntimeEventLog {
  private events: readonly RiveRuntimeEvent[] = EMPTY_EVENTS;
  private readonly listeners = new Set<() => void>();
  private notifyQueued = false;
  private readonly limit: number;

  constructor(limit = policy.telemetry.webEventLogEntries) {
    this.limit = Math.max(1, Math.floor(limit));
  }

  subscribe = (listener: () => void): (() => void) => {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  };

  getSnapshot = (): readonly RiveRuntimeEvent[] => this.events;

  getServerSnapshot = (): readonly RiveRuntimeEvent[] => EMPTY_EVENTS;

  append(event: RiveRuntimeEvent): void {
    this.events = [...this.events, event].slice(-this.limit);
    this.queueNotify();
  }

  reset(): void {
    if (!this.events.length) return;
    this.events = EMPTY_EVENTS;
    this.queueNotify();
  }

  private queueNotify(): void {
    if (this.notifyQueued) return;
    this.notifyQueued = true;
    queueMicrotask(() => {
      this.notifyQueued = false;
      this.listeners.forEach((listener) => listener());
    });
  }
}
