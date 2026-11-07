---
title: CADisplayLink
description: A timer object that allows your app to synchronize its drawing to the refresh rate of the display.
source: https://developer.apple.com/documentation/quartzcore/cadisplaylink
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/quartzcore/cadisplaylink.json
timestamp: 2026-05-13T20:41:36.535Z
---

**Navigation:** [Quartzcore](/documentation/quartzcore)

**Class**

# CADisplayLink

**Available on:** iOS 3.1+, iPadOS 3.1+, Mac Catalyst 13.1+, macOS 14.0+, tvOS 9.0+, visionOS 1.0+

> A timer object that allows your app to synchronize its drawing to the refresh rate of the display.

```swift
class CADisplayLink
```

## Overview

Your app initializes a new display link by providing a target object and a selector to call when the system updates the screen. To synchronize your display loop with the display, your application adds it to a run loop using the [add(to:forMode:)](/documentation/quartzcore/cadisplaylink/add(to:formode:)) method.

Once you associate the display link with a run loop, the system calls the selector on the target when the screen’s contents need to update. The target can read the display link’s [timestamp](/documentation/quartzcore/cadisplaylink/timestamp) property to retrieve the time the system displayed the previous frame. For example, an app that displays movies might use `timestamp` to calculate which video frame to display next. An app that performs its own animations might use `timestamp` to determine where and how visible objects appear in the upcoming frame.

The [duration](/documentation/quartzcore/cadisplaylink/duration) property provides the amount of time between frames at the [maximumFramesPerSecond](/documentation/UIKit/UIScreen/maximumFramesPerSecond). To calculate the actual frame duration, use [targetTimestamp](/documentation/quartzcore/cadisplaylink/targettimestamp) - [timestamp](/documentation/quartzcore/cadisplaylink/timestamp). You can use this value in your app to calculate the frame rate of the display, the approximate time the system displays the next frame, and to adjust the drawing behavior so that the next frame is ready in time to display.

Your app can disable notifications by setting [isPaused](/documentation/quartzcore/cadisplaylink/ispaused) to `true`. Also, if your app can’t provide frames in the time the system provides, you may want to choose a slower frame rate. An app with a slower but consistent frame rate appears smoother to the user than an app that skips frames. You can define the number of frames per second by setting [preferredFramesPerSecond](/documentation/quartzcore/cadisplaylink/preferredframespersecond).

When your app finishes with a display link, call [invalidate()](/documentation/quartzcore/cadisplaylink/invalidate()) to remove it from all run loops and to disassociate it from the target.

The code listing below shows how to create a display link and add it to the current run loop. The display link invokes the step function, which prints the target timestamp with each screen update.

### Swift

```swift
func createDisplayLink() {
    let displaylink = CADisplayLink(target: self,
                                    selector: #selector(step))
    
    displaylink.add(to: .current,
                    forMode: .defaultRunLoopMode)
}
     
func step(displaylink: CADisplayLink) {
    print(displaylink.targetTimestamp)
}
```

### Objective-C

```objc
- (void)createDisplayLink {
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self
                                                             selector:@selector(step:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop]
                      forMode:NSRunLoopCommonModes];
}

- (void)step:(CADisplayLink *)sender {
    NSLog(@"%f", sender.targetTimestamp);
}
```

You shouldn’t subclass [CADisplayLink](/documentation/quartzcore/cadisplaylink).

### Preferred and Actual Frame Rates

You control a display link’s frame rate (the number of times the system calls the selector of its target, per second) by setting [preferredFramesPerSecond](/documentation/quartzcore/cadisplaylink/preferredframespersecond). However, the actual frames per second may differ from the preferred value you set; actual frame rates are always a factor of the maximum refresh rate of the device. For example, if your device’s maximum refresh rate is 60 frames per second (defined by [maximumFramesPerSecond](/documentation/UIKit/UIScreen/maximumFramesPerSecond)), actual frame rates include 15, 20, 30, and 60 frames per second. If you set a display link’s preferred frame rate to a value higher than the maximum, the actual frame rate is the maximum.

In iOS 15, frame rate availability can change due to the system factoring in the system policy and user preference — including Low Power Mode, critical thermal state, and accessibility settings.

