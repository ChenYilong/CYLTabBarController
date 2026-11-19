package com.cyl.animateditem

import android.graphics.Bitmap

/**
 * [EN] The frames of a GIF, composited (each frame is the full image as shown at its time), with their delays. Decoded by
 *      `CYLGIFDecoder`, so a GIF can be shown at any time on every Android version: `android.graphics.Movie` is deprecated
 *      and on recent versions (API 37) draws one frame whatever time it is given (B24).
 * [CN] GIF 的帧（已合成：每帧是该时刻显示的完整图像）及其延时。由 `CYLGIFDecoder` 解码，使 GIF 能在所有 Android 版本上显示任意时刻：
 *      `android.graphics.Movie` 已废弃，在较新版本（API 37）上无论给定什么时刻都只绘制一帧（B24）。
 */
class CYLGIFFrames internal constructor(
    val width: Int,
    val height: Int,
    /**
     * [EN] ARGB pixels of each frame, `width * height` each. [CN] 每帧的 ARGB 像素，各 `width * height` 个。
     */
    internal val pixels: List<IntArray>,
    /**
     * [EN] How long each frame shows, in ms. [CN] 每帧显示的时长（毫秒）。
     */
    val delays: IntArray,
) {
    /**
     * [EN] The number of frames. [CN] 帧数。
     */
    val frameCount: Int get() = pixels.size
    /**
     * [EN] The length of one pass, in ms. [CN] 一次播放的时长（毫秒）。
     */
    val duration: Int = delays.sum().coerceAtLeast(1)
    private val bitmaps = arrayOfNulls<Bitmap>(pixels.size)

    /**
     * [EN] The frame shown at `time` ms into a pass (clamped to the pass). [CN] 一次播放中第 `time` 毫秒显示的帧（限制在一次播放内）。
     */
    fun frameAt(time: Int): Int {
        var left = time.coerceIn(0, duration - 1)
        for (index in delays.indices) {
            if (left < delays[index]) return index
            left -= delays[index]
        }
        return delays.size - 1
    }

    /**
     * [EN] The bitmap of frame `index`, made on first use. [CN] 第 `index` 帧的位图，首次使用时创建。
     */
    fun bitmap(index: Int): Bitmap = bitmaps[index] ?: Bitmap.createBitmap(pixels[index], width, height, Bitmap.Config.ARGB_8888).also { bitmaps[index] = it }
}

/**
 * [EN] A small GIF87a / GIF89a decoder: LZW image data, local and global color tables, interlacing, transparency and the
 *      frame disposal methods. A frame delay of 10 ms or less shows for 100 ms, as browsers do.
 * [CN] 小型 GIF87a / GIF89a 解码器：LZW 图像数据、局部与全局颜色表、隔行扫描、透明色以及帧处置方式。10 毫秒或更短的帧延时按 100 毫秒显示，与浏览器相同。
 */
object CYLGIFDecoder {
    /**
     * [EN] Upper bound of pixels kept for all frames (about 256 MB as ARGB). [CN] 所有帧保留像素数的上限（ARGB 约 256 MB）。
     */
    private const val MAX_TOTAL_PIXELS = 64L * 1024 * 1024

    /**
     * [EN] The frames of GIF `bytes`, or null when they are not a GIF or hold no frame. [CN] GIF `bytes` 的帧；不是 GIF 或没有帧时为 null。
     */
    @JvmStatic
    fun decode(bytes: ByteArray): CYLGIFFrames? = try { Reader(bytes).read() } catch (error: RuntimeException) { null }

    /** [EN] The graphic control extension of the next frame. [CN] 下一帧的图形控制扩展。 */
    private class Control {
        var disposal = 0
        var delay = 0
        var transparent = -1
        fun reset() { disposal = 0; delay = 0; transparent = -1 }
    }

    /** [EN] The logical screen the frames are drawn on. [CN] 绘制各帧的逻辑屏幕。 */
    private class Canvas(val width: Int, val height: Int) {
        val pixels = IntArray(width * height)
    }

    /** [EN] One image descriptor with its color table and decoded indices. [CN] 一个图像描述符，及其颜色表与解码后的索引。 */
    private class Frame(val left: Int, val top: Int, val width: Int, val height: Int, val interlaced: Boolean, val table: IntArray, val indices: ByteArray)

    private class Reader(private val data: ByteArray) {
        private var position = 0
        private var globalTable: IntArray? = null

