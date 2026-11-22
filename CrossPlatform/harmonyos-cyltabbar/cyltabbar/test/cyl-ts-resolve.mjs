// [EN] Node resolve hook for the tests: cyltabbar's .ts files import the GIF timing file of `cylanimateditem` by its package path
//      (an ArkTS package whose Index.ets Node cannot load); here that path resolves to the file in this repository.
//      Extensionless relative imports are retried with ".ts".
// [CN] 测试用的 Node 解析钩子：cyltabbar 的 .ts 文件按包路径导入 `cylanimateditem` 的 GIF 时间文件（Node 无法加载其 Index.ets）；这里该路径解析为
//      本仓库中的文件。不带扩展名的相对导入会加上 ".ts" 再试。
export async function resolve(specifier, context, nextResolve) {
  if (specifier === 'cylanimateditem/src/main/ets/CYLAnimatedItemGIFTiming') {
    return nextResolve(new URL('../../cylanimateditem/src/main/ets/CYLAnimatedItemGIFTiming.ts', import.meta.url).href, context);
  }
  if ((specifier.startsWith('./') || specifier.startsWith('../')) && !/\.[cm]?[jt]s$/.test(specifier)) {
    try {
      return await nextResolve(specifier + '.ts', context);
    } catch (e) {
      // [EN] Not a .ts file: resolve as given. [CN] 不是 .ts 文件：按原样解析。
    }
  }
  return nextResolve(specifier, context);
}
