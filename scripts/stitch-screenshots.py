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


# [EN] Written into every PNG this script makes, so scripts/check-screenshot-labels.py can tell a labeled image.
MARKER_KEY = 'CYLScreenshot'


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
    with open(text_file, 'w', encoding='utf-8') as handle:
        handle.write('\n'.join(lines))
    run(['ffmpeg', '-v', 'error', '-y', '-f', 'lavfi', '-i', f'color=c={BACKGROUND}:s={width}x{height}:d=1',
         '-frames:v', '1', '-vf',
         f"drawtext=fontfile='{filter_path(FONT)}':textfile='{filter_path(text_file)}':fontcolor={TEXT_COLOR}:fontsize={font_size}"
         f':line_spacing={line_height - font_size}:x={margin}:y={margin}', path])
    return path


def pad(path, width, height, out):
    """`path` on a white canvas of `width` x `height`, top left (no scaling)."""
    run(['ffmpeg', '-v', 'error', '-y', '-i', path, '-vf', f'pad={width}:{height}:0:0:color={BACKGROUND}',
         '-frames:v', '1', out])
    return out


def stack(paths, out, vertical):
    if len(paths) == 1:
        shutil.copy(paths[0], out)
        return out
    inputs = []
    for path in paths:
        inputs += ['-i', path]
    kind = 'vstack' if vertical else 'hstack'
    run(['ffmpeg', '-v', 'error', '-y', *inputs, '-filter_complex', f'{kind}=inputs={len(paths)}', '-frames:v', '1', out])
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--out', required=True)
    parser.add_argument('--header', required=True, help='Environment and purpose (English).')
    parser.add_argument('--footer', required=True, help='Result and method (English).')
    parser.add_argument('--columns', default='auto',
                        help='Cells per row: "auto" (default: 1, or 2 when one column is taller than a phone screen), or a number.')
    parser.add_argument('--gap', type=int, default=16, help='White space after each cell, in pixels (default 16).')
    parser.add_argument('cells', nargs='+', help='"caption=path" or "path".')
    options = parser.parse_args()
    if not shutil.which('ffmpeg'):
        sys.exit('ffmpeg is required')
    work = tempfile.mkdtemp(prefix='cyl-stitch-')
    cells = []
    for index, cell in enumerate(options.cells):
        caption, path = cell.split('=', 1) if '=' in cell and not os.path.exists(cell) else ('', cell)
        cells.append((caption, path))
    cell_width = max(size_of(path)[0] for _, path in cells)
    if options.columns == 'auto':
        # [EN] One column first; two when the one-column image (cells plus captions, header and footer, roughly) would be
        #      taller than one phone screen.
        estimate = sum(size_of(path)[1] + options.gap + int(cell_width * 0.06) for _, path in cells) + int(cell_width * 0.3)
        options.columns = 2 if len(cells) > 1 and estimate > cell_width * PHONE_SCREEN_RATIO else 1
    else:
        options.columns = int(options.columns)
    font_size = max(28, int(cell_width * options.columns * 0.02))
    # [EN] Each cell: its caption band above it, then the screenshot; all cells as wide as the widest, rows as tall as
    #      the tallest cell of the row.
    framed = []
    for index, (caption, path) in enumerate(cells):
        parts = []
        if caption:
            parts.append(band(caption, cell_width + options.gap, font_size, os.path.join(work, f'caption{index}.png')))
        width, height = size_of(path)
        parts.append(pad(path, cell_width + options.gap, height + options.gap, os.path.join(work, f'shot{index}.png')))
        framed.append(stack(parts, os.path.join(work, f'cell{index}.png'), vertical=True))
    rows = []
    for start in range(0, len(framed), options.columns):
        row = framed[start:start + options.columns]
        row_height = max(size_of(path)[1] for path in row)
        row = [pad(path, cell_width + options.gap, row_height, path + '.row.png') for path in row]
        while len(row) < options.columns:
            row.append(pad(row[0], cell_width + options.gap, row_height, os.path.join(work, f'blank{start}.png')))
            run(['ffmpeg', '-v', 'error', '-y', '-f', 'lavfi', '-i',
                 f'color=c={BACKGROUND}:s={cell_width + options.gap}x{row_height}:d=1', '-frames:v', '1', row[-1]])
        rows.append(stack(row, os.path.join(work, f'row{start}.png'), vertical=False))
    grid = stack(rows, os.path.join(work, 'grid.png'), vertical=True)
    total_width = size_of(grid)[0]
    header = band(options.header, total_width, font_size, os.path.join(work, 'header.png'))
    footer = band(options.footer, total_width, font_size, os.path.join(work, 'footer.png'))
    stack([header, grid, footer], options.out, vertical=True)
    add_marker(options.out, options.header, options.footer)
    width, height = size_of(options.out)
    shutil.rmtree(work, ignore_errors=True)
    note = ''
    if options.columns == 1 and len(cells) > 1 and height > width * PHONE_SCREEN_RATIO:
        note = ' (taller than one phone screen: use --columns 2)'
    print(f'{options.out}: {width} x {height}, {options.columns} column(s){note}')


if __name__ == '__main__':
    main()