        private fun byte(): Int = if (position < data.size) data[position++].toInt() and 0xFF else throw IndexOutOfBoundsException("end of GIF")
        private fun short(): Int = byte() or (byte() shl 8)
        private fun colorTable(size: Int): IntArray = IntArray(size) { (0xFF shl 24) or (byte() shl 16) or (byte() shl 8) or byte() }
        private fun skipSubBlocks() { while (true) { val length = byte(); if (length == 0) return; position += length } }

        fun read(): CYLGIFFrames? {
            val canvas = readHeader() ?: return null
            val frames = ArrayList<IntArray>()
            val delays = ArrayList<Int>()
            val control = Control()
            while (position < data.size) {
                when (byte()) {
                    0x21 -> readExtension(control)
                    0x2C -> {
                        if ((frames.size + 1L) * canvas.width * canvas.height > MAX_TOTAL_PIXELS) break
                        val frame = readFrame() ?: return null
                        frames.add(compose(canvas, frame, control))
                        delays.add(if (control.delay <= 10) 100 else control.delay)
                        control.reset()
                    }
                    else -> break // [EN] 0x3B (the trailer) or an unknown block. [CN] 0x3B（结束块）或未知块。
                }
            }
            if (frames.isEmpty()) return null
            return CYLGIFFrames(canvas.width, canvas.height, frames, delays.toIntArray())
        }

        /**
         * [EN] The signature and the logical screen descriptor (with the global color table); null when not a GIF.
         * [CN] 签名与逻辑屏幕描述符（及全局颜色表）；不是 GIF 时为 null。
         */
        private fun readHeader(): Canvas? {
            if (data.size < 13) return null
            val signature = String(data, 0, 6, Charsets.US_ASCII)
            if (signature != "GIF87a" && signature != "GIF89a") return null
            position = 6
            val width = short()
            val height = short()
            if (width <= 0 || height <= 0) return null
            val packed = byte()
            byte() // [EN] Background color index: disposal 2 clears to transparent, as browsers do. [CN] 背景色索引：处置方式 2 清为透明，与浏览器相同。
            byte() // [EN] Pixel aspect ratio. [CN] 像素宽高比。
            globalTable = if (packed and 0x80 != 0) colorTable(1 shl ((packed and 7) + 1)) else null
            return Canvas(width, height)
        }

        /**
         * [EN] An extension block: a graphic control extension sets `control`; every other one is skipped.
         * [CN] 扩展块：图形控制扩展设置 `control`；其他扩展跳过。
         */
        private fun readExtension(control: Control) {
            if (byte() == 0xF9) {
                val size = byte()
                val flags = byte()
                control.disposal = (flags shr 2) and 7
                control.delay = short() * 10
                val index = byte()
                control.transparent = if (flags and 1 != 0) index else -1
                position += size - 4
            }
            skipSubBlocks()
        }

        /**
         * [EN] An image descriptor and its data; null when it has no color table at all.
         * [CN] 图像描述符及其数据；完全没有颜色表时为 null。
         */
        private fun readFrame(): Frame? {
            val left = short()
            val top = short()
            val width = short()
            val height = short()
            val flags = byte()
            val table = if (flags and 0x80 != 0) colorTable(1 shl ((flags and 7) + 1)) else globalTable ?: return null
            return Frame(left, top, width, height, flags and 0x40 != 0, table, lzw(byte(), width * height))
        }

        /**
         * [EN] Draws `frame` on `canvas`, returns the composed picture, then applies the frame's disposal.
         * [CN] 将 `frame` 绘制到 `canvas`，返回合成后的画面，然后执行该帧的处置方式。
         */
        private fun compose(canvas: Canvas, frame: Frame, control: Control): IntArray {
            val previous = if (control.disposal == 3) canvas.pixels.copyOf() else null
            draw(canvas, frame, control.transparent)
            val picture = canvas.pixels.copyOf()
            when (control.disposal) {
                2 -> clear(canvas, frame)
                3 -> previous?.copyInto(canvas.pixels)
            }
            return picture
        }

        private fun draw(canvas: Canvas, frame: Frame, transparent: Int) {
            val rows = if (frame.interlaced) interlacedRows(frame.height) else IntArray(frame.height) { it }
            for (pass in 0 until frame.height) {
                val y = frame.top + rows[pass]
                if (y !in 0 until canvas.height) continue
                for (x in 0 until frame.width) {
                    val canvasX = frame.left + x
                    if (canvasX !in 0 until canvas.width) continue
                    val index = frame.indices[pass * frame.width + x].toInt() and 0xFF
                    if (index == transparent || index >= frame.table.size) continue
                    canvas.pixels[y * canvas.width + canvasX] = frame.table[index]
                }
            }
        }

