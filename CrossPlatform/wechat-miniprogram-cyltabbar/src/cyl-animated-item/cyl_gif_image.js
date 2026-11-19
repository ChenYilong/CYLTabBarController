/**
 * [EN] A small GIF reader for a GIF given as an item's image (not the GIF animation type): the mini program `<image>` loops
 *      a GIF and cannot stop it, so the item draws the first frame on a canvas while resting and shows the `<image>` only
 *      while playing (docs/GIF-Animation.md, as iOS 915bddbd, Android `CYLGIFDrawable`, HarmonyOS `CYLGIFImagePlayback`).
 *      `cylGIFImageInfo(bytes)` returns the logical size, the play time (the sum of the frame delays, 100 ms for a 0 delay)
 *      and the first frame as RGBA pixels; null when the bytes are not a GIF it can read. Pure JavaScript, tested in
 *      test/cyl_gif_image.test.js.
 * [CN] 作为条目图片传入的 GIF（不是 GIF 动画类型）的简易读取器：小程序 `<image>` 会循环播放 GIF 且无法停止，因此条目静止时在 canvas 上绘制
 *      第一帧，只在播放时显示 `<image>`（docs/GIF-Animation.md，与 iOS 915bddbd、Android `CYLGIFDrawable`、鸿蒙 `CYLGIFImagePlayback` 一致）。
 *      `cylGIFImageInfo(bytes)` 返回逻辑尺寸、播放时长（各帧延时之和，延时为 0 时按 100 毫秒）以及第一帧的 RGBA 像素；不是可读取的 GIF 时
 *      返回 null。纯 JavaScript，测试见 test/cyl_gif_image.test.js。
 */

/** [EN] Whether a path or URL is a GIF (".gif" before any query or fragment). [CN] 路径或 URL 是否为 GIF。 */
function cylIsGIFImagePath(path) {
  if (typeof path !== 'string' || !path) return false
  return path.split('#')[0].split('?')[0].toLowerCase().endsWith('.gif')
}

function cylReadColorTable(bytes, offset, size) {
  const table = []
  for (let i = 0; i < size; i++) {
    table.push([bytes[offset + i * 3], bytes[offset + i * 3 + 1], bytes[offset + i * 3 + 2]])
  }
  return table
}

/** [EN] The LZW dictionary after a clear code. [CN] 清除码之后的 LZW 字典。 */
function cylLZWInitialDictionary(clear, end) {
  const dictionary = []
  for (let i = 0; i < clear; i++) dictionary[i] = [i]
  dictionary[clear] = []
  dictionary[end] = null
  return dictionary
}

/**
 * [EN] The entry of `code`, adding the next dictionary entry; null when the data is corrupt (an unknown code without a previous one).
 * [CN] `code` 对应的条目，并添加下一个字典项；数据损坏（没有前一项却出现未知码）时返回 null。
 */
function cylLZWEntryForCode(dictionary, code, previous) {
  if (code < dictionary.length && dictionary[code]) {
    const entry = dictionary[code]
    if (previous) dictionary.push(previous.concat([entry[0]]))
    return entry
  }
  if (!previous) return null
  const entry = previous.concat([previous[0]])
  dictionary.push(entry)
  return entry
}

/** [EN] The code size after the dictionary grew: one bit more when full, up to 12. [CN] 字典增长后的码长：字典满时加一位，最多 12 位。 */
function cylLZWCodeSize(dictionaryLength, codeSize) {
  return dictionaryLength === (1 << codeSize) && codeSize < 12 ? codeSize + 1 : codeSize
}

/** [EN] Writes `entry` into `output` from `position`, as far as it fits; returns the new position. [CN] 把 `entry` 写入 `output`，写到容量为止；返回新位置。 */
function cylLZWWrite(output, position, entry) {
  let out = position
  for (let k = 0; k < entry.length && out < output.length; k++) output[out++] = entry[k]
  return out
}

