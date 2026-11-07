---
title: CHHapticEngine
description: An object that represents the connection to the haptic server.
source: https://developer.apple.com/documentation/corehaptics/chhapticengine
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/corehaptics/chhapticengine.json
timestamp: 2026-05-10T06:22:46.857Z
---

**Navigation:** [Core Haptics](/documentation/corehaptics)

**Class**

# CHHapticEngine

**Available on:** iOS 13.0+, iPadOS 13.0+, Mac Catalyst 13.0+, macOS 10.15+, tvOS 14.0+, visionOS 1.0+

> An object that represents the connection to the haptic server.

```swift
class CHHapticEngine
```

## Overview

If you want your app to play custom haptics, you need to create a haptic engine. The haptic engine establishes the connection between your app and the underlying device hardware. Even though you can define a haptic pattern without an engine, you need the engine to play that pattern.

![A dictionary defines a pattern, from which the haptic engine creates a pattern player for playing the haptic.](https://docs-assets.developer.apple.com/published/66a613deacd96bc7ac01d5a15e3eae73/media-3242669%402x.png)

Even though your app makes a request through the haptic engine, the operating system could still override the request with system services, like haptics from system notifications.

### Prepare Your App To Play Haptics

To prepare your app to play haptics, follow these steps, as demonstrated in the code below:

1. Create a haptic engine instance. Maintain a strong reference to it so it doesn’t go out of scope while the haptic is playing.
2. Call the haptic engine’s [start(completionHandler:)](/documentation/corehaptics/chhapticengine/start(completionhandler:)) for an asynchronous start, or [start()](/documentation/corehaptics/chhapticengine/start()) to start the engine synchronously (immediately).
3. Stop the engine by calling [stop(completionHandler:)](/documentation/corehaptics/chhapticengine/stop(completionhandler:)) when your app finishes haptic playback.

### Swift

```swift
do {
    // 1. Create a haptic engine instance.
    hapticEngine = try CHHapticEngine()

    // 2. Start the haptic engine.
    try hapticEngine.start()
} catch let error {
    print("Engine Error: \(error)")
}

// 3. Stop the engine.
hapticEngine.stop(completionHandler: { (_) -> Void in
    // Insert code to call after engine stops.
})
```

### Objective-C

```objc
// Create an error variable through which the engine returns error information.
NSError* error = nil;

// (1.) Create an instance of a haptic engine.
self.hapticEngine = [[CHHapticEngine alloc] initAndReturnError:&error];

// (2.) Start the haptic engine.
[self.hapticEngine startAndReturnError:&error];

// (3.) Stop the engine.
[self.hapticEngine stopWithCompletionHandler:^(NSError* error){
    // Insert code to call after engine stops.
}];
```

Although it’s possible to create content—[CHHapticPattern](/documentation/corehaptics/chhapticpattern) instances—independent of a CHHapticEngine, your app must use an engine to play that content.

## Inherits From

- [NSObject](/documentation/ObjectiveC/NSObject-swift.class)

## Conforms To

- [CVarArg](/documentation/Swift/CVarArg)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Hashable](/documentation/Swift/Hashable)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)

## Initializing a Haptic Engine

- [init()](/documentation/corehaptics/chhapticengine/init()) Creates an instance of the haptic engine.
- [init(audioSession:)](/documentation/corehaptics/chhapticengine/init(audiosession:)) Creates a haptic engine from an audio session.

## Starting and Stopping the Haptic Engine

- [start()](/documentation/corehaptics/chhapticengine/start()) Synchronously starts the haptic engine.
- [start(completionHandler:)](/documentation/corehaptics/chhapticengine/start(completionhandler:)) Asynchronously starts the haptic engine.
- [stop(completionHandler:)](/documentation/corehaptics/chhapticengine/stop(completionhandler:)) Asynchronously stops the haptic engine and executes the completion handler once the engine has stopped.
- [CHHapticEngine.CompletionHandler](/documentation/corehaptics/chhapticengine/completionhandler) A typealias for a completion handler that the engine calls after starting or stopping.

## Creating Haptic Pattern Players

- [makePlayer(with:)](/documentation/corehaptics/chhapticengine/makeplayer(with:)) Creates a standard haptic pattern player from a haptic pattern.
- [makeAdvancedPlayer(with:)](/documentation/corehaptics/chhapticengine/makeadvancedplayer(with:)) Creates an advanced haptic pattern player from a haptic pattern.

## Modifying Playback Properties

- [playsAudioOnly](/documentation/corehaptics/chhapticengine/playsaudioonly) A Boolean value that indicates whether the engine ignores haptic events and plays audio events only.
- [playsHapticsOnly](/documentation/corehaptics/chhapticengine/playshapticsonly) A Boolean value that indicates whether the engine ignores audio events.
- [isMutedForAudio](/documentation/corehaptics/chhapticengine/ismutedforaudio) A Boolean value that indicates whether the engine mutes audio.
- [isMutedForHaptics](/documentation/corehaptics/chhapticengine/ismutedforhaptics) A Boolean value that indicates whether the engine mutes haptics.

