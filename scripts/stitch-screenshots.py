#!/usr/bin/env python3
"""Stitch screenshots into one labeled image, as docs/Screenshot-Guidelines.md requires.

The result has, from top to bottom: a header band (environment and purpose), the cells (one caption band above each),
and a footer band (result, method). Columns: one column by default; two columns when one column would be taller than
one phone screen (height above PHONE_SCREEN_RATIO times the width, a 19.5:9 phone shown at phone width). The bands are added around the
screenshots, never drawn over them, and the screenshots keep their original pixels (no scaling). Only ffmpeg is
needed (with drawtext); no Python packages.

    python3 scripts/stitch-screenshots.py --out docs/assets/ios-rive-rest.png \\
        --header "iOS 27.2, iPhone 17 Pro simulator, macOS 27.3, Xcode 27.2, CYLTabBarController dcbfdec6, 2026-11-18. Purpose: Rive tags rest until played" \\
        --footer "Result: 0 changed pixels in all six icons over 11 s (expected: still until played). Method: pixel diff of two screenshots" \\
        "launch, no play=/tmp/a.png" "11 s later, 0 changed pixels=/tmp/b.png"

Each cell is "caption=path" (a cell without "=" has no caption). Text is English only.
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
import textwrap
import struct
import zlib

# [EN] A bold font: $CYL_SCREENSHOT_FONT, else the first that exists on macOS, Windows or Linux.
FONT = next((path for path in [os.environ.get('CYL_SCREENSHOT_FONT', ''),
                               '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
                               'C:/Windows/Fonts/arialbd.ttf',
                               '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'] if path and os.path.exists(path)),
            '/System/Library/Fonts/Supplemental/Arial Bold.ttf')
TEXT_COLOR = '0xFF3B30'
BACKGROUND = 'white'
# [EN] A common phone screen (19.5:9): an image taller than this times its width needs scrolling at phone width.
PHONE_SCREEN_RATIO = 19.5 / 9
# [EN] ffmpeg writes one frame per still image. [CN] ffmpeg 为每张静态图片只写一帧。
ONE_FRAME = ['-frames:v', '1']


# [EN] Written into every PNG this script makes, so scripts/check-screenshot-labels.py can tell a labeled image.
MARKER_KEY = 'CYLScreenshot'

# [EN] The folders the images may be read from and written to: this repository and the temporary folders. Paths come
#      from the command line (often written by an agent), so each is resolved and checked before it reaches open() or
#      ffmpeg: no path outside these folders, and an absolute path can never be read as an ffmpeg option.
# [CN] 允许读写图片的目录：本仓库与临时目录。路径来自命令行（常由 agent 生成），因此在交给 open() 或 ffmpeg 之前先解析并检查：
#      不允许这些目录之外的路径，且绝对路径不会被 ffmpeg 当作选项。
ROOT = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
ALLOWED_FOLDERS = tuple(dict.fromkeys(os.path.realpath(folder) for folder in (ROOT, tempfile.gettempdir())))
# [EN] An absolute path of plain characters only. [CN] 只含普通字符的绝对路径。
SAFE_PATH = re.compile(r'/[A-Za-z0-9._@+ /-]*')


def checked_pixels(value, name):
    """`value` as an int from 0 to 400 pixels, or the script exits."""
    pixels = int(value)
    if not 0 <= pixels <= 400:
        sys.exit(f'{name} must be from 0 to 400 pixels')
    return pixels


def checked_path(path, must_exist):
    """`path` resolved, of plain characters, inside ALLOWED_FOLDERS (and an existing file when `must_exist`), or the script exits."""
    resolved = os.path.realpath(path)
    # [EN] On Windows the resolved path is "C:\...": check it with forward slashes and without its drive letter, which
    #      keeps the same plain characters (and a path that starts with a drive is never taken as an ffmpeg option).
    # [CN] Windows 上解析后的路径为 "C:\..."：改用正斜杠并去掉盘符后检查，字符限制不变（以盘符开头的路径也不会被 ffmpeg 当作选项）。
    plain = resolved.replace('\\', '/')
    if os.name == 'nt' and len(plain) > 2 and plain[0].isalpha() and plain[1] == ':':
        plain = plain[2:]
    if not SAFE_PATH.fullmatch(plain):
        sys.exit(f'{path}: only letters, digits, spaces and ._@+/- are allowed in a path')
    if not any(resolved.startswith(folder + os.sep) for folder in ALLOWED_FOLDERS):
        sys.exit(f'{path}: outside the repository and the temporary folder')
    if must_exist and not os.path.isfile(resolved):
        sys.exit(f'{path}: no such file')
    return resolved


def add_marker(path, header, footer):
    """Adds a PNG tEXt chunk (MARKER_KEY: header and footer) before IEND. Pixels are untouched."""
    with open(path, 'rb') as handle:
        data = handle.read()
    if not data.startswith(b'\x89PNG'):
        return
    text = f'{MARKER_KEY}\0header={header}\nfooter={footer}'.encode('latin-1', 'replace')
    chunk = struct.pack('>I', len(text)) + b'tEXt' + text + struct.pack('>I', zlib.crc32(b'tEXt' + text) & 0xffffffff)
    end = data.rfind(b'IEND') - 4
    with open(path, 'wb') as handle:
        handle.write(data[:end] + chunk + data[end:])


def run(args):
    result = subprocess.run(args, capture_output=True, text=True)
    if result.returncode != 0:
        sys.exit('ffmpeg failed: ' + result.stderr[-800:])


def filter_path(path):
    """A path inside an ffmpeg filter argument: forward slashes, the drive colon escaped (Windows)."""
    return path.replace('\\', '/').replace(':', '\\:')


def size_of(path):
    if shutil.which('ffprobe'):
        out = subprocess.run(['ffprobe', '-v', 'error', '-select_streams', 'v:0', '-show_entries', 'stream=width,height',
                              '-of', 'csv=p=0:s=x', path], capture_output=True, text=True, check=True).stdout.strip()
        width, height = out.split('x')
        return int(width), int(height)
    # [EN] Without ffprobe (some Windows builds ship ffmpeg alone): the size from `ffmpeg -i`'s stream line.
    info = subprocess.run(['ffmpeg', '-hide_banner', '-i', path], capture_output=True, text=True).stderr
    match = re.search(r'Video:.*?(\d{2,5})x(\d{2,5})', info)
    if not match:
        sys.exit(f'cannot read the size of {path}')
    return int(match.group(1)), int(match.group(2))


def band(text, width, font_size, path):
    """A white band as wide as `width` with `text` wrapped inside it, left aligned."""
    chars = max(10, int(width / (font_size * 0.56)))
    lines = []
    for paragraph in text.split('\n'):
        lines.extend(textwrap.wrap(paragraph, chars) or [''])
    line_height = int(font_size * 1.3)
    margin = int(font_size * 0.6)
    height = margin * 2 + line_height * len(lines)
    text_file = path + '.txt'
    # [EN] newline='\n': on Windows text mode writes CRLF, and drawtext draws each \r as a line of its own, so the band
    #      (sized for LF lines) cut off its last lines.
    # [CN] newline='\n'：Windows 的文本模式写入 CRLF，drawtext 会把每个 \r 当作单独一行，按 LF 计算高度的说明栏会截掉最后几行。
    with open(text_file, 'w', encoding='utf-8', newline='\n') as handle:
        handle.write('\n'.join(lines))
    run(['ffmpeg', '-v', 'error', '-y', '-f', 'lavfi', '-i', f'color=c={BACKGROUND}:s={width}x{height}:d=1',
         *ONE_FRAME, '-vf',
         f"drawtext=fontfile='{filter_path(FONT)}':textfile='{filter_path(text_file)}':fontcolor={TEXT_COLOR}:fontsize={font_size}"
         # [EN] expansion=none: a "%" in a label (e.g. "%23" in a URL) is drawn as is, not taken as a drawtext expansion.
         f':line_spacing={line_height - font_size}:x={margin}:y={margin}:expansion=none', path])
    return path


def pad(path, width, height, out):
    """`path` on a white canvas of `width` x `height`, top left (no scaling)."""
    run(['ffmpeg', '-v', 'error', '-y', '-i', path, '-vf', f'pad={width}:{height}:0:0:color={BACKGROUND}',
         *ONE_FRAME, out])
    return out


def stack(paths, out, vertical):
    if len(paths) == 1:
        shutil.copy(paths[0], out)
        return out
    inputs = []
    for path in paths:
        inputs += ['-i', path]
    kind = 'vstack' if vertical else 'hstack'
    run(['ffmpeg', '-v', 'error', '-y', *inputs, '-filter_complex', f'{kind}=inputs={len(paths)}', *ONE_FRAME, out])
    return out


def blank(width, height, path):
    """
    [EN] A white image of the given size. [CN] 指定大小的白色图片。
    """
    run(['ffmpeg', '-v', 'error', '-y', '-f', 'lavfi', '-i', f'color=c={BACKGROUND}:s={width}x{height}:d=1', *ONE_FRAME, path])
    return path


def parse_options():
    """
    [EN] The command line, with the labels the rules require (docs/Screenshot-Guidelines.md) checked.
    [CN] 命令行参数，并检查规则要求的标签（docs/Screenshot-Guidelines.md）。
    """
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--out', required=True)
    parser.add_argument('--header', required=True, help='Environment and purpose (English).')
    parser.add_argument('--footer', required=True, help='Result and method (English).')
    parser.add_argument('--columns', default='auto',
                        help='Cells per row: "auto" (default: 1, or 2 when one column is taller than a phone screen), or a number.')
    parser.add_argument('--gap', type=int, default=16, help='White space after each cell, in pixels (default 16).')
    parser.add_argument('--top-gap', type=int, default=24,
                        help='White space between a header or caption band and the screenshot below it, in pixels (default 24), so a raised plus button or a badge at the top of a crop is never covered.')
    parser.add_argument('cells', nargs='+', help='"caption=path" or "path".')
    options = parser.parse_args()
    # [EN] scripts/check-screenshot-labels.py checks the same labels. [CN] scripts/check-screenshot-labels.py 检查同样的标签。
    if 'Purpose:' not in options.header:
        sys.exit('--header must end with "Purpose: <what the image shows>" (docs/Screenshot-Guidelines.md)')
    if 'Result:' not in options.footer:
        sys.exit('--footer must start with "Result: <what it proves> (expected: ...)" (docs/Screenshot-Guidelines.md)')
    if any(ord(character) > 127 for character in options.header + options.footer + ''.join(options.cells)):
        sys.exit('labels are English only (ASCII) (docs/Screenshot-Guidelines.md)')
    if not shutil.which('ffmpeg'):
        sys.exit('ffmpeg is required')
    return options


def read_cells(arguments):
    """
    [EN] (caption, checked path) for each "caption=path" or "path". [CN] 每个 "caption=path" 或 "path" 对应的（说明，校验后的路径）。
    """
    cells = []
    for cell in arguments:
        caption, path = cell.split('=', 1) if '=' in cell and not os.path.exists(cell) else ('', cell)
        cells.append((caption, checked_path(path, must_exist=True)))
    return cells


def choose_columns(requested, cells, cell_width, gap):
    """
    [EN] One column first; two when the one-column image (cells plus captions, header and footer, roughly) would be taller
         than one phone screen; or the number asked for.
    [CN] 优先一列；一列的图片（单元格加说明、页眉与页脚，粗略估计）高于一个手机屏幕时为两列；或使用指定的列数。
    """
    if requested != 'auto':
        return int(requested)
    estimate = sum(size_of(path)[1] + gap + int(cell_width * 0.06) for _, path in cells) + int(cell_width * 0.3)
    return 2 if len(cells) > 1 and estimate > cell_width * PHONE_SCREEN_RATIO else 1


def frame_cells(cells, cell_width, gap, top_gap, font_size, work):
    """
    [EN] Each cell: its caption band above it, a white gap (docs/Screenshot-Guidelines.md, "Space above the tab bar and
         below the bands"), then the screenshot, all as wide as the widest cell.
    [CN] 每个单元格：上方为说明，接着是白色间隔（docs/Screenshot-Guidelines.md「Space above the tab bar and below the bands」），
         然后是截图，宽度都与最宽的单元格相同。
    """
    framed = []
    for index, (caption, path) in enumerate(cells):
        parts = []
        if caption:
            parts.append(band(caption, cell_width + gap, font_size, os.path.join(work, f'caption{index}.png')))
        if top_gap > 0:
            parts.append(blank(cell_width + gap, top_gap, os.path.join(work, f'topgap{index}.png')))
        height = size_of(path)[1]
        parts.append(pad(path, cell_width + gap, height + gap, os.path.join(work, f'shot{index}.png')))
        framed.append(stack(parts, os.path.join(work, f'cell{index}.png'), vertical=True))
    return framed


def grid_of(framed, columns, cell_width, gap, work):
    """
    [EN] The framed cells in rows of `columns`, each row as tall as its tallest cell, a short last row padded with white.
    [CN] 把单元格按每行 `columns` 个排列，每行与其中最高的单元格同高，最后一行不足时用白色补齐。
    """
    rows = []
    for start in range(0, len(framed), columns):
        row = framed[start:start + columns]
        row_height = max(size_of(path)[1] for path in row)
        row = [pad(path, cell_width + gap, row_height, path + '.row.png') for path in row]
        while len(row) < columns:
            row.append(blank(cell_width + gap, row_height, os.path.join(work, f'blank{start}-{len(row)}.png')))
        rows.append(stack(row, os.path.join(work, f'row{start}.png'), vertical=False))
    return stack(rows, os.path.join(work, 'grid.png'), vertical=True)


def main():
    options = parse_options()
    out_path = checked_path(options.out, must_exist=False)
    # [EN] Whole numbers in a fixed range only reach the ffmpeg filters. [CN] 只有固定范围内的整数才会进入 ffmpeg 滤镜。
    gap = checked_pixels(options.gap, '--gap')
    top_gap = checked_pixels(options.top_gap, '--top-gap')
    work = tempfile.mkdtemp(prefix='cyl-stitch-')
    cells = read_cells(options.cells)
    cell_width = max(size_of(path)[0] for _, path in cells)
    # [EN] Even: with an odd cell width plus the gap, an ffmpeg band can come out 1 px narrower and vstack refuses it.
    cell_width += cell_width % 2
    columns = choose_columns(options.columns, cells, cell_width, gap)
    font_size = max(28, int(cell_width * columns * 0.02))
    grid = grid_of(frame_cells(cells, cell_width, gap, top_gap, font_size, work), columns, cell_width, gap, work)
    total_width = size_of(grid)[0]
    header = band(options.header, total_width, font_size, os.path.join(work, 'header.png'))
    footer = band(options.footer, total_width, font_size, os.path.join(work, 'footer.png'))
    # [EN] ffmpeg writes only inside the work folder; the result is copied to --out, which never reaches a command line.
    # [CN] ffmpeg 只在工作目录中写入；结果再复制到 --out，该路径不会进入任何命令行。
    result = stack([header, grid, footer], os.path.join(work, 'result.png'), vertical=True)
    add_marker(result, options.header, options.footer)
    width, height = size_of(result)
    shutil.copyfile(result, out_path)
    shutil.rmtree(work, ignore_errors=True)
    note = ''
    if columns == 1 and len(cells) > 1 and height > width * PHONE_SCREEN_RATIO:
        note = ' (taller than one phone screen: use --columns 2)'
    print(f'{out_path}: {width} x {height}, {columns} column(s){note}')

if __name__ == '__main__':
    main()
