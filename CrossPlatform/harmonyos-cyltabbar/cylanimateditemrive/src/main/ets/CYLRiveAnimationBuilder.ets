import { common } from '@kit.AbilityKit';
import { CYLAnimatedItemAnimationContext, CYLAnimatedItemEngines } from 'cylanimateditem';
import { CYLRiveIcon } from './CYLRiveIcon';
import { CYLRiveLoopPolicy } from './CYLRiveLoopPolicy';

/**
 * [EN] Registers Rive with `CYLAnimatedItemEngines`, so `CYLAnimatedItemView` plays .riv files: the type needs the `arm64-v8a`
 *      native library of @ohos/rive (the registry's built-in requirement, left alone here so the x86_64 debug kit's `x86_64`
 *      is never overwritten; the item shows its still image on a device without it), and, in a HAP
 *      installed with the x86_64 debug engine kit (`cylanimateditem/x86_64-debug-engines/rive`), `context` lets Rive play on
 *      the x86_64 emulator too. Call it once, in `aboutToAppear` of the page or the app's first component.
 * [CN] 向 `CYLAnimatedItemEngines` 注册 Rive，使 `CYLAnimatedItemView` 能播放 .riv 文件：该类型需要 @ohos/rive 的 `arm64-v8a` 原生库
 *      （没有它的设备上条目显示静态图片）；安装了 x86_64 调试引擎包（`cylanimateditem/x86_64-debug-engines/rive`）的 HAP 中，传入
 *      `context` 后 Rive 也能在 x86_64 模拟器上播放。调用一次即可，放在页面或 App 第一个组件的 `aboutToAppear` 中。
 */
export function cylRegisterRiveEngine(context?: common.Context): void {
  CYLAnimatedItemEngines.register('Rive', undefined, '@ohos/rive');
  CYLAnimatedItemEngines.loadX86_64DebugEngines(context);
}

/**
 * [EN] An `animationBuilder` for `CYLAnimatedItemView` that plays .riv files with `CYLRiveIcon` in the loop policy
 *      `CYLRiveLoopPolicy.WhilePlaying`: the item's `animationLoops` repeats the pass until it goes off (the pass playing
 *      finishes), `animationRestartToken` / `CYLAnimatedItemController.restartAnimation()` play again, `onAnimationEnd` comes at
 *      the end of a play-once pass, and a file that cannot load shows the item's still image. Options go in the file's
 *      fragment (`animationUrl: 'rive/icons.riv#artboard=CHAT&stateMachine=CHAT_Interactivity'`).
 * [CN] `CYLAnimatedItemView` 的 `animationBuilder`，使用 `CYLRiveIcon` 以 `CYLRiveLoopPolicy.WhilePlaying` 播放 .riv 文件：条目的
 *      `animationLoops` 重复播放直到关闭（正在播放的一遍播完）；`animationRestartToken` / `CYLAnimatedItemController.restartAnimation()` 再次播放；
 *      只播放一次的一遍结束时调用 `onAnimationEnd`；文件无法加载时显示条目的静态图片。选项写在文件的 fragment 中。
 */
@Builder
export function CYLRiveAnimationBuilder(context: CYLAnimatedItemAnimationContext) {
  CYLRiveIcon({
    path: context.url,
    iconSize: context.size,
    selected: context.selected,
    replayToken: context.restartToken,
    loops: context.loops,
    loopPolicy: CYLRiveLoopPolicy.WhilePlaying,
    registerReplay: (replay: () => void) => context.setRestartHandler(replay),
    onLoaded: () => context.onLoaded(),
    onEnded: () => context.onEnded(),
    onLoadError: (_message: string) => context.onFailed(),
  })
}
