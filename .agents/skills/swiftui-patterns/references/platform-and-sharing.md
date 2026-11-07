# Platform And Sharing

## Contents
- [Transferable, Drag & Drop, and ShareLink](#transferable-drag-drop-and-sharelink)
- [Media Patterns](#media-patterns)
- [Top Bar Overlays](#top-bar-overlays)
- [Title Menus](#title-menus)
- [Input Toolbar](#input-toolbar)
- [Menu Bar Commands](#menu-bar-commands)
- [macOS Settings](#macos-settings)

## Transferable, Drag & Drop, and ShareLink

### Intent

Adopt the `Transferable` protocol to enable sharing, drag and drop, copy/paste, and `ShareLink` with a unified API. Available iOS 16+.

> **Docs:** [Transferable](https://sosumi.ai/documentation/coretransferable/transferable) · [Choosing a transfer representation](https://sosumi.ai/documentation/coretransferable/choosing-a-transfer-representation-for-a-model-type)

### Transferable protocol overview

`Transferable` describes how a type converts to and from transfer representations (clipboard, drag, share sheet). Conform by implementing a static `transferRepresentation` property.

```swift
struct Note: Codable, Identifiable {
    let id: UUID
    var title: String
    var body: String
}

extension Note: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .note)
        ProxyRepresentation(exporting: \.body) // fallback: plain text
    }
}

extension UTType {
    static let note = UTType(exportedAs: "com.example.note")
}
```

Representation order matters — place the most specific first, with broader fallbacks after.

### Common transferable values

Use existing transferable values as proxies or fallbacks when they describe your data accurately:

| Value | Typical use |
|------|-------------|
| `String` | Plain-text previews, titles, or body fallbacks |
| `Data` | Binary payloads when you control serialization |
| `URL` | Links and file references |
| `Color` (SwiftUI) | Color transfer; semantic colors resolve against a default environment |
| `Codable` models | Custom JSON representations via `CodableRepresentation` |

### TransferRepresentation types

#### CodableRepresentation

For types conforming to `Codable`. Serializes to JSON by default:

```swift
static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .myType)
}
```

#### ProxyRepresentation

Delegate to another `Transferable` type. Ideal for quick text or URL fallbacks:

```swift
ProxyRepresentation(exporting: \.title)            // export only
ProxyRepresentation(\.url)                          // import + export via URL
```

#### DataRepresentation

Full control over binary serialization:

```swift
DataRepresentation(contentType: .png) { image in
    try image.pngData()
} importing: { data in
    try MyImage(data: data)
}
```

Use `DataRepresentation(exportedContentType:)` for export-only representations.

#### FileRepresentation

For large content best transferred as files:

```swift
FileRepresentation(contentType: .movie) { video in
    SentTransferredFile(video.fileURL)
} importing: { receivedFile in
    let dest = FileManager.default.temporaryDirectory.appendingPathComponent(receivedFile.file.lastPathComponent)
    try FileManager.default.copyItem(at: receivedFile.file, to: dest)
    return Video(url: dest)
}
```

### ShareLink

Present the system share sheet with a `Transferable` item:

```swift
ShareLink(item: note, preview: SharePreview(note.title)) {
    Label("Share", systemImage: "square.and.arrow.up")
}

// Multiple items
ShareLink(items: selectedNotes) { note in
    SharePreview(note.title)
}

// Simple string sharing
ShareLink(item: "Check out this app!", subject: Text("Cool App"))
```

`ShareLink` requires the item to conform to `Transferable`. The preview provides a title, optional image, and optional icon for the share sheet.

### Drag and drop

#### Making views draggable

```swift
struct NoteCard: View {
    let note: Note

    var body: some View {
        Text(note.title)
            .draggable(note) // Note must be Transferable
    }
}
```

Use `.draggable(note) { DragPreview(note) }` to provide a custom drag preview.

#### Drop destination

```swift
struct NoteBoard: View {
    @State private var notes: [Note] = []

    var body: some View {
        VStack {
            ForEach(notes) { NoteCard(note: $0) }
        }
        .dropDestination(for: Note.self) { droppedNotes, location in
            notes.append(contentsOf: droppedNotes)
            return true
        } isTargeted: { isOver in
            // Highlight drop zone
        }
    }
}
```

For reordering within a list, combine `.draggable` with `.dropDestination` or use `onMove` on `ForEach` inside `List`.

#### Handling multiple types

Accept multiple content types with separate `.dropDestination` modifiers or use `DropDelegate` for advanced logic:

```swift
.dropDestination(for: String.self) { strings, _ in
    notes.append(contentsOf: strings.map { Note(id: UUID(), title: $0, body: "") })
    return true
}
```

### Pasteboard integration

For direct clipboard access outside SwiftUI's drag/drop system, use `UIPasteboard`:

```swift
// Copy
UIPasteboard.general.string = note.title

// Paste
if let text = UIPasteboard.general.string {
    // use text
}
```

For `Transferable` types with custom content types, export to `Data` first:

```swift
let data = try await note.exported(as: .note)
UIPasteboard.general.setData(data, forPasteboardType: UTType.note.identifier)
```

On macOS 13+, prefer SwiftUI's `.copyable`, `.cuttable`, and command-based `.pasteDestination(for:action:validator:)` modifiers over direct pasteboard usage when you are wiring Edit menu commands and keyboard shortcuts. Current Apple docs list those command modifiers as iOS/iPadOS/Mac Catalyst 27 beta, not iOS 26 defaults. On iOS 26 targets, use `UIPasteboard` directly for custom clipboard commands, or use SwiftUI drag/drop and `ShareLink` for Transferable-driven sharing flows.

> **Docs:** [copyable(_:)](https://sosumi.ai/documentation/swiftui/view/copyable(_:)) · [cuttable(for:action:)](https://sosumi.ai/documentation/swiftui/view/cuttable(for:action:)) · [pasteDestination(for:action:validator:)](https://sosumi.ai/documentation/swiftui/view/pastedestination(for:action:validator:))

### Common patterns

#### Transferable enum with multiple representations

```swift
enum SharedContent: Transferable {
    case text(String)
    case url(URL)

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { content in
            switch content {
            case .text(let s): return s
            case .url(let u): return u.absoluteString
            }
        }
    }
}
```

#### Export-only conformance

When your type should be sharable but not importable:

```swift
extension Report: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { report in
            try report.renderPDF()
        }
    }
}
```

### Pitfalls

- Always declare custom `UTType` identifiers in Info.plist under Exported/Imported Type Identifiers.
- Representation order matters — the first matching representation wins. Put the richest format first.
- `FileRepresentation` files are temporary; copy them if you need to persist.
- Keep custom `UTType` declarations and transfer code in modules that are visible to every app target or extension that imports, exports, drags, or shares the type.
- Test drag and drop on device — Simulator haptics and drop targeting differ from hardware.

## Media Patterns

### Intent

Use consistent patterns for loading images, previewing media, and presenting a full-screen viewer.

### Core patterns

- Use `AsyncImage` for simple remote images. `LazyImage` is from the third-party Nuke library if you need advanced caching and prefetching.
- Prefer a lightweight preview component for inline media.
- Use a shared viewer state (e.g., `QuickLook`) to present a full-screen media viewer.
- Use `openWindow` for desktop/visionOS and a sheet for iOS.

### Example: inline media preview

```swift
struct MediaPreviewRow: View {
  @Environment(QuickLook.self) private var quickLook

  let attachments: [MediaAttachment]

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack {
        ForEach(attachments) { attachment in
          Button {
            quickLook.prepareFor(
              selectedMediaAttachment: attachment,
              mediaAttachments: attachments
            )
          } label: {
            LazyImage(url: attachment.previewURL) { state in
              if let image = state.image {
                image.resizable().aspectRatio(contentMode: .fill)
              } else {
                ProgressView()
              }
            }
            .frame(width: 120, height: 120)
            .clipped()
          }
          .buttonStyle(.plain)
        }
      }
    }
  }
}
```

### Example: global media viewer sheet

```swift
struct AppRoot: View {
  @State private var quickLook = QuickLook.shared

  var body: some View {
    content
      .environment(quickLook)
      .sheet(item: $quickLook.selectedMediaAttachment) { selected in
        MediaUIView(selectedAttachment: selected, attachments: quickLook.mediaAttachments)
      }
  }
}
```

### Design choices to keep

- Keep previews lightweight; load full media in the viewer.
- Use shared viewer state so any view can open media without prop-drilling.
- Use a single entry point for the viewer (sheet/window) to avoid duplicates.

### Pitfalls

- Avoid loading full-size images in list rows; use resized previews.
- Don’t present multiple viewer sheets at once; keep a single source of truth.

## Top Bar Overlays

### Intent

Provide a custom top selector or pill row that sits above scroll content, using `safeAreaBar(edge: .top)` on iOS 26 and a compatible fallback on earlier OS versions.

### iOS 26+ approach

Use `safeAreaBar(edge: .top)` to attach the view to the safe area bar. It insets the modified view, adjusts the safe area, and extends affected scroll edge effects.

```swift
if #available(iOS 26.0, *) {
  content
    .safeAreaBar(edge: .top) {
      TopSelectorView()
        .padding(.horizontal, .layoutPadding)
    }
}
```

### Fallback for earlier iOS

Use `.safeAreaInset(edge: .top)` and hide the toolbar background to avoid double layers.

```swift
content
  .toolbarBackground(.hidden, for: .navigationBar)
  .safeAreaInset(edge: .top, spacing: 0) {
    VStack(spacing: 0) {
      TopSelectorView()
        .padding(.vertical)
        .padding(.horizontal, .layoutPadding)
        .background(Color.primary.opacity(0.06))
        .background(Material.ultraThin)
      Divider()
    }
  }
```

### Design choices to keep

- Use `safeAreaBar` when available; it integrates better with the navigation bar.
- Use a subtle background + divider in the fallback to keep separation from content.
- Keep the selector height compact to avoid pushing content too far down.

### Pitfalls

- Don’t stack multiple top insets; it can create extra padding.
- Avoid heavy, opaque backgrounds that fight the navigation bar.

## Title Menus

### Intent

Use a title menu in the navigation bar to provide context‑specific filtering or quick actions without adding extra chrome.

### Core patterns

- Use `ToolbarTitleMenu` to attach a menu to the navigation title.
- Keep the menu content compact and grouped with dividers.

### Example: title menu for filters

```swift
@ToolbarContentBuilder
private var toolbarView: some ToolbarContent {
  ToolbarTitleMenu {
    Button("Latest") { timeline = .latest }
    Button("Resume") { timeline = .resume }
    Divider()
    Button("Local") { timeline = .local }
    Button("Federated") { timeline = .federated }
  }
}
```

### Example: attach to a view

```swift
NavigationStack {
  TimelineView()
    .toolbar {
      toolbarView
    }
}
```

### Example: title + menu together

```swift
struct TimelineScreen: View {
  @State private var timeline: TimelineFilter = .home

  var body: some View {
    NavigationStack {
      TimelineView()
        .toolbar {
          ToolbarItem(placement: .principal) {
            VStack(spacing: 2) {
              Text(timeline.title)
                .font(.headline)
              Text(timeline.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }

          ToolbarTitleMenu {
            Button("Home") { timeline = .home }
            Button("Local") { timeline = .local }
            Button("Federated") { timeline = .federated }
          }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
  }
}
```

### Example: title + subtitle with menu

```swift
ToolbarItem(placement: .principal) {
  VStack(spacing: 2) {
    Text(title)
      .font(.headline)
    Text(subtitle)
      .font(.caption)
      .foregroundStyle(.secondary)
  }
}
```

### Design choices to keep

- Only show the title menu when filtering or context switching is available.
- Keep the title readable; avoid long labels that truncate.
- Use secondary text below the title if extra context is needed.

### Pitfalls

- Don’t overload the menu with too many options.
- Avoid using title menus for destructive actions.

## Input Toolbar

### Intent

Use a bottom-anchored input bar for chat, composer, or quick actions without fighting the keyboard.

### Core patterns

- Use `.safeAreaInset(edge: .bottom)` to anchor the toolbar above the keyboard.
- Keep the main content in a `ScrollView` or `List`.
- Drive focus with `@FocusState` and set initial focus when needed.
- Avoid embedding the input bar inside the scroll content; keep it separate.

### Example: scroll view + bottom input

```swift
@MainActor
struct ConversationView: View {
  @FocusState private var isInputFocused: Bool
  @State private var scrollPosition = ScrollPosition(edge: .bottom)
  @State private var draft = ""

  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(messages) { message in
          MessageRow(message: message)
        }
      }
      .scrollTargetLayout()
      .padding(.horizontal, .layoutPadding)
    }
    .scrollPosition($scrollPosition)
    .safeAreaInset(edge: .bottom) {
      InputBar(text: $draft)
        .focused($isInputFocused)
    }
    .scrollDismissesKeyboard(.interactively)
    .onAppear { isInputFocused = true }
  }
}
```

### Design choices to keep

- Keep the input bar visually separated from the scrollable content.
- Use `.scrollDismissesKeyboard(.interactively)` for chat-like screens.
- Ensure send actions are reachable via keyboard return or a clear button.

### Pitfalls

- Avoid placing the input view inside the scroll stack; it will jump with content.
- Avoid nested scroll views that fight for drag gestures.

## Menu Bar Commands

### Contents

- [Intent](#intent)
- [Core patterns](#core-patterns)
- [Example: basic command menu](#example-basic-command-menu)
- [Example: insert and replace groups](#example-insert-and-replace-groups)
- [Example: focused menu state](#example-focused-menu-state)
- [Menu bar and Settings](#menu-bar-and-settings)
- [Pitfalls](#pitfalls)

### Intent

Use this when adding or customizing the macOS/iPadOS menu bar with SwiftUI commands.

### Core patterns

- Add commands at the `Scene` level with `.commands { ... }`.
- Use `SidebarCommands()` when your UI includes a navigation sidebar.
- Use `CommandMenu` for app-specific menus and group related actions.
- Use `CommandGroup` to insert items before/after system groups or replace them.
- Use `FocusedValue` for context-sensitive menu items that depend on the active scene.

### Example: basic command menu

```swift
@main
struct MyApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .commands {
      CommandMenu("Actions") {
        Button("Run", action: run)
          .keyboardShortcut("R")
        Button("Stop", action: stop)
          .keyboardShortcut(".")
      }
    }
  }

  private func run() {}
  private func stop() {}
}
```

### Example: insert and replace groups

```swift
WindowGroup {
  ContentView()
}
.commands {
  CommandGroup(before: .systemServices) {
    Button("Check for Updates") { /* open updater */ }
  }

  CommandGroup(after: .newItem) {
    Button("New from Clipboard") { /* create item */ }
  }

  CommandGroup(replacing: .help) {
    Button("User Manual") { /* open docs */ }
  }
}
```

### Example: focused menu state

```swift
@MainActor @Observable
final class DataModel {
  var items: [String] = []
}

struct ContentView: View {
  @State private var model = DataModel()

  var body: some View {
    List(model.items, id: \.self) { item in
      Text(item)
    }
    .focusedSceneValue(model)
  }
}

struct ItemCommands: Commands {
  @FocusedValue(DataModel.self) private var model: DataModel?

  var body: some Commands {
    CommandGroup(after: .newItem) {
      Button("New Item") {
        model?.items.append("Untitled")
      }
      .disabled(model == nil)
    }
  }
}
```

### Menu bar and Settings

- Defining a `Settings` scene adds the Settings menu item on macOS automatically.
- If you need a custom entry point inside the app, use `OpenSettingsAction` or `SettingsLink`.

### Pitfalls

- Avoid registering the same keyboard shortcut in multiple command groups.
- Don’t use menu items as the only discoverable entry point for critical features.

## macOS Settings

### Intent

Use this when building a macOS Settings window backed by SwiftUI's `Settings` scene.

### Core patterns

- Declare the Settings scene in the `App` and compile it only for macOS.
- Keep settings content in a dedicated root view (`SettingsView`) and drive values with `@AppStorage`.
- Use `TabView` to group settings sections when you have more than one category.
- Use `Form` inside each tab to keep controls aligned and accessible.
- Use `OpenSettingsAction` or `SettingsLink` for in-app entry points to the Settings window.

### Example: settings scene

```swift
@main
struct MyApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    #if os(macOS)
    Settings {
      SettingsView()
    }
    #endif
  }
}
```

### Example: tabbed settings view

```swift
@MainActor
struct SettingsView: View {
  @AppStorage("showPreviews") private var showPreviews = true
  @AppStorage("fontSize") private var fontSize = 12.0

  var body: some View {
    TabView {
      Tab("General", systemImage: "gear") {
        Form {
          Toggle("Show Previews", isOn: $showPreviews)
          Slider(value: $fontSize, in: 9...96) {
            Text("Font Size (\(fontSize, specifier: "%.0f") pts)")
          }
        }
      }

      Tab("Advanced", systemImage: "star") {
        Form {
          Toggle("Enable Advanced Mode", isOn: .constant(false))
        }
      }
    }
    .scenePadding()
    .frame(maxWidth: 420, minHeight: 240)
  }
}
```

### Skip navigation

- Avoid wrapping `SettingsView` in a `NavigationStack` unless you truly need deep push navigation.
- Prefer tabs or sections; Settings is already presented as a separate window and should feel flat.
- If you must show hierarchical settings, use a single `NavigationSplitView` with a sidebar list of categories.

### Pitfalls

- Don’t reuse iOS-only settings layouts (full-screen stacks, toolbar-heavy flows).
- Avoid large custom view hierarchies inside `Form`; keep rows focused and accessible.
