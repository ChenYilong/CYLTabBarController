/**
 * [EN] The player of one cyl-animated-item (`item.cylAnimatedItemPlayer()`): the mini program counterpart of HarmonyOS
 *      `CYLAnimatedItemPlayer` (`cylanimateditem/src/main/ets/CYLAnimatedItemPlayer.ts`, the reference of the engine contract
 *      in docs/Animated-Item.md, "Engine API across platforms"). A host that drives playback itself (a tag's resting
 *      progress, Play all) sets `drivesAnimationPlayback` to false and plays through it. Pure JavaScript without any wx API,
 *      tested in Node (test/cyl_animated_item_player.test.js).
 *      One player lives as long as its item; it looks the engine component up on every call, so a new file or a swapped
 *      engine never leaves it stale. What an engine cannot do it says (`supportsSpeed`, `supportsLoops`, `supportsProgress`,
 *      `supportsColors`) and the call is a no-op. The answers come from the animation type, so they are right before the
 *      engine is ready; `play()` before `animationready` is kept and happens when the file is ready.
 *      It is built over what the engine components already expose: `cylPlayFromStart`, `cylPause`, `cylSetProgress`
 *      (Lottie: `cylGoToAndStop`), `cylStop` and `cylSetSpeed` (through the item: `playAnimation()`, `cylStopAtProgress()`,
 *      and the item's `speed`, `loop` and `colors` properties, which the item hands to the engine).
 * [CN] 一个 cyl-animated-item 的播放器（`item.cylAnimatedItemPlayer()`）：对应鸿蒙的 `CYLAnimatedItemPlayer`
 *      （`cylanimateditem/src/main/ets/CYLAnimatedItemPlayer.ts`，docs/Animated-Item.md「Engine API across platforms」中引擎约定的基准）。
 *      自行驱动播放的宿主（标签的静止进度、全部播放）把 `drivesAnimationPlayback` 设为 false，并通过它播放。纯 JavaScript，不使用任何
 *      wx API，在 Node 中测试（test/cyl_animated_item_player.test.js）。
 *      一个播放器与其条目同寿命；每次调用都会重新查找引擎组件，因此换文件或换引擎后不会过期。引擎做不到的事通过 `supportsSpeed`、
 *      `supportsLoops`、`supportsProgress`、`supportsColors` 说明，调用则为空操作。答案取决于动画类型，因此在引擎就绪之前就是正确的；
 *      `animationready` 之前调用 `play()` 会被保留，文件就绪后再播放。
 *      它建立在引擎组件已有的方法之上：`cylPlayFromStart`、`cylPause`、`cylSetProgress`（Lottie 为 `cylGoToAndStop`）、`cylStop` 与
 *      `cylSetSpeed`（通过条目：`playAnimation()`、`cylStopAtProgress()`，以及条目交给引擎的 `speed`、`loop`、`colors` 属性）。
 */

/**
 * [EN] What each animation type can do, as the engine packages implement it (docs/Animated-Item.md): `progress` is a seek
 *      (`cylSetProgress`, or Lottie's `cylGoToAndStop`; Rive has none and rests through `cylStop`), `speed` is
 *      `cylSetSpeed`, `colors` the engine's `colors` property (Lottie keypaths, Rive view model colors). GIF is drawn by
 *      `<image>`: no speed, no seek; a GIF with stills plays one pass and loops, which the item times itself.
 * [CN] 每种动画类型能做什么，与各引擎包的实现一致（docs/Animated-Item.md）：`progress` 为跳转（`cylSetProgress`，或 Lottie 的
 *      `cylGoToAndStop`；Rive 没有，通过 `cylStop` 静止），`speed` 为 `cylSetSpeed`，`colors` 为引擎的 `colors` 属性（Lottie 的
 *      keypath、Rive 的 view model 颜色）。GIF 由 `<image>` 绘制：没有速度、没有跳转；有静帧的 GIF 播放一遍并可循环，由条目自己计时。
 */
