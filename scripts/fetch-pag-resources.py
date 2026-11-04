#!/usr/bin/env python3
"""
[EN] Downloads the PAG animation files listed in Example-Shared/PAGResources/pag-resources.json (issue #604) from the
     official libpag sample repositories, pinned to a commit, and checks each file's SHA-256. The files are not kept in
     this repository: like the libpag pod itself, they are fetched when you install, here by `pod install` in
     Example-PAG (a `pre_install` hook). Files already present with the right SHA-256 are skipped.

     Some sources have restrictive or no licenses (see the manifest's "repositories"); the files are only downloaded to
     your machine, from their original repositories. Check the terms before you ship any of them.

[CN] 从 libpag 官方示例仓库（固定到某个 commit）下载 Example-Shared/PAGResources/pag-resources.json 中列出的 PAG 动效文件
     （issue #604），并校验每个文件的 SHA-256。这些文件不保存在本仓库中：与 libpag pod 本身一样，在安装时获取，即在 Example-PAG 中执行
     `pod install` 时（`pre_install` 钩子）。已存在且 SHA-256 正确的文件会跳过。

     部分来源的许可有限制或没有许可（见清单中的 "repositories"）；文件只是从原仓库下载到你的电脑上。发布前请自行确认其使用条款。

Usage / 用法:
    python3 scripts/fetch-pag-resources.py            # download what is missing  下载缺少的文件
    python3 scripts/fetch-pag-resources.py --check    # exit 1 if a file is missing or wrong  文件缺失或不一致时退出码为 1
"""

import hashlib
import json
import os
import re
import sys
import tempfile
import time
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
RESOURCES_DIR = os.path.realpath(os.path.join(ROOT, "Example-Shared", "PAGResources"))
MANIFEST = os.path.join(RESOURCES_DIR, "pag-resources.json")

# [EN] The manifest is data: every value read from it is checked before it becomes a file path or a URL, so an edited
#      manifest cannot write outside RESOURCES_DIR or download from anywhere but the official libpag repositories.
# [CN] 清单是数据：从中读取的每个值在用作文件路径或 URL 之前都会校验，修改清单也无法写到 RESOURCES_DIR 之外，或从 libpag 官方仓库以外的地址下载。
RAW_PREFIX = "https://raw.githubusercontent.com/libpag/"
ALLOWED_REPOSITORIES = frozenset({
    "pag-ios", "pag-enterprise-ios", "pag-android", "pag-flutter", "pag-enterprise-android", "pag-web",
})
COMMIT_PATTERN = re.compile(r"[0-9a-f]{40}")
# "<repository>/<name>": one folder level, plain file names only (no "..", no absolute path).
# 「<仓库>/<文件名>」：只有一级目录，只允许普通文件名（不含 ".."，不是绝对路径）。
FILE_PATTERN = re.compile(r"[A-Za-z0-9][A-Za-z0-9_-]*/[A-Za-z0-9][A-Za-z0-9._-]*")
# A path inside the source repository: plain segments only. 源仓库中的路径：只允许普通的路径片段。
SOURCE_PATH_PATTERN = re.compile(r"[A-Za-z0-9_-][A-Za-z0-9._-]*(/[A-Za-z0-9_-][A-Za-z0-9._-]*)*")


class ManifestError(ValueError):
    pass


def safe_destination(relative_file):
    """[EN] The destination of a manifest entry, always inside RESOURCES_DIR. [CN] 清单条目的目标路径，始终位于 RESOURCES_DIR 内。"""
    if not isinstance(relative_file, str) or not FILE_PATTERN.fullmatch(relative_file):
        raise ManifestError("invalid file name in the manifest: {!r}".format(relative_file))
    destination = os.path.realpath(os.path.join(RESOURCES_DIR, relative_file))
    if os.path.commonpath([RESOURCES_DIR, destination]) != RESOURCES_DIR:
        raise ManifestError("file outside {}: {!r}".format(RESOURCES_DIR, relative_file))
    return destination


def safe_url(entry):
    """[EN] The raw URL of a manifest entry, only in an allowed libpag repository at a full commit.
    [CN] 清单条目的下载地址，只能是允许的 libpag 仓库中、固定到完整 commit 的文件。"""
    repository = entry.get("repository", "")
    commit = entry.get("commit", "")
    path = entry.get("path", "")
    owner, _, name = repository.partition("/")
    if owner != "libpag" or name not in ALLOWED_REPOSITORIES:
        raise ManifestError("repository not allowed: {!r}".format(repository))
    if not isinstance(commit, str) or not COMMIT_PATTERN.fullmatch(commit):
        raise ManifestError("invalid commit: {!r}".format(commit))
    if not isinstance(path, str) or not SOURCE_PATH_PATTERN.fullmatch(path):
        raise ManifestError("invalid source path: {!r}".format(path))
    url = RAW_PREFIX + "{}/{}/{}".format(name, commit, urllib.parse.quote(path))
    if not url.startswith(RAW_PREFIX):
        raise ManifestError("unexpected URL: {!r}".format(url))
    return url


def sha256_of(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 16), b""):
            digest.update(chunk)
    return digest.hexdigest()


def is_current(entry):
    path = safe_destination(entry["file"])
    return os.path.isfile(path) and sha256_of(path) == entry["sha256"]


def download(entry):
    url = safe_url(entry)
    destination = safe_destination(entry["file"])
    os.makedirs(os.path.dirname(destination), exist_ok=True)
    last_error = None
    for attempt in range(4):
        try:
            with urllib.request.urlopen(url, timeout=60) as response:
                data = response.read()
            if hashlib.sha256(data).hexdigest() != entry["sha256"]:
                raise ValueError("SHA-256 mismatch for {}".format(url))
            # Written next to the destination, then moved, so a failed download never leaves half a file.
            handle, temporary = tempfile.mkstemp(dir=os.path.dirname(destination))
            with os.fdopen(handle, "wb") as output:
                output.write(data)
            os.replace(temporary, destination)
            return
        except Exception as error:  # network errors and hash mismatches are retried
            last_error = error
            time.sleep(2 ** attempt)
    raise RuntimeError("could not download {}: {}".format(url, last_error))


def main():
    check_only = "--check" in sys.argv[1:]
    with open(MANIFEST, encoding="utf-8") as handle:
        manifest = json.load(handle)
    entries = manifest["files"]
    # Validate the whole manifest before anything is written or downloaded. 在写入或下载之前先校验整个清单。
    for entry in entries:
        safe_url(entry)
        safe_destination(entry["file"])
        if not re.fullmatch(r"[0-9a-f]{64}", str(entry.get("sha256", ""))):
            raise ManifestError("invalid sha256 for {!r}".format(entry.get("file")))
    missing = [entry for entry in entries if not is_current(entry)]
    if check_only:
        for entry in missing:
            print("missing or changed: {}".format(entry["file"]))
        return 1 if missing else 0
    for index, entry in enumerate(missing, 1):
        print("[{}/{}] {} <- {}@{}".format(index, len(missing), entry["file"], entry["repository"], entry["commit"][:7]))
        download(entry)
    print("PAG resources ready: {} files in {}".format(len(entries), os.path.relpath(RESOURCES_DIR, ROOT)))
    for repository in manifest["repositories"]:
        if not repository["license"].startswith(("Apache", "MIT")):
            print("note: {} license: {}".format(repository["repository"], repository["license"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
