# learn-codebase guide: where to write the output, and how to publish it safely

**Read this whole file before running claude-mem's learn-codebase, or before exporting or committing its output.**

Adapted on 2026-11-29 from the guide of the sibling repository CYLSearchViewController
(`docs/learn-codebase/README.md` there). **Tried**, **Source** and **Untested** below are that guide's labels and refer to its
run (Windows 11, claude-mem 17.0.2) unless this file says otherwise:

- **Tried**: done on the machine of that run.
- **Source**: read in the claude-mem 17.0.2 plugin code; not exercised separately.
- **Untested**: not tried (including everything on macOS and Linux).

Plugin behaviour can change between versions: check again after an upgrade.

Placeholders: `<repo>` the repository root; `<data dir>` claude-mem's data folder (`~/.claude-mem` by default, moved by
`CLAUDE_MEM_DATA_DIR`); `<plugin dir>` the installed plugin version folder
(`~/.claude/plugins/cache/thedotmack/claude-mem/<version>`); `<project>` the repository name,
`CYLTabBarController` here. Use `py` on Windows where this guide says `python3`.

## 1. Layout

| Path | What |
|:---|:---|
| `docs/learn-codebase/README.md` | This guide |
| `docs/learn-codebase/learn-codebase-YYYY-MM-DD/` | One folder per run, with its own index `README.md` |

The 2026-11-29 run, [learn-codebase-2026-11-29/](learn-codebase-2026-11-29/README.md), is a **partial** read: five numbered
summaries and two reference files. The summaries also quote selected claude-mem observation records (see section 6).

## 2. Say where the output goes

The learn-codebase skill asks the agent to read every source file in full. **It defines no output path** (**Tried**: the
skill text has none). No claude-mem setting for a separate deliverables folder is known (**Untested**: reported from a
reading of the plugin code that was not repeated for this guide). So **name the
path in your prompt**. Otherwise a session may keep notes in a temporary folder or create its own folder under
`<data dir>/deliverables/`.

Run the command from the repository root with a prompt like this:

```text
/claude-mem:learn-codebase
Before you start, read docs/learn-codebase/README.md in full and follow it.
Write every deliverable in English, using repository-relative paths only.
Final location: docs/learn-codebase/learn-codebase-<YYYY-MM-DD>/ in this repository.
Draft outside docs/learn-codebase (a temporary folder) and move files in only after the cleanup in the guide.
Do not export raw claude-mem observations into the repository.
Do not commit until the cleanup and checks in the guide pass.
```

- **Draft outside the watched folder, then move in.** Once the folder is watched (section 3), every saved version of a file
  is stored as a new memory and old versions stay in the database (**Tried**: after one cleanup pass the database held 114
  rows for 55 paths, including text from before the cleanup).
- `~/.claude-mem/deliverables/<project>/` is not the repository. claude-mem's own deliverables feature is reported to
  **copy** certain files there and record them, and not to read a folder created there by hand (**Untested**: from the same
  unrepeated reading). If files are already there, check that no database record points at them, copy, compare checksums, then delete the originals
  (**Tried**).
- **Project names.** The 2026-11-29 session was started from the parent folder of all repositories, and claude-mem filed
  its work state under that folder's name, not under this repository (**Tried**). Starting from `<repo>` should give
  `<project>` (**Untested**). Always pass the right `project` to memory searches.

## 3. Let claude-mem ingest the folder (also on a new computer)

The committed folder travels with Git; claude-mem's local database does not travel with it. **To get the existing
knowledge on a new computer, you do not need to run learn-codebase again**: clone, add the watch root, restart the
worker. Re-run the skill only when you want a fresh reading; give it a new dated folder.

The setting is `CLAUDE_MEM_MEMORY_WATCH_ROOTS` in `<data dir>/settings.json`. Its value is a **string that contains
JSON**: a list of at most 8 objects with `path` (absolute, or starting with `~/`) and `project` (**Source**; used with
four entries, **Tried**). Watch `<repo>/docs/learn-codebase` only, never all of `docs/`.

Other sessions may edit the same file: merge your entry, never replace the list. `settings.json` can hold tokens: never
print it or commit it, or its backup. Save this as `add_watch_root.py` outside the repository and run
`python3 add_watch_root.py <repo> <project>`:

