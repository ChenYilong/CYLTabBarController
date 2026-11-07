---
title: UIAlertController
description: An object that displays an alert message.
source: https://developer.apple.com/documentation/uikit/uialertcontroller
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uialertcontroller.json
timestamp: 2026-04-14T13:14:48.258Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UIAlertController

**Available on:** iOS 8.0+, iPadOS 8.0+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+

> An object that displays an alert message.

```swift
@MainActor class UIAlertController
```

## Overview

Use this class to configure alerts and action sheets with the message that you want to display and the actions from which to choose. After configuring the alert controller with the actions and style you want, present it using the [present(_:animated:completion:)](/documentation/uikit/uiviewcontroller/present(_:animated:completion:)) method. UIKit displays alerts and action sheets modally over your app’s content.

In addition to displaying a message to a user, you can associate actions with your alert controller to give people a way to respond. For each action you add using the [addAction(_:)](/documentation/uikit/uialertcontroller/addaction(_:)) method, the alert controller configures a button with the action details. When a person taps that action, the alert controller executes the block you provided when creating the action object. The following code shows how to configure an alert with a single action.

### Swift

```swift
let alert = UIAlertController(title: "My Alert", message: "This is an alert.", preferredStyle: .alert) 
alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in 
NSLog("The \"OK\" alert occured.")
}))
self.present(alert, animated: true, completion: nil)
```

### Objective-C

```objc
UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"My Alert"
                               message:@"This is an alert."
                               preferredStyle:UIAlertControllerStyleAlert];
 
UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
   handler:^(UIAlertAction * action) {}];
 
[alert addAction:defaultAction];
[self presentViewController:alert animated:YES completion:nil];
```

When configuring an alert with the [UIAlertController.Style.alert](/documentation/uikit/uialertcontroller/style/alert) style, you can also add text fields to the alert interface. The alert controller lets you provide a block for configuring your text fields prior to display. The alert controller maintains a reference to each text field so that you can access its value later.

> **Important:** The [UIAlertController](/documentation/uikit/uialertcontroller) class is intended to be used as-is and doesn’t support subclassing. The view hierarchy for this class is private and must not be modified.

## Inherits From

- [UIViewController](/documentation/uikit/uiviewcontroller)

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
- [Sendable](/documentation/Swift/Sendable)
- [SendableMetatype](/documentation/Swift/SendableMetatype)
- [UIActivityItemsConfigurationProviding](/documentation/uikit/uiactivityitemsconfigurationproviding)
- [UIAppearanceContainer](/documentation/uikit/uiappearancecontainer)
- [UIContentContainer](/documentation/uikit/uicontentcontainer)
- [UIFocusEnvironment](/documentation/uikit/uifocusenvironment)
- [UIPasteConfigurationSupporting](/documentation/uikit/uipasteconfigurationsupporting)
- [UIResponderStandardEditActions](/documentation/uikit/uiresponderstandardeditactions)
- [UISpringLoadedInteractionSupporting](/documentation/uikit/uispringloadedinteractionsupporting)
- [UIStateRestoring](/documentation/uikit/uistaterestoring)
- [UITraitChangeObservable](/documentation/uikit/uitraitchangeobservable-67e94)
- [UITraitEnvironment](/documentation/uikit/uitraitenvironment)
- [UIUserActivityRestoring](/documentation/uikit/uiuseractivityrestoring)

## Creating an alert controller

- [init(title:message:preferredStyle:)](/documentation/uikit/uialertcontroller/init(title:message:preferredstyle:)) Creates and returns a view controller for displaying an alert.

## Configuring the alert

- [title](/documentation/uikit/uialertcontroller/title) The title of the alert.
- [message](/documentation/uikit/uialertcontroller/message) Descriptive text that provides more details about the reason for the alert.
- [preferredStyle](/documentation/uikit/uialertcontroller/preferredstyle) The style of the alert controller.
- [UIAlertController.Style](/documentation/uikit/uialertcontroller/style) Constants indicating the type of alert to display.

## Configuring the user actions

- [addAction(_:)](/documentation/uikit/uialertcontroller/addaction(_:)) Attaches an action object to the alert or action sheet.
- [actions](/documentation/uikit/uialertcontroller/actions) The actions that the user can take in response to the alert or action sheet.
- [preferredAction](/documentation/uikit/uialertcontroller/preferredaction) The preferred action for the user to take from an alert.

## Configuring text fields

- [addTextField(configurationHandler:)](/documentation/uikit/uialertcontroller/addtextfield(configurationhandler:)) Adds a text field to an alert.
- [textFields](/documentation/uikit/uialertcontroller/textfields) The array of text fields displayed by the alert.

## Configuring alert severity

- [severity](/documentation/uikit/uialertcontroller/severity) Indicates the severity of the alert.
- [UIAlertControllerSeverity](/documentation/uikit/uialertcontrollerseverity) Constants for specifying the severity of an alert in apps built with Mac Catalyst.

## Alerts

- [Getting the user’s attention with alerts and action sheets](/documentation/uikit/getting-the-user-s-attention-with-alerts-and-action-sheets) Present important information to a person or prompt them about an important choice.
- [UIAlertAction](/documentation/uikit/uialertaction) An action that can be taken when the user taps a button in an alert.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
