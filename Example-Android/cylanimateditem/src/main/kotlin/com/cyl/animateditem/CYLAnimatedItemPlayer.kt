package com.cyl.animateditem

/**
 * [EN] The player of a `CYLAnimatedItemView`: one object over whatever engine plays its file, as HarmonyOS
 *      `CYLAnimatedItemPlayer` (`item.animatedItemPlayer`). It stays valid when the file or the engine changes. The
 *      `supports…` flags say what the engine of the file's type can do (Lottie: speed, progress, colors; PAG and SVGA:
 *      speed, progress; Rive: speed, colors; GIF: none of the three); `loops` works for every type. Nothing plays and
 *      nothing is stored while the item has no animation view.
 * [CN] `CYLAnimatedItemView` 的播放器：覆盖播放其文件的任何引擎的同一个对象，对应鸿蒙的 `CYLAnimatedItemPlayer`（`item.animatedItemPlayer`）。
 *      文件或引擎变化后仍然有效。`supports…` 标志说明文件类型的引擎能做什么（Lottie：速度、进度、颜色；PAG 与 SVGA：速度、进度；
 *      Rive：速度、颜色；GIF：这三项都不支持）；`loops` 对所有类型有效。条目没有动画视图时不播放也不保存任何值。
 */
class CYLAnimatedItemPlayer internal constructor(private val item: CYLAnimatedItemView) {

    private val type: String? get() = item.animationURL?.let { CYLAnimatedItemSource.parse(it).type }

    /**
     * [EN] Whether `speed` changes the playback of this file's type. [CN] `speed` 是否会改变该文件类型的播放。
     */
    val supportsSpeed: Boolean get() = type in setOf("Lottie", "PAG", "Rive", "SVGA")

    /**
     * [EN] Whether `loops` changes the playback (every type). [CN] `loops` 是否会改变播放（所有类型）。
     */
    val supportsLoops: Boolean get() = type != null

    /**
     * [EN] Whether `stopAtProgress` and `progress` work for this file's type. [CN] `stopAtProgress` 与 `progress` 是否对该文件类型有效。
     */
    val supportsProgress: Boolean get() = type in setOf("Lottie", "PAG", "SVGA")

    /**
     * [EN] Whether `applyColors` recolors this file's type. [CN] `applyColors` 是否能为该文件类型换色。
     */
    val supportsColors: Boolean get() = type in setOf("Lottie", "Rive")

    /**
     * [EN] The speed (1 by default); 0 or less keeps the file's own speed. [CN] 速度（默认 1）；0 或负数使用文件自身的速度。
     */
    var speed: Float
        get() = item.animationSpeed
        set(value) { item.animationSpeed = value }

    /**
     * [EN] Whether the animation loops. [CN] 动画是否循环。
     */
    var loops: Boolean
        get() = item.animationLoops
        set(value) { item.animationLoops = value }

    /**
     * [EN] Whether a pass is running now; null when the engine cannot tell. [CN] 当前是否正在播放；引擎无法判断时为 null。
     */
    val isPlaying: Boolean? get() = item.animationPlayer?.isPlaying

    /**
     * [EN] The progress (0 the first frame, 1 the last); 0 without an animation view. [CN] 进度（0 为首帧，1 为末帧）；没有动画视图时为 0。
     */
    val progress: Float get() = item.animationPlayer?.progress ?: 0f

    /**
     * [EN] Plays from the current progress (looping per `loops`). [CN] 从当前进度开始播放（是否循环由 `loops` 决定）。
     */
    fun play() = item.playAnimation()

    /**
     * [EN] Stops and shows `progress` (0 to 1) as a still frame. [CN] 停止并把 `progress`（0 到 1）显示为静止帧。
     */
    fun stopAtProgress(progress: Float) {
        item.animationRestingProgress = progress
        item.stopAnimation()
    }

    /**
     * [EN] Called when a pass that does not loop reaches its end; the same moment as `animationEndListener`. Set null to
     *      remove it. [CN] 不循环的一遍播放到结尾时调用，与 `animationEndListener` 同一时刻。设为 null 移除。
     */
    var onEnded: (() -> Unit)?
        get() = item.playerEndedCallback
        set(value) { item.playerEndedCallback = value }

    /**
     * [EN] Recolors the animation by layer name where the engine can (`supportsColors`); null restores its colors. [CN] 引擎支持时（`supportsColors`）按图层名称给动画换色；null 恢复原色。
     */
    fun applyColors(colors: Map<String, Int>?) {
        item.animationPlayer?.applyColors(colors, item.resources.configuration)
    }
}
