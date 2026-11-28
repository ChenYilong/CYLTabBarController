import { cylInflateZlib } from './CYLInflate';

/**
 * [EN] FIX: issue #415. The SVGA 2.x file format (svga.proto of SVGAPlayer, `MovieEntity`), decoded in ArkTS: the same
 *      decoder as the WeChat mini program player (CrossPlatform/svga-miniprogram/miniprogram_dist/svga/cyl_svga_movie.js),
 *      with the pure TypeScript inflate (CYLInflate.ts), so it also runs under Node (test/CYLAnimatedItemSVGADecoder.test.mjs).
 *      SVGA 1.x files (ZIP archives) are rejected.
 * [CN] FIX: issue #415。用 ArkTS 解码 SVGA 2.x 文件格式（SVGAPlayer 的 svga.proto，`MovieEntity`）：与微信小程序播放器
 *      （CrossPlatform/svga-miniprogram/miniprogram_dist/svga/cyl_svga_movie.js）相同的解码器，解压使用纯 TypeScript 的 inflate（CYLInflate.ts），
 *      因此也能在 Node 下运行。SVGA 1.x 文件
 *      （ZIP）会被拒绝。
 */
export class CYLSVGALayout {
  x: number = 0;
  y: number = 0;
  width: number = 0;
  height: number = 0;
}

export class CYLSVGATransform {
  a: number = 0;
  b: number = 0;
  c: number = 0;
  d: number = 0;
  tx: number = 0;
  ty: number = 0;
}

export class CYLSVGAColor {
  r: number = 0;
  g: number = 0;
  b: number = 0;
  a: number = 0;
}

export class CYLSVGAStyle {
  fill?: CYLSVGAColor;
  stroke?: CYLSVGAColor;
  strokeWidth: number = 0;
  lineCap: number = 0;
  lineJoin: number = 0;
  miterLimit: number = 0;
  lineDash: number[] = [0, 0, 0];
}

export class CYLSVGARect {
  x: number = 0;
  y: number = 0;
  width: number = 0;
  height: number = 0;
  cornerRadius: number = 0;
}

export class CYLSVGAEllipse {
  x: number = 0;
  y: number = 0;
  radiusX: number = 0;
  radiusY: number = 0;
}

/**
 * [EN] type 0 shape (an SVG path `d`), 1 rect, 2 ellipse, 3 keep (the shapes of the previous frame, resolved while decoding).
 * [CN] type 0 形状（SVG 路径 `d`），1 矩形，2 椭圆，3 保持（沿用上一帧的形状，解码时展开）。
 */
export class CYLSVGAShape {
  type: number = 0;
  d: string = '';
  rect?: CYLSVGARect;
  ellipse?: CYLSVGAEllipse;
  styles?: CYLSVGAStyle;
  transform?: CYLSVGATransform;
}

export class CYLSVGAFrame {
  alpha: number = 0;
  layout?: CYLSVGALayout;
  transform?: CYLSVGATransform;
  clipPath: string = '';
  shapes: CYLSVGAShape[] = [];
}

export class CYLSVGASprite {
  imageKey: string = '';
  matteKey: string = '';
  frames: CYLSVGAFrame[] = [];
}

export class CYLSVGAMovie {
  version: string = '';
  viewBoxWidth: number = 0;
  viewBoxHeight: number = 0;
  fps: number = 20;
  frames: number = 0;
  images: Map<string, Uint8Array> = new Map<string, Uint8Array>();
  sprites: CYLSVGASprite[] = [];
}

