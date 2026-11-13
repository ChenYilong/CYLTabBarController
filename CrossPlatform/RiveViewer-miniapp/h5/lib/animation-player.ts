import type { RenderEngine, RiveInput, RiveMetadata, WebRivePlayer } from "./rive-player";
import type { PlayerCallbacks } from "./rive-player";
import type { AnimationFormat } from "./animation-format";

export type AnimationPlayer = Pick<
  WebRivePlayer,
  | "load"
  | "loadArtboardCatalog"
  | "resize"
  | "setFit"
  | "setQuality"
  | "setSpeed"
  | "setAudioEnabled"
  | "play"
  | "pause"
  | "reset"
  | "selectArtboard"
  | "selectStateMachine"
  | "selectAnimation"
  | "setInput"
  | "fireInput"
  | "pointer"
  | "dispose"
>;

export type AnimationMetadata = RiveMetadata;
export type AnimationInput = RiveInput;

export async function createAnimationPlayer(
  format: AnimationFormat,
  canvas: HTMLCanvasElement,
  lottieContainer: HTMLDivElement,
  callbacks: PlayerCallbacks,
  renderEngine: RenderEngine,
): Promise<AnimationPlayer> {
  if (format === "lottie") {
    const { WebLottiePlayer } = await import("./lottie-player");
    return new WebLottiePlayer(lottieContainer, callbacks);
  }
  if (format === "pag") {
    const { WebPagPlayer } = await import("./pag-player");
    return new WebPagPlayer(canvas, callbacks);
  }
  const { WebRivePlayer } = await import("./rive-player");
  return new WebRivePlayer(canvas, callbacks, renderEngine);
}
