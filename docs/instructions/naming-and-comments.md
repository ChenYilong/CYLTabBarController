# Naming and Comments [`naming-and-comments`]

## Naming: keep the project's prefixes

Every class, protocol, type, and function in this project starts with `CYL`, and every category method and category property starts with `cyl_`. A file you create or bring in (copied from another project, a sample, or a snippet) follows the same rules:

- **New types and files**: name new classes, structs, enums, protocols, file-private C functions, and constants with the `CYL` prefix (`CYLBadgeView`, `CYLDemoTheme`), and name the file after its main type (`CYLBadgeView.m`, `UIView+CYLBadgeExtention.m`).
- **Category/extension members**: name every method and property added in a category with the `cyl_` prefix (`-cyl_showBadgeValue:`), also in extensions of system types written in Swift, Kotlin, Dart, or TypeScript in this repository.
- **Remove foreign prefixes**: remove any other prefix the copied code carries (another project's or author's prefix, `XX`, `My`, `QMUI`, `JX`, etc.) and rename its symbols, files, and references accordingly; keep credit to the source in a comment instead.
- **Shipped public APIs**: keep the names of public APIs that already shipped, as the Public API rule requires; this rule is for new code.
- **Sample apps**: sample apps follow it too. React Native and Flutter components, helpers, and assets of the examples use `CYL` (`CYLBadgeView`, `cyl_badge_sample_icon`), unless the platform's own naming forbids it (for example, Dart file names are snake_case: `cyl_badge_view.dart`).

## Public API comments: one documentation block format

A caller reads a public API's comment through the IDE's documentation (Xcode Quick Help, the generated Swift interface, Android Studio, editor hovers), and only a documentation comment gets there whole. **The official documentation rules of each language are the reference**; within them:

- **One-line comments use the block format too.** A one-line comment on public API is written like a multi-line one: three lines above the declaration (`/*!`, ` * text`, ` */` in Objective-C). Never `/*! text */` on one line, and never a trailing comment after a declaration or an enum case (`/**< */`, `/*!< */`, `///<`, `//`).
- **One format per public file**, for short and long comments alike.
- **Every platform and language**, each in its documentation tool's block form:
  - Objective-C public headers: `/*! … */` (HeaderDoc; Xcode shows it to Objective-C callers and in the Swift interface generated from the header).
  - Swift: `/** … */` (Swift Markup; Swift does not read `/*!` as documentation).
  - Kotlin, Java, TypeScript, JavaScript: `/** … */` (KDoc, Javadoc, TSDoc / JSDoc).
  - Python: a triple-quoted docstring on its own lines.
  - Go: `/* … */`; C#: `/** … */` with XML tags; Rust: `/** … */`.
  - A language without a block form uses its only documentation comment form in the whole file.
  - Where a language's official rule names one form, that rule wins: Dart keeps `///` (Effective Dart requires it for doc comments), and the official guides of Go (`//`), C# and Rust (`///`) prefer line comments; follow them in those languages.

Check with `python3 scripts/check-public-api-comments.py` (iOS public headers, the Android library modules, the React Native sources, the Flutter sources); `--fix` rewrites one-line blocks into three lines, `//` / `///` comments in Objective-C headers into `/*! … */` blocks, and moves trailing comments above the declaration (merged into its existing block when it has one, since a second block would hide the first).

## Bilingual comments

Comments are bilingual: write `[EN]` / `[CN]` blocks; mark fixes with `FIX: issue #N`. A comment written in Chinese is tagged `[CN]` and is followed directly by its English translation tagged `[EN]`, in the same comment style (inside the same block comment on public API; `//` lines elsewhere). Comments that only contain a person's name, and commented-out code, need no translation.

## No Chinese text in code

Every string literal that contains Chinese, including log, assert, and debug messages, goes through `CYLLocalizedString(@"<original Chinese text>")` (Swift: `CYLLocalizedString("...")`), with `[NSString stringWithFormat:]` / `String(format:)` for values. `CYLLocalizedString()` is declared with `NS_FORMAT_ARGUMENT(1)`, so keep placeholders and arguments in step.

The only exceptions are resource identifiers (for example, an image asset name) and constants that are documented as localization keys; never touch Xcode project files, plists, or storyboards for this.
