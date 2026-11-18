/**
 * [EN] cylanimateditem: the animated icon + title component of CYLTabBarController for HarmonyOS NEXT, the counterpart of
 *      iOS `CYLAnimatedItemView` (the CYLAnimatedItem pod) and Android `com.cyl.animateditem.CYLAnimatedItemView`. It
 *      depends on no other package (not on cyltabbar) and on no animation library. Guide: docs/Animated-Item.md.
 * [CN] cylanimateditem：鸿蒙版 CYLTabBarController 的动效图标 + 标题组件，对应 iOS 的 `CYLAnimatedItemView`（CYLAnimatedItem pod）与 Android 的
 *      `com.cyl.animateditem.CYLAnimatedItemView`。它不依赖任何其他包（不依赖 cyltabbar），也不依赖任何动画库。文档：docs/Animated-Item.md。
 */
export {
  CYLAnimatedItemView, CYLAnimatedItemAxis, CYLAnimatedItemAccessoryPlacement, CYLAnimatedItemAnimationContext, CYLAnimatedItemController,
  CYLAnimatedItemEngines, cylAnimatedItemTypeOf, cylIconColorFilter
} from './src/main/ets/CYLAnimatedItemView';
export { CYLAnimatedItemStackView } from './src/main/ets/CYLAnimatedItemStackView';
export {
  CYLAnimatedItemStackModel, CYLAnimatedItemStackItem, CYLAnimatedItemStackActionHandler, CYLAnimatedItemStackDefaultSpacing
} from './src/main/ets/CYLAnimatedItemStackModel';
