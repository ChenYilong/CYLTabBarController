---
source: project
description: Quick reference with Apple documentation links
---

# Liquid Glass Quick Reference

> Official links and condensed lookup tables

## Official Apple Documentation

### Core APIs

| API | URL |
|-----|-----|
| glassEffect(_:in:) | https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:) |
| GlassEffectContainer | https://developer.apple.com/documentation/swiftui/glasseffectcontainer/ |
| glassEffectID | https://developer.apple.com/documentation/swiftui/view/glasseffectid(_:in:) |
| Adopting Liquid Glass | https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass |
| Applying to Custom Views | https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views |

### Human Interface Guidelines

| Topic | URL |
|-------|-----|
| Main HIG | https://developer.apple.com/design/human-interface-guidelines/ |
| Materials | https://developer.apple.com/design/human-interface-guidelines/materials |
| App Icons | https://developer.apple.com/design/human-interface-guidelines/app-icons |
| SF Symbols | https://developer.apple.com/design/human-interface-guidelines/sf-symbols |

---

## WWDC 2025 Sessions

### Design

| Session | ID | Description |
|---------|-----|-------------|
| Meet Liquid Glass | 219 | Core overview |
| New look of app icons | 220 | Icon design |
| Icon Composer | 361 | Icon tool tutorial |
| SF Symbols 7 | 337 | Draw animations |

**Watch**: https://developer.apple.com/videos/play/wwdc2025/[ID]/

### Implementation

| Session | ID | Description |
|---------|-----|-------------|
| Build SwiftUI app | 323 | SwiftUI walkthrough |
| Build UIKit app | 284 | UIKit walkthrough |

---

## Tools & Resources

| Tool | Location |
|------|----------|
| Icon Composer | Xcode 26 |
| SF Symbols 7 | https://developer.apple.com/sf-symbols/ |
| Design Resources | https://developer.apple.com/design/resources/ |
| Design Gallery | https://developer.apple.com/design/new-design-gallery/ |
| Design Awards | https://developer.apple.com/design/awards/ |

---

## API Quick Reference

### Glass Variants

```swift
.glassEffect()                    // .regular, .capsule
.glassEffect(.regular)            // Standard controls
.glassEffect(.clear)              // Over media (photos/maps)
.glassEffect(.identity)           // Disabled/conditional
```

### Modifiers

```swift
.glassEffect(.regular.tint(.blue))           // Semantic color
.glassEffect(.regular.interactive())          // Press effects
.glassEffect(.regular.tint(.blue).interactive())
```

### Shapes

```swift
.glassEffect(.regular, in: .capsule)
.glassEffect(.regular, in: .circle)
.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
.glassEffect(.regular, in: .rect(cornerRadius: .containerConcentric))
```

### Container & Morphing

```swift
GlassEffectContainer(spacing: 30) {
    // Glass elements morph within spacing threshold
}

.glassEffectID("id", in: namespace)  // Enable morphing
```

### Sheets

```swift
.presentationDetents([.medium, .large])  // Required for glass
.scrollContentBackground(.hidden)         // For Form in sheet
.matchedTransitionSource(id:in:)          // Morph from button
.navigationTransition(.zoom(sourceID:in:))
```

### Toolbar

```swift
ToolbarSpacer(.fixed)      // Default spacing
ToolbarSpacer(.flexible)   // Fill available space
ToolbarItemGroup(placement:) { }
```

### Animations

```swift
withAnimation(.bouncy) { }
withAnimation(.bouncy(duration: 0.5, extraBounce: 0.2)) { }
```

### SF Symbols

```swift
.symbolEffect(.drawOn, value: trigger)
.symbolEffect(.drawOff, value: trigger)
.symbolEffect(.bounce, value: trigger)
```

---

## Accessibility Environment

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
@Environment(\.accessibilityReduceMotion) var reduceMotion
@Environment(\.colorSchemeContrast) var contrast
```

---

## Platform Versions

| Platform | Version |
|----------|---------|
| iOS | 26 |
| iPadOS | 26 |
| macOS | Tahoe 26 |
| watchOS | 26 |
| tvOS | 26 |
| visionOS | 26 |
| Xcode | 26 |
| macOS (Icon Composer) | Sequoia 15.3+ |

---

## Community

- [LiquidGlassReference (GitHub)](https://github.com/conorluddy/LiquidGlassReference)
- [Apple Developer Forums](https://developer.apple.com/forums/)
- [Swift Forums](https://forums.swift.org/)
