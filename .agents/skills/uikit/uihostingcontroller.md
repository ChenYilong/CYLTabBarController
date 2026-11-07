---
title: UIHostingController
description: A UIKit view controller that manages a SwiftUI view hierarchy.
source: https://developer.apple.com/documentation/swiftui/uihostingcontroller
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/swiftui/uihostingcontroller.json
timestamp: 2026-06-26T06:39:36.963Z
---

**Navigation:** [SwiftUI](/documentation/swiftui)

**Class**

# UIHostingController

**Available on:** iOS 13.0+, iPadOS 13.0+, Mac Catalyst 13.0+, tvOS 13.0+, visionOS 1.0+

> A UIKit view controller that manages a SwiftUI view hierarchy.

```swift
@MainActor @preconcurrency class UIHostingController<Content> where Content : View
```

## Overview

Create a `UIHostingController` object when you want to integrate SwiftUI views into a UIKit view hierarchy. At creation time, specify the SwiftUI view you want to use as the root view for this view controller; you can change that view later using the [rootView](/documentation/swiftui/uihostingcontroller/rootview) property. Use the hosting controller like you would any other view controller, by presenting it or embedding it as a child view controller in your interface.

## Inherits From

- [UIViewController](/documentation/UIKit/UIViewController)

## Conforms To

- [CVarArg](/documentation/Swift/CVarArg)
- [Copyable](/documentation/Swift/Copyable)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Escapable](/documentation/Swift/Escapable)
- [Hashable](/documentation/Swift/Hashable)
- [NSCoding](/documentation/Foundation/NSCoding)
- [NSExtensionRequestHandling](/documentation/Foundation/NSExtensionRequestHandling)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [NSTouchBarProvider](/documentation/AppKit/NSTouchBarProvider)
- [UIActivityItemsConfigurationProviding](/documentation/UIKit/UIActivityItemsConfigurationProviding)
- [UIAppearanceContainer](/documentation/UIKit/UIAppearanceContainer)
- [UIContentContainer](/documentation/UIKit/UIContentContainer)
- [UIFocusEnvironment](/documentation/UIKit/UIFocusEnvironment)
- [UIPasteConfigurationSupporting](/documentation/UIKit/UIPasteConfigurationSupporting)
- [UIResponderStandardEditActions](/documentation/UIKit/UIResponderStandardEditActions)
- [UIStateRestoring](/documentation/UIKit/UIStateRestoring)
- [UITraitChangeObservable](/documentation/UIKit/UITraitChangeObservable-67e94)
- [UITraitEnvironment](/documentation/UIKit/UITraitEnvironment)
- [UIUserActivityRestoring](/documentation/UIKit/UIUserActivityRestoring)

## Creating a hosting controller object

- [init(rootView:)](/documentation/swiftui/uihostingcontroller/init(rootview:)) Creates a hosting controller object that wraps the specified SwiftUI view.
- [init(coder:rootView:)](/documentation/swiftui/uihostingcontroller/init(coder:rootview:)) Creates a hosting controller object from an archive and the specified SwiftUI view.
- [init(coder:)](/documentation/swiftui/uihostingcontroller/init(coder:)) Creates a hosting controller object from the contents of the specified archive.

## Responding to view-related events

- [loadView()](/documentation/swiftui/uihostingcontroller/loadview())
- [viewWillAppear(_:)](/documentation/swiftui/uihostingcontroller/viewwillappear(_:)) Notifies the view controller that its view is about to be added to a view hierarchy.
- [viewDidAppear(_:)](/documentation/swiftui/uihostingcontroller/viewdidappear(_:)) Notifies the view controller that its view has been added to a view hierarchy.
- [viewWillDisappear(_:)](/documentation/swiftui/uihostingcontroller/viewwilldisappear(_:)) Notifies the view controller that its view will be removed from a view hierarchy.
- [viewDidDisappear(_:)](/documentation/swiftui/uihostingcontroller/viewdiddisappear(_:))
- [willMove(toParent:)](/documentation/swiftui/uihostingcontroller/willmove(toparent:))
- [didMove(toParent:)](/documentation/swiftui/uihostingcontroller/didmove(toparent:))
- [viewWillTransition(to:with:)](/documentation/swiftui/uihostingcontroller/viewwilltransition(to:with:))
- [viewWillLayoutSubviews()](/documentation/swiftui/uihostingcontroller/viewwilllayoutsubviews())
- [target(forAction:withSender:)](/documentation/swiftui/uihostingcontroller/target(foraction:withsender:))
- [rootView](/documentation/swiftui/uihostingcontroller/rootview) The root view of the SwiftUI view hierarchy managed by this view controller.

