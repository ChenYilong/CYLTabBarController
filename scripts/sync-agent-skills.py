#!/usr/bin/env python3
"""
[EN] Vendors the third-party agent skills listed in .agents/skills.json into .agents/skills, at the pinned commits, and
     records each one's hash in .agents/skills.lock.json. cyl-* skills are this project's own and are only checked.
       python3 scripts/sync-agent-skills.py                 # vendor again from the manifest
       python3 scripts/sync-agent-skills.py --check         # offline: exit 1 on drift or a broken skill (CI runs this)
       python3 scripts/sync-agent-skills.py --update REPO   # move REPO's pin to its default branch's latest commit, then vendor
     Python 3 standard library and git only. Untrusted input: nothing from a skill is ever executed here.
[CN] 按 .agents/skills.json 中固定的 commit，把第三方 agent skills 拷贝到 .agents/skills，并在 .agents/skills.lock.json 中记录每个 skill 的哈希。
     cyl-* 是本项目自己的 skill，只做检查。只依赖 Python 3 标准库和 git。第三方内容不可信：这里不会执行 skill 中的任何内容。
"""
import argparse
import base64
import hashlib
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
AGENTS = ROOT / ".agents"
SKILLS = AGENTS / "skills"
MANIFEST = AGENTS / "skills.json"
LOCK = AGENTS / "skills.lock.json"
NAME_LINE_RE = re.compile(r"^name:(.*)$", re.M)
VALID_NAME_RE = re.compile(r"[a-z0-9]+(-[a-z0-9]+)*")
REPOSITORY_RE = re.compile(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+")
COMMIT_RE = re.compile(r"[0-9a-f]{40}")
SKILL_FILE = "SKILL.md"
SKIPPED = {".git", ".github", ".DS_Store", "__pycache__"}
UPSTREAM_LICENSE = "UPSTREAM-LICENSE"


def skill_name(skill_md):
    """[EN] The `name:` of a SKILL.md's frontmatter, or None. [CN] SKILL.md frontmatter 中的 `name:`，没有时为 None。"""
    text = skill_md.read_text(encoding="utf-8", errors="replace")
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    match = NAME_LINE_RE.search(text[:end] if end > 0 else text)
    return match.group(1).strip().strip("'\"") if match else None


def child_path(base, relative):
    """[EN] `base`/`relative`, refused when it leaves `base`: manifests, lock files and third-party SKILL.md files are data.
    [CN] `base`/`relative`，超出 `base` 时拒绝：清单、锁文件与第三方 SKILL.md 都是数据，不可信。"""
    root = os.path.realpath(base)
    path = os.path.realpath(os.path.join(root, str(relative)))
    if os.path.commonpath([root, path]) != root:
        sys.exit("Path outside %s: %s" % (root, relative))
    return pathlib.Path(path)


def installed_skill_folder(name):
    """[EN] The folder of a skill, for a valid skill name only. [CN] 技能的文件夹，只接受有效的技能名。"""
    if not VALID_NAME_RE.fullmatch(str(name)):
        sys.exit("Invalid skill name: %r" % (name,))
    return child_path(SKILLS, name)


def check_source(source):
    """[EN] Checks a manifest entry before it becomes a URL or a git argument. [CN] 在用作 URL 或 git 参数之前校验清单项。"""
    if not REPOSITORY_RE.fullmatch(str(source.get("repo", ""))):
        sys.exit("Invalid repository: %r" % (source.get("repo"),))
    if not COMMIT_RE.fullmatch(str(source.get("commit", ""))):
        sys.exit("%s: the commit must be a full hash" % source["repo"])


def integrity(folder):
    """[EN] A hash of every file's path and content, without macOS metadata. [CN] 所有文件路径与内容的哈希，不含 macOS 元数据。"""
    digest = hashlib.sha256()
    for path in sorted(p for p in folder.rglob("*") if p.is_file() and not ignored(p.name)):
        digest.update(path.relative_to(folder).as_posix().encode())
        digest.update(b"\0")
        digest.update(path.read_bytes())
    return "sha256-" + base64.b64encode(digest.digest()).decode()


def ignored(name):
    return name in SKIPPED or name.startswith("._")


def remove_folder(folder):
    """[EN] On exFAT, macOS removes `._*` files by itself during the walk: walk again until it is gone.
    [CN] 在 exFAT 上，macOS 会在遍历期间自行删除 `._*` 文件：重复删除直到文件夹消失。"""
    for _ in range(5):
        shutil.rmtree(folder, ignore_errors=True)
        if not folder.exists():
            return
    sys.exit("Could not remove %s" % folder)


def clone(repo, commit, into):
    url = "https://github.com/%s.git" % repo
    subprocess.check_call(["git", "clone", "-q", "--filter=blob:none", url, str(into)])
    subprocess.check_call(["git", "-C", str(into), "checkout", "-q", commit])


def vendor_skill(source, relative, checkout, entries):
    """[EN] Copies one skill of `checkout` and records it. [CN] 拷贝 `checkout` 中的一个技能并记录。"""
    origin = child_path(checkout, os.path.join(source.get("root", ""), relative))
    declared = skill_name(origin / SKILL_FILE)
    if not declared:
        sys.exit("%s/%s: %s has no name" % (source["repo"], relative, SKILL_FILE))
    # [EN] Agent Skills names are lowercase and hyphenated; another name is replaced by the folder's name.
    # [CN] Agent Skills 的名字只含小写字母和连字符；其他名字替换为文件夹名。
    name = declared if VALID_NAME_RE.fullmatch(declared) else origin.name.split("--")[-1]
    if name in entries or name.startswith("cyl-"):
        sys.exit("%s/%s: the name %s is already taken" % (source["repo"], relative, name))
    target = installed_skill_folder(name)
    remove_folder(target)
    excluded = frozenset(source.get("exclude", []))
    def ignore_names(_, names, excluded=excluded):
        return [n for n in names if ignored(n) or n in excluded]
    shutil.copytree(origin, target, symlinks=False, dirs_exist_ok=True, ignore=ignore_names)
    shutil.copy(child_path(checkout, source["licenseFile"]), target / UPSTREAM_LICENSE)
    if declared != name:
        skill_md = target / SKILL_FILE
        text = skill_md.read_text(encoding="utf-8")
        skill_md.write_text(NAME_LINE_RE.sub("name: " + name, text, count=1), encoding="utf-8")
    entries[name] = {"source": source["repo"], "path": relative, "commit": source["commit"],
                     "license": source["license"], "integrity": integrity(target)}


def vendor(manifest):
    entries = {}
    with tempfile.TemporaryDirectory() as temp:
        for index, source in enumerate(manifest["sources"]):
            check_source(source)
            checkout = pathlib.Path(temp) / str(index)
            clone(source["repo"], source["commit"], checkout)
            for relative in source["skills"]:
                vendor_skill(source, relative, checkout, entries)
    previous = json.loads(LOCK.read_text()).get("skills", {}) if LOCK.exists() else {}
    for name in set(previous) - set(entries):
        remove_folder(installed_skill_folder(name))
    LOCK.write_text(json.dumps({"schemaVersion": 1, "skills": dict(sorted(entries.items()))}, indent=2) + "\n")
    print("Vendored %d skills from %d repositories." % (len(entries), len(manifest["sources"])))


def coverage_problems():
    """[EN] A new document or demo must reach the project skills, so a new project can be started from them.
    [CN] 新文档或新 Demo 必须写入项目 skill，这样才能基于 skill 创建新项目。"""
    problems = []
    api_map = (SKILLS / "cyl-api-map" / SKILL_FILE).read_text(encoding="utf-8")
    for document in sorted((ROOT / "docs").glob("*.md")):
        if document.name != "README.md" and not ignored(document.name) and "docs/%s)" % document.name not in api_map:
            problems.append("docs/%s: no row in the cyl-api-map skill" % document.name)
    new_project = (SKILLS / "cyl-new-project" / SKILL_FILE).read_text(encoding="utf-8")
    output = subprocess.check_output(["git", "-C", str(ROOT), "ls-files", "-z", "Example*"], text=True)
    for demo in sorted({path.split("/")[0] for path in output.split("\0") if "/" in path}):
        if "`%s`" % demo not in new_project and "`%s/`" % demo not in new_project:
            problems.append("%s: not in the table of the cyl-new-project skill" % demo)
    return problems


def lock_problems(entries):
    problems = []
    for name, entry in entries.items():
        folder = installed_skill_folder(name)
        if not folder.is_dir():
            problems.append("%s: in the lock file, missing on disk" % name)
        elif integrity(folder) != entry["integrity"]:
            problems.append("%s: edited by hand; run the sync, or change the manifest" % name)
        elif not (folder / UPSTREAM_LICENSE).is_file():
            problems.append("%s: its upstream license is missing" % name)
    return problems


def folder_problems(on_disk, entries):
    problems = []
    for name in sorted(on_disk):
        if name not in entries and not name.startswith("cyl-"):
            problems.append("%s: not in the lock file; only cyl-* skills are written here" % name)
        skill_md = SKILLS / name / SKILL_FILE
        if not skill_md.is_file():
            problems.append("%s: no %s" % (name, SKILL_FILE))
        elif skill_name(skill_md) != name:
            problems.append("%s: the frontmatter name differs from the folder" % name)
    return problems


def check():
    entries = json.loads(LOCK.read_text())["skills"] if LOCK.exists() else {}
    on_disk = {p.name for p in SKILLS.iterdir() if p.is_dir()}
    problems = lock_problems(entries) + folder_problems(on_disk, entries) + coverage_problems()
    link = ROOT / ".claude" / "skills"
    if not link.is_symlink() or link.resolve() != SKILLS.resolve():
        problems.append(".claude/skills must be a symlink to ../.agents/skills")
    for problem in problems:
        print("error: " + problem)
    print("Checked %d skills: %s." % (len(on_disk), "%d problems" % len(problems) if problems else "OK"))
    return 1 if problems else 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--update", metavar="OWNER/REPO")
    args = parser.parse_args()
    if args.check:
        return check()
    manifest = json.loads(MANIFEST.read_text())
    if args.update:
        matches = [s for s in manifest["sources"] if s["repo"] == args.update]
        if not matches:
            sys.exit("%s is not in the manifest" % args.update)
        check_source({"repo": args.update, "commit": matches[0]["commit"]})
        output = subprocess.check_output(["git", "ls-remote", "--", "https://github.com/%s.git" % args.update, "HEAD"], text=True)
        commit = output.split()[0] if output.split() else ""
        # [EN] Only a full commit hash reaches the manifest. [CN] 只有完整的提交哈希才会写入清单。
        if not COMMIT_RE.fullmatch(commit):
            sys.exit("unexpected ls-remote output for %s" % args.update)
        matches[0]["commit"] = commit
        with open(MANIFEST, "w", encoding="utf-8") as manifest_file:
            json.dump(manifest, manifest_file, indent=2, ensure_ascii=False)
            manifest_file.write("\n")
    SKILLS.mkdir(parents=True, exist_ok=True)
    vendor(manifest)
    return check()


if __name__ == "__main__":
    sys.exit(main())
