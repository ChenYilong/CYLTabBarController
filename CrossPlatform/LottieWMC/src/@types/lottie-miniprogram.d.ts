declare module "lottie-miniprogram" {
    function setup(canvas: Record<string, any>): void;
    function destroy(): void;
    function loadAnimation(option: LoadAnimationOption): Animation;
}

interface LoadAnimationOption {
    animationData?: object,
    path?: string,
    loop?: boolean,
    autoplay?: boolean,
    rendererSettings: {
        context: Record<string, any>
    }
}

interface Animation {
    play(): void;
    pause(): void;
    stop(): void;
    destroy(): void;
}