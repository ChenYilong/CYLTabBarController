/**
 * [EN] cyldeallocblockexecutor: the HarmonyOS (ArkTS) port of the CYLDeallocBlockExecutor callback registry. Guide: docs/Lifecycle-Callbacks.md.
 * [CN] cyldeallocblockexecutor：CYLDeallocBlockExecutor 回调注册表的鸿蒙（ArkTS）移植。文档：docs/Lifecycle-Callbacks.md。
 */
export {
  CYLLifecycleCallbacks, CYLLifecycleCallback, CYLLifecycleEvent, CYLLifecycleInfo, cylLifecycleEventName,
  cylDeallocCallbackIllegalIdentifier
} from './src/main/ets/CYLLifecycleCallbacks';