/** [EN] UTF-8 bytes as a string (no platform decoder, so Node can run it). [CN] UTF-8 字节转为字符串（不依赖平台解码器）。 */
function cylUTF8(bytes: Uint8Array): string {
  let text = '';
  let i = 0;
  while (i < bytes.length) {
    const b = bytes[i++];
    let code = b;
    if (b >= 0xf0) {
      code = ((b & 0x07) << 18) | ((bytes[i] & 0x3f) << 12) | ((bytes[i + 1] & 0x3f) << 6) | (bytes[i + 2] & 0x3f);
      i += 3;
    } else if (b >= 0xe0) {
      code = ((b & 0x0f) << 12) | ((bytes[i] & 0x3f) << 6) | (bytes[i + 1] & 0x3f);
      i += 2;
    } else if (b >= 0xc0) {
      code = ((b & 0x1f) << 6) | (bytes[i] & 0x3f);
      i += 1;
    }
    text += String.fromCodePoint(code);
  }
  return text;
}

/**
 * [EN] A protobuf reader over bytes. [CN] 读取字节的 protobuf 解析器。
 */
class CYLProtoReader {
  readonly bytes: Uint8Array;
  position: number = 0;
  private view: DataView;

  constructor(bytes: Uint8Array) {
    this.bytes = bytes;
    this.view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  }

  varint(): number {
    let result = 0;
    let multiplier = 1;
    let byte = 0x80;
    while ((byte & 0x80) !== 0 && this.position < this.bytes.length) {
      byte = this.bytes[this.position];
      this.position += 1;
      result += (byte & 0x7f) * multiplier;
      multiplier *= 128;
    }
    return result;
  }

  float(): number {
    const value = this.view.getFloat32(this.position, true);
    this.position += 4;
    return value;
  }

  bytesField(): Uint8Array {
    const length = this.varint();
    const start = this.position;
    this.position += length;
    return this.bytes.subarray(start, start + length);
  }

  text(): string {
    return cylUTF8(this.bytesField());
  }

  skip(wireType: number): void {
    if (wireType === 0) {
      this.varint();
    } else if (wireType === 1) {
      this.position += 8;
    } else if (wireType === 2) {
      this.position += this.varint();
    } else if (wireType === 5) {
      this.position += 4;
    } else {
      throw new Error(`CYLSVGA: unsupported protobuf wire type ${wireType}`);
    }
  }
}

type CYLFieldHandler = (reader: CYLProtoReader, field: number, wireType: number) => boolean;

/**
 * [EN] Reads the fields of one message; `handle` reads a field and returns true, or returns false to skip it.
 * [CN] 读取一个消息的字段；`handle` 读取字段并返回 true，返回 false 时跳过。
 */
function cylMessage(bytes: Uint8Array, handle: CYLFieldHandler): void {
  const reader = new CYLProtoReader(bytes);
  while (reader.position < bytes.length) {
    const tag = reader.varint();
    const field = Math.floor(tag / 8);
    const wireType = tag % 8;
    if (!handle(reader, field, wireType)) {
      reader.skip(wireType);
    }
  }
}

function cylLayout(bytes: Uint8Array): CYLSVGALayout {
  const layout = new CYLSVGALayout();
  cylMessage(bytes, (reader: CYLProtoReader, field: number, wireType: number): boolean => {
    if (wireType !== 5) {
      return false;
    }
    if (field === 1) {
      layout.x = reader.float();
    } else if (field === 2) {
      layout.y = reader.float();
    } else if (field === 3) {
      layout.width = reader.float();
    } else if (field === 4) {
      layout.height = reader.float();
    } else {
      return false;
    }
    return true;
  });
  return layout;
}

/**
 * [EN] proto3 leaves out fields equal to 0, so a present transform starts from zeros. [CN] proto3 不写等于 0 的字段，因此存在的变换从 0 开始。
 */
function cylTransform(bytes: Uint8Array): CYLSVGATransform {
  const transform = new CYLSVGATransform();
  cylMessage(bytes, (reader: CYLProtoReader, field: number, wireType: number): boolean => {
    if (wireType !== 5) {
      return false;
    }
    switch (field) {
      case 1: transform.a = reader.float(); break;
      case 2: transform.b = reader.float(); break;
      case 3: transform.c = reader.float(); break;
      case 4: transform.d = reader.float(); break;
      case 5: transform.tx = reader.float(); break;
      case 6: transform.ty = reader.float(); break;
      default: return false;
    }
    return true;
  });
  return transform;
}

