---
title: UIWindowScene
description: A scene that manages one or more windows for your app.
source: https://developer.apple.com/documentation/uikit/uiwindowscene
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uiwindowscene.json
timestamp: 2026-06-26T06:39:37.125Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UIWindowScene

**Available on:** iOS 13.0+, iPadOS 13.0+, Mac Catalyst 13.1+, tvOS 13.0+, visionOS 1.0+

> A scene that manages one or more windows for your app.

```swift
@MainActor class UIWindowScene
```

## Overview

A [UIWindowScene](/documentation/uikit/uiwindowscene) object manages one instance of your app’s UI, including one or more windows that you display from that scene. The scene object manages the display of your windows on the user’s device, and the life cycle of that scene as the user interacts with it. When the state of the scene changes, the scene object notifies its delegate object, which adopts the [UIWindowSceneDelegate](/documentation/uikit/uiwindowscenedelegate) protocol. The scene also posts appropriate notifications to registered observers. Use the delegate object or notification observers to respond to any changes.

Don’t create window scene objects directly. Instead, specify that you want a [UIWindowScene](/documentation/uikit/uiwindowscene) object at configuration time by including the class name for the scene in the scene configuration details of your app’s `Info.plist` file. You can also specify the class name when creating a [UISceneConfiguration](/documentation/uikit/uisceneconfiguration) object in your app delegate’s [application(_:configurationForConnecting:options:)](/documentation/uikit/uiapplicationdelegate/application(_:configurationforconnecting:options:)) method. When the user interacts with your app, the system creates an appropriate scene object based on the configuration data you provided. To create a scene programmatically, call the [requestSceneSessionActivation(_:userActivity:options:errorHandler:)](/documentation/uikit/uiapplication/requestscenesessionactivation(_:useractivity:options:errorhandler:)) method of [UIApplication](/documentation/uikit/uiapplication).

## Inherits From

- [UIScene](/documentation/uikit/uiscene)

## Conforms To

- [CVarArg](/documentation/Swift/CVarArg)
- [Copyable](/documentation/Swift/Copyable)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Escapable](/documentation/Swift/Escapable)
- [Hashable](/documentation/Swift/Hashable)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [NSTouchBarProvider](/documentation/AppKit/NSTouchBarProvider)
- [Sendable](/documentation/Swift/Sendable)
- [SendableMetatype](/documentation/Swift/SendableMetatype)
- [UIActivityItemsConfigurationProviding](/documentation/uikit/uiactivityitemsconfigurationproviding)
- [UIPasteConfigurationSupporting](/documentation/uikit/uipasteconfigurationsupporting)
- [UIResponderStandardEditActions](/documentation/uikit/uiresponderstandardeditactions)
- [UITraitChangeObservable](/documentation/uikit/uitraitchangeobservable-67e94)
- [UITraitEnvironment](/documentation/uikit/uitraitenvironment)
- [UIUserActivityRestoring](/documentation/uikit/uiuseractivityrestoring)

## Getting the active windows

- [windows](/documentation/uikit/uiwindowscene/windows) The windows associated with the scene.
- [keyWindow](/documentation/uikit/uiwindowscene/keywindow) The key window associated with the scene.
- [screen](/documentation/uikit/uiwindowscene/screen) The screen that displays the contents of the scene.

## Getting the interface attributes

- [traitCollection](/documentation/uikit/uiwindowscene/traitcollection) The traits that describe the current environment of the scene.
- [sizeRestrictions](/documentation/uikit/uiwindowscene/sizerestrictions) The minimum and maximum size of the app’s windows.
- [UISceneSizeRestrictions](/documentation/uikit/uiscenesizerestrictions) An object that specifies the minimum and maximum sizes for resizable windows.

## Observing trait changes

- [UITraitChangeObservable](/documentation/uikit/uitraitchangeobservable-67e94) A type that calls your code in reaction to changes in the trait environment.

## Overriding trait values

- [traitOverrides](/documentation/uikit/uiwindowscene/traitoverrides-1klo1)
- [UITraitOverrides](/documentation/uikit/uitraitoverrides-swift.struct) A mutable container of traits you use to set trait changes for an object and its descendants.

## Providing a PDF version of your scene

- [screenshotService](/documentation/uikit/uiwindowscene/screenshotservice) An object that generates a high-fidelity version of your app’s content.
- [UIScreenshotService](/documentation/uikit/uiscreenshotservice) An object that coordinates the creation of PDF screenshots of an app’s content.

## Sharing content

- [activityItemsConfigurationSource](/documentation/uikit/uiwindowscene/activityitemsconfigurationsource) An object that can provide shareable items for a scene.
- [UIActivityItemsConfigurationProviding](/documentation/uikit/uiactivityitemsconfigurationproviding) An interface that provides a source for shareable content to fulfill user requests to share current content.

## Determining window behaviors

- [isFullScreen](/documentation/uikit/uiwindowscene/isfullscreen) A Boolean value that indicates whether the window scene is full screen or windowed.
- [windowingBehaviors](/documentation/uikit/uiwindowscene/windowingbehaviors) An object that specifies the behaviors of the window.
- [UISceneWindowingBehaviors](/documentation/uikit/uiscenewindowingbehaviors) An object with properties that determine the behavior of a window.

