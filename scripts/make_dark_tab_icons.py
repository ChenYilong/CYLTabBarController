#!/usr/bin/env python3
"""Generate dark variants of tab bar icons for the demos (#620).

Each dark icon is the original icon recolored to a light gray, keeping its alpha. It shows the three ways the library
picks up dark tab images:

  --suffix NAME            new imageset NAME_dark next to NAME (the naming convention, `UIImage.cyl_darkImageNameSuffix`)
  --copy NAME NEW_NAME     new imageset NEW_NAME next to NAME (for `CYLTabBarItemDarkImage` or a UIImage object)
  --appearance NAME        a Dark appearance inside NAME's own imageset (an asset catalog image, the recommended way)

Usage: scripts/make_dark_tab_icons.py <Assets.xcassets> [--suffix NAME]... [--copy NAME NEW_NAME]... [--appearance NAME]...
Requires Pillow. Running it again overwrites what it generated before.
"""

import argparse
import json
import os
import re
import sys

from PIL import Image

DARK_GRAY = (214, 214, 214)
DARK_APPEARANCE = [{"appearance": "luminosity", "value": "dark"}]
IMAGESET_EXTENSION = ".imageset"
CATALOG_EXTENSION = ".xcassets"
CONTENTS_FILE = "Contents.json"
# A plain file name: no path separators and no leading dot (so no "..").
SAFE_NAME = re.compile(r"[A-Za-z0-9_@+\-][A-Za-z0-9_@+.\- ]*")


def checked_name(name):
    """`name` if it is a plain file name, else exit."""
    if not SAFE_NAME.fullmatch(name):
        sys.exit("invalid name: %r" % name)
    return name


def checked_catalog(path):
    """The real path of an existing .xcassets directory, else exit."""
    catalog = os.path.realpath(path)
    if not (catalog.endswith(CATALOG_EXTENSION) and os.path.isdir(catalog)):
        sys.exit("not an asset catalog: %r" % path)
    return catalog


def inside(base, path):
    """The real path of `path` if it is inside `base`, else exit: nothing is read or written outside the catalog."""
    path = os.path.realpath(path)
    if os.path.commonpath([base, path]) != base:
        sys.exit("path outside %s: %r" % (base, path))
    return path


def child(catalog, directory, name):
    """`directory`/`name`, with `name` a plain file name, kept inside `catalog`."""
    return inside(catalog, os.path.join(directory, checked_name(name)))


def find_imageset(catalog, name):
    imageset_name = checked_name(name) + IMAGESET_EXTENSION
    for root, dirs, _ in os.walk(catalog):
        if imageset_name in dirs:
            return child(catalog, root, imageset_name)
    sys.exit("no %s in %s" % (imageset_name, catalog))


def recolor(source, destination):
    image = Image.open(source).convert("RGBA")
    pixels = image.load()
    for y in range(image.size[1]):
        for x in range(image.size[0]):
            pixels[x, y] = DARK_GRAY + (pixels[x, y][3],)
    image.save(destination, optimize=True)


def light_entries(catalog, imageset):
    with open(child(catalog, imageset, CONTENTS_FILE)) as file:
        contents = json.load(file)
    return contents, [entry for entry in contents["images"] if "filename" in entry and "appearances" not in entry]


def write_contents(catalog, imageset, contents):
    with open(child(catalog, imageset, CONTENTS_FILE), "w") as file:
        json.dump(contents, file, indent=2)
        file.write("\n")


def copy_recolored(catalog, name, new_name):
    source = find_imageset(catalog, name)
    destination = child(catalog, os.path.dirname(source), checked_name(new_name) + IMAGESET_EXTENSION)
    os.makedirs(destination, exist_ok=True)
    _, entries = light_entries(catalog, source)
    images = []
    for entry in entries:
        filename = entry["filename"].replace(name, new_name, 1)
        recolor(child(catalog, source, entry["filename"]), child(catalog, destination, filename))
        images.append(dict(entry, filename=filename))
    write_contents(catalog, destination, {"images": images, "info": {"author": "xcode", "version": 1}})


def add_dark_appearance(catalog, name):
    imageset = find_imageset(catalog, name)
    contents, entries = light_entries(catalog, imageset)
    images = list(entries)
    for entry in entries:
        base, extension = os.path.splitext(entry["filename"])
        filename = base.replace(name, name + "_dark_appearance", 1) + extension
        recolor(child(catalog, imageset, entry["filename"]), child(catalog, imageset, filename))
        images.append(dict(entry, filename=filename, appearances=DARK_APPEARANCE))
    contents["images"] = images
    write_contents(catalog, imageset, contents)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("catalog")
    parser.add_argument("--suffix", action="append", default=[], metavar="NAME")
    parser.add_argument("--copy", action="append", default=[], nargs=2, metavar=("NAME", "NEW_NAME"))
    parser.add_argument("--appearance", action="append", default=[], metavar="NAME")
    arguments = parser.parse_args()
    catalog = checked_catalog(arguments.catalog)
    for name in arguments.suffix:
        copy_recolored(catalog, name, name + "_dark")
    for name, new_name in arguments.copy:
        copy_recolored(catalog, name, new_name)
    for name in arguments.appearance:
        add_dark_appearance(catalog, name)


if __name__ == "__main__":
    main()
