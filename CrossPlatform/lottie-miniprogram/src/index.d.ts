type BaseRendererConfig = {
  imagePreserveAspectRatio?: string;
  className?: string;
};

type CanvasRendererConfig = BaseRendererConfig & {
  clearCanvas?: boolean;
  context: CanvasRenderingContext2D;
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
  path?: string;
}

type AnimationDirection = 1 | -1;
type AnimationSegment = [number, number];
type AnimationEventName = 'enterFrame' | 'loopComplete' | 'complete' | 'segmentStart' | 'destroy';
type AnimationEventCallback<T = any> = (args: T) => void;

interface LoadAnimationReturnType {
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

declare module lottie {
  var loadAnimation: (options: LoadAnimationParameter) => LoadAnimationReturnType;
  var setup: (node: any) => void;
}

export default lottie;
