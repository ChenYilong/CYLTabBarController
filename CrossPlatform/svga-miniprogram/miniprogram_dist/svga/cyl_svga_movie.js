/**
 * [EN] Decodes an SVGA 2.x file: zlib-compressed protobuf (svga.proto of SVGAPlayer, `MovieEntity`). Pure JavaScript, no
 *      browser or Node API, so it runs in a mini program, in Node tests and anywhere else. SVGA 1.x files (ZIP archives
 *      with movie.spec) are reported as unsupported.
 *      cylDecodeSVGA(arrayBuffer) -> { version, viewBoxWidth, viewBoxHeight, fps, frames, images: {key: Uint8Array},
 *      sprites: [{ imageKey, matteKey, frames: [{ alpha, layout, transform, clipPath, shapes }] }] }.
 * [CN] 解码 SVGA 2.x 文件：zlib 压缩的 protobuf（SVGAPlayer 的 svga.proto，`MovieEntity`）。纯 JavaScript，不依赖浏览器或 Node
 *      API，因此可在小程序、Node 测试等任何环境运行。SVGA 1.x 文件（含 movie.spec 的 ZIP）报告为不支持。
 */
const { unzlibSync } = require('./fflate.js')

/**
 * [EN] A protobuf reader over bytes. [CN] 读取字节的 protobuf 解析器。
 */
function CYLProtoReader(bytes) {
  this.bytes = bytes
  this.position = 0
  this.view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)
}

CYLProtoReader.prototype.varint = function () {
  let result = 0
  let shift = 0
  let byte
  do {
    byte = this.bytes[this.position++]
    if (shift < 28) {
      result |= (byte & 0x7f) << shift
    } else {
      result += (byte & 0x7f) * Math.pow(2, shift)
    }
    shift += 7
  } while (byte & 0x80)
  return result >>> 0 === result || shift > 28 ? result : result >>> 0
}

CYLProtoReader.prototype.float = function () {
  const value = this.view.getFloat32(this.position, true)
  this.position += 4
  return value
}

CYLProtoReader.prototype.bytesField = function () {
  const length = this.varint()
  const start = this.position
  this.position += length
  return this.bytes.subarray(start, start + length)
}

CYLProtoReader.prototype.string = function () {
  return cylUTF8(this.bytesField())
}

CYLProtoReader.prototype.skip = function (wireType) {
  if (wireType === 0) {
    this.varint()
  } else if (wireType === 1) {
    this.position += 8
  } else if (wireType === 2) {
    this.position += this.varint()
  } else if (wireType === 5) {
    this.position += 4
  } else {
    throw new Error(`cyl-svga: unsupported protobuf wire type ${wireType}`)
  }
}

/**
 * [EN] Reads the fields of one message: `handle(field, wireType)` reads a field and returns true, or returns false to skip it.
 * [CN] 读取一个消息的字段：`handle(field, wireType)` 读取字段并返回 true，返回 false 时跳过该字段。
 */
function cylMessage(bytes, handle) {
  const reader = new CYLProtoReader(bytes)
  while (reader.position < bytes.length) {
    const tag = reader.varint()
    const field = tag >>> 3
    const wireType = tag & 7
    if (!handle(reader, field, wireType)) {
      reader.skip(wireType)
    }
  }
}

function cylUTF8(bytes) {
  let out = ''
  for (let index = 0; index < bytes.length;) {
    const byte = bytes[index++]
    let code
    if (byte < 0x80) {
      code = byte
    } else if (byte < 0xe0) {
      code = ((byte & 0x1f) << 6) | (bytes[index++] & 0x3f)
    } else if (byte < 0xf0) {
      code = ((byte & 0x0f) << 12) | ((bytes[index++] & 0x3f) << 6) | (bytes[index++] & 0x3f)
    } else {
      code = ((byte & 0x07) << 18) | ((bytes[index++] & 0x3f) << 12) | ((bytes[index++] & 0x3f) << 6) | (bytes[index++] & 0x3f)
    }
    out += String.fromCodePoint(code)
  }
  return out
}