## Working with window geometry

- [effectiveGeometry](/documentation/uikit/uiwindowscene/effectivegeometry) The current values for the window scene’s geometry in system space.
- [requestGeometryUpdate(_:errorHandler:)](/documentation/uikit/uiwindowscene/requestgeometryupdate(_:errorhandler:)) Requests an update to the window scene’s geometry using the specified geometry preferences object.
- [UIWindowScene.Geometry](/documentation/uikit/uiwindowscene/geometry) An object that provides geometry information about the window scene.
- [UIWindowScene.GeometryPreferences](/documentation/uikit/uiwindowscene/geometrypreferences) An abstract superclass for representing window scene geometry preferences.
- [UIWindowScene.GeometryPreferences.iOS](/documentation/uikit/uiwindowscene/geometrypreferences/ios) An object that represents the geometry preferences for a window scene in an iOS app.
- [UIWindowScene.GeometryPreferences.Mac](/documentation/uikit/uiwindowscene/geometrypreferences/mac) An object that represents the geometry preferences for a window scene in an app built with Mac Catalyst.
- [UIWindowScene.GeometryPreferences.Vision](/documentation/uikit/uiwindowscene/geometrypreferences/vision)
- [UIProposedSceneSizeNoPreference](/documentation/uikit/uiproposedscenesizenopreference) Used as the value for a dimension of a size related preference when wanting to leave it unchanged.

## Working with focus

- [focusSystem](/documentation/uikit/uiwindowscene/focussystem) The focus system that’s responsible for the window scene.

## Getting the status bar configuration

- [statusBarManager](/documentation/uikit/uiwindowscene/statusbarmanager) The current configuration of the status bar.
- [UIStatusBarManager](/documentation/uikit/uistatusbarmanager) An object that describes the configuration of the status bar.

## Configuring a window’s title bar

- [titlebar](/documentation/uikit/uiwindowscene/titlebar) The title bar displayed in a window of a Mac app.
- [UITitlebar](/documentation/uikit/uititlebar) An object that you use to configure the title bar of a window in a Mac app built with Mac Catalyst.

## Configuring the windowing control style

- [UIWindowScene.WindowingControlStyle](/documentation/uikit/uiwindowscene/windowingcontrolstyle) Describes the placement and style of the system windowing controls for a scene

## Supporting types

- [UIWindowScene.ActivationAction](/documentation/uikit/uiwindowscene/activationaction) A menu element that requests a window scene.
- [UIWindowScene.ActivationConfiguration](/documentation/uikit/uiwindowscene/activationconfiguration) An object that provides configuration options for a window scene request.
- [UIWindowScene.ActivationInteraction](/documentation/uikit/uiwindowscene/activationinteraction) An interaction that facilitates activating a window scene when a user pinches out on the interaction’s view.
- [UIWindowScene.ActivationRequestOptions](/documentation/uikit/uiwindowscene/activationrequestoptions) An object that contains information you want the system to use when activating a new window scene.
- [UIWindowSceneDestructionRequestOptions](/documentation/uikit/uiwindowscenedestructionrequestoptions) An object that contains information to use when removing a window scene from your app.
- [UIWindowScene.DismissalAnimation](/documentation/uikit/uiwindowscene/dismissalanimation) Constants that indicate the types of animations available for dismissing a scene’s windows.
- [UIWindowSceneDragInteraction](/documentation/uikit/uiwindowscenedraginteraction) An interaction you add to a view that enables pan gestures to change the containing window scene’s position.
- [UIWindowScene.ResizingRestrictions](/documentation/uikit/uiwindowscene/resizingrestrictions)
- [UIWindowSceneResizingRestrictions](/documentation/uikit/uiwindowsceneresizingrestrictions)
- [UIWindowScene.PresentationStyle](/documentation/uikit/uiwindowscene/presentationstyle) The placement of a window scene relative to other scenes in the workspace.

## Deprecated symbols

- [coordinateSpace](/documentation/uikit/uiwindowscene/coordinatespace) The coordinate space occupied by the scene.
- [interfaceOrientation](/documentation/uikit/uiwindowscene/interfaceorientation) The orientation to use when displaying content in your windows.

## Instance Properties

- [closureConfirmation](/documentation/uikit/uiwindowscene/closureconfirmation) A configuration describing a confirmation dialog to be shown when a user action will result in destruction of the scene session and disconnection of the scene.

## Instance Methods

- [displayLink(action:)](/documentation/uikit/uiwindowscene/displaylink(action:))
- [displayLink(target:selector:)](/documentation/uikit/uiwindowscene/displaylink(target:selector:)) Creates a display link targeting the display associated with this scene.

## Window scenes

- [Supporting multiple windows on iPad](/documentation/uikit/supporting-multiple-windows-on-ipad) Support side-by-side instances of your app’s interface and create new windows.
- [UIWindowSceneDelegate](/documentation/uikit/uiwindowscenedelegate) Additional methods that you use to manage app-specific tasks occurring in a scene.
- [UIScene](/documentation/uikit/uiscene) An object that represents one instance of your app’s user interface.
- [UISceneDelegate](/documentation/uikit/uiscenedelegate) The core methods you use to respond to life-cycle events occurring within a scene.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
