#!/usr/bin/env python3
"""
[EN] Downloads the animation files of the demos, listed in Example-Shared/<Folder>/*-resources.json, pinned and checked
     against their SHA-256. The files are not kept in this repository: like the pods themselves, they are fetched when you
     install, by `pod install` in Example-PAG (a `pre_install` hook). Files already present with the right
     SHA-256 are skipped. One script serves every animation library: a library added later adds a manifest
     ("files": single files from a GitHub repository at a full commit) and, for a new repository, one line to
     ALLOWED_GITHUB_REPOSITORIES.

     Some sources have restrictive or no licenses (see each manifest); the files are only downloaded to your machine,
     from their original location. Check the terms before you ship any of them.

[CN] 下载 Demo 使用的动效文件（列在 Example-Shared/<目录>/*-resources.json 中），固定版本并校验 SHA-256。这些文件不保存在本仓库中：与 pod
     本身一样，在安装时获取，即在 Example-PAG 中执行 `pod install` 时（`pre_install` 钩子）。已存在且 SHA-256 正确的文件会跳过。
     所有动画库共用这一个脚本：以后新增的动画库只需新增一个清单（"files"：GitHub 仓库中固定到完整 commit 的单个文件），来源是新的仓库时，
     再在 ALLOWED_GITHUB_REPOSITORIES 中加一行。

     部分来源的许可有限制或没有许可（见各清单）；文件只是从原来的位置下载到你的电脑上。发布前请自行确认其使用条款。

Usage / 用法:
    python3 scripts/fetch-animation-resources.py PAGResources            # download what is missing  下载缺少的文件
    python3 scripts/fetch-animation-resources.py PAGResources --check    # exit 1 if a file is missing or wrong  缺失或不一致时退出码为 1
    python3 scripts/fetch-animation-resources.py --check                 # every folder  所有目录
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
SHARED_DIR = os.path.realpath(os.path.join(ROOT, "Example-Shared"))

# [EN] Manifests are data: every value read from one is checked before it becomes a file path or a URL, so an edited
#      manifest cannot write outside its folder or download from anywhere but these sources.
# [CN] 清单是数据：从中读取的每个值在用作文件路径或 URL 之前都会校验，修改清单也无法写到其目录之外，或从以下来源以外的地址下载。
ALLOWED_GITHUB_REPOSITORIES = {
    "Tencent": frozenset({"libpag"}),
    "libpag": frozenset({
        "pag-ios", "pag-enterprise-ios", "pag-android", "pag-flutter", "pag-enterprise-android", "pag-web",
    }),
}
GITHUB_RAW_PREFIX = "https://raw.githubusercontent.com/"
# [EN] Files kept in Git LFS ("lfs": true in the manifest): the raw URL only gives a small pointer file.
# [CN] 保存在 Git LFS 中的文件（清单中的 "lfs": true）：raw 地址只能得到一个很小的指针文件。
GITHUB_LFS_PREFIX = "https://media.githubusercontent.com/media/"

FOLDER_PATTERN = re.compile(r"[A-Za-z][A-Za-z0-9]*Resources")
COMMIT_PATTERN = re.compile(r"[0-9a-f]{40}")
SHA256_PATTERN = re.compile(r"[0-9a-f]{64}")
# "<sub folder>/<name>": one folder level, plain file names only (no "..", no absolute path).
# 「<子目录>/<文件名>」：只有一级目录，只允许普通文件名（不含 ".."，不是绝对路径）。
FILE_PATTERN = re.compile(r"[A-Za-z0-9][A-Za-z0-9_-]*/[A-Za-z0-9][A-Za-z0-9._-]*")
# A path inside a repository: plain segments only. 仓库中的路径：只允许普通的路径片段。
SOURCE_PATH_PATTERN = re.compile(r"[A-Za-z0-9_-][A-Za-z0-9._-]*(/[A-Za-z0-9_-][A-Za-z0-9._-]*)*")
MAX_DOWNLOAD_SIZE = 64 * 1024 * 1024


class ManifestError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise ManifestError(message)


def safe_destination(folder, relative_file):
    """[EN] The destination of a manifest entry, always inside `folder`. [CN] 清单条目的目标路径，始终位于 `folder` 内。"""
    require(isinstance(relative_file, str) and FILE_PATTERN.fullmatch(relative_file),
            "invalid file name in the manifest: {!r}".format(relative_file))
    destination = os.path.realpath(os.path.join(folder, relative_file))
    require(os.path.commonpath([folder, destination]) == folder, "file outside {}: {!r}".format(folder, relative_file))
    return destination


def github_url(entry):
    """[EN] A file of an allowed GitHub repository at a full commit. [CN] 允许的 GitHub 仓库中、固定到完整 commit 的文件。"""
    owner, _, name = str(entry.get("repository", "")).partition("/")
    require(name in ALLOWED_GITHUB_REPOSITORIES.get(owner, ()), "repository not allowed: {!r}".format(entry.get("repository")))
    commit, path = entry.get("commit", ""), entry.get("path", "")
    require(isinstance(commit, str) and COMMIT_PATTERN.fullmatch(commit), "invalid commit: {!r}".format(commit))
    require(isinstance(path, str) and SOURCE_PATH_PATTERN.fullmatch(path), "invalid source path: {!r}".format(path))
    prefix = GITHUB_LFS_PREFIX if entry.get("lfs") is True else GITHUB_RAW_PREFIX
    return "{}{}/{}/{}/{}".format(prefix, owner, name, commit, urllib.parse.quote(path))


def check_sha256(value, what):
    require(SHA256_PATTERN.fullmatch(str(value)), "invalid sha256 for {!r}".format(what))


def plan(folder, manifest):
    """
    [EN] Validates the whole manifest before anything is downloaded, then returns its downloads as
         (url, sha256, [(None, sha256, destination)]).
    [CN] 在下载之前先校验整个清单，然后以 (url, sha256, [(None, sha256, 目标路径)]) 的形式返回其下载项。
    """
    downloads = []
    for entry in manifest.get("files", []):
        check_sha256(entry.get("sha256"), entry.get("file"))
        downloads.append((github_url(entry), entry["sha256"], [(None, entry["sha256"], safe_destination(folder, entry["file"]))]))
    return downloads


def sha256_of_file(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 16), b""):
            digest.update(chunk)
    return digest.hexdigest()


def is_current(destination, sha256):
    return os.path.isfile(destination) and sha256_of_file(destination) == sha256


def fetch(url, sha256):
    last_error = None
    for attempt in range(4):
        try:
            with urllib.request.urlopen(url, timeout=60) as response:
                data = response.read(MAX_DOWNLOAD_SIZE + 1)
            if len(data) > MAX_DOWNLOAD_SIZE:
                raise ValueError("too large: {}".format(url))
            if hashlib.sha256(data).hexdigest() != sha256:
                raise ValueError("SHA-256 mismatch for {}".format(url))
            return data
        except Exception as error:  # network errors and hash mismatches are retried
            last_error = error
            time.sleep(2 ** attempt)
    raise RuntimeError("could not download {}: {}".format(url, last_error))


def write(destination, data, sha256):
    if hashlib.sha256(data).hexdigest() != sha256:
        raise ValueError("SHA-256 mismatch for {}".format(destination))
    os.makedirs(os.path.dirname(destination), exist_ok=True)
    # [EN] Written next to the destination, then moved, so a failure never leaves half a file; kept as mkstemp creates
    #      it (readable by the owner only).
    # [CN] 先写到目标旁边再移动，失败时不会留下不完整的文件；保持 mkstemp 创建时的权限（仅所有者可读写）。
    handle, temporary = tempfile.mkstemp(dir=os.path.dirname(destination))
    with os.fdopen(handle, "wb") as output:
        output.write(data)
    os.replace(temporary, destination)


def resource_folder(folder_name):
    """[EN] Example-Shared/<folder_name>, validated. [CN] 校验后的 Example-Shared/<folder_name>。"""
    require(FOLDER_PATTERN.fullmatch(folder_name), "invalid folder: {!r}".format(folder_name))
    folder = os.path.realpath(os.path.join(SHARED_DIR, folder_name))
    require(os.path.commonpath([SHARED_DIR, folder]) == SHARED_DIR, "folder outside Example-Shared: {!r}".format(folder_name))
    return folder


def folder_downloads(folder):
    """[EN] The downloads of every manifest in `folder`. [CN] `folder` 中所有清单的下载项。"""
    manifests = sorted(name for name in os.listdir(folder) if name.endswith("-resources.json") and not name.startswith("._"))
    require(manifests, "no *-resources.json in {}".format(folder))
    downloads = []
    for manifest_name in manifests:
        with open(os.path.join(folder, manifest_name), encoding="utf-8") as handle:
            downloads.extend(plan(folder, json.load(handle)))
    return downloads


def download_missing(folder, url, sha256, missing):
    """[EN] Downloads `url` once and writes the missing targets. [CN] 下载 `url` 一次，并写入缺少的目标文件。"""
    print("{} <- {}".format(", ".join(os.path.relpath(target[2], folder) for target in missing), url))
    data = fetch(url, sha256)
    for _, target_sha256, destination in missing:
        write(destination, data, target_sha256)


def process(folder_name, check_only):
    """[EN] Checks, or fetches, one folder; returns the number of missing files. [CN] 校验或下载一个目录，返回缺少的文件数。"""
    folder = resource_folder(folder_name)
    missing_count = 0
    total = 0
    for url, sha256, targets in folder_downloads(folder):
        missing = [target for target in targets if not is_current(target[2], target[1])]
        total += len(targets)
        missing_count += len(missing)
        if check_only:
            for target in missing:
                print("missing or changed: {}".format(os.path.relpath(target[2], ROOT)))
        elif missing:
            download_missing(folder, url, sha256, missing)
    if not check_only:
        print("{}: {} files ready".format(folder_name, total))
    return missing_count


def main():
    arguments = sys.argv[1:]
    check_only = "--check" in arguments
    folders = [argument for argument in arguments if argument != "--check"]
    if not folders:
        folders = sorted(name for name in os.listdir(SHARED_DIR) if FOLDER_PATTERN.fullmatch(name))
    missing = sum(process(folder, check_only) for folder in folders)
    return 1 if check_only and missing else 0


if __name__ == "__main__":
    sys.exit(main())
