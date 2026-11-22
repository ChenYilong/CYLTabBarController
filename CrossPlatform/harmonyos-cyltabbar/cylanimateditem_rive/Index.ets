/**
 * [EN] cylanimateditem_rive: the Rive engine of CYLAnimatedItemView (@ohos/rive). Call `CYLAnimatedItemRive.register()`
 *      once. Guide: cylanimateditem/README.md, "Engine views".
 * [CN] cylanimateditem_rive：CYLAnimatedItemView 的 Rive 引擎（@ohos/rive）。调用一次 `CYLAnimatedItemRive.register()`。
 */
export {
  CYLAnimatedItemRive, CYLAnimatedItemRivePlayer, CYLAnimatedItemRiveView, cylRiveRendererType, cylRiveIsSupported,
  cylEnsureRiveInitialized
} from './src/main/ets/CYLAnimatedItemRive';
export { CYLAnimatedItemRiveOption, cylRiveNextNumber, cylRiveUsesLegacyRuntime } from './src/main/ets/CYLAnimatedItemRiveOptions';
