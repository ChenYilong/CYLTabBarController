// [EN] cylutils: the bottom layer of the HarmonyOS modules (docs/Animated-Item-Badge-CrossPlatform.md, D8). The only module that depends on the lifecycle
//      library (`cyldeallocblockexecutor`); it re-exports it, so every other module imports `LifecycleController` and the rest from 'cylutils'.
// [CN] cylutils：鸿蒙各模块的最底层（docs/Animated-Item-Badge-CrossPlatform.md，D8）。唯一依赖生命周期库（`cyldeallocblockexecutor`）的模块；它重新导出该库，
//      因此其他模块都从 'cylutils' 导入 `LifecycleController` 等。
export * from 'cyldeallocblockexecutor';