function cylLayout(bytes) {
  const layout = { x: 0, y: 0, width: 0, height: 0 }
  cylMessage(bytes, (reader, field, wireType) => {
    const names = { 1: 'x', 2: 'y', 3: 'width', 4: 'height' }
    if (names[field] && wireType === 5) {
      layout[names[field]] = reader.float()
      return true
    }
    return false
  })
  return layout
}

function cylTransform(bytes) {
  const transform = { a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0 }
  // [EN] proto3 leaves out fields equal to 0, so a present message starts from zeros, not the identity.
  // [CN] proto3 不写等于 0 的字段，因此存在的消息从 0 开始，而不是单位矩阵。
  transform.a = 0
  transform.d = 0
  cylMessage(bytes, (reader, field, wireType) => {
    const names = { 1: 'a', 2: 'b', 3: 'c', 4: 'd', 5: 'tx', 6: 'ty' }
    if (names[field] && wireType === 5) {
      transform[names[field]] = reader.float()
      return true
    }
    return false
  })
  return transform
}

function cylColor(bytes) {
  const color = { r: 0, g: 0, b: 0, a: 0 }
  cylMessage(bytes, (reader, field, wireType) => {
    const names = { 1: 'r', 2: 'g', 3: 'b', 4: 'a' }
    if (names[field] && wireType === 5) {
      color[names[field]] = reader.float()
      return true
    }
    return false
  })
  return color
}

function cylStyle(bytes) {
  const style = { fill: null, stroke: null, strokeWidth: 0, lineCap: 0, lineJoin: 0, miterLimit: 0, lineDash: [0, 0, 0] }
  cylMessage(bytes, (reader, field, wireType) => {
    if ((field === 1 || field === 2) && wireType === 2) {
      style[field === 1 ? 'fill' : 'stroke'] = cylColor(reader.bytesField())
    } else if (field === 3 && wireType === 5) {
      style.strokeWidth = reader.float()
    } else if ((field === 4 || field === 5) && wireType === 0) {
      style[field === 4 ? 'lineCap' : 'lineJoin'] = reader.varint()
    } else if (field === 6 && wireType === 5) {
      style.miterLimit = reader.float()
    } else if (field >= 7 && field <= 9 && wireType === 5) {
      style.lineDash[field - 7] = reader.float()
    } else {
      return false
    }
    return true
  })
  return style
}

/**
 * [EN] ShapeEntity: type 0 shape (an SVG path `d`), 1 rect, 2 ellipse, 3 keep (the shapes of the previous frame).
 * [CN] ShapeEntity：type 0 形状（SVG 路径 `d`），1 矩形，2 椭圆，3 保持（沿用上一帧的形状）。
 */
function cylShape(bytes) {
  const shape = { type: 0, d: '', rect: null, ellipse: null, styles: null, transform: null }
  cylMessage(bytes, (reader, field, wireType) => {
    if (field === 1 && wireType === 0) {
      shape.type = reader.varint()
    } else if (field === 2 && wireType === 2) {
      cylMessage(reader.bytesField(), (args, argField, argWire) => {
        if (argField === 1 && argWire === 2) {
          shape.d = args.string()
          return true
        }
        return false
      })
    } else if (field === 3 && wireType === 2) {
      const rect = { x: 0, y: 0, width: 0, height: 0, cornerRadius: 0 }
      const names = { 1: 'x', 2: 'y', 3: 'width', 4: 'height', 5: 'cornerRadius' }
      cylMessage(reader.bytesField(), (args, argField, argWire) => {
        if (names[argField] && argWire === 5) {
          rect[names[argField]] = args.float()
          return true
        }
        return false
      })
      shape.rect = rect
    } else if (field === 4 && wireType === 2) {
      const ellipse = { x: 0, y: 0, radiusX: 0, radiusY: 0 }
      const names = { 1: 'x', 2: 'y', 3: 'radiusX', 4: 'radiusY' }
      cylMessage(reader.bytesField(), (args, argField, argWire) => {
        if (names[argField] && argWire === 5) {
          ellipse[names[argField]] = args.float()
          return true
        }
        return false
      })
      shape.ellipse = ellipse
    } else if (field === 10 && wireType === 2) {
      shape.styles = cylStyle(reader.bytesField())
    } else if (field === 11 && wireType === 2) {
      shape.transform = cylTransform(reader.bytesField())
    } else {
      return false
    }
    return true
  })
  return shape
}

