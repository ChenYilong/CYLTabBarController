# Skills and Documentation [`skills-and-docs`]

## Skills

`.agents/skills` holds the skills; `.claude/skills` only points there.

TODO: Install the WeChat developer tools skills: <https://developers.weixin.qq.com/miniprogram/dev/devtools/Skills.html>

### Project skills (`cyl-*`, maintained here)

| Skill | Use it when |
|:---|:---|
| `cyl-new-project` | Creating a new app or demo on this library. **Every new demo must follow it.** |
| `cyl-plus-button` | Writing or changing a plus button: title alignment, stand-in, images, limits. |
| `cyl-xcode-compat` | Touching a `.xcodeproj` or a deployment target; choosing which Xcode or iOS version a feature needs. |
| `cyl-tab-animation` | Working with Lottie, PAG, Rive, or GIF tab icons; suggest running the matching demo first. |
| `cyl-theme` | Working with skins or in-place tab updates. |
| `cyl-api-map` | Finding the API and document for a feature. |
| `cyl-docs` | Adding a feature or editing `README.md` or `docs/`. |
| `cyl-verify` | Building, testing, running the simulator, or reading common failures. |
| `cyl-harmonyos-setup` | Preparing Windows and DevEco Studio for HarmonyOS; prerequisites for installing the local emulator. |
| `cyl-harmonyos-a11y-l10n` | HarmonyOS accessibility, localization (strings from the iOS bundle), and accessibility-first UI tests. |

### Third-party skills

Third-party skills are listed in `.agents/skills.json`, pinned in `.agents/skills.lock.json`, and vendored by `python3 scripts/sync-agent-skills.py`. Do not edit them by hand: change the manifest and sync. See [../Agent-Skills.md](../Agent-Skills.md) for what is there and why.

Their advice is generic. Where a third-party skill conflicts with a rule here, `AGENTS.md` and the `cyl-*` skills win. For example, third-party skills may target modern Swift, while this library is Objective-C with a Swift 5 API.

## Keep the skills current

Every new API, feature, limit, or demo updates, in the same change: the relevant `docs/` file, `README.md`, and the affected `cyl-*` skills (at least a row in `cyl-api-map`). The goal is that someone can start a new project from these skills alone.

`scripts/sync-agent-skills.py --check` fails when a document or a demo is missing from the skills. A change to animated tab icons also updates [../Tab-Icon-Animation-Quick-Start.md](../Tab-Icon-Animation-Quick-Start.md).

## Reading bilingual docs and comments

The documents in `docs/` and the code comments are bilingual. AI agents read only the English part and skip the Chinese part:

- **Keywords**: `[EN]` starts the English part, `[CN]` the Chinese part. Always read what starts with `[EN]`; skip what starts with `[CN]`.
- **`docs/`**: read the `## [EN]…` heading and skip its `## [CN]…` twin. In a table with `中文 | English` columns, read only the right column. In a heading or a cell written as `中文 / English`, read only the part after the `/`.
- **Code comments**: read the `[EN]` block and skip the `[CN]` block, which runs until the next `[EN]`, the next tag, or the end of the comment.
- **Exception**: text with no English version (for example, an older comment in Chinese only) is read as is, since it is the only source.
- **Writing is not affected**: new text is still written in both languages, as the `cyl-docs` skill and the code rules require.

## Documentation

Every new feature and user-visible change ships with bilingual documentation in `docs/` and `README.md`, as two-column tables, and `python3 scripts/update-docs-navigation.py` is run after any change to them. Never edit generated blocks by hand. Full rules: the `cyl-docs` skill.
