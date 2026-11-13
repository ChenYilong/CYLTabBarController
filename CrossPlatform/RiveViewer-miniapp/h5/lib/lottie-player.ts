import type { AnimationItem, BMEnterFrameEvent } from "lottie-web";
import type { PlayerCallbacks, RiveMetadata } from "./rive-player";

type LottieDocument = {
  w: number;
  h: number;
  fr: number;
  ip: number;
  op: number;
  layers: unknown[];
  assets?: Array<{ p?: string; e?: number }>;
  fonts?: { list?: Array<{ fPath?: string }> };
};

function parseLottie(source: ArrayBuffer): LottieDocument {
  let value: unknown;
  try {
    value = JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(source));
  } catch {
    throw new Error("JSON 不是有效的 Lottie 动画");
  }
  const document = value as Partial<LottieDocument>;
  if (
    !document || typeof document !== "object" || !Array.isArray(document.layers)
    || !Number.isFinite(document.w) || !Number.isFinite(document.h)
    || !Number.isFinite(document.fr) || !Number.isFinite(document.ip)
    || !Number.isFinite(document.op)
  ) throw new Error("JSON 不是有效的 Lottie 动画");
  const externalImage = document.assets?.some((asset) => (
    typeof asset.p === "string" && !asset.p.startsWith("data:") && asset.e !== 1
  ));
  const externalFont = document.fonts?.list?.some((font) => Boolean(font.fPath?.trim()));
  if (externalImage || externalFont) {
    throw new Error("Lottie 暂只支持资源已内嵌的单个 JSON 文件");
  }
  return document as LottieDocument;
}

export class WebLottiePlayer {
  private readonly container: HTMLDivElement;
  private readonly callbacks: PlayerCallbacks;
  private animation: AnimationItem | null = null;
  private document: LottieDocument | null = null;
  private playing = true;
  private fit: "contain" | "cover" = "contain";
  private lastPerformanceAt = 0;
  private performanceFrames = 0;
  private removeEnterFrame: (() => void) | null = null;

  constructor(container: HTMLDivElement, callbacks: PlayerCallbacks) {
    this.container = container;
    this.callbacks = callbacks;
  }

  async load(source: ArrayBuffer): Promise<RiveMetadata> {
    const document = parseLottie(source);
    const module = await import("lottie-web/build/player/lottie_canvas");
    const lottie = module.default;
    this.document = document;
    this.container.replaceChildren();
    const animation = lottie.loadAnimation({
      container: this.container,
      renderer: "canvas",
      loop: true,
      autoplay: true,
      animationData: document,
      rendererSettings: {
        clearCanvas: true,
        progressiveLoad: false,
        preserveAspectRatio: "xMidYMid meet",
      },
    });
    this.animation = animation;
    this.removeEnterFrame = animation.addEventListener("enterFrame", (event: BMEnterFrameEvent) => {
      const now = performance.now();
      const duration = Math.max(0, this.animation?.getDuration() || 0);
      const time = Math.max(0, event.currentTime / Math.max(1, document.fr));
      this.callbacks.onProgress({
        name: "Lottie",
        time,
        duration,
        progress: duration ? Math.min(1, time / duration) : 0,
      });
      this.performanceFrames += 1;
      if (!this.lastPerformanceAt) this.lastPerformanceAt = now;
      if (now - this.lastPerformanceAt >= 500) {
        this.callbacks.onPerformance((this.performanceFrames * 1000) / (now - this.lastPerformanceAt));
        this.lastPerformanceAt = now;
        this.performanceFrames = 0;
      }
    });
    const metadata = this.metadata();
    this.callbacks.onMetadata(metadata);
    this.callbacks.onPlayback(true, "正在播放 Lottie");
    await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()));
    this.setFit(this.fit);
    return metadata;
  }

  private metadata(): RiveMetadata {
    return {
      artboardNames: [], artboardCount: 0, artboardCatalogLoaded: true, activeArtboard: "",
      stateMachines: [], activeStateMachine: "", animations: ["Lottie"],
      activeAnimation: "Lottie", inputs: [], width: this.document?.w || 0,
      height: this.document?.h || 0, hasAudio: false, audioEnabled: false,
    };
  }

  async loadArtboardCatalog(onProgress: (progress: number) => void): Promise<string[]> {
    onProgress(100);
    return [];
  }

  resize(): void { this.animation?.resize(); }
  setFit(fit: "contain" | "cover"): void {
    this.fit = fit;
    if (this.animation?.renderer?.renderConfig) {
      this.animation.renderer.renderConfig.preserveAspectRatio = fit === "cover" ? "xMidYMid slice" : "xMidYMid meet";
      this.animation.resize();
    }
  }
  setQuality(): void {}
  setSpeed(speed: number): void { this.animation?.setSpeed(speed); }
  setAudioEnabled(): void {}
  play(): void { this.playing = true; this.animation?.play(); this.callbacks.onPlayback(true, "正在播放 Lottie"); }
  pause(): void { this.playing = false; this.animation?.pause(); this.callbacks.onPlayback(false, "已暂停"); }
  reset(): void { this.animation?.goToAndPlay(0, true); this.playing = true; this.callbacks.onPlayback(true, "正在播放 Lottie"); }
  selectArtboard(): void {}
  selectStateMachine(): void {}
  selectAnimation(): void { if (!this.playing) this.play(); }
  setInput(): void {}
  fireInput(): void {}
  pointer(): void {}
  dispose(): void {
    this.removeEnterFrame?.();
    this.removeEnterFrame = null;
    this.animation?.destroy();
    this.animation = null;
    this.container.replaceChildren();
  }
}