```python
import json, os, pathlib, shutil, sys, time

repo, project = pathlib.Path(sys.argv[1]).resolve(), sys.argv[2]
folder = repo / "docs" / "learn-codebase"
if not folder.is_dir():
    sys.exit(f"missing folder: {folder}")
data = pathlib.Path(os.environ.get("CLAUDE_MEM_DATA_DIR") or pathlib.Path.home() / ".claude-mem")
path = data / "settings.json"
raw = path.read_text(encoding="utf-8")
settings = json.loads(raw)
roots = json.loads(settings.get("CLAUDE_MEM_MEMORY_WATCH_ROOTS") or "[]")
if any(pathlib.Path(r["path"]).expanduser() == folder for r in roots):
    sys.exit("already present; nothing changed")
roots.append({"path": str(folder), "project": project})
if len(roots) > 8:
    sys.exit("claude-mem accepts at most 8 watch roots")
shutil.copy2(path, path.with_name(f"settings.json.bak-{int(time.time())}"))
settings["CLAUDE_MEM_MEMORY_WATCH_ROOTS"] = json.dumps(roots)
if path.read_text(encoding="utf-8") != raw:
    sys.exit("settings.json changed while running; run again")
temp = path.with_name("settings.json.tmp")
temp.write_text(json.dumps(settings, indent=2), encoding="utf-8")
os.replace(temp, path)
print("watch roots:", ", ".join(r["project"] for r in roots))
```

Then restart the worker, which reads this setting when it starts (**Source**). All sessions on the computer share it.

```sh
cd "<plugin dir>"
node scripts/bun-runner.js scripts/worker-service.cjs restart
```

It prints `Worker restart verified` (**Tried**). Clear an old `CLAUDE_MEM_MEMORY_WATCH_ROOTS` entry that points at a
folder from another computer; merging does not remove it.

**What the watcher reads** (**Source**): only `.md` files of at most **65,536 bytes**; at most 500 files; folders at most
8 levels deep; names starting with a dot and symbolic links are skipped. Larger files are skipped **silently**. Each file
is stored as a memory titled `Memory file: <relative path> (revision ...)`. Deleting a file does not delete its memories.
Importing 55 files took under a minute, restart included (**Tried**).

**Cloud sync.** Before ingesting anything private, check whether claude-mem cloud sync is set up (setting names start
with `CLAUDE_MEM_CLOUD_SYNC_`). Check only whether a token is present; never print it. `<data dir>/sync-health.json`
has `state` and `lastSuccessAt` fields that show whether syncing currently succeeds (**Tried**). With sync on, assume
ingested text, earlier revisions included, can leave the computer (**Untested**: which records are uploaded was not
checked).

**Verify the import.** Save as `check_memory.py` and run
`python3 -X utf8 check_memory.py <repo> <project>` (add the data folder as a third argument if it is not the default).
It only reads the database. The table layout is claude-mem 17.0.2's.

```python
import json, pathlib, sqlite3, sys

repo, project = pathlib.Path(sys.argv[1]).resolve(), sys.argv[2]
data = pathlib.Path(sys.argv[3]) if len(sys.argv) > 3 else pathlib.Path.home() / ".claude-mem"
db = sqlite3.connect((data / "claude-mem.db").resolve().as_uri() + "?mode=ro", uri=True)
latest = {}
for source, text in db.execute(
        "select json_extract(metadata,'$.sourcePath'), narrative from observations "
        "where project=? and title like 'Memory file:%' order by id", (project,)):
    latest[pathlib.Path(source)] = text.strip()
files = sorted((repo / "docs" / "learn-codebase").rglob("*.md"))
missing = [f for f in files if latest.get(f) != f.read_text(encoding="utf-8").strip()]
print(f"{len(files)} files, {len(files) - len(missing)} stored in their current version")
for f in missing:
    print("  not current:", f.relative_to(repo).as_posix(), f.stat().st_size, "bytes")
sys.exit(1 if missing else 0)
```

You can also search with the `mem-search` skill, passing `project`.

## 4. Clean the output before it becomes public

This repository is **public**, and Git history keeps whatever is pushed. Do this on the drafts, before they enter the
watched folder.

1. **Leave raw claude-mem observation dumps out** (a `memory/` folder). On 2026-11-29 they held almost all the local
   paths, they only repeat what the database already has, and the large ones exceeded the watcher limit. Keep a local
   copy outside the repository if wanted (**Tried**).
2. **Remove what identifies the computer or the person:** home folder paths; your local username, including 8.3 short
   names such as `ABCDEF~1`; organization or school names and cloud-sync folder names; temporary, session and
   scratchpad folders and session ids; `.claude` and `.claude-mem` locations under a home folder; host names, device
   serial numbers, private IP addresses; email addresses.
3. **Never include secrets.** Do not read keystores or environment files into notes. Review every keyword hit by hand
   and report file, line and verdict.
4. **Keep public facts:** the GitHub account and repository URLs, package and bundle ids, the copyright line, loopback
   addresses, placeholders such as `%APPDATA%`, and paths the repository's own documents already publish.
5. **Mark what was not verified, in every `.md` file.** A memory search returns one file, so a warning in an index is
   not enough. Put a notice at the top, for example:
   `> **UNVERIFIED.** Static reading at <commit>; nothing was built, run or tested.` Say who wrote it (a subagent's
   claims need their own warning) and label each unchecked finding, for example `R (not re-checked)`. A re-check by
   reading is not a reproduction.