function cylColor(bytes: Uint8Array): CYLSVGAColor {
  const color = new CYLSVGAColor();
  cylMessage(bytes, (reader: CYLProtoReader, field: number, wireType: number): boolean => {
    if (wireType !== 5) {
      return false;
    }
    switch (field) {
      case 1: color.r = reader.float(); break;
      case 2: color.g = reader.float(); break;
      case 3: color.b = reader.float(); break;
      case 4: color.a = reader.float(); break;
      default: return false;
    }
    return true;
  });
  return color;
}

function cylStyle(bytes: Uint8Array): CYLSVGAStyle {
  const style = new CYLSVGAStyle();
  cylMessage(bytes, (reader: CYLProtoReader, field: number, wireType: number): boolean => {
    if (field === 1 && wireType === 2) {
      style.fill = cylColor(reader.bytesField());
    } else if (field === 2 && wireType === 2) {
      style.stroke = cylColor(reader.bytesField());
    } else if (field === 3 && wireType === 5) {
      style.strokeWidth = reader.float();
    } else if (field === 4 && wireType === 0) {
      style.lineCap = reader.varint();
    } else if (field === 5 && wireType === 0) {
      style.lineJoin = reader.varint();
    } else if (field === 6 && wireType === 5) {
      style.miterLimit = reader.float();
    } else if (field >= 7 && field <= 9 && wireType === 5) {
      style.lineDash[field - 7] = reader.float();
    } else {
      return false;
    }
    return true;
  });
  return style;
}

function cylShape(bytes: Uint8Array): CYLSVGAShape {
  const shape = new CYLSVGAShape();
  cylMessage(bytes, (reader: CYLProtoReader, field: number, wireType: number): boolean => {
    if (field === 1 && wireType === 0) {
      shape.type = reader.varint();
    } else if (field === 2 && wireType === 2) {
      cylMessage(reader.bytesField(), (args: CYLProtoReader, argField: number, argWire: number): boolean => {
        if (argField === 1 && argWire === 2) {
          shape.d = args.text();
          return true;
        }
        return false;
      });
    } else if (field === 3 && wireType === 2) {
      const rect = new CYLSVGARect();
      cylMessage(reader.bytesField(), (args: CYLProtoReader, argField: number, argWire: number): boolean => {
        if (argWire !== 5) {
          return false;
        }
        switch (argField) {
          case 1: rect.x = args.float(); break;
          case 2: rect.y = args.float(); break;
          case 3: rect.width = args.float(); break;
          case 4: rect.height = args.float(); break;
          case 5: rect.cornerRadius = args.float(); break;
          default: return false;
        }
        return true;
      });
      shape.rect = rect;
    } else if (field === 4 && wireType === 2) {
      const ellipse = new CYLSVGAEllipse();
      cylMessage(reader.bytesField(), (args: CYLProtoReader, argField: number, argWire: number): boolean => {
        if (argWire !== 5) {
          return false;
        }
        switch (argField) {
          case 1: ellipse.x = args.float(); break;
          case 2: ellipse.y = args.float(); break;
          case 3: ellipse.radiusX = args.float(); break;
          case 4: ellipse.radiusY = args.float(); break;
          default: return false;
        }
        return true;
      });
      shape.ellipse = ellipse;
    } else if (field === 10 && wireType === 2) {
      shape.styles = cylStyle(reader.bytesField());
    } else if (field === 11 && wireType === 2) {
      shape.transform = cylTransform(reader.bytesField());
    } else {
      return false;
    }
    return true;
  });
  return shape;
}