const CYL_PLAYER_CAPABILITIES = {
  lottie: { progress: true, speed: true, colors: true },
  pag: { progress: true, speed: true, colors: false },
  rive: { progress: false, speed: true, colors: true },
  svga: { progress: true, speed: true, colors: false },
  gif: { progress: false, speed: false, colors: false },
}

/**
 * [EN] The colors as the item's `colors` property wants them: an object keypath (Lottie) or view model property (Rive) ->
 *      color ("#RRGGBB" or "#AARRGGBB"). A `Map` (the HarmonyOS type) or an object; null / undefined / empty: null, which
 *      restores the file's own colors.
 * [CN] 条目 `colors` 属性所需的颜色：对象，keypath（Lottie）或 view model 属性（Rive）-> 颜色（"#RRGGBB" 或 "#AARRGGBB"）。
 *      接受 `Map`（鸿蒙的类型）或对象；null / undefined / 空对象为 null，恢复文件自身的颜色。
 */
function cylPlayerColors(colors) {
  if (!colors) return null
  const entries = colors instanceof Map ? [...colors.entries()] : Object.entries(colors)
  return entries.length > 0 ? Object.fromEntries(entries) : null
}

/**
 * [EN] The handle a host plays an item through. `host` is what the item gives it (an adapter, so no component is needed in a
 *      test): `engine()` the engine component or null, `type()` the animation type ('lottie', 'pag', 'rive', 'svga', 'gif' or
 *      ''), `usesLoop()` whether the item can loop this file (an engine, a GIF with stills or a GIF image), `get(name)` and
 *      `set(patch)` for the item's `speed`, `loop` and `colors`, `isPlaying()`, `play()` and `stopAtProgress(progress)`.
 * [CN] 宿主用来播放条目的句柄。`host` 由条目提供（一个适配器，测试中无需组件）：`engine()` 为引擎组件或 null，`type()` 为动画类型
 *      （'lottie'、'pag'、'rive'、'svga'、'gif' 或 ''），`usesLoop()` 为条目能否循环该文件（引擎、有静帧的 GIF 或 GIF 图片），
 *      `get(name)` 与 `set(patch)` 读写条目的 `speed`、`loop`、`colors`，以及 `isPlaying()`、`play()` 与 `stopAtProgress(progress)`。
 */
class CYLAnimatedItemPlayer {
  constructor(host) {
    this.cylHost = host
    this.cylEndedCallback = null
  }

  /** [EN] The animation type ('lottie', 'pag', 'rive', 'svga', 'gif'), '' without an animation. [CN] 动画类型，没有动画时为 ''。 */
  get type() {
    return this.cylHost.type() || ''
  }

  /** [EN] Whether `speed` takes effect (every engine but GIF). [CN] `speed` 是否生效（除 GIF 外的所有引擎）。 */
  get supportsSpeed() {
    const capabilities = CYL_PLAYER_CAPABILITIES[this.type]
    return !!capabilities && capabilities.speed
  }

  /** [EN] Whether `loops` takes effect. [CN] `loops` 是否生效。 */
  get supportsLoops() {
    return !!this.cylHost.usesLoop()
  }

  /** [EN] Whether `stopAtProgress` can stop on any frame (false: it rests on the first or last one, as the item does). [CN] `stopAtProgress` 能否停在任意帧（false：停在第一帧或最后一帧，与条目相同）。 */
  get supportsProgress() {
    const capabilities = CYL_PLAYER_CAPABILITIES[this.type]
    return !!capabilities && capabilities.progress
  }

  /** [EN] Whether `applyColors` recolors the animation (Lottie and Rive). [CN] `applyColors` 能否改色（Lottie 与 Rive）。 */
  get supportsColors() {
    const capabilities = CYL_PLAYER_CAPABILITIES[this.type]
    return !!capabilities && capabilities.colors
  }

  /** [EN] The playback speed (1 is the file's own). [CN] 播放速度（1 为文件自身速度）。 */
  get speed() {
    const speed = Number(this.cylHost.get('speed'))
    return speed > 0 ? speed : 1
  }