6. **Keep each file at most 65,536 bytes, notice included.** Split larger files at headings into `name.md`,
   `name-part2.md`, ... with links both ways. Before adding the links, check that the joined parts equal the original
   (**Tried**).
7. **Check relative links** after every move, split or removal.
8. **Scan with a positive control** (below), then read samples yourself. A pattern scan is **not** a review of the text:
   say so when you publish.

Save as `scan_private.py` outside the repository. Pass your own extra terms (organization, cloud folder, host name) on
the command line, so they are never written into a file:

```sh
python3 -X utf8 scan_private.py <folder> "<organization>" "<cloud folder name>"
```

```python
import pathlib, re, sys

root, extra = pathlib.Path(sys.argv[1]), sys.argv[2:]
SEP = r"[\\/]+"
user = pathlib.Path.home().name
parts = [re.escape(p) for p in re.split(r"[ ._-]+", user) if p]
checks = {
    "home path": rf"(?i)(\b[A-Z]:{SEP}Users{SEP}\w|/c/Users/\w|(?<![\w.])/(Users|home)/\w)",
    "temp or session folder": rf"(?i)(AppData{SEP}Local{SEP}Temp|\.claude{SEP}projects|scratchpad{SEP}|\b\w{{6}}~\d\b)",
    "email": r"[\w.%+-]+@[\w-]+(\.[\w-]+)*\.[A-Za-z]{2,}\b",
    "secret value": r"(gh[pousr]_\w{20,}|github_pat_\w{20,}|\bsk-[\w-]{20,}|AKIA[0-9A-Z]{16}|BEGIN [A-Z ]*PRIVATE KEY)",
}
samples = {
    "home path": "C:" + "\\Users\\" + "someone",
    "temp or session folder": "ABCDEF" + "~1",
    "email": "someone" + "@" + "example.org",
    "secret value": "ghp_" + "a" * 24,
}
if len(parts) > 1:
    checks["user name"] = "(?i)" + r"[ ._%-]{1,3}".join(parts)
    samples["user name"] = user
else:
    print("note: one-word user name; it is only matched inside home paths")
for i, term in enumerate(extra, 1):
    checks[f"extra term {i}"] = "(?i)" + re.escape(term)
    samples[f"extra term {i}"] = term
broken = [k for k, v in checks.items() if not re.search(v, samples[k])]
if broken:
    sys.exit(f"positive control failed: {broken}")
review = r"(?i)(passw(or)?d|secret|api[_-]?key|private[_-]?key|credential|keystore|signing|bearer)"
files = [p for p in root.rglob("*") if p.is_file()]
if not files:
    sys.exit("nothing to scan")
found = 0
for f in files:
    for number, line in enumerate(f.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        for name, pattern in list(checks.items()) + [("review by hand", review)]:
            match = re.search(pattern, line)
            if match:
                found += name != "review by hand"
                print(f"{name}: {f.relative_to(root).as_posix()}:{number}: "
                      f"{line[max(0, match.start() - 40):match.end() + 60]}")
print(f"scanned {len(files)} files; blocking hits: {found}")
sys.exit(1 if found else 0)
```

The output repeats the matched text: keep it out of the repository. A hit can be harmless (a type name such as
`textPassword`, an example address); decide each one and record why.

## 5. Commit and push

Committing publishes the notes: ask the owner first. Then follow [git.md](../instructions/git.md) (read it in full). In addition:

1. Stage by path (`git add -- docs/learn-codebase`), never `git add -A`; check `git diff --cached --name-only`.
2. Scan **both** the staged diff and everything the push will publish: `git diff --cached` and
   `git log -p origin/<branch>..HEAD`.
3. `touch .git/hooks/NO_AUTO_SYNC`, write the message as `git.md` requires, push without force.
4. Run `check_memory.py` again.

## 6. Notes from the 2026-11-29 run in this repository

- The export was first written to `<data dir>/deliverables/<project>/`. No row of the database's `deliverables` table pointed
  at those files; they were cleaned in a draft folder, moved here, compared by checksum and then deleted there.
- The scan's first pass reported 133 blocking hits (home folder paths, temporary session folders, the cloud folder name).
  They were replaced by repository-relative paths and `<temporary folder>`; a message id was removed too. The pass after
  that reported none. A pattern scan is not a review of the text, and nobody has reviewed all of it.
- Departure from section 4, step 1: the numbered summaries keep the observation records they quote, because
  `03-cross-platform.md` is made almost entirely of them. They were committed with the folder.
- Committed and pushed on 2026-11-29 on the owner's request. Before that, the folder was scanned again with the
  organization and cloud folder names as extra terms: no real hit (the short organization name matched only inside words
  such as "automatic", and the one other hit is this guide's placeholder short name). This was a pattern scan and a
  look at the quoted records' titles, not a review of all the text.
