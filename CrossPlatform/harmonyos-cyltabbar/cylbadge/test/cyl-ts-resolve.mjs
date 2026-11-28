// [EN] Node resolve hook for the tests: the module's .ts files import each other without an extension (as ArkTS needs), so
//      an extensionless relative import is retried with ".ts". Used through cyl-ts-import.mjs.
// [CN] 测试用的 Node 解析钩子：模块的 .ts 文件互相导入时不带扩展名（ArkTS 的要求），因此不带扩展名的相对导入会加上 ".ts" 再试。
export async function resolve(specifier, context, nextResolve) {
  if ((specifier.startsWith('./') || specifier.startsWith('../')) && !/\.[cm]?[jt]s$/.test(specifier)) {
    try {
      return await nextResolve(specifier + '.ts', context);
    } catch (e) {
      // [EN] Not a .ts file: resolve as given. [CN] 不是 .ts 文件：按原样解析。
    }
  }
  return nextResolve(specifier, context);
}
