#!/usr/bin/env python3
"""
[EN] Downloads the Rive animation files listed in Example-Shared/RiveResources/rive-resources.json: each package's
     archive from pub.dev, pinned to a version and checked against its SHA-256, then only the listed members, each checked
     against its own SHA-256. The files are not kept in this repository: like the RiveRuntime pod itself, they are fetched
     when you install, here by `pod install` in Example-Rive (a `pre_install` hook). Files already present with the right
     SHA-256 are skipped.

[CN] 下载 Example-Shared/RiveResources/rive-resources.json 中列出的 Rive 动效文件：从 pub.dev 下载每个包的固定版本归档，并校验其 SHA-256，
     然后只解压清单中列出的文件，并逐个校验 SHA-256。这些文件不保存在本仓库中：与 RiveRuntime pod 本身一样，在安装时获取，即在
     Example-Rive 中执行 `pod install` 时（`pre_install` 钩子）。已存在且 SHA-256 正确的文件会跳过。

Usage / 用法:
    python3 scripts/fetch-rive-resources.py            # download what is missing  下载缺少的文件
    python3 scripts/fetch-rive-resources.py --check    # exit 1 if a file is missing or wrong  文件缺失或不一致时退出码为 1
"""

import hashlib
import io
import json
import os
import re
import sys
import tarfile
import tempfile
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
RESOURCES_DIR = os.path.realpath(os.path.join(ROOT, "Example-Shared", "RiveResources"))
MANIFEST = os.path.join(RESOURCES_DIR, "rive-resources.json")

# [EN] The manifest is data: every value read from it is checked before it becomes a file path or a URL, so an edited
#      manifest cannot write outside RESOURCES_DIR or download from anywhere but pub.dev's package archives.
# [CN] 清单是数据：从中读取的每个值在用作文件路径或 URL 之前都会校验，修改清单也无法写到 RESOURCES_DIR 之外，或从 pub.dev 包归档以外的地址下载。
ARCHIVE_PREFIX = "https://pub.dev/api/archives/"
PACKAGE_PATTERN = re.compile(r"[a-z][a-z0-9_]{0,63}")
VERSION_PATTERN = re.compile(r"\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?")
SHA256_PATTERN = re.compile(r"[0-9a-f]{64}")
# "<package>/<name>": one folder level, plain file names only (no "..", no absolute path).
# 「<包名>/<文件名>」：只有一级目录，只允许普通文件名（不含 ".."，不是绝对路径）。
FILE_PATTERN = re.compile(r"[a-z][a-z0-9_]*/[A-Za-z0-9][A-Za-z0-9._-]*")
# A path inside the archive: plain segments only. 归档中的路径：只允许普通的路径片段。
MEMBER_PATTERN = re.compile(r"[A-Za-z0-9_-][A-Za-z0-9._-]*(/[A-Za-z0-9_-][A-Za-z0-9._-]*)*")
MAX_ARCHIVE_SIZE = 64 * 1024 * 1024


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


def safe_url(package):
    """[EN] The pub.dev archive URL of a package at a fixed version. [CN] 固定版本的包在 pub.dev 上的归档地址。"""
    name = package.get("package", "")
    version = package.get("version", "")
    if not isinstance(name, str) or not PACKAGE_PATTERN.fullmatch(name):
        raise ManifestError("invalid package name: {!r}".format(name))
    if not isinstance(version, str) or not VERSION_PATTERN.fullmatch(version):
        raise ManifestError("invalid version: {!r}".format(version))
    url = "{}{}-{}.tar.gz".format(ARCHIVE_PREFIX, name, version)
    if not url.startswith(ARCHIVE_PREFIX):
        raise ManifestError("unexpected URL: {!r}".format(url))
    return url


def validate(manifest):
    """[EN] Validates the whole manifest before anything is written or downloaded. [CN] 在写入或下载之前先校验整个清单。"""
    for package in manifest["packages"]:
        safe_url(package)
        if not SHA256_PATTERN.fullmatch(str(package.get("archive_sha256", ""))):
            raise ManifestError("invalid archive_sha256 for {!r}".format(package.get("package")))
        for entry in package["files"]:
            safe_destination(entry["file"])
            if not isinstance(entry.get("member"), str) or not MEMBER_PATTERN.fullmatch(entry["member"]):
                raise ManifestError("invalid archive member: {!r}".format(entry.get("member")))
            if not SHA256_PATTERN.fullmatch(str(entry.get("sha256", ""))):
                raise ManifestError("invalid sha256 for {!r}".format(entry.get("file")))


def sha256_of(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 16), b""):
            digest.update(chunk)
    return digest.hexdigest()


def is_current(entry):
    path = safe_destination(entry["file"])
    return os.path.isfile(path) and sha256_of(path) == entry["sha256"]


def download_archive(package):
    url = safe_url(package)
    last_error = None
    for attempt in range(4):
        try:
            with urllib.request.urlopen(url, timeout=60) as response:
                data = response.read(MAX_ARCHIVE_SIZE + 1)
            if len(data) > MAX_ARCHIVE_SIZE:
                raise ValueError("archive too large: {}".format(url))
            if hashlib.sha256(data).hexdigest() != package["archive_sha256"]:
                raise ValueError("SHA-256 mismatch for {}".format(url))
            return data
        except Exception as error:  # network errors and hash mismatches are retried
            last_error = error
            time.sleep(2 ** attempt)
    raise RuntimeError("could not download {}: {}".format(url, last_error))


def extract(archive, entries):
    """[EN] Reads only the listed regular files (no links, no other member is written). [CN] 只读取清单中列出的普通文件（不处理链接，不写入其他成员）。"""
    with tarfile.open(fileobj=io.BytesIO(archive), mode="r:gz") as tar:
        for entry in entries:
            member = tar.getmember(entry["member"])
            if not member.isfile():
                raise ValueError("not a regular file in the archive: {}".format(entry["member"]))
            data = tar.extractfile(member).read()
            if hashlib.sha256(data).hexdigest() != entry["sha256"]:
                raise ValueError("SHA-256 mismatch for {}".format(entry["member"]))
            destination = safe_destination(entry["file"])
            os.makedirs(os.path.dirname(destination), exist_ok=True)
            # Written next to the destination, then moved, so a failure never leaves half a file.
            # 先写到目标旁边再移动，失败时不会留下不完整的文件。
            handle, temporary = tempfile.mkstemp(dir=os.path.dirname(destination))
            with os.fdopen(handle, "wb") as output:
                output.write(data)
            # [EN] Kept as mkstemp creates it: readable by the owner only. [CN] 保持 mkstemp 创建时的权限：仅所有者可读写。
            os.replace(temporary, destination)


def main():
    check_only = "--check" in sys.argv[1:]
    with open(MANIFEST, encoding="utf-8") as handle:
        manifest = json.load(handle)
    validate(manifest)
    missing_count = 0
    total = 0
    for package in manifest["packages"]:
        missing = [entry for entry in package["files"] if not is_current(entry)]
        total += len(package["files"])
        missing_count += len(missing)
        if check_only:
            for entry in missing:
                print("missing or changed: {}".format(entry["file"]))
            continue
        if missing:
            print("{} {} <- {}".format(package["package"], package["version"], safe_url(package)))
            extract(download_archive(package), missing)
    if check_only:
        return 1 if missing_count else 0
    print("Rive resources ready: {} files in {}".format(total, os.path.relpath(RESOURCES_DIR, ROOT)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