## Checking for modality

- [isModalInPresentation](/documentation/swiftui/uihostingcontroller/ismodalinpresentation)

## Managing the size

- [sizingOptions](/documentation/swiftui/uihostingcontroller/sizingoptions) The options for how the hosting controller tracks changes to the size of its SwiftUI content.
- [preferredContentSizeDidChange(forChildContentContainer:)](/documentation/swiftui/uihostingcontroller/preferredcontentsizedidchange(forchildcontentcontainer:))
- [sizeThatFits(in:)](/documentation/swiftui/uihostingcontroller/sizethatfits(in:)) Calculates and returns the most appropriate size for the current view.
- [safeAreaRegions](/documentation/swiftui/uihostingcontroller/safearearegions) The safe area regions that this view controller adds to its view.

## Configuring the status bar

- [preferredStatusBarStyle](/documentation/swiftui/uihostingcontroller/preferredstatusbarstyle) The preferred status bar style for the view controller.
- [preferredStatusBarUpdateAnimation](/documentation/swiftui/uihostingcontroller/preferredstatusbarupdateanimation) The animation style to use when hiding or showing the status bar for this view controller.
- [prefersStatusBarHidden](/documentation/swiftui/uihostingcontroller/prefersstatusbarhidden) A Boolean value that indicates whether the view controller prefers the status bar to be hidden or shown.
- [childForStatusBarStyle](/documentation/swiftui/uihostingcontroller/childforstatusbarstyle)
- [childForStatusBarHidden](/documentation/swiftui/uihostingcontroller/childforstatusbarhidden)

## Configuring the home indicator

- [prefersHomeIndicatorAutoHidden](/documentation/swiftui/uihostingcontroller/prefershomeindicatorautohidden) A Boolean value that indicates whether the view controller prefers the home indicator to be hidden or shown.
- [childForHomeIndicatorAutoHidden](/documentation/swiftui/uihostingcontroller/childforhomeindicatorautohidden)

## Configuring the interface appearance

- [preferredUserInterfaceStyle](/documentation/swiftui/uihostingcontroller/preferreduserinterfacestyle) The preferred interface style for this view controller.
- [preferredScreenEdgesDeferringSystemGestures](/documentation/swiftui/uihostingcontroller/preferredscreenedgesdeferringsystemgestures) Sets the screen edge from which you want your gesture to take precedence over the system gesture.
- [childForScreenEdgesDeferringSystemGestures](/documentation/swiftui/uihostingcontroller/childforscreenedgesdeferringsystemgestures)

## Accessing the available key commands

- [keyCommands](/documentation/swiftui/uihostingcontroller/keycommands)

## Managing undo

- [undoManager](/documentation/swiftui/uihostingcontroller/undomanager)

## Instance Properties

- [childViewControllerForPreferredContainerBackgroundStyle](/documentation/swiftui/uihostingcontroller/childviewcontrollerforpreferredcontainerbackgroundstyle)
- [preferredContainerBackgroundStyle](/documentation/swiftui/uihostingcontroller/preferredcontainerbackgroundstyle)

## Instance Methods

- [addChild(_:)](/documentation/swiftui/uihostingcontroller/addchild(_:))
- [canPerformAction(_:withSender:)](/documentation/swiftui/uihostingcontroller/canperformaction(_:withsender:))

## Displaying SwiftUI views in UIKit

- [Using SwiftUI with UIKit](/documentation/UIKit/using-swiftui-with-uikit) Learn how to incorporate SwiftUI views into a UIKit app.
- [Unifying your app’s animations](/documentation/swiftui/unifying-your-app-s-animations) Create a consistent UI animation experience across SwiftUI, UIKit, and AppKit.
- [UIHostingControllerSizingOptions](/documentation/swiftui/uihostingcontrollersizingoptions) Options for how a hosting controller tracks its content’s size.
- [UIHostingConfiguration](/documentation/swiftui/uihostingconfiguration) A content configuration suitable for hosting a hierarchy of SwiftUI views.
- [UIHostingSceneDelegate](/documentation/swiftui/uihostingscenedelegate) Extends `UIKit/UISceneDelegate` to bridge SwiftUI scenes.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