/** [EN] LZW decode of one image's sub-blocks into color indices. [CN] 将一帧的数据子块按 LZW 解码为颜色下标。 */
function cylLZWDecode(data, minCodeSize, pixelCount) {
  const clear = 1 << minCodeSize
  const end = clear + 1
  const output = new Uint8Array(pixelCount)
  let codeSize = minCodeSize + 1
  let dictionary = cylLZWInitialDictionary(clear, end)
  let bitBuffer = 0
  let bitCount = 0
  let previous = null
  let out = 0
  for (let i = 0; i < data.length && out < pixelCount; i++) {
    bitBuffer |= data[i] << bitCount
    bitCount += 8
    while (bitCount >= codeSize && out < pixelCount) {
      const code = bitBuffer & ((1 << codeSize) - 1)
      bitBuffer >>= codeSize
      bitCount -= codeSize
      if (code === clear) {
        dictionary = cylLZWInitialDictionary(clear, end)
        codeSize = minCodeSize + 1
        previous = null
        continue
      }
      if (code === end) return output
      const entry = cylLZWEntryForCode(dictionary, code, previous)
      if (!entry) return output
      out = cylLZWWrite(output, out, entry)
      previous = entry
      codeSize = cylLZWCodeSize(dictionary.length, codeSize)
    }
  }
  return output
}

/** [EN] A little-endian 16 bit value. [CN] 小端 16 位值。 */
function cylReadU16(bytes, offset) {
  return bytes[offset] | (bytes[offset + 1] << 8)
}

/** [EN] The bytes of a GIF input. [CN] GIF 输入的字节。 */
function cylGIFBytes(input) {
  return input instanceof Uint8Array ? input : new Uint8Array(input || [])
}

/**
 * [EN] The signature, the logical size and the global color table; `offset` is where the blocks start. Null when it is not a GIF.
 * [CN] 签名、逻辑尺寸与全局颜色表；`offset` 是数据块的起点。不是 GIF 时为 null。
 */
function cylReadGIFHeader(bytes) {
  if (bytes.length < 13) return null
  const signature = String.fromCodePoint(bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5])
  if (signature !== 'GIF87a' && signature !== 'GIF89a') return null
  const width = cylReadU16(bytes, 6)
  const height = cylReadU16(bytes, 8)
  if (!width || !height) return null
  const flags = bytes[10]
  let offset = 13
  let globalTable = null
  if (flags & 0x80) {
    const size = 1 << ((flags & 0x07) + 1)
    globalTable = cylReadColorTable(bytes, offset, size)
    offset += size * 3
  }
  return { width, height, globalTable, offset }
}

/** [EN] The offset after the data sub-blocks that start at `offset` and their terminator. [CN] 从 `offset` 开始的数据子块及其结束符之后的位置。 */
function cylSkipSubBlocks(bytes, offset) {
  let position = offset
  while (position < bytes.length && bytes[position] !== 0) position += bytes[position] + 1
  return position + 1
}

/** [EN] The delay (ms) and the transparent color index of a graphic control extension at `offset`; null when it is too short. [CN] `offset` 处图形控制扩展的延时（毫秒）与透明色下标；太短时为 null。 */
function cylReadGraphicControl(bytes, offset) {
  if (bytes[offset] >= 4) {
    return { delay: cylReadU16(bytes, offset + 2) * 10, transparent: (bytes[offset + 1] & 0x01) ? bytes[offset + 4] : -1 }
  }
  return null
}

/**
 * [EN] One image block at `offset` (after the 0x2C): its place, its color table (the local one, else the global one), the LZW data and the
 *      offset after the block. [CN] `offset` 处的一个图像块（0x2C 之后）：位置、颜色表（局部表，否则全局表）、LZW 数据以及块之后的位置。
 */
