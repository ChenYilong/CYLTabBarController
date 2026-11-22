/**
 * [EN] cylanimateditem_rive: the Rive engine of CYLAnimatedItemView (@ohos/rive); a thin re-export of `cylanimateditemrive`, where the Rive logic lives once. Call `CYLAnimatedItemRive.register()`
 *      once. Guide: cylanimateditem/README.md, "Engine views".
 * [CN] cylanimateditem_rive：CYLAnimatedItemView 的 Rive 引擎（@ohos/rive）；对 `cylanimateditemrive` 的薄层重新导出，Rive 逻辑只在那里维护一份。调用一次 `CYLAnimatedItemRive.register()`。
 */
export {
  CYLAnimatedItemRive, CYLAnimatedItemRivePlayer, CYLAnimatedItemRiveView, cylRiveRendererType, cylRiveIsSupported,
  cylEnsureRiveInitialized, CYLAnimatedItemRiveOption, cylRiveNextNumber, cylRiveUsesLegacyRuntime
} from 'cylanimateditemrive';
