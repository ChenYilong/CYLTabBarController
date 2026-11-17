package com.cyl.animateditem

/**
 * [EN] CGSize. [CN] 尺寸。
 */
data class CYLSize(val width: Float, val height: Float) {
    companion object {
        @JvmField val zero = CYLSize(0f, 0f)
    }
}

/**
 * [EN] UIOffset. [CN] 偏移。
 */
data class CYLOffset(val horizontal: Float, val vertical: Float) {
    companion object {
        @JvmField val zero = CYLOffset(0f, 0f)
    }
}
