---
title: XCUIApplication
description: A proxy that can launch, monitor, and terminate a test application.
source: https://developer.apple.com/documentation/xcuiautomation/xcuiapplication
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/xcuiautomation/xcuiapplication.json
timestamp: 2026-05-10T06:22:51.217Z
---

**Navigation:** [XCUIAutomation](/documentation/xcuiautomation)

**Class**

# XCUIApplication

**Available on:** iOS, iPadOS, Mac Catalyst, macOS, tvOS, visionOS, watchOS, Xcode 16.3+

> A proxy that can launch, monitor, and terminate a test application.

```swift
@MainActor class XCUIApplication
```

## Overview

Use this class to launch, monitor, and terminate your app in a UI test. Use [wait(for:timeout:)](/documentation/xcuiautomation/xcuiapplication/wait(for:timeout:)) to launch your app and wait for it to reach an expected state before you check test conditions.

## Inherits From

- [XCUIElement](/documentation/xcuiautomation/xcuielement)

## Conforms To

- [CVarArg](/documentation/Swift/CVarArg)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Hashable](/documentation/Swift/Hashable)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [XCUIElementAttributes](/documentation/xcuiautomation/xcuielementattributes)
- [XCUIElementSnapshotProviding](/documentation/xcuiautomation/xcuielementsnapshotproviding)
- [XCUIElementTypeQueryProvider](/documentation/xcuiautomation/xcuielementtypequeryprovider)
- [XCUIScreenshotProviding](/documentation/xcuiautomation/xcuiscreenshotproviding)

## Creating an application proxy

- [init()](/documentation/xcuiautomation/xcuiapplication/init()) Creates a proxy for the application that’s configured as the Target Application in Xcode’s target settings.
- [init(bundleIdentifier:)](/documentation/xcuiautomation/xcuiapplication/init(bundleidentifier:)) Creates a proxy for an application for the specified bundle identifier.
- [init(url:)](/documentation/xcuiautomation/xcuiapplication/init(url:)-90e7z) Creates a proxy for the application at the specified file system URL.

## Launching the application

- [launch()](/documentation/xcuiautomation/xcuiapplication/launch()) Launches the application.
- [launchArguments](/documentation/xcuiautomation/xcuiapplication/launcharguments) The arguments that pass to the application on launch.
- [launchEnvironment](/documentation/xcuiautomation/xcuiapplication/launchenvironment) The environment variables that pass to the application on launch.
- [open(_:)](/documentation/xcuiautomation/xcuiapplication/open(_:)) Launches the application by URL.

## Activating the application

- [activate()](/documentation/xcuiautomation/xcuiapplication/activate()) Activates the application.

## Terminating the application

- [terminate()](/documentation/xcuiautomation/xcuiapplication/terminate()) Terminates any running instance of the application.

## Determining application state

- [state](/documentation/xcuiautomation/xcuiapplication/state-swift.property) The most recent state of the application.
- [XCUIApplication.State](/documentation/xcuiautomation/xcuiapplication/state-swift.enum) The possible states of an application during UI testing.

## Waiting for an application state

- [wait(for:timeout:)](/documentation/xcuiautomation/xcuiapplication/wait(for:timeout:)) Waits for the application to reach the specified state or timeout.

## Resetting authorization status

- [resetAuthorizationStatus(for:)](/documentation/xcuiautomation/xcuiapplication/resetauthorizationstatus(for:)) Resets the authorization status for a protected resource.
- [XCUIProtectedResource](/documentation/xcuiautomation/xcuiprotectedresource) A system resource that requires user authorization to access.

## Performing an accessibility audit

- [performAccessibilityAudit(for:_:)](/documentation/xcuiautomation/xcuiapplication/performaccessibilityaudit(for:_:))
- [XCUIAccessibilityAuditType](/documentation/xcuiautomation/xcuiaccessibilityaudittype)
- [XCUIAccessibilityAuditIssue](/documentation/xcuiautomation/xcuiaccessibilityauditissue)

## Initializers

- [init(URL:)](/documentation/xcuiautomation/xcuiapplication/init(url:)-6ga10)

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