function cylFrame(bytes) {
  const frame = { alpha: 0, layout: null, transform: null, clipPath: '', shapes: [] }
  cylMessage(bytes, (reader, field, wireType) => {
    if (field === 1 && wireType === 5) {
      frame.alpha = reader.float()
    } else if (field === 2 && wireType === 2) {
      frame.layout = cylLayout(reader.bytesField())
    } else if (field === 3 && wireType === 2) {
      frame.transform = cylTransform(reader.bytesField())
    } else if (field === 4 && wireType === 2) {
      frame.clipPath = reader.string()
    } else if (field === 5 && wireType === 2) {
      frame.shapes.push(cylShape(reader.bytesField()))
    } else {
      return false
    }
    return true
  })
  return frame
}

function cylSprite(bytes) {
  const sprite = { imageKey: '', matteKey: '', frames: [] }
  cylMessage(bytes, (reader, field, wireType) => {
    if (field === 1 && wireType === 2) {
      sprite.imageKey = reader.string()
    } else if (field === 2 && wireType === 2) {
      sprite.frames.push(cylFrame(reader.bytesField()))
    } else if (field === 3 && wireType === 2) {
      sprite.matteKey = reader.string()
    } else {
      return false
    }
    return true
  })
  // [EN] SVGA writes "keep" shapes to mean "the same shapes as the previous frame": resolve them once here.
  // [CN] SVGA 用 "keep" 形状表示“与上一帧相同的形状”：在这里统一展开。
  let previous = []
  sprite.frames.forEach((frame) => {
    if (frame.shapes.length > 0 && frame.shapes[0].type === 3) {
      frame.shapes = previous
    } else {
      previous = frame.shapes
    }
  })
  return sprite
}

/**
 * [EN] Decodes the bytes of an .svga file (ArrayBuffer or Uint8Array). Throws for an SVGA 1.x (ZIP) or broken file.
 * [CN] 解码 .svga 文件的字节（ArrayBuffer 或 Uint8Array）。SVGA 1.x（ZIP）或损坏的文件会抛出错误。
 */
function cylDecodeSVGA(data) {
  const input = data instanceof Uint8Array ? data : new Uint8Array(data)
  if (input[0] === 0x50 && input[1] === 0x4b) {
    throw new Error('cyl-svga: SVGA 1.x files (ZIP) are not supported; convert them to SVGA 2.x.')
  }
  const bytes = unzlibSync(input)
  const movie = { version: '', viewBoxWidth: 0, viewBoxHeight: 0, fps: 20, frames: 0, images: {}, sprites: [] }
  cylMessage(bytes, (reader, field, wireType) => {
    if (field === 1 && wireType === 2) {
      movie.version = reader.string()
    } else if (field === 2 && wireType === 2) {
      cylMessage(reader.bytesField(), (params, paramField, paramWire) => {
        if (paramField === 1 && paramWire === 5) {
          movie.viewBoxWidth = params.float()
        } else if (paramField === 2 && paramWire === 5) {
          movie.viewBoxHeight = params.float()
        } else if (paramField === 3 && paramWire === 0) {
          movie.fps = params.varint()
        } else if (paramField === 4 && paramWire === 0) {
          movie.frames = params.varint()
        } else {
          return false
        }
        return true
      })
    } else if (field === 3 && wireType === 2) {
      let key = ''
      let value = null
      cylMessage(reader.bytesField(), (entry, entryField, entryWire) => {
        if (entryField === 1 && entryWire === 2) {
          key = entry.string()
        } else if (entryField === 2 && entryWire === 2) {
          value = entry.bytesField()
        } else {
          return false
        }
        return true
      })
      if (key && value) {
        movie.images[key] = value
      }
    } else if (field === 4 && wireType === 2) {
      movie.sprites.push(cylSprite(reader.bytesField()))
    } else {
      return false
    }
    return true
  })
  if (!(movie.fps > 0)) { // NOSONAR: NaN / undefined fps are invalid too, unlike `<= 0`
    movie.fps = 20
  }
  return movie
}

module.exports = { cylDecodeSVGA }