## Playing a Pattern

- [playPattern(from:)](/documentation/corehaptics/chhapticengine/playpattern(from:)-6m9m5) Plays a pattern that’s defined in a file at the specified URL.
- [playPattern(from:)](/documentation/corehaptics/chhapticengine/playpattern(from:)-7u8se) Plays a pattern from the specified data.

## Registering Audio Resources

- [registerAudioResource(_:options:)](/documentation/corehaptics/chhapticengine/registeraudioresource(_:options:)) Registers an external audio to use as a custom waveform.
- [unregisterAudioResource(_:)](/documentation/corehaptics/chhapticengine/unregisteraudioresource(_:)) Unregisters an external audio file that you previously registered with the engine.
- [CHHapticAudioResourceID](/documentation/corehaptics/chhapticaudioresourceid) A type that identifies a custom audio resource.

## Monitoring Finished Playback

- [notifyWhenPlayersFinished(finishedHandler:)](/documentation/corehaptics/chhapticengine/notifywhenplayersfinished(finishedhandler:)) Notifies you when all haptic pattern players have finished playing their haptic patterns.
- [CHHapticEngine.FinishedHandler](/documentation/corehaptics/chhapticengine/finishedhandler) A type alias for a completion handler to execute after finishing haptic playback.
- [CHHapticEngine.FinishedAction](/documentation/corehaptics/chhapticengine/finishedaction) Possible actions to take after the haptic engine finishes execution.

## Handling Haptic Engine Resets

- [resetHandler](/documentation/corehaptics/chhapticengine/resethandler-swift.property) A block that the haptic engine calls after recovering from a haptic server error.
- [CHHapticEngine.ResetHandler](/documentation/corehaptics/chhapticengine/resethandler-swift.typealias) A typealias for the block that the haptic engine calls after being reset.

## Handling Haptic Engine Stoppages

- [stoppedHandler](/documentation/corehaptics/chhapticengine/stoppedhandler-swift.property) A closure the haptic engine calls when it stops due to external causes.
- [CHHapticEngine.StoppedHandler](/documentation/corehaptics/chhapticengine/stoppedhandler-swift.typealias) A typealias for the block that the haptic engine calls after it stops due to an external cause.
- [CHHapticEngine.StoppedReason](/documentation/corehaptics/chhapticengine/stoppedreason) The enumeration of reasons the haptic engine stopped running.

## Getting the Current Media Time

- [currentTime](/documentation/corehaptics/chhapticengine/currenttime) The absolute time, in seconds, to use for scheduling haptic and audio events.
- [CHHapticTimeImmediate](/documentation/corehaptics/chhaptictimeimmediate) A time constant used to schedule a command immediately.

## Querying System Capabilities

- [capabilitiesForHardware()](/documentation/corehaptics/chhapticengine/capabilitiesforhardware()) Returns a device capability object that describes the device’s haptic support and limitations.
- [CHHapticDeviceCapability](/documentation/corehaptics/chhapticdevicecapability) A protocol that defines haptics and audio capabilities of a device.
- [CHHapticParameterAttributes](/documentation/corehaptics/chhapticparameterattributes) A protocol for providing default, mininum, and maximum values of a parameter.
- [attributes(forDynamicParameter:)](/documentation/corehaptics/chhapticdevicecapability/attributes(fordynamicparameter:)) Requests the haptic device’s attributes for a dynamic parameter.

## Managing Power

- [isAutoShutdownEnabled](/documentation/corehaptics/chhapticengine/isautoshutdownenabled) A Boolean value that indicates whether the haptic engine starts and stops automatically on request from one of its pattern players, or when idle.

## Initializers

- [init(andReturnError:)](/documentation/corehaptics/chhapticengine/init(andreturnerror:))

## Instance Properties

- [intendedSpatialExperience](/documentation/corehaptics/chhapticengine/intendedspatialexperience-55ca0) The CHHapticEngine’s intended [SpatialAudioExperience](/documentation/AudioToolbox/SpatialAudioExperience).

## Essentials

- [Preparing your app to play haptics](/documentation/corehaptics/preparing-your-app-to-play-haptics) Set up your app to play haptics.
- [Playing a single-tap haptic pattern](/documentation/corehaptics/playing-a-single-tap-haptic-pattern) Create and play a transient haptic pattern from a dictionary literal inline.
- [CHHapticPattern](/documentation/corehaptics/chhapticpattern) An object representing a haptic waveform.
- [CHHapticPatternPlayer](/documentation/corehaptics/chhapticpatternplayer) A protocol that defines a standard pattern player capable of playing haptic patterns with fixed parameters.
- [CHHapticAdvancedPatternPlayer](/documentation/corehaptics/chhapticadvancedpatternplayer) A protocol that defines an advanced pattern player capable of looping, seeking, pausing, and resuming haptic playback.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
