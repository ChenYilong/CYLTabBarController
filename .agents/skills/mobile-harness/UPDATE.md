# mobile-harness update

Use this file when the user requests an update or a confirmed version
incompatibility blocks the task. Normal sessions use the installed versions
after the dependency checks in `AGENTS.md`; do not check for newer releases,
fetch, pull, or upgrade packages just because a session started. For
first-time setup or missing dependencies, read `install.md`.

Before a compatibility repair, identify the incompatible component and the
version needed to fix it. A connection, sandbox, authentication, or unsupported
capability error alone is not evidence that an update is needed; use the
platform recovery guide to diagnose it. Update only the affected component.
Preserve pinned versions unless the user authorizes changing them.

`<harness-root>` below is the directory containing this repository's
`AGENTS.md`. When the harness is loaded through a CLAUDE.md import or a skill
symlink, resolve the real repository path first. `<state-root>` is defined in
`AGENTS.md`.

## Update the Harness

If the harness is installed as a Claude Code plugin, update it through the
plugin manager (`/plugin`, or `claude plugin update mobile-harness@<marketplace>`)
and do not use git or the skills CLI. A copy added from claude.ai
(`mobile-harness@synced`) updates itself when Claude Code starts. The new
version loads after `/reload-plugins` or in a new session; until then
`<harness-root>` still holds the old files.

Otherwise, when an update to the harness files is requested or needed, first check that
`<harness-root>/.git` exists. If it does not (for example a copy installed
with the skills CLI), do not run the pull — `git -C` would operate on an
enclosing repository — and run `npx skills update` from the project where
the skill was installed instead. `npx skills update` deletes and recopies the
skill folder, including `local/` and `.venv/`: copy `<state-root>/local/` out
first, restore it afterward, then redo the `install.md` venv setup.

```bash
git -C <harness-root> pull --ff-only
```

Handle the result:

- Updated or already up to date: continue.
- Offline or network failure: continue with the current version and tell the
  user the update did not run. Do not retry in a loop.
- `Not possible to fast-forward`, diverged history, or local-changes errors:
  the clone needs repair. See Force Update.

The soft update never overwrites local changes.

## Force Update (repair)

Force update resets the clone to the remote state and discards local
modifications to tracked files:

```bash
git -C <harness-root> fetch origin
git -C <harness-root> reset --hard origin/main
```

Rules:

- Ask the user before running it. Tell them what the soft update refused
  (dirty files, diverged history) and that local edits to tracked harness
  files will be lost.
- Never run `git clean -x`, `git clean -fdx`, or delete untracked files.
  `local/` and `.venv/` live inside this repository as
  ignored directories. `reset --hard` leaves them alone; `git clean -x`
  destroys them.
- Do not repair a development checkout. If the user says the clone is where
  they edit the harness itself, stop and let them resolve it.

## Update Python Dependencies

The git pull only refreshes the Markdown harness; Python libraries are
versioned separately on PyPI. A harness update does not require upgrading
working dependencies. Below, `<python>` is the configured interpreter, or
`<state-root>/.venv/bin/python` if no other environment was specified.

For a confirmed compatibility problem, install a compatible version of only
the affected package and its required dependencies. For an explicitly
requested refresh of all unpinned Mobilerun packages, use:

```bash
<python> -m pip install -U "mobilerun-core[local]" mobilerun-core-local mobilerun-sdk
<python> -c "from mobilerun_core import Mobilerun; from importlib.metadata import version; print('mobilerun-core', version('mobilerun-core'), '/ mobilerun-core-local', version('mobilerun-core-local'))"
```

The explicit `mobilerun-core-local` and `mobilerun-sdk` entries are intentional:
they force already-installed transitive runtime packages to upgrade in the
selected venv.

If offline, continue with the current version when it works. If the identified
incompatibility still blocks the task, report the blocker rather than retrying
an upgrade in a loop.

## After Updating

- Files read earlier in this session may be stale. Re-read a guide before
  relying on it.
- If the update changed `AGENTS.md`, re-read it before continuing.
- Recheck `from mobilerun_core import Mobilerun` in the configured interpreter,
  then verify the affected operation. If either still fails, diagnose the
  remaining error rather than automatically upgrading again.
