import type { TimelineProgress } from "./rive-player";

export type PlaybackTelemetrySnapshot = {
  timeline: TimelineProgress;
  fps: number;
};

const EMPTY_TIMELINE: TimelineProgress = {
  name: "",
  time: 0,
  duration: 0,
  progress: 0,
};

export function formatPlaybackTime(seconds: number): string {
  if (!Number.isFinite(seconds) || seconds <= 0) return "00:00.0";
  const minutes = Math.floor(seconds / 60);
  const remainder = seconds - minutes * 60;
  return `${String(minutes).padStart(2, "0")}:${remainder.toFixed(1).padStart(4, "0")}`;
}

export class PlaybackTelemetry {
  private listeners = new Set<() => void>();
  private snapshot: PlaybackTelemetrySnapshot = {
    timeline: EMPTY_TIMELINE,
    fps: 0,
  };

  subscribe = (listener: () => void): (() => void) => {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  };

  getSnapshot = (): PlaybackTelemetrySnapshot => this.snapshot;

  reset(): void {
    this.publish({ timeline: EMPTY_TIMELINE, fps: 0 });
  }

  updateTimeline(timeline: TimelineProgress): void {
    this.publish({ ...this.snapshot, timeline });
  }

  updateFps(fps: number): void {
    if (fps === this.snapshot.fps) return;
    this.publish({ ...this.snapshot, fps });
  }

  private publish(snapshot: PlaybackTelemetrySnapshot): void {
    this.snapshot = snapshot;
    this.listeners.forEach((listener) => listener());
  }
}
