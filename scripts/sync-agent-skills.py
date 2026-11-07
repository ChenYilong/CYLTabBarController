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
NAME_RE = re.compile(r"^name:\s*['\"]?([^'\"\n]+?)['\"]?\s*$", re.M)
VALID_NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
SKIPPED = {".git", ".github", ".DS_Store", "__pycache__"}
UPSTREAM_LICENSE = "UPSTREAM-LICENSE"


def skill_name(skill_md):
    """[EN] The `name:` of a SKILL.md's frontmatter, or None. [CN] SKILL.md frontmatter 中的 `name:`，没有时为 None。"""
    text = skill_md.read_text(encoding="utf-8", errors="replace")
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    match = NAME_RE.search(text[:end] if end > 0 else text)
    return match.group(1).strip() if match else None


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


def vendor(manifest):
    entries = {}
    with tempfile.TemporaryDirectory() as temp:
        for index, source in enumerate(manifest["sources"]):
            checkout = pathlib.Path(temp) / str(index)
            clone(source["repo"], source["commit"], checkout)
            for relative in source["skills"]:
                origin = (checkout / source.get("root", "") / relative).resolve()
                declared = skill_name(origin / "SKILL.md")
                if not declared:
                    sys.exit("%s/%s: SKILL.md has no name" % (source["repo"], relative))
                # [EN] Agent Skills names are lowercase and hyphenated; another name is replaced by the folder's name.
                # [CN] Agent Skills 的名字只含小写字母和连字符；其他名字替换为文件夹名。
                name = declared if VALID_NAME_RE.match(declared) else origin.name.split("--")[-1]
                if name in entries or name.startswith("cyl-"):
                    sys.exit("%s/%s: the name %s is already taken" % (source["repo"], relative, name))
                target = SKILLS / name
                remove_folder(target)
                excluded = set(source.get("exclude", []))
                shutil.copytree(origin, target, symlinks=False, dirs_exist_ok=True,
                                ignore=lambda _, names: [n for n in names if ignored(n) or n in excluded])
                shutil.copy(checkout / source["licenseFile"], target / UPSTREAM_LICENSE)
                if declared != name:
                    skill_md = target / "SKILL.md"
                    text = skill_md.read_text(encoding="utf-8")
                    skill_md.write_text(NAME_RE.sub("name: " + name, text, count=1), encoding="utf-8")
                entries[name] = {"source": source["repo"], "path": relative, "commit": source["commit"],
                                 "license": source["license"], "integrity": integrity(target)}
    tracked = set(entries)
    previous = json.loads(LOCK.read_text()).get("skills", {}) if LOCK.exists() else {}
    for name in set(previous) - tracked:
        remove_folder(SKILLS / name)
    LOCK.write_text(json.dumps({"schemaVersion": 1, "skills": dict(sorted(entries.items()))}, indent=2) + "\n")
    print("Vendored %d skills from %d repositories." % (len(entries), len(manifest["sources"])))


def coverage_problems():
    """[EN] A new document or demo must reach the project skills, so a new project can be started from them.
    [CN] 新文档或新 Demo 必须写入项目 skill，这样才能基于 skill 创建新项目。"""
    problems = []
    api_map = (SKILLS / "cyl-api-map" / "SKILL.md").read_text(encoding="utf-8")
    for document in sorted((ROOT / "docs").glob("*.md")):
        if document.name != "README.md" and not ignored(document.name) and "docs/%s)" % document.name not in api_map:
            problems.append("docs/%s: no row in the cyl-api-map skill" % document.name)
    new_project = (SKILLS / "cyl-new-project" / "SKILL.md").read_text(encoding="utf-8")
    output = subprocess.check_output(["git", "-C", str(ROOT), "ls-files", "-z", "Example*"], text=True)
    for demo in sorted({path.split("/")[0] for path in output.split("\0") if "/" in path}):
        if "`%s`" % demo not in new_project and "`%s/`" % demo not in new_project:
            problems.append("%s: not in the table of the cyl-new-project skill" % demo)
    return problems


def check():
    problems = []
    entries = json.loads(LOCK.read_text())["skills"] if LOCK.exists() else {}
    on_disk = {p.name for p in SKILLS.iterdir() if p.is_dir()}
    for name, entry in entries.items():
        folder = SKILLS / name
        if not folder.is_dir():
            problems.append("%s: in the lock file, missing on disk" % name)
        elif integrity(folder) != entry["integrity"]:
            problems.append("%s: edited by hand; run the sync, or change the manifest" % name)
        elif not (folder / UPSTREAM_LICENSE).is_file():
            problems.append("%s: its upstream license is missing" % name)
    for name in sorted(on_disk - set(entries)):
        if not name.startswith("cyl-"):
            problems.append("%s: not in the lock file; only cyl-* skills are written here" % name)
    for name in sorted(on_disk):
        skill_md = SKILLS / name / "SKILL.md"
        if not skill_md.is_file():
            problems.append("%s: no SKILL.md" % name)
        elif skill_name(skill_md) != name:
            problems.append("%s: the frontmatter name differs from the folder" % name)
    problems.extend(coverage_problems())
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
        output = subprocess.check_output(["git", "ls-remote", "https://github.com/%s.git" % args.update, "HEAD"], text=True)
        matches[0]["commit"] = output.split()[0]
        MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
    SKILLS.mkdir(parents=True, exist_ok=True)
    vendor(manifest)
    return check()


if __name__ == "__main__":
    sys.exit(main())
