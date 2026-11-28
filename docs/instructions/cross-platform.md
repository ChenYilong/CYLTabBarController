# React Native and Flutter (tag: `cross-platform`)

Full text of the `cross-platform` rules. [AGENTS.md](../../AGENTS.md#react-native-and-flutter-tag-cross-platform) keeps the summary of this tag;
read this file when a task touches the tag. Moved verbatim from AGENTS.md on 2026-11-22 (instruction files are organized
by tag and kept under 200 lines: see [instructions.md](instructions.md)).

- **React Native and Flutter components** live in `CrossPlatform/` ([docs/Cross-Platform-Components.md](docs/Cross-Platform-Components.md)),
  thin wrappers around `CYLTabBarHostView` (iOS and Android): put shared behavior in the host view, not in a wrapper.
  Their examples use this repository's iOS pod and Android sources: a library change that affects configuration
  initialization, the plus button or badges is checked in them too. A configuration key they need goes into both
  libraries (iOS and `Example-Android`), never only into a wrapper.
