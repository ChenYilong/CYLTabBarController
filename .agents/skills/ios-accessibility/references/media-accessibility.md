# Media Accessibility

Accessibility patterns for audio and video content using AVFoundation.

## Contents

- [Closed Captions and Subtitles](#closed-captions-and-subtitles)
- [SwiftUI VideoPlayer](#swiftui-videoplayer)
- [Custom Player Controls](#custom-player-controls)

## Closed Captions and Subtitles

### AVMediaCharacteristic Tags

AVFoundation uses media characteristics to identify accessibility tracks:

Docs: [AVMediaCharacteristic](https://sosumi.ai/documentation/avfoundation/avmediacharacteristic)

| Characteristic | Purpose |
| -------------- | ------- |
| `.transcribesSpokenDialogForAccessibility` | Captions/SDH — transcribes dialog for deaf or hard of hearing users |
| `.describesMusicAndSoundForAccessibility` | Captions that include descriptions of music and sound effects |
| `.describesVideoForAccessibility` | Audio descriptions — narrates visual content for blind or low-vision users |
| `.easyToRead` | Simplified captions for cognitive accessibility |
| `.containsOnlyForcedSubtitles` | Subtitles that display only when content differs from the device language |
| `.languageTranslation` | Subtitles providing a language translation |

### Selecting Accessible Media

```swift
import AVFoundation

let asset = AVURLAsset(url: videoURL)
let group = try await asset.load(.mediaSelectionGroup(forMediaCharacteristic: .legible))

if let group {
    // Find the closed caption option
    let ccOptions = AVMediaSelectionGroup.mediaSelectionOptions(
        from: group.options,
        with: .transcribesSpokenDialogForAccessibility
    )

    if let ccOption = ccOptions.first {
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.select(ccOption, in: group)
    }
}
```

### Audio Descriptions

```swift
let adGroup = try await asset.load(.mediaSelectionGroup(forMediaCharacteristic: .audible))

if let adGroup {
    let adOptions = AVMediaSelectionGroup.mediaSelectionOptions(
        from: adGroup.options,
        with: .describesVideoForAccessibility
    )

    if let adOption = adOptions.first {
        playerItem.select(adOption, in: adGroup)
    }
}
```

### System Accessibility Settings

AVPlayer automatically selects captioned/described tracks when the user
enables these in Settings → Accessibility → Subtitles & Captioning. You don't
need manual selection unless providing a custom media selection UI.

Check user preferences:

```swift
import MediaAccessibility

let captioningEnabled = MACaptionAppearanceIsDisplayedAutomatically(.user)
```

## SwiftUI VideoPlayer

SwiftUI's `VideoPlayer` inherits AVPlayer's automatic accessibility track
selection:

```swift
import AVKit
import SwiftUI

struct AccessibleVideoView: View {
    let player: AVPlayer

    var body: some View {
        VideoPlayer(player: player)
            .accessibilityLabel("Training video")
            .accessibilityHint("Double-tap to play or pause")
    }
}
```

## Custom Player Controls

When building custom video controls, ensure:

- Play/pause, seek, and volume controls are all focusable and labeled
- Current time and duration are announced on focus changes
- Captions toggle is available and labeled
- Progress slider uses `accessibilityValue` to announce time position
- Controls remain visible/accessible when captions overlay is active

```swift
Button(action: toggleCaptions) {
    Image(systemName: captionsEnabled ? "captions.bubble.fill" : "captions.bubble")
}
.accessibilityLabel(captionsEnabled ? "Captions on" : "Captions off")
.accessibilityHint("Toggles closed captions")
```