        /**
         * [EN] The image row of each stored row of an interlaced frame. [CN] 隔行帧中每个存储行对应的图像行。
         */
        private fun interlacedRows(height: Int): IntArray {
            val rows = IntArray(height)
            var stored = 0
            for ((start, step) in listOf(0 to 8, 4 to 8, 2 to 4, 1 to 2)) {
                var row = start
                while (row < height) { rows[stored++] = row; row += step }
            }
            return rows
        }

        private fun clear(canvas: Canvas, frame: Frame) {
            for (y in maxOf(0, frame.top) until minOf(canvas.height, frame.top + frame.height)) {
                for (x in maxOf(0, frame.left) until minOf(canvas.width, frame.left + frame.width)) canvas.pixels[y * canvas.width + x] = 0
            }
        }

        /**
         * [EN] Decodes LZW data (sub-blocks after the minimum code size) into `count` color indices.
         * [CN] 将 LZW 数据（最小码长之后的子块）解码为 `count` 个颜色索引。
         */
        private fun lzw(minimumCodeSize: Int, count: Int): ByteArray {
            val out = ByteArray(count)
            // [EN] The sub-blocks joined. [CN] 合并子块。
            val stream = java.io.ByteArrayOutputStream()
            while (true) {
                val length = byte()
                if (length == 0) break
                stream.write(data, position, minOf(length, data.size - position))
                position += length
            }
            if (minimumCodeSize !in 1..11) return out
            return LzwDecoder(stream.toByteArray(), minimumCodeSize, out).decode()
        }
    }

    /**
     * [EN] The LZW decoder of one frame: reads variable-width codes from `codes` and writes color indices into `out`.
     * [CN] 一帧的 LZW 解码器：从 `codes` 读取变长码，并将颜色索引写入 `out`。
     */
    private class LzwDecoder(private val codes: ByteArray, private val minimumCodeSize: Int, private val out: ByteArray) {
        private val clear = 1 shl minimumCodeSize
        private val end = clear + 1
        private val prefix = IntArray(4096)
        private val suffix = ByteArray(4096)
        private val stack = ByteArray(4097)
        private var codeSize = minimumCodeSize + 1
        private var next = clear + 2
        private var old = -1
        private var first = 0
        private var written = 0
        private var bits = 0
        private var bitCount = 0
        private var index = 0

        init {
            for (code in 0 until clear) suffix[code] = code.toByte()
        }

        fun decode(): ByteArray {
            while (written < out.size) {
                val code = readCode()
                if (code < 0 || code == end) break
                if (code == clear) {
                    codeSize = minimumCodeSize + 1
                    next = clear + 2
                    old = -1
                    continue
                }
                val decoded = if (old == -1) writeFirst(code) else writeSequence(code)
                if (!decoded) break
                old = code
            }
            return out
        }

        /** [EN] The next code, or -1 when the data ends. [CN] 下一个码；数据结束时为 -1。 */
        private fun readCode(): Int {
            while (bitCount < codeSize && index < codes.size) {
                bits = bits or ((codes[index++].toInt() and 0xFF) shl bitCount)
                bitCount += 8
            }
            if (bitCount < codeSize) return -1
            val code = bits and ((1 shl codeSize) - 1)
            bits = bits ushr codeSize
            bitCount -= codeSize
            return code
        }

        /** [EN] The first code after a clear: a literal index. [CN] 清除码之后的第一个码：一个字面索引。 */
        private fun writeFirst(code: Int): Boolean {
            if (code >= clear) return false
            out[written++] = code.toByte()
            first = code
            return true
        }

        /** [EN] A code from the table (or the next one), written out, then added to the table. [CN] 表中的码（或下一个码），写出后加入表中。 */
        private fun writeSequence(code: Int): Boolean {
            var current = code
            var top = 0
            if (code >= next) {
                stack[top++] = first.toByte()
                current = old
            }
            while (current >= clear) {
                if (top >= stack.size - 1 || current >= 4096) return false
                stack[top++] = suffix[current]
                current = prefix[current]
            }
            first = suffix[current].toInt() and 0xFF
            stack[top++] = first.toByte()
            while (top > 0 && written < out.size) out[written++] = stack[--top]
            if (next < 4096) {
                prefix[next] = old
                suffix[next] = first.toByte()
                next++
                if (next == (1 shl codeSize) && codeSize < 12) codeSize++
            }
            return true
        }
    }
}