function cylReadGIFImage(bytes, offset, globalTable) {
  const image = {
    left: cylReadU16(bytes, offset), top: cylReadU16(bytes, offset + 2),
    w: cylReadU16(bytes, offset + 4), h: cylReadU16(bytes, offset + 6),
    flags: bytes[offset + 8], table: globalTable,
  }
  let position = offset + 9
  if (image.flags & 0x80) {
    const size = 1 << ((image.flags & 0x07) + 1)
    image.table = cylReadColorTable(bytes, position, size)
    position += size * 3
  }
  image.minCodeSize = bytes[position++]
  const chunks = []
  let length = 0
  while (position < bytes.length && bytes[position] !== 0) {
    const size = bytes[position]
    chunks.push(bytes.subarray(position + 1, position + 1 + size))
    length += size
    position += size + 1
  }
  image.data = new Uint8Array(length)
  let at = 0
  chunks.forEach((chunk) => { image.data.set(chunk, at); at += chunk.length })
  image.offset = position + 1
  return image
}

/** [EN] The row order of an image: interlaced images store every 8th row first, then every 8th from 4, every 4th from 2, every 2nd from 1. [CN] 图像的行顺序：隔行图像先存每 8 行的第 0 行，再是从 4 开始每 8 行、从 2 开始每 4 行、从 1 开始每 2 行。 */
function cylGIFRowOrder(height, interlaced) {
  const rows = []
  const passes = interlaced ? [[0, 8], [4, 8], [2, 4], [1, 2]] : [[0, 1]]
  passes.forEach(([start, step]) => { for (let y = start; y < height; y += step) rows.push(y) })
  return rows
}

/** [EN] The RGBA first frame (width * height * 4) of `image` on the logical screen; `transparent` is the transparent color index. [CN] `image` 在逻辑画面上的 RGBA 第一帧；`transparent` 为透明色下标。 */
function cylRenderGIFFrame(image, width, height, transparent) {
  const indices = cylLZWDecode(image.data, image.minCodeSize, image.w * image.h)
  const frame = new Uint8ClampedArray(width * height * 4)
  cylGIFRowOrder(image.h, (image.flags & 0x40) !== 0).forEach((y, row) => {
    for (let x = 0; x < image.w; x++) {
      const index = indices[row * image.w + x]
      const px = image.left + x
      const py = image.top + y
      if (index === transparent || px >= width || py >= height) continue
      const color = image.table[index] || [0, 0, 0]
      const at = (py * width + px) * 4
      frame[at] = color[0]
      frame[at + 1] = color[1]
      frame[at + 2] = color[2]
      frame[at + 3] = 255
    }
  })
  return frame
}

/** [EN] The result of `cylGIFImageInfo`; null without a frame. [CN] `cylGIFImageInfo` 的结果；没有帧时为 null。 */
function cylGIFResult(width, height, duration, frame) {
  return frame ? { width, height, duration: duration || 100, frame } : null
}

/**
 * [EN] The logical width and height, the play time (ms) and the first frame (RGBA, width * height * 4) of a GIF.
 * [CN] GIF 的逻辑宽高、播放时长（毫秒）与第一帧（RGBA，width * height * 4）。
 */
function cylGIFImageInfo(input) {
  const bytes = cylGIFBytes(input)
  const header = cylReadGIFHeader(bytes)
  if (!header) return null
  const { width, height } = header
  let offset = header.offset
  let duration = 0
  let delay = 0
  let transparent = -1
  let frame = null
  while (offset < bytes.length) {
    const block = bytes[offset++]
    if (block === 0x3B) break
    if (block === 0x21) {
      const label = bytes[offset++]
      const control = label === 0xF9 ? cylReadGraphicControl(bytes, offset) : null
      if (control) ({ delay, transparent } = control)
      offset = cylSkipSubBlocks(bytes, offset)
      continue
    }
    if (block !== 0x2C) return cylGIFResult(width, height, duration, frame)
    const image = cylReadGIFImage(bytes, offset, header.globalTable)
    offset = image.offset
    duration += delay > 0 ? delay : 100
    if (!frame && image.table) frame = cylRenderGIFFrame(image, width, height, transparent)
    delay = 0
    transparent = -1
  }
  return cylGIFResult(width, height, duration, frame)
}

module.exports = { cylIsGIFImagePath, cylGIFImageInfo }
