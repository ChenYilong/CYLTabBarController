/**
 * [EN] Resource helpers of CYLAnimatedItemView (pure, unit tested with Node: test/CYLAnimatedItemResources.test.mjs).
 * [CN] CYLAnimatedItemView 的资源工具（纯函数，用 Node 做单元测试：test/CYLAnimatedItemResources.test.mjs）。
 */

/** [EN] The resource type of `sys.symbol` resources (media is 20000). [CN] `sys.symbol` 资源的类型（media 为 20000）。 */
export const CYL_SYMBOL_RESOURCE_TYPE: number = 40000;

/**
 * [EN] Whether an image is a system symbol resource (`$r('sys.symbol.xmark')`): an ArkUI Image draws nothing for it (B30),
 *      so CYLAnimatedItemView draws it as a SymbolGlyph in `iconColor`.
 * [CN] 图片是否为系统符号资源（`$r('sys.symbol.xmark')`）：ArkUI Image 不绘制它（B30），因此 CYLAnimatedItemView 用 SymbolGlyph 按 `iconColor` 绘制。
 */
export function cylIsSymbolResource(image: Object | string | undefined): boolean {
  if (image === undefined || image === null || typeof image !== 'object') {
    return false;
  }
  return (image as Record<string, Object>)['type'] === CYL_SYMBOL_RESOURCE_TYPE;
}
