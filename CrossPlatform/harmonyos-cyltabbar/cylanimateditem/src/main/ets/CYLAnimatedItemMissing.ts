/**
 * [EN] A file the animation engines cannot show: the reasons (the same four strings on every platform) and the reporter
 *      that tells the host once per resource per item (pure, unit tested with Node: test/CYLAnimatedItemMissing.test.mjs).
 *      `CYLAnimatedItemView.onResourceMissing` and `CYLAnimatedItemEngines.resourceMissingListener` receive the same call.
 *      iOS and Android: `onResourceMissing`, `CYLAnimationEngines.resourceMissingListener`.
 * [CN] 动画引擎无法显示的文件：原因（各平台字符串相同）与按资源对每个条目只通知宿主一次的报告器（纯逻辑，用 Node 做单元测试：
 *      test/CYLAnimatedItemMissing.test.mjs）。`CYLAnimatedItemView.onResourceMissing` 与 `CYLAnimatedItemEngines.resourceMissingListener`
 *      收到同一次调用。
 */

/** [EN] The file does not exist. [CN] 文件不存在。 */
export const CYL_RESOURCE_NOT_FOUND: string = 'not found';
/** [EN] The file exists but cannot be read (empty, no permission). [CN] 文件存在但无法读取（为空、无权限）。 */
export const CYL_RESOURCE_UNREADABLE: string = 'unreadable';
/** [EN] The engine cannot decode the file (corrupt, wrong format). [CN] 引擎无法解码文件（已损坏、格式错误）。 */
export const CYL_RESOURCE_DECODE_FAILED: string = 'decode failed';
/** [EN] No engine for the file's type, or its native library is not built for this device. [CN] 没有该文件类型的引擎，或其原生库没有为本设备构建。 */
export const CYL_RESOURCE_ENGINE_LIBRARY_MISSING: string = 'engine library missing';

/** [EN] The callback shape of a missing resource. [CN] 资源缺失的回调形式。 */
export type CYLAnimatedItemResourceMissingCallback = (resource: string, reason: string) => void;

/**
 * [EN] The file name or path as configured: the `#` options of a source are not part of it. [CN] 按配置给出的文件名或路径：不含 source 的 `#` 选项。
 */
export function cylAnimatedItemResourceOf(url: string): string {
  const hash = url.indexOf('#');
  return hash < 0 ? url : url.substring(0, hash);
}

/**
 * [EN] One per item: calls the item's callback, then the global listener, once per resource. A callback that throws does not
 *      stop the other, and nothing crashes.
 * [CN] 每个条目一个：对每个资源只调用一次条目的回调，再调用全局监听。回调抛出异常不影响另一个，也不会崩溃。
 */
export class CYLAnimatedItemMissingReporter {
  private readonly reported: string[] = [];

  /** [EN] Returns whether it reported (false: the resource was already reported, or empty). [CN] 返回是否已报告（false：该资源已报告过，或为空）。 */
  report(resource: string, reason: string, callback?: CYLAnimatedItemResourceMissingCallback,
    listener?: CYLAnimatedItemResourceMissingCallback): boolean {
    if (resource.length === 0 || this.reported.includes(resource)) {
      return false;
    }
    this.reported.push(resource);
    try {
      callback?.(resource, reason);
    } catch (e) {
      // [EN] The host's callback failed: the global listener still hears it. [CN] 宿主的回调失败：全局监听仍会收到。
    }
    try {
      listener?.(resource, reason);
    } catch (e) {
      // [EN] Nothing to do. [CN] 无需处理。
    }
    return true;
  }
}