  /** [EN] Applied at once, also while playing (0 or less: 1); a no-op without `supportsSpeed`. [CN] 立即生效，播放中也一样（0 或更小为 1）；没有 `supportsSpeed` 时为空操作。 */
  set speed(value) {
    if (!this.supportsSpeed) return
    const speed = Number(value)
    this.cylHost.set({ speed: speed > 0 ? speed : 1 })
  }

  /** [EN] Whether a pass repeats. [CN] 一遍播放结束后是否重复。 */
  get loops() {
    return !!this.cylHost.get('loop')
  }

  /** [EN] Applied at once: turning it off lets the pass in progress finish; a no-op without `supportsLoops`. [CN] 立即生效：关闭时当前这一遍播放完；没有 `supportsLoops` 时为空操作。 */
  set loops(value) {
    if (!this.supportsLoops) return
    this.cylHost.set({ loop: !!value })
  }

  /** [EN] True from `play()` until `stopAtProgress` or the end of a play-once pass; a looping animation stays true. [CN] 从 `play()` 到 `stopAtProgress` 或只播放一次的一遍结束为 true；循环动画保持为 true。 */
  get isPlaying() {
    return !!this.cylHost.isPlaying()
  }

  /** [EN] Plays from progress 0 once (a file still loading plays when ready). [CN] 从进度 0 播放一次（仍在加载的文件就绪后播放）。 */
  play() {
    this.cylHost.play()
  }

  /**
   * [EN] Stops at `progress` (0...1; 1 is the last frame). Without `supportsProgress` it rests on the first frame (below 1)
   *      or the last (1 or more), the way the item rests.
   * [CN] 停在 `progress`（0...1；1 为最后一帧）。没有 `supportsProgress` 时停在第一帧（小于 1）或最后一帧（1 或更大），与条目静止时相同。
   */
  stopAtProgress(progress) {
    const value = Number(progress)
    this.cylHost.stopAtProgress(Number.isFinite(value) ? Math.min(1, Math.max(0, value)) : 0)
  }

  /**
   * [EN] Registers the callback of the end of a play-once pass (`loops` off; not after `stopAtProgress`); a GIF image without
   *      stills never reports it. Returns a function that removes it. One callback: the next call replaces it; null clears it.
   * [CN] 注册只播放一次（`loops` 关闭；`stopAtProgress` 之后不触发）的一遍播放结束时的回调；没有静帧的 GIF 图片从不触发。
   *      返回移除该回调的函数。只有一个回调：再次调用会替换它；传 null 清除。
   */
  onEnded(callback) {
    const registered = typeof callback === 'function' ? callback : null
    this.cylEndedCallback = registered
    return () => {
      if (this.cylEndedCallback === registered) this.cylEndedCallback = null
    }
  }

  /**
   * [EN] Recolors the animation: keypath (Lottie) or view model property (Rive) -> color, as a `Map` or an object; undefined,
   *      null or empty restores the file's own colors. A no-op without `supportsColors`.
   * [CN] 为动画改色：keypath（Lottie）或 view model 属性（Rive）-> 颜色，`Map` 或对象；undefined、null 或空时恢复文件自身的颜色。
   *      没有 `supportsColors` 时为空操作。
   */
  applyColors(colors) {
    if (!this.supportsColors) return
    this.cylHost.set({ colors: cylPlayerColors(colors) })
  }

  /** [EN] For the item: a play-once pass ended. [CN] 供条目调用：只播放一次的一遍播放结束。 */
  didEnd() {
    if (this.cylEndedCallback) this.cylEndedCallback()
  }

  /** [EN] For the item when it goes away: drops the callback. [CN] 条目消失时由条目调用：丢弃回调。 */
  destroy() {
    this.cylEndedCallback = null
  }
}

module.exports = { CYLAnimatedItemPlayer, CYL_PLAYER_CAPABILITIES, cylPlayerColors }
