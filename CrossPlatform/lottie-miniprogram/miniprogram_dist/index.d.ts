type BaseRendererConfig = {
  imagePreserveAspectRatio?: string;
  className?: string;
};

/**
 * Issue #41: a mini program project has no DOM typings (`CanvasRenderingContext2D`), so the context is typed as the
 * 2D context object of a `<canvas type="2d">` node, which `WechatMiniprogram.CanvasRenderingContext.CanvasRenderingContext2D`
 * of miniprogram-api-typings satisfies.
 */
type CYLCanvasContext2D = { canvas?: any; [key: string]: any };

type CanvasRendererConfig = BaseRendererConfig & {
  clearCanvas?: boolean;
  context: CYLCanvasContext2D;
  progressiveLoad?: boolean;
  preserveAspectRatio?: string;
};

interface LoadAnimationParameter {
  renderer?: 'canvas';
  loop?: boolean | number;
  autoplay?: boolean;
  name?: string;
  rendererSettings?: CanvasRendererConfig;
  animationData?: any;
  /** A network URL, or a file of the mini program package or the user data folder (Lottie JSON only). */
  path?: string;
  initialSegment?: AnimationSegment;
}

type AnimationDirection = 1 | -1;
type AnimationSegment = [number, number];
type AnimationEventName = 'enterFrame' | 'loopComplete' | 'complete' | 'segmentStart' | 'destroy';
type AnimationEventCallback<T = any> = (args: T) => void;

interface LoadAnimationReturnType {
  isLoaded: boolean;
  currentFrame: number;
  totalFrames: number;
  play(): void;
  stop(): void;
  pause(): void;
  setSpeed(speed: number): void;
  goToAndPlay(value: number, isFrame?: boolean): void;
  goToAndStop(value: number, isFrame?: boolean): void;
  setDirection(direction: AnimationDirection): void;
  playSegments(segments: AnimationSegment | AnimationSegment[], forceFlag?: boolean): void;
  setSubframe(useSubFrames: boolean): void;
  destroy(): void;
  getDuration(inFrames?: boolean): number;
  triggerEvent<T = any>(name: AnimationEventName, args: T): void;
  addEventListener<T = any>(name: AnimationEventName, callback: AnimationEventCallback<T>): void;
  removeEventListener<T = any>(name: AnimationEventName, callback: AnimationEventCallback<T>): void;
}

declare namespace lottie {
  /** Registers the node of a `<canvas type="2d">`; call it before loadAnimation(). */
  var setup: (node: any) => void;
  var loadAnimation: (options: LoadAnimationParameter) => LoadAnimationReturnType;
  var freeze: () => void;
  var unfreeze: () => void;
  /** Destroys every animation, or the ones with this name (PR #17). */
  var destroy: (name?: string) => void;
  /** The interval of the frame timer in ms when no canvas is registered (issue #28). */
  var setFrameInterval: (interval: number) => void;
}

export const setup: typeof lottie.setup;
export const loadAnimation: typeof lottie.loadAnimation;
export const freeze: typeof lottie.freeze;
export const unfreeze: typeof lottie.unfreeze;
export const destroy: typeof lottie.destroy;
export const setFrameInterval: typeof lottie.setFrameInterval;

export default lottie;
