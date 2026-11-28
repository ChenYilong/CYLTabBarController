/**
 * [EN] Inflate (RFC 1951) for SVGA 2.x files, which are zlib streams (RFC 1950) of a protobuf movie, in plain TypeScript so
 *      the decoder runs anywhere (UI thread, worker, Node unit tests) without a native zlib binding. Moved from
 *      CollectionViewClassifyMenu's example (harmony/entry/src/main/ets/animation/svga/CYLInflate.ets).
 * [CN] SVGA 2.x 文件的 Inflate（RFC 1951）：文件是 protobuf 动画的 zlib 流（RFC 1950）。用纯 TypeScript 实现，解码器可在任何地方运行（UI 线程、
 *      worker、Node 单元测试），无需原生 zlib。从 CollectionViewClassifyMenu 示例迁移而来。
 */

const LENGTH_BASE: number[] = [3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115,
  131, 163, 195, 227, 258];
const LENGTH_EXTRA: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0];
const DIST_BASE: number[] = [1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537,
  2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577];
const DIST_EXTRA: number[] = [0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13,
  13];
const CODE_LENGTH_ORDER: number[] = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];

/** A canonical Huffman code: symbol counts per length and the symbols sorted by code. */
class CYLHuffman {
  counts: Uint16Array = new Uint16Array(16);
  symbols: Uint16Array;

  constructor(lengths: Uint8Array, count: number) {
    this.symbols = new Uint16Array(count);
    for (let i = 0; i < count; i++) {
      this.counts[lengths[i]]++;
    }
    this.counts[0] = 0;
    const offsets = new Uint16Array(16);
    for (let len = 1; len < 16; len++) {
      offsets[len] = offsets[len - 1] + this.counts[len - 1];
    }
    for (let i = 0; i < count; i++) {
      if (lengths[i] !== 0) {
        this.symbols[offsets[lengths[i]]++] = i;
      }
    }
  }
}

class CYLBitReader {
  private readonly data: Uint8Array;
  position: number;
  private bitBuffer: number = 0;
  private bitCount: number = 0;

  constructor(data: Uint8Array, position: number) {
    this.data = data;
    this.position = position;
  }

  bits(count: number): number {
    while (this.bitCount < count) {
      if (this.position >= this.data.length) {
        throw new Error('CYLSVGA: zlib: truncated deflate stream');
      }
      this.bitBuffer |= this.data[this.position++] << this.bitCount;
      this.bitCount += 8;
    }
    const value = this.bitBuffer & ((1 << count) - 1);
    this.bitBuffer >>>= count;
    this.bitCount -= count;
    return value;
  }

  alignToByte(): void {
    this.bitBuffer = 0;
    this.bitCount = 0;
  }

  byte(): number {
    if (this.position >= this.data.length) {
      throw new Error('CYLSVGA: zlib: truncated deflate stream');
    }
    return this.data[this.position++];
  }

  decode(h: CYLHuffman): number {
    let code = 0;
    let first = 0;
    let index = 0;
    for (let len = 1; len < 16; len++) {
      code |= this.bits(1);
      const count = h.counts[len];
      if (code - count < first) {
        return h.symbols[index + (code - first)];
      }
      index += count;
      first += count;
      first <<= 1;
      code <<= 1;
    }
    throw new Error('CYLSVGA: zlib: bad Huffman code');
  }
}

class CYLOutput {
  buffer: Uint8Array;
  length: number = 0;

  constructor(capacity: number) {
    this.buffer = new Uint8Array(Math.max(1024, capacity));
  }

  private ensure(extra: number): void {
    if (this.length + extra <= this.buffer.length) {
      return;
    }
    let size = this.buffer.length * 2;
    while (size < this.length + extra) {
      size *= 2;
    }
    const grown = new Uint8Array(size);
    grown.set(this.buffer.subarray(0, this.length));
    this.buffer = grown;
  }

  push(value: number): void {
    this.ensure(1);
    this.buffer[this.length++] = value;
  }

  copy(distance: number, length: number): void {
    if (distance > this.length) {
      throw new Error('CYLSVGA: zlib: bad deflate distance');
    }
    this.ensure(length);
    let from = this.length - distance;
    for (let i = 0; i < length; i++) {
      this.buffer[this.length++] = this.buffer[from++];
    }
  }
}

function fixedLiteralLength(symbol: number): number {
  if (symbol < 144) {
    return 8;
  }
  if (symbol < 256) {
    return 9;
  }
  return symbol < 280 ? 7 : 8;
}

