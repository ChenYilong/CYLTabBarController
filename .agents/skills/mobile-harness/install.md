# mobile-harness installation

Use this file for installing the Python dependency and registering this
Markdown harness with an agent runtime. For day-to-day device work, start with
`AGENTS.md` or `SKILL.md`.

## Python Dependency

Install the full `mobilerun-core` surface into `<state-root>` (see `AGENTS.md`):
the repository directory for a clone, or the plugin data directory for a Claude
Code plugin install.

```bash
cd <state-root>
"$(command -v python3.13 || command -v python3.12 || command -v python3.11)" -m venv .venv
.venv/bin/python -m pip install "mobilerun-core[local]"
.venv/bin/python -c "from mobilerun_core import Mobilerun; from importlib.metadata import version; print('mobilerun-core', version('mobilerun-core'), '/ mobilerun-core-local', version('mobilerun-core-local'))"
```

Needs Python 3.11-3.13; if none is on `PATH`, `uv python find '>=3.11,<3.14'`
prints one. Do not commit `.venv/`.

Tell agents which Python runtime to use:

```text
Use <state-root>/.venv/bin/python for mobile-harness.
```

Base `mobilerun-core` includes cloud support through `mobilerun-sdk`. The
`local` extra installs `mobilerun-core-local`, which `mobilerun-core` uses
internally for:

- local Android ADB with optional Portal: `backend="local-android-adb"`
- local Android Portal HTTP-only: `backend="local-android-http"`
- local iOS HTTP (`mobilerun-ios --local`, or the `ios-portal` app
  on Simulator): `backend="local-ios-http"`

## Environment

Cloud devices require:

```bash
export MOBILERUN_CLOUD_API_KEY="..."
export MOBILERUN_API_BASE_URL="https://api.mobilerun.ai/v1"
export MOBILERUN_CLOUD_DEVICE_ID="..."
```

Local Android Portal HTTP-only requires:

```bash
export MOBILERUN_ANDROID_PORTAL_URL="http://127.0.0.1:18080"
export MOBILERUN_ANDROID_PORTAL_TOKEN="..."
```

Local iOS can use:

```bash
export MOBILERUN_IOS_PORTAL_URL="http://127.0.0.1:8080"
# Simulator through the ios-portal app: http://127.0.0.1:6643
```

A local iPhone or iPad also needs the `mobilerun-ios` CLI
(`brew install droidrun/tap/mobilerun-ios`) with a one-time
device setup; see https://docs.mobilerun.ai/framework/guides/device-setup (iOS
tab). Local mode needs no Mobilerun login.

Do not print tokens or API keys in logs, chat, screenshots, or summaries. If an
existing runtime exposes a differently named Mobilerun key, map it into
`MOBILERUN_CLOUD_API_KEY` before running `mobilerun-core` code.

## Runtime Registration

Keep the repository together when registering it. The root `SKILL.md` and
`AGENTS.md` depend on files under `platforms/`, `core/`, `apps/`, and
`local/`.

### Codex

Register the full repository as a Codex skill directory. If
`skills/mobile-harness` already exists as a real directory (for example an
earlier copied install), `ln -sfn` would create the link inside it instead of
replacing it. Before deleting that directory, move any `local/` content it
holds into this repository's `local/`, and ask the user before the deletion:

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
ln -sfn "$(pwd)" "${CODEX_HOME:-$HOME/.codex}/skills/mobile-harness"
```

New Codex sessions can then load `mobile-harness` as a skill while preserving
relative file paths.

### Claude Code

Install it as a plugin:

```text
/plugin marketplace add droidrun/mobile-harness
/plugin install mobile-harness@mobile-harness
```

The plugin keeps `.venv/` and `local/` in its data directory (`<state-root>`),
which plugin updates leave in place. Set up the Python dependency there. For an
install from this repository's marketplace that directory is
`~/.claude/plugins/data/mobile-harness-mobile-harness/`.

Or add an import to `~/.claude/CLAUDE.md` that points at a clone's
`AGENTS.md`, for example:

```markdown
@~/Developer/mobile-harness/AGENTS.md
```

Keep the repository at that path so relative references such as
`platforms/android/GUIDE.md` remain readable.

### OpenClaw

This repository is a Python `mobilerun-core` harness. If packaging it for OpenClaw,
package the repository as a skill directory with the root `SKILL.md` as the
entrypoint and make the whole directory available to the agent.

For first-time setup or a missing dependency in OpenClaw, install:

```bash
python -m pip install "mobilerun-core[local]"
```

Provide the same environment variables listed above. If the host already
provides `MOBILERUN_API_KEY`, set `MOBILERUN_CLOUD_API_KEY` to that value for
`mobilerun-core`.

## Updating

Normal sessions check the installed dependencies and use the existing versions.
Update only when requested or when a confirmed version incompatibility blocks
the task. `UPDATE.md` covers those updates and repairs; pinned versions remain
unchanged unless the user authorizes changing them.
