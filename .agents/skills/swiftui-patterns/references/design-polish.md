# Design Polish

## Contents
- [HIG Alignment](#hig-alignment)
- [Theming and Dynamic Type](#theming-and-dynamic-type)
- [Haptics](#haptics)
- [Matched Transitions](#matched-transitions)
- [Loading and Placeholders](#loading-and-placeholders)
- [Focus Handling](#focus-handling)

## HIG Alignment

iOS Human Interface Guidelines patterns for layout, typography, color, accessibility, and feedback in SwiftUI.

### Contents

- [Layout and Spacing](#layout-and-spacing)
- [Typography](#typography)
- [Color System](#color-system)
- [Navigation Patterns](#navigation-patterns)
- [Feedback](#feedback)
- [Accessibility](#accessibility)
- [Error and Empty States](#error-and-empty-states)

### Layout and Spacing

#### Spacing Grid

Omit `spacing:` on stacks to get SwiftUI's adaptive default. Only specify an explicit value when you need a deliberate departure from the default — and when you do, stick to the 4pt grid below.

This is a common design convention, not an Apple-prescribed system, but it keeps layouts visually coherent. Avoid inventing values between grid stops.

| Points | Token | Typical use |
|--------|-------|-------------|
| 4 | `.xxSmall` | Tight icon-to-label padding, inline badge offsets |
| 8 | `.xSmall` | Related elements within a group, compact stack gaps |
| 12 | `.small` | List row internal padding, label-to-secondary-text |
| 16 | `.medium` | Standard margin, default section gap |
| 20 | `.mediumLarge` | Comfortable breathing room between distinct controls |
| 24 | `.large` | Section separators, card internal padding |
| 32 | `.xLarge` | Major groupings, header-to-content gap |
| 40 | `.xxLarge` | Large section breaks |
| 48 | `.xxxLarge` | Hero/splash spacing, onboarding screens |

```swift
enum Spacing {
    static let xxSmall: CGFloat = 4
    static let xSmall: CGFloat = 8
    static let small: CGFloat = 12
    static let medium: CGFloat = 16
    static let mediumLarge: CGFloat = 20
    static let large: CGFloat = 24
    static let xLarge: CGFloat = 32
    static let xxLarge: CGFloat = 40
    static let xxxLarge: CGFloat = 48
}
```

#### Standard Margins

```swift
private let standardMargin: CGFloat = 16
private let compactMargin: CGFloat = 8
private let largeMargin: CGFloat = 24

extension EdgeInsets {
    static let standard = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    static let listRow = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
}
```

#### Safe Area Handling

```swift
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
    .padding(.horizontal)
}
.safeAreaInset(edge: .bottom) {
    HStack {
        Button("Cancel") { }
            .buttonStyle(.bordered)
        Spacer()
        Button("Confirm") { }
            .buttonStyle(.borderedProminent)
    }
    .padding()
    .background(.regularMaterial)
}
```

#### Adaptive Layouts

Use `horizontalSizeClass` to adapt between compact and regular widths:

```swift
@Environment(\.horizontalSizeClass) private var sizeClass

private var columns: [GridItem] {
    switch sizeClass {
    case .compact:
        [GridItem(.flexible())]
    case .regular:
        [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    default:
        [GridItem(.flexible())]
    }
}
```

### Typography

#### System Font Styles

Use system font styles for automatic Dynamic Type support:

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `.largeTitle` | 34pt | Regular | Screen titles |
| `.title` | 28pt | Regular | Section headers |
| `.title2` | 22pt | Regular | Sub-section headers |
| `.title3` | 20pt | Regular | Group headers |
| `.headline` | 17pt | Semibold | Row titles |
| `.body` | 17pt | Regular | Primary content |
| `.callout` | 16pt | Regular | Secondary content |
| `.subheadline` | 15pt | Regular | Supporting text |
| `.footnote` | 13pt | Regular | Tertiary info |
| `.caption` | 12pt | Regular | Labels |
| `.caption2` | 11pt | Regular | Small labels |

#### Custom Font with Dynamic Type

```swift
extension Font {
    static func customBody(_ name: String) -> Font {
        .custom(name, size: 17, relativeTo: .body)
    }
}
```

### Color System

#### Semantic Colors

Use semantic colors for automatic light/dark mode support:

```swift
// Labels
Color.primary           // Primary text
Color.secondary         // Secondary text
Color(uiColor: .tertiaryLabel)

// Backgrounds
Color(uiColor: .systemBackground)
Color(uiColor: .secondarySystemBackground)
Color(uiColor: .systemGroupedBackground)

// Fills and Separators
Color(uiColor: .systemFill)
Color(uiColor: .separator)
```

#### Tint Colors

```swift
// Apply app-wide tint
ContentView()
    .tint(.blue)
```

Use `.tint(...)` or `.foregroundStyle(.tint)` for interactive elements and `Color.red` for destructive actions.

### Navigation Patterns

#### Hierarchical (NavigationSplitView)

Use for iPad/macOS multi-column layouts:

```swift
NavigationSplitView {
    List(items, selection: $selectedItem) { item in
        NavigationLink(value: item) { ItemRow(item: item) }
    }
    .navigationTitle("Items")
} detail: {
    if let item = selectedItem {
        ItemDetailView(item: item)
    } else {
        ContentUnavailableView("Select an Item", systemImage: "sidebar.leading")
    }
}
```

#### Tab-Based

Use `TabView` with a `NavigationStack` per tab. See the `swiftui-navigation` skill for full tab patterns.

#### Toolbar

```swift
.toolbar {
    ToolbarItem(placement: .topBarLeading) { EditButton() }
    ToolbarItemGroup(placement: .topBarTrailing) {
        Button("Filter", systemImage: "line.3.horizontal.decrease.circle") { }
        Button("Add", systemImage: "plus") { }
    }
    ToolbarItemGroup(placement: .bottomBar) {
        Button("Archive", systemImage: "archivebox") { }
        Spacer()
        Text("\(itemCount) items").font(.footnote).foregroundStyle(.secondary)
        Spacer()
        Button("Share", systemImage: "square.and.arrow.up") { }
    }
}
```

#### Search Integration

```swift
.searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
.searchScopes($searchScope) {
    ForEach(SearchScope.allCases, id: \.self) { scope in
        Text(scope.rawValue.capitalized).tag(scope)
    }
}
```

### Feedback

#### Haptic Feedback

Prefer SwiftUI's `sensoryFeedback(_:trigger:)` for state-driven feedback in SwiftUI views.

```swift
Button("Save") {
    didSave.toggle()
}
.sensoryFeedback(.success, trigger: didSave)

Picker("Sort", selection: $sortOrder) {
    Text("Recent").tag(SortOrder.recent)
    Text("Popular").tag(SortOrder.popular)
}
.sensoryFeedback(.selection, trigger: sortOrder)
```

Use the UIKit generators only when you need imperative feedback from UIKit or non-SwiftUI integration points.

See the Haptics section below for structured patterns.

### Accessibility

#### VoiceOver Support

```swift
VStack(alignment: .leading) {
    Text(item.title).font(.headline)
    Text(item.subtitle).font(.subheadline).foregroundStyle(.secondary)
    HStack {
        Image(systemName: "star.fill")
        Text("\(item.rating, specifier: "%.1f")")
    }
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(item.title), \(item.subtitle)")
.accessibilityValue("Rating: \(item.rating) stars")
.accessibilityHint("Double tap to view details")
.accessibilityAddTraits(.isButton)
```

#### Dynamic Type Support

Adapt layout for accessibility sizes:

```swift
@Environment(\.dynamicTypeSize) private var dynamicTypeSize

var body: some View {
    if dynamicTypeSize.isAccessibilitySize {
        VStack(alignment: .leading) {
            leadingContent
            trailingContent
        }
    } else {
        HStack {
            leadingContent
            Spacer()
            trailingContent
        }
    }
}
```

### Error and Empty States

Use `ContentUnavailableView` for both:

```swift
// Error state
ContentUnavailableView {
    Label("Unable to Load", systemImage: "exclamationmark.triangle")
} description: {
    Text(error.localizedDescription)
} actions: {
    Button("Try Again") { Task { await retry() } }
        .buttonStyle(.borderedProminent)
}

// Empty state
ContentUnavailableView {
    Label("No Photos", systemImage: "camera")
} description: {
    Text("Take your first photo to get started.")
} actions: {
    Button("Take Photo") { showCamera = true }
        .buttonStyle(.borderedProminent)
}
```

## Theming and Dynamic Type

### Intent

Provide a clean, scalable theming approach that keeps view code semantic and consistent.

### Core patterns

- Use a single `Theme` object as the source of truth (colors, fonts, spacing).
- Inject theme at the app root and read it via `@Environment(Theme.self)` in views.
- Prefer semantic colors (`primaryBackground`, `secondaryBackground`, `label`, `tint`) instead of raw colors.
- Keep user-facing theme controls in a dedicated settings screen.
- Apply Dynamic Type scaling through text styles, `Font.custom(_:size:relativeTo:)`, or `@ScaledMetric` for numeric layout values.

### Example: Theme object

```swift
@MainActor
@Observable
final class Theme {
  var tintColor: Color = .blue
  var primaryBackground: Color = .white
  var secondaryBackground: Color = .gray.opacity(0.1)
  var labelColor: Color = .primary
  var fontSizeScale: Double = 1.0
}
```

### Example: inject at app root

```swift
@main
struct MyApp: App {
  @State private var theme = Theme()

  var body: some Scene {
    WindowGroup {
      AppView()
        .environment(theme)
    }
  }
}
```

### Example: view usage

```swift
struct ProfileView: View {
  @Environment(Theme.self) private var theme

  var body: some View {
    VStack {
      Text("Profile")
        .foregroundStyle(theme.labelColor)
    }
    .background(theme.primaryBackground)
  }
}
```

### Design choices to keep

- Keep theme values semantic and minimal; avoid duplicating system colors.
- Store user-selected theme values in persistent storage if needed.
- Ensure contrast between text and backgrounds.

### Pitfalls

- Avoid sprinkling raw `Color` values in views; it breaks consistency.
- Do not tie theme to a single view’s local state.
- Avoid using `@Environment(\.colorScheme)` as the only theme control; it should complement your theme.

## Haptics

### Intent

Use haptics sparingly to reinforce user actions (tab selection, refresh, success/error) and respect user preferences.

### Core patterns

- Prefer `sensoryFeedback(_:trigger:)` in SwiftUI views for state-driven feedback.
- Centralize imperative feedback in a `HapticManager` only when UIKit interop or non-view code requires it.
- Gate haptics behind user preferences and hardware support.
- Use distinct types for different UX moments (selection vs. notification vs. refresh).
- Escalate to Core Haptics only for custom patterns that exceed SwiftUI's built-in feedback types.

### SwiftUI-first pattern

```swift
struct SaveButton: View {
  @State private var saveToken = 0

  var body: some View {
    Button("Save") {
      persistChanges()
      saveToken += 1
    }
    .sensoryFeedback(.success, trigger: saveToken)
  }
}
```

### UIKit interop pattern

```swift
@MainActor
final class HapticManager {
  static let shared = HapticManager()

  enum HapticType {
    case buttonPress
    case tabSelection
    case dataRefresh(intensity: CGFloat)
    case notification(UINotificationFeedbackGenerator.FeedbackType)
  }

  private let selectionGenerator = UISelectionFeedbackGenerator()
  private let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
  private let notificationGenerator = UINotificationFeedbackGenerator()

  private init() { selectionGenerator.prepare() }

  func fire(_ type: HapticType, isEnabled: Bool) {
    guard isEnabled else { return }
    switch type {
    case .buttonPress:
      impactGenerator.impactOccurred()
    case .tabSelection:
      selectionGenerator.selectionChanged()
    case let .dataRefresh(intensity):
      impactGenerator.impactOccurred(intensity: intensity)
    case let .notification(style):
      notificationGenerator.notificationOccurred(style)
    }
  }
}
```

### Example: usage

```swift
Button("Save") {
  HapticManager.shared.fire(.notification(.success), isEnabled: preferences.hapticsEnabled)
}

TabView(selection: $selectedTab) { /* tabs */ }
  .onChange(of: selectedTab) { _, _ in
    HapticManager.shared.fire(.tabSelection, isEnabled: preferences.hapticTabSelectionEnabled)
  }
```

### Design choices to keep

- Haptics should be subtle and not fire on every tiny interaction.
- Respect user preferences (toggle to disable).
- Keep haptic triggers close to the user action, not deep in data layers.

### Pitfalls

- Avoid firing multiple haptics in quick succession.
- Do not assume haptics are available; check support.

### Core Haptics (CHHapticEngine)

For advanced haptic patterns beyond the simple feedback generators, use Core Haptics. It provides precise control over haptic intensity, sharpness, and timing with support for audio-haptic synchronization.

> **Docs:** [CHHapticEngine](https://sosumi.ai/documentation/corehaptics/chhapticengine) · [Preparing your app to play haptics](https://sosumi.ai/documentation/corehaptics/preparing-your-app-to-play-haptics)

#### Capabilities check

Always verify hardware support before creating an engine:

```swift
import CoreHaptics

let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
let supportsAudio = CHHapticEngine.capabilitiesForHardware().supportsAudio
```

#### Engine setup and lifecycle

```swift
@MainActor
final class CoreHapticManager {
    private var engine: CHHapticEngine?

    func prepareEngine() throws {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        engine = try CHHapticEngine()

        // Called when the engine stops due to external cause (audio session interruption, app backgrounding)
        engine?.stoppedHandler = { reason in
            print("Haptic engine stopped: \(reason)")
        }

        // Called after the engine is reset (e.g., after audio session interruption ends)
        engine?.resetHandler = { [weak self] in
            do {
                try self?.engine?.start()
            } catch {
                print("Failed to restart engine: \(error)")
            }
        }

        try engine?.start()
    }

    func stopEngine() {
        engine?.stop()
    }
}
```

Key lifecycle rules:
- Call `engine.start()` before playing any patterns.
- Handle `stoppedHandler` — the system can stop the engine when your app moves to the background or during audio interruptions.
- Handle `resetHandler` — restart the engine when the system resets it.
- Call `engine.stop()` when haptics are no longer needed to save battery.

#### CHHapticPattern and CHHapticEvent

Build patterns from individual haptic and audio events:

```swift
func playTransientTap() throws {
    let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
    let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)

    // Transient: short, single-tap feel
    let event = CHHapticEvent(
        eventType: .hapticTransient,
        parameters: [intensity, sharpness],
        relativeTime: 0
    )

    let pattern = try CHHapticPattern(events: [event], parameters: [])
    let player = try engine?.makePlayer(with: pattern)
    try player?.start(atTime: CHHapticTimeImmediate)
}
```

**Event types:**

| Type | Description |
|------|-------------|
| `.hapticTransient` | Brief, tap-like impulse |
| `.hapticContinuous` | Sustained vibration over a `duration` |
| `.audioContinuous` | Sustained audio tone |
| `.audioCustom` | Play a custom audio resource |

**Common parameters:** `.hapticIntensity` (0–1), `.hapticSharpness` (0–1), `.attackTime`, `.decayTime`, `.releaseTime`.

#### Playing patterns with CHHapticPatternPlayer

```swift
func playContinuousBuzz() throws {
    let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
    let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)

    let event = CHHapticEvent(
        eventType: .hapticContinuous,
        parameters: [intensity, sharpness],
        relativeTime: 0,
        duration: 0.5
    )

    let pattern = try CHHapticPattern(events: [event], parameters: [])
    let player = try engine?.makePlayer(with: pattern)
    try player?.start(atTime: CHHapticTimeImmediate)
}
```

For looping, seeking, and pausing, use `CHHapticAdvancedPatternPlayer` via `engine.makeAdvancedPlayer(with:)`.

#### Haptic parameter curves (CHHapticParameterCurve)

Smoothly vary parameters over time within a pattern:

```swift
func playRampingPattern() throws {
    let event = CHHapticEvent(
        eventType: .hapticContinuous,
        parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
        ],
        relativeTime: 0,
        duration: 1.0
    )

    // Ramp intensity from 0.2 → 1.0 over 1 second
    let curve = CHHapticParameterCurve(
        parameterID: .hapticIntensityControl,
        controlPoints: [
            .init(relativeTime: 0, value: 0.2),
            .init(relativeTime: 0.5, value: 0.7),
            .init(relativeTime: 1.0, value: 1.0)
        ],
        relativeTime: 0
    )

    let pattern = try CHHapticPattern(events: [event], parameterCurves: [curve])
    let player = try engine?.makePlayer(with: pattern)
    try player?.start(atTime: CHHapticTimeImmediate)
}
```

#### Audio-haptic synchronization (AHAP files)

AHAP (Apple Haptic and Audio Pattern) files define haptic patterns in JSON for easy authoring and design iteration. Load them directly:

```swift
func playAHAPFile() throws {
    guard let url = Bundle.main.url(forResource: "success", withExtension: "ahap") else { return }
    try engine?.playPattern(from: url)
}
```

AHAP files support the same events, parameters, and parameter curves as the programmatic API. Use the **Core Haptics** design tools in Xcode to preview patterns.

> **Docs:** [Representing haptic patterns in AHAP files](https://sosumi.ai/documentation/corehaptics/representing-haptic-patterns-in-ahap-files)

## Matched Transitions

### Intent

Use matched transitions to create smooth continuity between a source view (thumbnail, avatar) and a destination view (sheet, detail, viewer).

### Core patterns

- Use a shared `Namespace` and a stable ID for the source.
- Use `matchedTransitionSource` + `navigationTransition(.zoom(...))` on iOS 18+.
- Use `matchedGeometryEffect` for in-place transitions within a view hierarchy.
- Keep IDs stable across view updates (avoid random UUIDs).

### Example: media preview to full-screen viewer (iOS 18+)

```swift
struct MediaPreview: View {
  @Namespace private var namespace
  let attachments: [MediaAttachment]

  var body: some View {
    NavigationStack {
      List(attachments) { attachment in
        NavigationLink(value: attachment) {
          ThumbnailView(attachment: attachment)
            .matchedTransitionSource(id: attachment.id, in: namespace)
        }
      }
      .navigationDestination(for: MediaAttachment.self) { item in
        MediaViewer(item: item)
          .navigationTransition(.zoom(sourceID: item.id, in: namespace))
      }
    }
  }
}
```

### Example: matched geometry within a view

```swift
struct ToggleBadge: View {
  @Namespace private var space
  @State private var isOn = false

  var body: some View {
    Button {
      withAnimation(.spring) { isOn.toggle() }
    } label: {
      Image(systemName: isOn ? "eye" : "eye.slash")
        .matchedGeometryEffect(id: "icon", in: space)
    }
  }
}
```

### Design choices to keep

- Prefer `matchedTransitionSource` for supported navigation zoom transitions.
- Keep source and destination sizes reasonable to avoid jarring scale changes.
- Use `withAnimation` for state-driven transitions.

### Pitfalls

- Don’t use unstable IDs; it breaks the transition.
- Avoid mismatched shapes (e.g., square to circle) unless the design expects it.

## Loading and Placeholders

Use this when a view needs a consistent loading state (skeletons, redaction, empty state) without blocking interaction.

### Patterns to prefer

- **Redacted placeholders** for list/detail content to preserve layout while loading.
- **ContentUnavailableView** for empty or error states after loading completes.
- **ProgressView** only for short, global operations (use sparingly in content-heavy screens).

### Recommended approach

1. Keep the real layout, render placeholder data, then apply `.redacted(reason: .placeholder)`.
2. For lists, show a fixed number of placeholder rows (avoid infinite spinners).
3. Switch to `ContentUnavailableView` when load finishes but data is empty.

### Pitfalls

- Don’t animate layout shifts during redaction; keep frames stable.
- Avoid nesting multiple spinners; use one loading indicator per section.
- Keep placeholder count small (3–6) to reduce jank on low-end devices.

### Minimal usage

```swift
VStack {
  if isLoading {
    ForEach(0..<3, id: \.self) { _ in
      RowView(model: .placeholder())
    }
    .redacted(reason: .placeholder)
  } else if items.isEmpty {
    ContentUnavailableView("No items", systemImage: "tray")
  } else {
    ForEach(items) { item in RowView(model: item) }
  }
}
```

## Focus Handling

This file covers basic form-focus patterns only. For directional focus, focus sections, scene-focused values, and `UIFocusGuide`, see the `focus-engine` skill.

### Intent

Use `@FocusState` to control keyboard focus, chain fields, and coordinate focus across complex forms.

### Core patterns

- Use an enum to represent focusable fields.
- Set initial focus in `onAppear`.
- Use `.onSubmit` to move focus to the next field.
- For dynamic lists of fields, use an enum with associated values (e.g., `.option(Int)`).

### Example: single field focus

```swift
struct AddServerView: View {
  @State private var server = ""
  @FocusState private var isServerFieldFocused: Bool

  var body: some View {
    Form {
      TextField("Server", text: $server)
        .focused($isServerFieldFocused)
    }
    .onAppear { isServerFieldFocused = true }
  }
}
```

### Example: chained focus with enum

```swift
struct EditTagView: View {
  enum FocusField { case title, symbol, newTag }
  @FocusState private var focusedField: FocusField?

  var body: some View {
    Form {
      TextField("Title", text: $title)
        .focused($focusedField, equals: .title)
        .onSubmit { focusedField = .symbol }

      TextField("Symbol", text: $symbol)
        .focused($focusedField, equals: .symbol)
        .onSubmit { focusedField = .newTag }
    }
    .onAppear { focusedField = .title }
  }
}
```

### Example: dynamic focus for variable fields

```swift
struct PollView: View {
  enum FocusField: Hashable { case option(Int) }
  @FocusState private var focused: FocusField?
  @State private var options: [String] = ["", ""]
  @State private var currentIndex = 0

  var body: some View {
    ForEach(options.indices, id: \.self) { index in
      TextField("Option \(index + 1)", text: $options[index])
        .focused($focused, equals: .option(index))
        .onSubmit { addOption(at: index) }
    }
    .onAppear { focused = .option(0) }
  }

  private func addOption(at index: Int) {
    options.append("")
    currentIndex = index + 1
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(10))
      focused = .option(currentIndex)
    }
  }
}
```

### Design choices to keep

- Keep focus state local to the view that owns the fields.
- Use focus changes to drive UX (validation messages, helper UI).
- Pair with `.scrollDismissesKeyboard(...)` when using ScrollView/Form.

### Pitfalls

- Don’t store focus state in shared objects; it is view-local.
- Avoid aggressive focus changes during animation; delay if needed.
