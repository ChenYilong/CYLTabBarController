import { PAGInit } from "libpag";
import type { PlayerCallbacks, RiveMetadata } from "./rive-player";

type PagRuntime = Awaited<ReturnType<typeof PAGInit>>;
type PagFile = Awaited<ReturnType<PagRuntime["PAGFile"]["load"]>>;
type PagView = NonNullable<Awaited<ReturnType<PagRuntime["PAGView"]["init"]>>>;

let runtimePromise: Promise<PagRuntime> | null = null;

function getRuntime(): Promise<PagRuntime> {
  if (!runtimePromise) {
    runtimePromise = PAGInit().catch((error) => {
      runtimePromise = null;
      throw error;
    });
  }
  return runtimePromise;
}

export class WebPagPlayer {
  private readonly canvas: HTMLCanvasElement;
  private readonly callbacks: PlayerCallbacks;
  private runtime: PagRuntime | null = null;
  private file: PagFile | null = null;
  private view: PagView | null = null;
  private playing = true;
  private baseDuration = 0;
  private speed = 1;
  private fit: "contain" | "cover" = "contain";
  private cssWidth = 1;
  private cssHeight = 1;
  private quality = 1;
  private updateListener: (() => void) | null = null;
  private performanceStartedAt = 0;
  private performanceFrames = 0;

  constructor(canvas: HTMLCanvasElement, callbacks: PlayerCallbacks) {
    this.canvas = canvas;
    this.callbacks = callbacks;
  }

  async load(source: ArrayBuffer): Promise<RiveMetadata> {
    if (source.byteLength < 4 || new TextDecoder().decode(source.slice(0, 3)) !== "PAG") {
      throw new Error("文件头不是有效的 PAG");
    }
    this.runtime = await getRuntime();
    this.file = await this.runtime.PAGFile.load(source);
    if (!this.file) throw new Error("PAG 文件无法解析");
    this.baseDuration = this.file.duration();
    this.resize(this.cssWidth, this.cssHeight);
    const view = await this.runtime.PAGView.init(this.file, this.canvas, { useScale: true, firstFrame: true });
    if (!view) throw new Error("PAG 画布初始化失败");
    this.view = view;
    this.resize(this.cssWidth, this.cssHeight);
    view.setRepeatCount(0);
    this.applyFit();
    this.updateListener = () => this.reportFrame();
    view.addListener("onAnimationUpdate", this.updateListener);
    await view.play();
    const metadata = this.metadata();
    this.callbacks.onMetadata(metadata);
    this.callbacks.onPlayback(true, "正在播放 PAG");
    return metadata;
  }

  private metadata(): RiveMetadata {
    return {
      artboardNames: [], artboardCount: 0, artboardCatalogLoaded: true, activeArtboard: "",
      stateMachines: [], activeStateMachine: "", animations: ["PAG"], activeAnimation: "PAG",
      inputs: [], width: this.file?.width() || 0, height: this.file?.height() || 0,
      hasAudio: false, audioEnabled: false,
    };
  }

  private reportFrame(): void {
    if (!this.view) return;
    const now = performance.now();
    const duration = this.view.duration() / 1_000_000;
    const progress = this.view.getProgress();
    this.callbacks.onProgress({ name: "PAG", time: duration * progress, duration, progress });
    this.performanceFrames += 1;
    if (!this.performanceStartedAt) this.performanceStartedAt = now;
    if (now - this.performanceStartedAt >= 500) {
      this.callbacks.onPerformance((this.performanceFrames * 1000) / (now - this.performanceStartedAt));
      this.performanceStartedAt = now;
      this.performanceFrames = 0;
    }
  }

  async loadArtboardCatalog(onProgress: (progress: number) => void): Promise<string[]> { onProgress(100); return []; }
  resize(width: number, height: number): void {
    this.cssWidth = Math.max(1, width);
    this.cssHeight = Math.max(1, height);
    const ratio = Math.min(window.devicePixelRatio || 1, this.quality);
    const nextWidth = Math.max(1, Math.round(this.cssWidth * ratio));
    const nextHeight = Math.max(1, Math.round(this.cssHeight * ratio));
    if (this.canvas.width !== nextWidth) this.canvas.width = nextWidth;
    if (this.canvas.height !== nextHeight) this.canvas.height = nextHeight;
    this.view?.updateSize();
    if (this.view && !this.playing) void this.view.flush();
  }
  private applyFit(): void {
    if (!this.view) return;
    this.view.setScaleMode(this.fit === "cover" ? 3 : 2);
    if (!this.playing) void this.view.flush();
  }
  setFit(fit: "contain" | "cover"): void { this.fit = fit; this.applyFit(); }
  setQuality(quality: number): void { this.quality = Math.max(1, Math.min(2, quality)); this.resize(this.cssWidth, this.cssHeight); }
  setSpeed(speed: number): void {
    this.speed = Math.max(0.1, Math.min(8, speed));
    if (!this.file || !this.view || !this.baseDuration) return;
    const progress = this.view.getProgress();
    const wasPlaying = this.playing;
    this.view.pause();
    this.file.setDuration(this.baseDuration / this.speed);
    this.view.setProgress(progress);
    if (wasPlaying) void this.view.play();
    else void this.view.flush();
  }
  setAudioEnabled(): void {}
  play(): void { this.playing = true; void this.view?.play(); this.callbacks.onPlayback(true, "正在播放 PAG"); }
  pause(): void { this.playing = false; this.view?.pause(); this.callbacks.onPlayback(false, "已暂停"); }
  reset(): void { if (!this.view) return; void this.view.stop(false).then(() => this.play()); }
  selectArtboard(): void {}
  selectStateMachine(): void {}
  selectAnimation(): void { if (!this.playing) this.play(); }
  setInput(): void {}
  fireInput(): void {}
  pointer(): void {}
  dispose(): void {
    if (this.view && this.updateListener) this.view.removeListener("onAnimationUpdate", this.updateListener);
    this.view?.destroy();
    this.file?.destroy();
    this.view = null;
    this.file = null;
  }
}
