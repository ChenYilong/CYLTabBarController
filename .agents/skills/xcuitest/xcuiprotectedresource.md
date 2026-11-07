---
title: XCUIProtectedResource
description: A system resource that requires user authorization to access.
source: https://developer.apple.com/documentation/xcuiautomation/xcuiprotectedresource
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/xcuiautomation/xcuiprotectedresource.json
timestamp: 2026-04-14T13:14:58.482Z
---

**Navigation:** [XCUIAutomation](/documentation/xcuiautomation)

**Enumeration**

# XCUIProtectedResource

**Available on:** iOS 13.4+, iPadOS 13.4+, Mac Catalyst 13.4+, macOS 10.15.4+, tvOS 13.4+, visionOS 1.0+, watchOS 6.2+, Xcode 16.3+

> A system resource that requires user authorization to access.

```swift
enum XCUIProtectedResource
```

## Conforms To

- [BitwiseCopyable](/documentation/Swift/BitwiseCopyable)
- [Equatable](/documentation/Swift/Equatable)
- [Hashable](/documentation/Swift/Hashable)
- [RawRepresentable](/documentation/Swift/RawRepresentable)
- [Sendable](/documentation/Swift/Sendable)
- [SendableMetatype](/documentation/Swift/SendableMetatype)

## Protected resources

- [XCUIProtectedResource.location](/documentation/xcuiautomation/xcuiprotectedresource/location) The protected resource case for Location Services.
- [XCUIProtectedResource.userTracking](/documentation/xcuiautomation/xcuiprotectedresource/usertracking) The protected resource case for access to tracking data.
- [XCUIProtectedResource.contacts](/documentation/xcuiautomation/xcuiprotectedresource/contacts) The protected resource case for access to Contacts.
- [XCUIProtectedResource.calendar](/documentation/xcuiautomation/xcuiprotectedresource/calendar) The protected resource case for acces to Calendar data.
- [XCUIProtectedResource.reminders](/documentation/xcuiautomation/xcuiprotectedresource/reminders) The protected resource case for access to Reminders data.
- [XCUIProtectedResource.photos](/documentation/xcuiautomation/xcuiprotectedresource/photos) The protected resource case for access to Photos.
- [XCUIProtectedResource.bluetooth](/documentation/xcuiautomation/xcuiprotectedresource/bluetooth) The protected resource case for Bluetooth utilization.
- [XCUIProtectedResource.localNetwork](/documentation/xcuiautomation/xcuiprotectedresource/localnetwork) The protected resource case for finding and communicating with devices on the local network.
- [XCUIProtectedResource.microphone](/documentation/xcuiautomation/xcuiprotectedresource/microphone) The protected resource case for access to the microphone.
- [XCUIProtectedResource.camera](/documentation/xcuiautomation/xcuiprotectedresource/camera) The protected resource case for access to the camera.
- [XCUIProtectedResource.health](/documentation/xcuiautomation/xcuiprotectedresource/health) The protected resource case for access to Health data.
- [XCUIProtectedResource.homeKit](/documentation/xcuiautomation/xcuiprotectedresource/homekit) The protected resource case for access to Home data.
- [XCUIProtectedResource.mediaLibrary](/documentation/xcuiautomation/xcuiprotectedresource/medialibrary) The protected resource case for access to the media library.
- [XCUIProtectedResource.keyboardNetwork](/documentation/xcuiautomation/xcuiprotectedresource/keyboardnetwork) The protected resource case for access to the keyboard network.
- [XCUIProtectedResource.systemRootDirectory](/documentation/xcuiautomation/xcuiprotectedresource/systemrootdirectory) The protected resource case for access to the system root directory.
- [XCUIProtectedResource.userDesktopDirectory](/documentation/xcuiautomation/xcuiprotectedresource/userdesktopdirectory) The protected resource case for access to the Desktop directory.
- [XCUIProtectedResource.userDocumentsDirectory](/documentation/xcuiautomation/xcuiprotectedresource/userdocumentsdirectory) The protected resource case for access to the Documents directory.
- [XCUIProtectedResource.userDownloadsDirectory](/documentation/xcuiautomation/xcuiprotectedresource/userdownloadsdirectory) The protected resource case for access to the Downloads directory.
- [XCUIProtectedResource.focus](/documentation/xcuiautomation/xcuiprotectedresource/focus) The protected resource case to see and share Focus status.
- [XCUIProtectedResource.removableVolumes](/documentation/xcuiautomation/xcuiprotectedresource/removablevolumes) The protected resource case for access to removable volumes.
- [XCUIProtectedResource.networkVolumes](/documentation/xcuiautomation/xcuiprotectedresource/networkvolumes) The protected resource case for access to network volumes.
- [XCUIProtectedResource.appleEvents](/documentation/xcuiautomation/xcuiprotectedresource/appleevents) The protected resource case for the use of Apple Events.

## Initializers

- [init(rawValue:)](/documentation/xcuiautomation/xcuiprotectedresource/init(rawvalue:))

## Resetting authorization status

- [resetAuthorizationStatus(for:)](/documentation/xcuiautomation/xcuiapplication/resetauthorizationstatus(for:)) Resets the authorization status for a protected resource.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