function fixedCodes(): CYLHuffman[] {
  const lengths = new Uint8Array(288);
  for (let i = 0; i < 288; i++) {
    lengths[i] = fixedLiteralLength(i);
  }
  const distances = new Uint8Array(30);
  distances.fill(5);
  return [new CYLHuffman(lengths, 288), new CYLHuffman(distances, 30)];
}

function dynamicCodes(reader: CYLBitReader): CYLHuffman[] {
  const literalCount = reader.bits(5) + 257;
  const distanceCount = reader.bits(5) + 1;
  const codeCount = reader.bits(4) + 4;
  const codeLengths = new Uint8Array(19);
  for (let i = 0; i < codeCount; i++) {
    codeLengths[CODE_LENGTH_ORDER[i]] = reader.bits(3);
  }
  const codeLengthCode = new CYLHuffman(codeLengths, 19);
  const lengths = new Uint8Array(literalCount + distanceCount);
  let i = 0;
  while (i < literalCount + distanceCount) {
    const symbol = reader.decode(codeLengthCode);
    if (symbol < 16) {
      lengths[i++] = symbol;
      continue;
    }
    let repeat = 0;
    let value = 0;
    if (symbol === 16) {
      if (i === 0) {
        throw new Error('CYLSVGA: zlib: bad code lengths');
      }
      value = lengths[i - 1];
      repeat = 3 + reader.bits(2);
    } else if (symbol === 17) {
      repeat = 3 + reader.bits(3);
    } else {
      repeat = 11 + reader.bits(7);
    }
    while (repeat-- > 0 && i < lengths.length) {
      lengths[i++] = value;
    }
  }
  return [new CYLHuffman(lengths.subarray(0, literalCount), literalCount),
    new CYLHuffman(lengths.subarray(literalCount), distanceCount)];
}

/** Copies one stored (uncompressed) deflate block to the output. */
function inflateStoredBlock(reader: CYLBitReader, output: CYLOutput): void {
  reader.alignToByte();
  const length = reader.byte() | (reader.byte() << 8);
  reader.byte();
  reader.byte();
  for (let i = 0; i < length; i++) {
    output.push(reader.byte());
  }
}

/** Decodes the literal and length/distance symbols of one Huffman-compressed deflate block until its end symbol. */
function inflateCompressedBlock(reader: CYLBitReader, output: CYLOutput, codes: CYLHuffman[]): void {
  for (;;) {
    const symbol = reader.decode(codes[0]);
    if (symbol < 256) {
      output.push(symbol);
    } else if (symbol === 256) {
      return;
    } else {
      inflateMatch(reader, output, codes, symbol);
    }
  }
}

/** Copies one back-reference (length symbol, then distance) to the output. */
function inflateMatch(reader: CYLBitReader, output: CYLOutput, codes: CYLHuffman[], symbol: number): void {
  const index = symbol - 257;
  if (index >= LENGTH_BASE.length) {
    throw new Error('CYLSVGA: zlib: bad length symbol');
  }
  const length = LENGTH_BASE[index] + reader.bits(LENGTH_EXTRA[index]);
  const d = reader.decode(codes[1]);
  if (d >= DIST_BASE.length) {
    throw new Error('CYLSVGA: zlib: bad distance symbol');
  }
  output.copy(DIST_BASE[d] + reader.bits(DIST_EXTRA[d]), length);
}

/**
 * Inflates a raw deflate stream starting at `offset`.
 */
export function cylInflateRaw(data: Uint8Array, offset: number = 0): Uint8Array {
  const reader = new CYLBitReader(data, offset);
  const output = new CYLOutput(data.length * 4);
  let last = 0;
  while (last === 0) {
    last = reader.bits(1);
    const type = reader.bits(2);
    if (type === 0) {
      inflateStoredBlock(reader, output);
      continue;
    }
    if (type === 3) {
      throw new Error('CYLSVGA: zlib: bad deflate block');
    }
    inflateCompressedBlock(reader, output, type === 1 ? fixedCodes() : dynamicCodes(reader));
  }
  return output.buffer.slice(0, output.length);
}

/**
 * Inflates a zlib stream (RFC 1950): checks the two-byte header, skips it, and inflates the rest.
 */
export function cylInflateZlib(data: Uint8Array): Uint8Array {
  if (data.length < 2 || (data[0] & 0x0f) !== 8 || ((data[0] << 8) | data[1]) % 31 !== 0) {
    throw new Error('CYLSVGA: not a zlib stream (damaged file)');
  }
  return cylInflateRaw(data, (data[1] & 0x20) !== 0 ? 6 : 2);
}
