---
name: ios-liquid-glass
user-invocable: true
description: "API reference: Liquid Glass (iOS 26+). Query for glass effects, navigation patterns, GlassEffect modifiers, design principles."
context: fork
agent: Explore
---

# iOS Liquid Glass Reference

API reference for the Liquid Glass design system (iOS 26+): glass effects, containers, morphing transitions, and related system behaviors. This documents what the system provides — design direction is yours.

## When to Use

- Implementing glass materials, `glassEffect` modifiers, or `GlassEffectContainer`
- Navigation surfaces that use system glass (tabs, toolbars, sheets)
- Checking how glass adapts to accessibility settings
- Creating app icons with Icon Composer

## Apple's Stated Design Principles

Apple describes Liquid Glass with three principles (reference, not a mandate):

| Principle | Description |
|-----------|-------------|
| **Hierarchy** | Controls float above content. Glass frames content rather than obscuring it. |
| **Harmony** | Software design aligns with hardware — concentric corners, fluid gestures. |
| **Consistency** | Adapts across iPhone, iPad, Mac — same identity, contextual expression. |

One functional constraint worth knowing: glass is designed for the navigation/control layer. Applying it to content surfaces defeats its sampling model (see containers below).

## Liquid Glass Core API

### Basic Glass Effect

```swift
import SwiftUI

// Simple glass application
Text("Action")
    .padding()
    .glassEffect() // .regular variant, .capsule shape

// With explicit parameters
Button("Confirm") { }
    .padding()
    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12), isEnabled: true)
```

### Glass Variants

| Variant | Use Case |
|---------|----------|
| `.regular` | Toolbars, nav bars, tab bars, standard controls |
| `.clear` | Floating controls over media (photos, maps, video) |
| `.identity` | Conditional disable: `glassEffect(isActive ? .regular : .identity)` |

### Glass Modifiers

```swift
// Semantic tinting
.glassEffect(.regular.tint(.accentColor))

// Interactive behaviors (scaling, shimmer, touch illumination)
.glassEffect(.regular.interactive())

// Combined
.glassEffect(.regular.tint(.blue).interactive())
```

### Custom Shapes

```swift
// Standard shapes
.glassEffect(.regular, in: .capsule)
.glassEffect(.regular, in: .circle)
.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))

// Container-concentric (matches device/container corners)
.glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric))
```

## GlassEffectContainer & Morphing

### Container Setup

Glass cannot sample other glass. Use containers for multiple glass elements:

```swift
GlassEffectContainer(spacing: 30) {
    HStack(spacing: 20) {
        ForEach(actions) { action in
            Button(action.title, systemImage: action.icon) { }
                .frame(width: 44, height: 44)
                .glassEffect(.regular.interactive())
        }
    }
}
```

### Morphing Transitions

```swift
struct ExpandableActions: View {
    @State private var isExpanded = false
    @Namespace private var namespace

    var body: some View {
        GlassEffectContainer(spacing: 30) {
            VStack(spacing: 30) {
                if isExpanded {
                    ActionButton(icon: "rotate.right")
                        .glassEffectID("rotate", in: namespace)
                }

                HStack(spacing: 30) {
                    if isExpanded {
                        ActionButton(icon: "slider.horizontal.3")
                            .glassEffectID("adjust", in: namespace)
                    }

                    Button {
                        withAnimation(.bouncy) { isExpanded.toggle() }
                    } label: {
                        Image(systemName: isExpanded ? "xmark" : "plus")
                            .frame(width: 56, height: 56)
                    }
                    .glassEffect(.regular.tint(.accentColor).interactive())
                    .glassEffectID("toggle", in: namespace)

                    if isExpanded {
                        ActionButton(icon: "crop")
                            .glassEffectID("crop", in: namespace)
                    }
                }

                if isExpanded {
                    ActionButton(icon: "wand.and.stars")
                        .glassEffectID("enhance", in: namespace)
                }
            }
        }
    }
}
```

## Navigation Patterns

### Tab Bar (Floating)

```swift
TabView {
    Tab("Home", systemImage: "house") {
        HomeView()
    }

    Tab("Search", systemImage: "magnifyingglass") {
        SearchView()
    }

    Tab("Profile", systemImage: "person") {
        ProfileView()
    }
}
// Tab bar now floats, reacts to background, collapses on scroll
```

### Toolbar with Grouping

```swift
.toolbar {
    ToolbarItemGroup(placement: .topBarTrailing) {
        Button("Edit", systemImage: "pencil") { }
        Button("Share", systemImage: "square.and.arrow.up") { }
    }

    ToolbarSpacer(.flexible, placement: .topBarTrailing)

    ToolbarItem(placement: .topBarTrailing) {
        Button("Done", systemImage: "checkmark") { }
            .tint(.accentColor)
    }
}
```

### Sheets with Morphing

```swift
struct ContentView: View {
    @State private var showSettings = false
    @Namespace private var namespace

    var body: some View {
        NavigationStack {
            ContentView()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Settings", systemImage: "gear") {
                            showSettings = true
                        }
                        .matchedTransitionSource(id: "settings", in: namespace)
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                        .navigationTransition(.zoom(sourceID: "settings", in: namespace))
                        .presentationDetents([.medium, .large])
                }
        }
    }
}
```

## SF Symbols Effects

```swift
Image(systemName: "checkmark.circle")
    .symbolEffect(.drawOn, value: isComplete)

Image(systemName: "heart.fill")
    .symbolEffect(.bounce, value: isFavorite)
```

## Haptics API

```swift
import UIKit

// Impact feedback
let generator = UIImpactFeedbackGenerator(style: .medium)
generator.impactOccurred()

// Selection feedback
let selection = UISelectionFeedbackGenerator()
selection.selectionChanged()

// Success/error
let notification = UINotificationFeedbackGenerator()
notification.notificationOccurred(.success)
```

## Accessibility Behaviors

### Automatic Glass Adaptations

Glass automatically adapts to:
- **Reduce Transparency**: More frosting
- **Increase Contrast**: Stark borders
- **Reduce Motion**: Tones down animation

### Manual Checks

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation? {
    reduceMotion ? nil : .bouncy
}
```

System expectations: minimum 44x44pt touch targets, accessibility labels, Dynamic Type support.

## Reference

For official Apple documentation links, WWDC session IDs, and API quick reference tables, see [reference.md](reference.md).
