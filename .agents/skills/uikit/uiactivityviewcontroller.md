---
title: UIActivityViewController
description: A view controller that you use to offer standard services from your app.
source: https://developer.apple.com/documentation/uikit/uiactivityviewcontroller
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uiactivityviewcontroller.json
timestamp: 2026-04-14T13:14:48.020Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UIActivityViewController

**Available on:** iOS 6.0+, iPadOS 6.0+, Mac Catalyst 13.1+, visionOS 1.0+

> A view controller that you use to offer standard services from your app.

```swift
class UIActivityViewController
```

## Overview

The system provides several standard services, such as copying items to the pasteboard, posting content to social media sites, sending items via email or SMS, and more. Apps can also define custom services.

Your app is responsible for configuring, presenting, and dismissing this view controller. Configuration for the view controller involves specifying the data objects on which the view controller should act. (You can also specify the list of custom services your app supports.) When presenting the view controller, you must do so using the appropriate means for the current device. On iPad, you must present the view controller in a popover. On iPhone and iPod touch, you must present it modally.

## Inherits From

- [UIViewController](/documentation/uikit/uiviewcontroller)

## Conforms To

- [CVarArg](/documentation/Swift/CVarArg)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Hashable](/documentation/Swift/Hashable)
- [NSCoding](/documentation/Foundation/NSCoding)
- [NSExtensionRequestHandling](/documentation/Foundation/NSExtensionRequestHandling)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [NSTouchBarProvider](/documentation/AppKit/NSTouchBarProvider)
- [Sendable](/documentation/Swift/Sendable)
- [SendableMetatype](/documentation/Swift/SendableMetatype)
- [UIActivityItemsConfigurationProviding](/documentation/uikit/uiactivityitemsconfigurationproviding)
- [UIAppearanceContainer](/documentation/uikit/uiappearancecontainer)
- [UIContentContainer](/documentation/uikit/uicontentcontainer)
- [UIFocusEnvironment](/documentation/uikit/uifocusenvironment)
- [UIPasteConfigurationSupporting](/documentation/uikit/uipasteconfigurationsupporting)
- [UIResponderStandardEditActions](/documentation/uikit/uiresponderstandardeditactions)
- [UIStateRestoring](/documentation/uikit/uistaterestoring)
- [UITraitChangeObservable](/documentation/uikit/uitraitchangeobservable-67e94)
- [UITraitEnvironment](/documentation/uikit/uitraitenvironment)
- [UIUserActivityRestoring](/documentation/uikit/uiuseractivityrestoring)

## Initializing the activity view controller

- [init(activityItems:applicationActivities:)](/documentation/uikit/uiactivityviewcontroller/init(activityitems:applicationactivities:)) Initializes a new activity view controller object that acts on the specified data.
- [init(activityItemsConfiguration:)](/documentation/uikit/uiactivityviewcontroller/init(activityitemsconfiguration:)) Initializes a new activity view controller object that acts on the specified configuration.
- [UIActivityItemsConfiguration](/documentation/uikit/uiactivityitemsconfiguration) A configuration that allows a responder to export data through a variety of interactions.
- [UIActivityItemsConfigurationReading](/documentation/uikit/uiactivityitemsconfigurationreading) A set of methods adopted by an object so that the object can act as an activity items configuration.

## Accessing the completion handler

- [completionWithItemsHandler](/documentation/uikit/uiactivityviewcontroller/completionwithitemshandler-swift.property) The completion handler to execute after the activity view controller is dismissed.
- [UIActivityViewController.CompletionWithItemsHandler](/documentation/uikit/uiactivityviewcontroller/completionwithitemshandler-swift.typealias) A completion handler to execute after the activity view controller is dismissed.

## Excluding specific activity types

- [excludedActivityTypes](/documentation/uikit/uiactivityviewcontroller/excludedactivitytypes) The list of services that should not be displayed.

## Excluding specific sections

- [excludedActivitySectionTypes](/documentation/uikit/uiactivityviewcontroller/excludedactivitysectiontypes) Hides some sections of the activity view controller. Default is none
- [UIActivitySectionTypes](/documentation/uikit/uiactivitysectiontypes)

## Elevating a prominent activity

- [allowsProminentActivity](/documentation/uikit/uiactivityviewcontroller/allowsprominentactivity) A Boolean value the system uses to elevate a system activity to make it more prominent.

## Deprecated

- [completionHandler](/documentation/uikit/uiactivityviewcontroller/completionhandler-swift.property) The completion handler to execute after the activity view controller is dismissed.
- [UIActivityViewController.CompletionHandler](/documentation/uikit/uiactivityviewcontroller/completionhandler-swift.typealias) A completion handler to execute after the activity view controller is dismissed.

## Services

- [UIActivity](/documentation/uikit/uiactivity) An abstract class that you subclass to implement app-specific services.
- [UIActivityItemSource](/documentation/uikit/uiactivityitemsource) A set of methods that an activity view controller uses to retrieve the data items to act on.
- [UIActivityItemProvider](/documentation/uikit/uiactivityitemprovider) A proxy for data that passes to an activity view controller.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
