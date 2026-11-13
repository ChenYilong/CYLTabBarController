#!/usr/bin/env python3
"""从 8×4 头像母图生成方格母版与 32px 运行时头像。"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


AVATAR_KEYS = (
    "pinecone-squirrel",
    "sleepy-fox",
    "moon-fawn",
    "cloud-bear",
    "mushroom-rabbit",
    "dew-hedgehog",
    "berry-raccoon",
    "tree-owl",
    "honey-badger",
    "shell-otter",
    "dandelion-lamb",
    "moss-mole",
    "star-tanuki",
    "raindrop-frog",
    "flower-mouse",
    "chestnut-hamster",
    "autumn-wolf",
    "cotton-puppy",
    "gummy-panda",
    "firefly-kitten",
    "windchime-ferret",
    "peach-chipmunk",
    "scarf-penguin",
    "lantern-tanuki",
    "acorn-piglet",
    "sunset-pony",
    "mint-snake",
    "hawthorn-red-panda",
    "pine-tit",
    "snow-marten",
    "mooncake-monkey",
    "persimmon-wildcat",
)

GRID_COLUMNS = 8
GRID_ROWS = 4
MASTER_CELL_SIZE = 480
RUNTIME_SIZE = 32


def proportional_edge(index: int, count: int, length: int) -> int:
    return round(index * length / count)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("master", type=Path)
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()

    with Image.open(args.source) as source_image:
        source = source_image.convert("RGB")

    if source.width != source.height * 2:
        raise SystemExit(
            f"母图必须是 2:1，当前为 {source.width}×{source.height}"
        )

    args.master.parent.mkdir(parents=True, exist_ok=True)
    args.output_dir.mkdir(parents=True, exist_ok=True)

    master = Image.new(
        "RGB",
        (GRID_COLUMNS * MASTER_CELL_SIZE, GRID_ROWS * MASTER_CELL_SIZE),
    )

    for index, avatar_key in enumerate(AVATAR_KEYS):
        row, column = divmod(index, GRID_COLUMNS)
        left = proportional_edge(column, GRID_COLUMNS, source.width)
        top = proportional_edge(row, GRID_ROWS, source.height)
        right = proportional_edge(column + 1, GRID_COLUMNS, source.width)
        bottom = proportional_edge(row + 1, GRID_ROWS, source.height)
        tile = source.crop((left, top, right, bottom))

        master_tile = tile.resize(
            (MASTER_CELL_SIZE, MASTER_CELL_SIZE), Image.Resampling.LANCZOS
        )
        master.paste(
            master_tile,
            (column * MASTER_CELL_SIZE, row * MASTER_CELL_SIZE),
        )

        runtime_tile = tile.resize(
            (RUNTIME_SIZE, RUNTIME_SIZE), Image.Resampling.LANCZOS
        )
        runtime_tile.save(
            args.output_dir / f"{avatar_key}.webp",
            format="WEBP",
            lossless=True,
            method=6,
        )

    master.save(args.master, format="PNG", optimize=True)

    print(f"master={args.master} size={master.width}x{master.height} mode={master.mode}")
    print(
        f"avatars={len(AVATAR_KEYS)} size={RUNTIME_SIZE}x{RUNTIME_SIZE} "
        f"mode=RGB output={args.output_dir}"
    )


if __name__ == "__main__":
    main()