function cylFrame(bytes: Uint8Array): CYLSVGAFrame {
  const frame = new CYLSVGAFrame();
  cylMessage(bytes, (reader: CYLProtoReader, field: number, wireType: number): boolean => {
    if (field === 1 && wireType === 5) {
      frame.alpha = reader.float();
    } else if (field === 2 && wireType === 2) {
      frame.layout = cylLayout(reader.bytesField());
    } else if (field === 3 && wireType === 2) {
      frame.transform = cylTransform(reader.bytesField());
    } else if (field === 4 && wireType === 2) {
      frame.clipPath = reader.text();
    } else if (field === 5 && wireType === 2) {
      frame.shapes.push(cylShape(reader.bytesField()));
    } else {
      return false;
    }
    return true;
  });
  return frame;
}

function cylSprite(bytes: Uint8Array): CYLSVGASprite {
  const sprite = new CYLSVGASprite();
  cylMessage(bytes, (reader: CYLProtoReader, field: number, wireType: number): boolean => {
    if (field === 1 && wireType === 2) {
      sprite.imageKey = reader.text();
    } else if (field === 2 && wireType === 2) {
      sprite.frames.push(cylFrame(reader.bytesField()));
    } else if (field === 3 && wireType === 2) {
      sprite.matteKey = reader.text();
    } else {
      return false;
    }
    return true;
  });
  let previous: CYLSVGAShape[] = [];
  sprite.frames.forEach((frame: CYLSVGAFrame) => {
    if (frame.shapes.length > 0 && frame.shapes[0].type === 3) {
      frame.shapes = previous;
    } else {
      previous = frame.shapes;
    }
  });
  return sprite;
}

/**
 * [EN] Decodes the inflated protobuf bytes of an SVGA 2.x movie. [CN] 解码 SVGA 2.x 动画解压后的 protobuf 字节。
 */
export function cylDecodeSVGAMovie(bytes: Uint8Array): CYLSVGAMovie {
  const movie = new CYLSVGAMovie();
  cylMessage(bytes, (reader: CYLProtoReader, field: number, wireType: number): boolean => {
    if (field === 1 && wireType === 2) {
      movie.version = reader.text();
    } else if (field === 2 && wireType === 2) {
      cylMessage(reader.bytesField(), (params: CYLProtoReader, paramField: number, paramWire: number): boolean => {
        if (paramField === 1 && paramWire === 5) {
          movie.viewBoxWidth = params.float();
        } else if (paramField === 2 && paramWire === 5) {
          movie.viewBoxHeight = params.float();
        } else if (paramField === 3 && paramWire === 0) {
          movie.fps = params.varint();
        } else if (paramField === 4 && paramWire === 0) {
          movie.frames = params.varint();
        } else {
          return false;
        }
        return true;
      });
    } else if (field === 3 && wireType === 2) {
      let key = '';
      let value: Uint8Array | undefined = undefined;
      cylMessage(reader.bytesField(), (entry: CYLProtoReader, entryField: number, entryWire: number): boolean => {
        if (entryField === 1 && entryWire === 2) {
          key = entry.text();
        } else if (entryField === 2 && entryWire === 2) {
          value = entry.bytesField();
        } else {
          return false;
        }
        return true;
      });
      if (key.length > 0 && value !== undefined) {
        movie.images.set(key, value);
      }
    } else if (field === 4 && wireType === 2) {
      movie.sprites.push(cylSprite(reader.bytesField()));
    } else {
      return false;
    }
    return true;
  });
  if (movie.fps <= 0 || Number.isNaN(movie.fps)) {
    movie.fps = 20;
  }
  return movie;
}

/**
 * [EN] Inflates and decodes the bytes of an .svga file; rejects SVGA 1.x (ZIP) and damaged files.
 * [CN] 解压并解码 .svga 文件的字节；拒绝 SVGA 1.x（ZIP）与损坏的文件。
 */
export function cylInflateSVGAMovie(data: Uint8Array): CYLSVGAMovie {
  if (data.length > 1 && data[0] === 0x50 && data[1] === 0x4b) {
    throw new Error('CYLSVGA: SVGA 1.x files (ZIP) are not supported; convert them to SVGA 2.x.');
  }
  return cylDecodeSVGAMovie(cylInflateZlib(data));
}
