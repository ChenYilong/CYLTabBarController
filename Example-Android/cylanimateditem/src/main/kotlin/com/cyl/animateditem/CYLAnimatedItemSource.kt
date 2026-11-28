package com.cyl.animateditem

/**
 * [EN] An animation source split into its file and its `#` / `?` options: the Android counterpart of HarmonyOS
 *      `CYLAnimatedItemSource` (`cylAnimatedItemFileAndOptions`). The test vectors are shared by every platform:
 *      `CrossPlatform/animated-item-fixtures/source-options.json`.
 * [CN] 拆成文件与 `#` / `?` 选项的动画来源：对应鸿蒙的 `CYLAnimatedItemSource`（`cylAnimatedItemFileAndOptions`）。各平台共用测试向量：
 *      `CrossPlatform/animated-item-fixtures/source-options.json`。
 */
data class CYLAnimatedItemSource(
    /**
     * [EN] The file without the `asset:` prefix and the options; empty for inline JSON. [CN] 去掉 `asset:` 前缀与选项的文件；内联 JSON 时为空。
     */
    val file: String,
    /**
     * [EN] "Lottie", "PAG", "Rive", "SVGA" or "GIF" from the file extension (inline JSON is "Lottie"); null when unknown. [CN] 由扩展名得到的类型（内联 JSON 为 "Lottie"）；未知时为 null。
     */
    val type: String?,
    /**
     * [EN] The options, in source order, names and values percent-decoded. [CN] 选项，按出现顺序，名称与值已做百分号解码。
     */
    val options: Map<String, String>,
    /**
     * [EN] The text when the source is inline Lottie JSON (it starts with `{`), else null. [CN] 来源是内联 Lottie JSON（以 `{` 开头）时的文本，否则为 null。
     */
    val inlineJSON: String? = null,
) {
    companion object {
        /**
         * [EN] Parses `input`. Options follow the first `#` or `?`; pairs are split at `&`, and at a `#` or `?` that does not
         *      follow `=`; a pair without a name is dropped; an undecodable text is kept as it is.
         * [CN] 解析 `input`。选项在第一个 `#` 或 `?` 之后；键值对以 `&` 分隔，也在不紧跟 `=` 的 `#` 或 `?` 处分隔；没有名称的键值对被丢弃；无法解码的文本保持原样。
         */
        @JvmStatic
        fun parse(input: String): CYLAnimatedItemSource {
            val text = input.trim()
            if (text.startsWith("{")) return CYLAnimatedItemSource("", "Lottie", emptyMap(), text)
            val start = text.indexOfFirst { it == '#' || it == '?' }
            val file = (if (start < 0) text else text.substring(0, start)).removePrefix("asset:")
            val options = LinkedHashMap<String, String>()
            if (start >= 0) {
                for (pair in splitPairs(text, start)) {
                    val equals = pair.indexOf('=')
                    if (equals <= 0) continue
                    options[decode(pair.substring(0, equals))] = decode(pair.substring(equals + 1))
                }
            }
            return CYLAnimatedItemSource(file, CYLAnimationEngines.typeOf(null, file), options)
        }

        private fun splitPairs(text: String, start: Int): List<String> {
            val pairs = ArrayList<String>()
            val current = StringBuilder()
            for (index in start + 1 until text.length) {
                val character = text[index]
                val splits = character == '&' || ((character == '#' || character == '?') && text[index - 1] != '=')
                if (splits) { pairs.add(current.toString()); current.setLength(0) } else current.append(character)
            }
            pairs.add(current.toString())
            return pairs
        }

        private fun decode(text: String): String = try {
            val bytes = java.io.ByteArrayOutputStream()
            var index = 0
            while (index < text.length) {
                val character = text[index]
                if (character == '%') {
                    bytes.write(text.substring(index + 1, index + 3).toInt(16))
                    index += 3
                } else {
                    bytes.write(character.toString().toByteArray(Charsets.UTF_8))
                    index += 1
                }
            }
            val decoder = Charsets.UTF_8.newDecoder()
            decoder.decode(java.nio.ByteBuffer.wrap(bytes.toByteArray())).toString()
        } catch (error: RuntimeException) { text } catch (error: java.nio.charset.CharacterCodingException) { text }
    }
}
