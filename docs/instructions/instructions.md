# Instruction files: tags and the 200-line limit (tag: `instructions`)

Added 2026-11-22 by the owner. Applies to every instruction file of this repository: `AGENTS.md` (loaded through
`CLAUDE.md`), `instructions.md`, `docs/instructions.md`, and any agent file added later (for example a `CLAUDE.md`
with content of its own).

1. **Classify by tag.** Every rule belongs to one tag, a keyword such as `testing`, `windows-harmonyos` (Windows
   scenarios), `macos` (macOS-only scenarios), `documentation`, `git`, `code`. Each tag is a visible heading in the
   instruction file, written `## <Title> (tag: `<tag>`)`; no tag heading is hidden or folded away.
2. **200 lines at most.** An instruction file stays under 200 lines. When a tag's content does not fit, the heading keeps
   a short summary and the rest moves to `docs/instructions/<tag>.md` (one file per tag), linked from the heading with a
   relative path (`docs/instructions/<tag>.md` from the repository root).
3. **Read on demand.** The summary under each heading is always read; the tag's file is opened when a task touches the
   tag (its keyword, platform or scenario), so the detail is read only when it is needed.
4. **Moving text.** Rules are moved verbatim, never dropped; a new rule goes under its tag's heading (summary) and into
   the tag's file (full text). A new tag gets a heading, a row in the tag table of `AGENTS.md` and its own file.
5. **Check.** `wc -l AGENTS.md instructions.md docs/instructions.md` prints no file above 200 lines.

Current tags and files: the table at the top of [AGENTS.md](../../AGENTS.md).
