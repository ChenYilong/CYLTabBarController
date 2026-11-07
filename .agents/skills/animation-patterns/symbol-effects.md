# SF Symbol Effects

Animate SF Symbols using the `.symbolEffect()` modifier (iOS 17+) — not `withAnimation`.

## Available Effects

| Effect | Visual | Use Case |
|--------|--------|----------|
| `.bounce` | Jumps up once | Tap feedback, notification arrival |
| `.pulse` | Fades in and out | Ongoing activity, waiting state |
| `.variableColor` | Animates multi-layer color | Signal strength, download progress |
| `.replace` | Cross-fades to new symbol | Play/pause toggle, state change |
| `.wiggle` | Shakes side to side | Attention, error indication |
| `.breathe` | Gentle scale pulse | Ambient activity, Siri-like |
| `.rotate` | Rotates the symbol | Loading, refresh, processing |

## Three Usage Patterns

### 1. Continuous (Repeating)

Starts when the view appears and loops indefinitely. Pass the effect directly to `.symbolEffect()`:

```swift
// Pulsing while loading
Image(systemName: "wifi")
    .symbolEffect(.pulse, isActive: isSearching)

// Variable color always running
Image(systemName: "antenna.radiowaves.left.and.right")
    .symbolEffect(.variableColor.iterative)

// Breathing while recording
Image(systemName: "mic.fill")
    .symbolEffect(.breathe, isActive: isRecording)
```

Use `isActive:` to start/stop the effect based on state.

### 2. One-Shot (Event-Based with value:)

Triggers once each time a value changes. Use the `.symbolEffect(_:value:)` modifier:

```swift
// Bounce on tap
@State private var bounceCount = 0

Image(systemName: "heart.fill")
    .symbolEffect(.bounce, value: bounceCount)
    .onTapGesture {
        bounceCount += 1
    }

// Wiggle on error
Image(systemName: "exclamationmark.triangle")
    .symbolEffect(.wiggle, value: errorCount)

// Rotate on refresh
Image(systemName: "arrow.clockwise")
    .symbolEffect(.rotate, value: refreshCount)
```

### 3. Content Transition (Symbol Swap)

Animate between different symbols using `.contentTransition(.symbolEffect(.replace))`:

```swift
Image(systemName: isPlaying ? "pause.fill" : "play.fill")
    .contentTransition(.symbolEffect(.replace))
    .animation(.smooth, value: isPlaying)

Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
    .contentTransition(.symbolEffect(.replace.downUp))
```

Replace directions: `.replace`, `.replace.downUp`, `.replace.upUp`, `.replace.offUp`

## Effect Options

### Speed and Repeat

```swift
Image(systemName: "bell.fill")
    .symbolEffect(.bounce, options: .speed(2.0), value: trigger)

Image(systemName: "bell.fill")
    .symbolEffect(.bounce, options: .repeat(3), value: trigger)

// Combine options
Image(systemName: "bell.fill")
    .symbolEffect(.bounce, options: .speed(1.5).repeat(2), value: trigger)
```

### Non-Repeating (for continuous effects)

```swift
// Pulse exactly once, then stop
Image(systemName: "heart.fill")
    .symbolEffect(.pulse, options: .nonRepeating, value: trigger)
```

### Variable Color Modes

```swift
// Iterative — layers animate one by one
.symbolEffect(.variableColor.iterative)

// Cumulative — layers build up
.symbolEffect(.variableColor.cumulative)

// Reversing — forward then backward
.symbolEffect(.variableColor.iterative.reversing)

// Hide inactive layers (instead of dimming)
.symbolEffect(.variableColor.iterative.hideInactiveLayers)
```

## Anti-Patterns

```swift
// ❌ WRONG: Using withAnimation for symbol effects
withAnimation(.spring) {
    Image(systemName: "star.fill")
}
// Symbol effects are NOT driven by withAnimation — they have their own timing

// ✅ RIGHT: Use .symbolEffect modifier
Image(systemName: "star.fill")
    .symbolEffect(.bounce, value: trigger)

// ❌ WRONG: Using .animation() modifier for symbol swap
Image(systemName: isPlaying ? "pause.fill" : "play.fill")
    .animation(.spring, value: isPlaying)
// This animates the IMAGE view, not the SYMBOL content

// ✅ RIGHT: Use contentTransition for symbol swap
Image(systemName: isPlaying ? "pause.fill" : "play.fill")
    .contentTransition(.symbolEffect(.replace))

// ❌ WRONG: Applying symbolEffect to non-symbol views
Text("Hello")
    .symbolEffect(.bounce, value: trigger)  // No effect on Text
// symbolEffect only works on Image views with SF Symbols
```

## Accessibility — Reduce Motion

Symbol effects automatically respect the system's Reduce Motion setting:

- **Bounce, wiggle, rotate** — suppressed entirely when Reduce Motion is on
- **Pulse, breathe** — reduced to opacity-only change
- **Variable color** — still plays (it's informational, not decorative)
- **Replace** — falls back to cross-fade

No manual handling needed for symbol effects — the system manages this automatically. However, if you use `isActive:` to show ongoing state, ensure the state is also communicated through non-motion means (label, color, VoiceOver):

```swift
Image(systemName: "wifi")
    .symbolEffect(.variableColor.iterative, isActive: isSearching)
    .accessibilityLabel(isSearching ? "Searching for networks" : "Wi-Fi")
```