The system rounds, to the nearest factor, preferred frame rates that aren’t a divisor of the maximum frame rate. For example, setting a preferred frame rate to either 26 or 35 frames per second on a device with a maximum refresh rate of 60 frames per second yields an actual frame rate of 30 times per second.

The code listing below shows how to calculate the actual frame rate by dividing 1 by your display link’s [timestamp](/documentation/quartzcore/cadisplaylink/timestamp) subtracted from its [targetTimestamp](/documentation/quartzcore/cadisplaylink/targettimestamp).

### Swift

```swift
// Calculate the actual frame rate.
let actualFramesPerSecond = 1 / (displaylink.targetTimestamp - displaylink.timestamp)
```

### Objective-C

```objc
// Calculate the actual frame rate.
double actualFramesPerSecond = 1 / (displaylink.targetTimestamp - displaylink.timestamp);
```

> **Note:** If your app needs more control over refresh rate to ensure smooth rendering of frames, use [CAMetalDisplayLink](/documentation/quartzcore/cametaldisplaylink) and the information from [CAMetalLayer](/documentation/quartzcore/cametallayer) instances to render frames.

## Inherits From

- [NSObject](/documentation/ObjectiveC/NSObject-swift.class)

## Conforms To

- [CVarArg](/documentation/Swift/CVarArg)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Hashable](/documentation/Swift/Hashable)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)

## Creating a Display Link

- [init(target:selector:)](/documentation/quartzcore/cadisplaylink/init(target:selector:)) Creates a display link for a target that calls its selector.

## Configuring a Display Link

- [duration](/documentation/quartzcore/cadisplaylink/duration) The time interval between screen refresh updates.
- [preferredFrameRateRange](/documentation/quartzcore/cadisplaylink/preferredframeraterange) A range of frequencies your app allows for frame updates, affecting how often the system invokes your delegate’s callback.
- [preferredFramesPerSecond](/documentation/quartzcore/cadisplaylink/preferredframespersecond) A frequency your app prefers for frame updates, affecting how often the system invokes your delegate’s callback.
- [isPaused](/documentation/quartzcore/cadisplaylink/ispaused) A Boolean value that indicates whether the system suspends the display link’s notifications to the target.
- [timestamp](/documentation/quartzcore/cadisplaylink/timestamp) The time interval that represents when the last frame displayed.
- [targetTimestamp](/documentation/quartzcore/cadisplaylink/targettimestamp) The time interval that represents when the next frame displays.
- [frameInterval](/documentation/quartzcore/cadisplaylink/frameinterval) The number of frames that must pass before the display link notifies the target again.

## Scheduling a Display Link to Send Notifications

- [add(to:forMode:)](/documentation/quartzcore/cadisplaylink/add(to:formode:)) Registers the display link with a run loop.
- [remove(from:forMode:)](/documentation/quartzcore/cadisplaylink/remove(from:formode:)) Removes the display link from the run loop for the given mode.
- [invalidate()](/documentation/quartzcore/cadisplaylink/invalidate()) Removes the display link from all run loop modes.

## Related Documentation

- [Presenting content on a connected display](/documentation/UIKit/presenting-content-on-a-connected-display) Fill connected displays with additional content from your app.

## Animation Timing

- [CACurrentMediaTime()](/documentation/quartzcore/cacurrentmediatime()) Returns the current absolute time, in seconds.
- [CAMediaTimingFunction](/documentation/quartzcore/camediatimingfunction) A function that defines the pacing of an animation as a timing curve.
- [CAMediaTiming](/documentation/quartzcore/camediatiming) Methods that model a hierarchical timing system, allowing objects to map time between their parent and local time.
- [CAMetalDisplayLink](/documentation/quartzcore/cametaldisplaylink) A class your Metal app uses to register for callbacks to synchronize its animations for a display.
- [CAMetalDisplayLink.Update](/documentation/quartzcore/cametaldisplaylink/update) Stores information about a single update from a Metal display link instance.
- [CAMetalDisplayLinkDelegate](/documentation/quartzcore/cametaldisplaylinkdelegate) A protocol your app implements to respond to callbacks from Core Animation for a Metal display link.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
