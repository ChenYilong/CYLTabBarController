# Agent Instructions

The repository instructions are in [CLAUDE.md](CLAUDE.md). Follow them for every change, in particular:

- Reading bilingual text: in `docs/` and in code comments, read only the English part, marked `[EN]` (or the `English` column of a
  table), and skip the Chinese part, marked `[CN]`. Text with no English version is read as is. New text is still written in
  both languages.

- Every new feature needs bilingual Chinese–English documentation, as two-column tables (one Chinese column, one
  English column): a new file in `docs/` and an update to `README.md`.
- Bug-free debugging screenshots go into `docs/assets/`; final screenshots go into `README.md`.
- Attachments live in an `assets/` folder next to the Markdown file that uses them, linked with the shortest relative
  path (`assets/name.png`).
- After any change to `README.md` or `docs/` (a Markdown edit, or a file or folder added, renamed or removed), run
  `python3 scripts/update-docs-navigation.py` to regenerate the navigation. Never edit the generated blocks by hand.
- Code contains no Chinese text: string literals with Chinese go through `CYLLocalizedString()` (added to every
  `.lproj` table), and every Chinese comment is tagged `[CN]` with its English translation below, tagged `[EN]`.
- Every `docs/*.md` file declares the classes it documents under its title (`<!-- bound-classes: ... -->`); the script
  writes the binding table into the document and the documents' GitHub links into each bound class header. Run the
  script again whenever a document or a class header is added, renamed or moved.
- PlusButton images: read [docs/PlusButton.md](docs/PlusButton.md) first. With a plus child view controller on Liquid Glass, the
  stand-in ignores selected images and shows only the real plus button's normal image.
  When the app asks for the title to be aligned (`+alignsTitleWithTabBarItemTitles`), the two line up by icon only.
