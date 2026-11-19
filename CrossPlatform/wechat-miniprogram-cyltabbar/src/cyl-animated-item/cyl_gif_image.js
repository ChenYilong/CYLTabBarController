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

/** [EN] LZW decode of one image's sub-blocks into color indices. [CN] 将一帧的数据子块按 LZW 解码为颜色下标。 */
function cylLZWDecode(data, minCodeSize, pixelCount) {
  const clear = 1 << minCodeSize
  const end = clear + 1
  const output = new Uint8Array(pixelCount)
  let codeSize = minCodeSize + 1
  let dictionary = []
  const reset = () => {
    dictionary = []
    for (let i = 0; i < clear; i++) dictionary[i] = [i]
    dictionary[clear] = []
    dictionary[end] = null
    codeSize = minCodeSize + 1
  }
  reset()
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
        reset()
        previous = null
        continue
      }
      if (code === end) return output
      let entry
      if (code < dictionary.length && dictionary[code]) {
        entry = dictionary[code]
        if (previous) dictionary.push(previous.concat([entry[0]]))
      } else if (previous) {
        entry = previous.concat([previous[0]])
        dictionary.push(entry)
      } else {
        return output
      }
      for (let k = 0; k < entry.length && out < pixelCount; k++) output[out++] = entry[k]
      previous = entry
      if (dictionary.length === (1 << codeSize) && codeSize < 12) codeSize += 1
    }
  }
  return output
}

/**
 * [EN] The logical width and height, the play time (ms) and the first frame (RGBA, width * height * 4) of a GIF.
 * [CN] GIF 的逻辑宽高、播放时长（毫秒）与第一帧（RGBA，width * height * 4）。
 */
function cylGIFImageInfo(input) {
  const bytes = input instanceof Uint8Array ? input : new Uint8Array(input || [])
  if (bytes.length < 13) return null
  const signature = String.fromCharCode(bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5])
  if (signature !== 'GIF87a' && signature !== 'GIF89a') return null
  const width = bytes[6] | (bytes[7] << 8)
  const height = bytes[8] | (bytes[9] << 8)
  if (!width || !height) return null
  const flags = bytes[10]
  let offset = 13
  let globalTable = null
  if (flags & 0x80) {
    const size = 1 << ((flags & 0x07) + 1)
    globalTable = cylReadColorTable(bytes, offset, size)
    offset += size * 3
  }
  let duration = 0
  let delay = 0
  let transparent = -1
  let frame = null
  while (offset < bytes.length) {
    const block = bytes[offset++]
    if (block === 0x3B) break
    if (block === 0x21) {
      const label = bytes[offset++]
      if (label === 0xF9 && bytes[offset] >= 4) {
        const packed = bytes[offset + 1]
        delay = (bytes[offset + 2] | (bytes[offset + 3] << 8)) * 10
        transparent = (packed & 0x01) ? bytes[offset + 4] : -1
      }
      while (offset < bytes.length && bytes[offset] !== 0) offset += bytes[offset] + 1
      offset += 1
      continue
    }
    if (block !== 0x2C) return frame ? { width, height, duration: duration || 100, frame } : null
    const left = bytes[offset] | (bytes[offset + 1] << 8)
    const top = bytes[offset + 2] | (bytes[offset + 3] << 8)
    const w = bytes[offset + 4] | (bytes[offset + 5] << 8)
    const h = bytes[offset + 6] | (bytes[offset + 7] << 8)
    const imageFlags = bytes[offset + 8]
    offset += 9
    let table = globalTable
    if (imageFlags & 0x80) {
      const size = 1 << ((imageFlags & 0x07) + 1)
      table = cylReadColorTable(bytes, offset, size)
      offset += size * 3
    }
    const minCodeSize = bytes[offset++]
    const chunks = []
    let length = 0
    while (offset < bytes.length && bytes[offset] !== 0) {
      const size = bytes[offset]
      chunks.push(bytes.subarray(offset + 1, offset + 1 + size))
      length += size
      offset += size + 1
    }
    offset += 1
    duration += delay > 0 ? delay : 100
    if (!frame && table) {
      const data = new Uint8Array(length)
      let position = 0
      chunks.forEach((chunk) => { data.set(chunk, position); position += chunk.length })
      const indices = cylLZWDecode(data, minCodeSize, w * h)
      frame = new Uint8ClampedArray(width * height * 4)
      const interlaced = (imageFlags & 0x40) !== 0
      const rows = []
      if (interlaced) {
        [[0, 8], [4, 8], [2, 4], [1, 2]].forEach(([start, step]) => { for (let y = start; y < h; y += step) rows.push(y) })
      } else {
        for (let y = 0; y < h; y++) rows.push(y)
      }
      rows.forEach((y, row) => {
        for (let x = 0; x < w; x++) {
          const index = indices[row * w + x]
          const px = left + x
          const py = top + y
          if (index === transparent || px >= width || py >= height) continue
          const color = table[index] || [0, 0, 0]
          const at = (py * width + px) * 4
          frame[at] = color[0]
          frame[at + 1] = color[1]
          frame[at + 2] = color[2]
          frame[at + 3] = 255
        }
      })
    }
    delay = 0
    transparent = -1
  }
  return frame ? { width, height, duration: duration || 100, frame } : null
}

module.exports = { cylIsGIFImagePath, cylGIFImageInfo }
