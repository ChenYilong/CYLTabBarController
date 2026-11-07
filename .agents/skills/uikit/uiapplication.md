---
title: UIApplication
description: The centralized point of control and coordination for apps running in iOS.
source: https://developer.apple.com/documentation/uikit/uiapplication
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uiapplication.json
timestamp: 2026-06-26T06:39:36.913Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UIApplication

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+

> The centralized point of control and coordination for apps running in iOS.

```swift
@MainActor class UIApplication
```

## Overview

Every iOS app has exactly one instance of [UIApplication](/documentation/uikit/uiapplication) (or, very rarely, a subclass of [UIApplication](/documentation/uikit/uiapplication)). When an app launches, the system calls the [UIApplicationMain(_:_:_:_:)](/documentation/uikit/uiapplicationmain(_:_:_:_:)-1yub7) function. Among its other tasks, this function creates a singleton [UIApplication](/documentation/uikit/uiapplication) object that you access using [shared](/documentation/uikit/uiapplication/shared).

Your app’s application object handles the initial routing of incoming user events. It dispatches action messages forwarded to it by control objects (instances of the [UIControl](/documentation/uikit/uicontrol) class) to appropriate target objects. The application object maintains a list of open windows ([UIWindow](/documentation/uikit/uiwindow) objects), which it can use to retrieve any of the app’s [UIView](/documentation/uikit/uiview) objects.

The [UIApplication](/documentation/uikit/uiapplication) class defines a delegate that conforms to the [UIApplicationDelegate](/documentation/uikit/uiapplicationdelegate) protocol and must implement some of the protocol’s methods. The application object informs the delegate of significant runtime events—for example, app launch, low-memory warnings, and app termination—giving it an opportunity to respond appropriately.

Apps can cooperatively handle a resource, such as an email or an image file, through the [open(_:options:completionHandler:)](/documentation/uikit/uiapplication/open(_:options:completionhandler:)) method. For example, an app that calls this method with an email URL causes the Mail app to launch and display the message.

The APIs in this class allow you to manage device-specific behavior. Use your [UIApplication](/documentation/uikit/uiapplication) object to do the following:

- Temporarily suspend incoming touch events ([beginIgnoringInteractionEvents()](/documentation/uikit/uiapplication/beginignoringinteractionevents()))
- Register for remote notifications ([registerForRemoteNotifications()](/documentation/uikit/uiapplication/registerforremotenotifications()))
- Trigger the undo-redo UI ([applicationSupportsShakeToEdit](/documentation/uikit/uiapplication/applicationsupportsshaketoedit))
- Determine whether there is an installed app registered to handle a URL scheme ([canOpenURL(_:)](/documentation/uikit/uiapplication/canopenurl(_:)))
- Extend the execution of the app so that it can finish a task in the background ([beginBackgroundTask(expirationHandler:)](/documentation/uikit/uiapplication/beginbackgroundtask(expirationhandler:)) and [beginBackgroundTask(withName:expirationHandler:)](/documentation/uikit/uiapplication/beginbackgroundtask(withname:expirationhandler:)))
- Schedule and cancel local notifications ([scheduleLocalNotification(_:)](/documentation/uikit/uiapplication/schedulelocalnotification(_:)) and [cancelLocalNotification(_:)](/documentation/uikit/uiapplication/cancellocalnotification(_:)))
- Coordinate the reception of remote-control events ([beginReceivingRemoteControlEvents()](/documentation/uikit/uiapplication/beginreceivingremotecontrolevents()) and [endReceivingRemoteControlEvents()](/documentation/uikit/uiapplication/endreceivingremotecontrolevents()))
- Perform app-level state restoration tasks (methods in the [Managing state restoration](/documentation/uikit/uiapplication#Managing-state-restoration) task group)

### Subclassing notes

Most apps don’t need to subclass [UIApplication](/documentation/uikit/uiapplication). Instead, use an app delegate to manage interactions between the system and the app.

If your app must handle incoming events before the system does—a very rare situation—you can implement a custom event or action dispatching mechanism. To do this, subclass [UIApplication](/documentation/uikit/uiapplication) and override the [sendEvent(_:)](/documentation/uikit/uiapplication/sendevent(_:)) and/or the [sendAction(_:to:from:for:)](/documentation/uikit/uiapplication/sendaction(_:to:from:for:)) methods. For every event you intercept, after you handle the event, dispatch it back to the system by calling:

```swift
super.sendEvent(event)
```

Intercepting events is only rarely required and you should avoid it if possible.

## Inherits From

- [UIResponder](/documentation/uikit/uiresponder)

## Conforms To

- [CVarArg](/documentation/Swift/CVarArg)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Hashable](/documentation/Swift/Hashable)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [NSTouchBarProvider](/documentation/AppKit/NSTouchBarProvider)
- [Sendable](/documentation/Swift/Sendable)
- [SendableMetatype](/documentation/Swift/SendableMetatype)
- [UIActivityItemsConfigurationProviding](/documentation/uikit/uiactivityitemsconfigurationproviding)
- [UIPasteConfigurationSupporting](/documentation/uikit/uipasteconfigurationsupporting)
- [UIResponderStandardEditActions](/documentation/uikit/uiresponderstandardeditactions)
- [UIUserActivityRestoring](/documentation/uikit/uiuseractivityrestoring)

## Accessing the shared application

- [shared](/documentation/uikit/uiapplication/shared) The singleton app instance.

## Configuring your app’s behavior

- [delegate](/documentation/uikit/uiapplication/delegate) The delegate of the app object.
- [UIApplicationDelegate](/documentation/uikit/uiapplicationdelegate) A set of methods to manage shared behaviors for your app.

## Registering for remote notifications

- [registerForRemoteNotifications()](/documentation/uikit/uiapplication/registerforremotenotifications()) Registers to receive remote notifications through Apple Push Notification service.
- [unregisterForRemoteNotifications()](/documentation/uikit/uiapplication/unregisterforremotenotifications()) Unregisters for all remote notifications received through Apple Push Notification service.
- [isRegisteredForRemoteNotifications](/documentation/uikit/uiapplication/isregisteredforremotenotifications) A Boolean value that indicates whether the app is currently registered for remote notifications.

## Getting the application state

- [applicationState](/documentation/uikit/uiapplication/applicationstate) The app’s current state, or that of its most active scene.
- [UIApplication.State](/documentation/uikit/uiapplication/state) Constants that indicate the running states of an app.

## Getting scene information

- [supportsMultipleScenes](/documentation/uikit/uiapplication/supportsmultiplescenes) A Boolean value that indicates whether the app may display multiple scenes simultaneously.
- [connectedScenes](/documentation/uikit/uiapplication/connectedscenes) The app’s currently connected scenes.
- [openSessions](/documentation/uikit/uiapplication/opensessions) The sessions whose scenes are either currently active or archived by the system.

## Managing a scene’s life cycle

- [activateSceneSession(for:errorHandler:)](/documentation/uikit/uiapplication/activatescenesession(for:errorhandler:)) Asks the system to activate an existing scene or create a new scene and associate it with your app.
- [requestSceneSessionDestruction(_:options:errorHandler:)](/documentation/uikit/uiapplication/requestscenesessiondestruction(_:options:errorhandler:)) Asks the system to dismiss an existing scene and remove it from the app switcher.
- [requestSceneSessionRefresh(_:)](/documentation/uikit/uiapplication/requestscenesessionrefresh(_:)) Asks the system to update any system UI associated with the specified scene.
- [UISceneSessionActivationRequest](/documentation/uikit/uiscenesessionactivationrequest-swift.struct) A collection of properties that you use to request activation of a scene.
- [UIScene.ActivationRequestOptions](/documentation/uikit/uiscene/activationrequestoptions) An object that contains information you want the system to use when activating the session associated with a scene.
- [UISceneDestructionRequestOptions](/documentation/uikit/uiscenedestructionrequestoptions) An object you pass to UIKit to permanently remove a scene and its associated session from your app.

## Managing background tasks

- [backgroundRefreshStatus](/documentation/uikit/uiapplication/backgroundrefreshstatus) Indicates whether the app can refresh content when running in the background.
- [UIBackgroundRefreshStatus](/documentation/uikit/uibackgroundrefreshstatus) Constants that indicate whether background execution is enabled for the app.
- [backgroundRefreshStatusDidChangeNotification](/documentation/uikit/uiapplication/backgroundrefreshstatusdidchangenotification) A notification that posts when the app’s status for downloading content in the background changes.
- [beginBackgroundTask(withName:expirationHandler:)](/documentation/uikit/uiapplication/beginbackgroundtask(withname:expirationhandler:)) Marks the start of a task with a custom name that should continue if the app enters the background.
- [beginBackgroundTask(expirationHandler:)](/documentation/uikit/uiapplication/beginbackgroundtask(expirationhandler:)) Marks the start of a task that should continue if the app enters the background.
- [endBackgroundTask(_:)](/documentation/uikit/uiapplication/endbackgroundtask(_:)) Marks the end of a specific long-running background task.
- [UIBackgroundTaskIdentifier](/documentation/uikit/uibackgroundtaskidentifier) A unique token that identifies a request to run in the background.
- [backgroundTimeRemaining](/documentation/uikit/uiapplication/backgroundtimeremaining) The maximum amount of time remaining for the app to run in the background.

## Fetching content in the background

- [backgroundFetchIntervalMinimum](/documentation/uikit/uiapplication/backgroundfetchintervalminimum) The smallest fetch interval supported by the system.
- [backgroundFetchIntervalNever](/documentation/uikit/uiapplication/backgroundfetchintervalnever) A fetch interval large enough to prevent fetch operations from occurring.

## Opening a URL resource

- [open(_:options:completionHandler:)](/documentation/uikit/uiapplication/open(_:options:completionhandler:)) Attempts to asynchronously open the resource at the specified URL.
- [canOpenURL(_:)](/documentation/uikit/uiapplication/canopenurl(_:)) Returns a Boolean value that indicates whether an app is available to handle a URL scheme.
- [UIApplication.OpenExternalURLOptionsKey](/documentation/uikit/uiapplication/openexternalurloptionskey) Options for opening a URL.

## Deep linking to custom settings

- [openSettingsURLString](/documentation/uikit/uiapplication/opensettingsurlstring) The URL string you use to deep link to your app’s custom settings in the Settings app.
- [openNotificationSettingsURLString](/documentation/uikit/uiapplication/opennotificationsettingsurlstring) The URL string you use to deep link to your app’s notification settings in the Settings app.
- [UIApplicationOpenNotificationSettingsURLString](/documentation/uikit/uiapplicationopennotificationsettingsurlstring) A constant that provides the URL string you use to deep link to your app’s notification settings in the Settings app.
- [openDefaultApplicationsSettingsURLString](/documentation/uikit/uiapplication/opendefaultapplicationssettingsurlstring) The URL string used to select a default app in the Settings app.

## Managing the app’s idle timer

- [isIdleTimerDisabled](/documentation/uikit/uiapplication/isidletimerdisabled) A Boolean value that controls whether the idle timer is disabled for the app.

## Managing state restoration

- [extendStateRestoration()](/documentation/uikit/uiapplication/extendstaterestoration()) Tells the app that your code is restoring state asynchronously.
- [completeStateRestoration()](/documentation/uikit/uiapplication/completestaterestoration()) Tells the app that your code has finished any asynchronous state restoration.
- [ignoreSnapshotOnNextApplicationLaunch()](/documentation/uikit/uiapplication/ignoresnapshotonnextapplicationlaunch()) Prevents the app from using the recent snapshot image during the next launch cycle.
- [registerObject(forStateRestoration:restorationIdentifier:)](/documentation/uikit/uiapplication/registerobject(forstaterestoration:restorationidentifier:)) Registers a custom object for use with the state restoration system.

## Providing an app’s shortcut items

- [shortcutItems](/documentation/uikit/uiapplication/shortcutitems) The Home screen dynamic quick actions for your app; available on devices that support 3D Touch.

## Accessing protected content

- [isProtectedDataAvailable](/documentation/uikit/uiapplication/isprotecteddataavailable) A Boolean value that indicates whether content protection is active.
- [protectedDataDidBecomeAvailableNotification](/documentation/uikit/uiapplication/protecteddatadidbecomeavailablenotification) A notification that posts when the protected files become available for your code to access.
- [protectedDataWillBecomeUnavailableNotification](/documentation/uikit/uiapplication/protecteddatawillbecomeunavailablenotification) A notification that posts shortly before protected files are locked down and become inaccessible.

## Receiving remote control events

- [beginReceivingRemoteControlEvents()](/documentation/uikit/uiapplication/beginreceivingremotecontrolevents()) Tells the app to begin receiving remote-control events.
- [endReceivingRemoteControlEvents()](/documentation/uikit/uiapplication/endreceivingremotecontrolevents()) Tells the app to stop receiving remote-control events.

## Accessing the layout direction

- [userInterfaceLayoutDirection](/documentation/uikit/uiapplication/userinterfacelayoutdirection) The layout direction of the user interface.
- [UIUserInterfaceLayoutDirection](/documentation/uikit/uiuserinterfacelayoutdirection) Constants that specify the directional flow of the user interface.

## Controlling and handling events

- [sendEvent(_:)](/documentation/uikit/uiapplication/sendevent(_:)) Dispatches an event to the appropriate responder objects in the app.
- [sendAction(_:to:from:for:)](/documentation/uikit/uiapplication/sendaction(_:to:from:for:)) Sends an action message identified by the selector to a specified target.
- [applicationSupportsShakeToEdit](/documentation/uikit/uiapplication/applicationsupportsshaketoedit) A Boolean value that determines whether shaking the device displays the undo-redo user interface.

## Managing the app’s icon

- [supportsAlternateIcons](/documentation/uikit/uiapplication/supportsalternateicons) A Boolean value that indicates whether the app is allowed to change its icon.
- [alternateIconName](/documentation/uikit/uiapplication/alternateiconname) The name of the icon the system displays for the app.
- [setAlternateIconName(_:completionHandler:)](/documentation/uikit/uiapplication/setalternateiconname(_:completionhandler:)) Changes the icon the system displays for the app.

## Managing the preferred content size

- [preferredContentSizeCategory](/documentation/uikit/uiapplication/preferredcontentsizecategory) The font sizing option preferred by the user.
- [UIContentSizeCategory](/documentation/uikit/uicontentsizecategory) Constants that indicate the preferred size of your content.
- [UIContentSizeCategoryAdjusting](/documentation/uikit/uicontentsizecategoryadjusting) A collection of methods that give controls an easy way to adopt automatic adjustment to content category changes.
- [didChangeNotification](/documentation/uikit/uicontentsizecategory/didchangenotification) A notification that posts when the user changes the preferred content size setting.
- [newValueUserInfoKey](/documentation/uikit/uicontentsizecategory/newvalueuserinfokey) A key that reflects the new preferred content size.

## Specifying the supported interface orientations

- [supportedInterfaceOrientations(for:)](/documentation/uikit/uiapplication/supportedinterfaceorientations(for:)) Returns the default set of interface orientations to use for the view controllers in the specified window.

## Tracking controls in the run loop

- [tracking](/documentation/Foundation/RunLoop/Mode/tracking) The mode set while tracking in controls takes place.

## Detecting screenshots

- [userDidTakeScreenshotNotification](/documentation/uikit/uiapplication/userdidtakescreenshotnotification) A notification that posts when a person takes a screenshot on the device.

## Discovering if your app is the default app in a category

- [isDefault(_:)](/documentation/uikit/uiapplication/isdefault(_:)) Reports whether this app is the person’s default app in the given category.
- [UIApplication.Category](/documentation/uikit/uiapplication/category) Constants that describe the types of apps in the system.
- [UIApplication.CategoryDefaultError](/documentation/uikit/uiapplication/categorydefaulterror) Errors that can happen when the system checks if your app is the default app in a category.

## Deprecated

- [Deprecated symbols](/documentation/uikit/uiapplication-deprecated-symbols) Review unsupported symbols and their replacements.

## Structures

- [UIApplication.BackgroundRefreshStatusDidChangeMessage](/documentation/uikit/uiapplication/backgroundrefreshstatusdidchangemessage)
- [UIApplication.DidBecomeActiveMessage](/documentation/uikit/uiapplication/didbecomeactivemessage)
- [UIApplication.DidEnterBackgroundMessage](/documentation/uikit/uiapplication/didenterbackgroundmessage)
- [UIApplication.DidFinishLaunchingMessage](/documentation/uikit/uiapplication/didfinishlaunchingmessage)
- [UIApplication.DidReceiveMemoryWarningMessage](/documentation/uikit/uiapplication/didreceivememorywarningmessage)
- [UIApplication.ProtectedDataDidBecomeAvailableMessage](/documentation/uikit/uiapplication/protecteddatadidbecomeavailablemessage)
- [UIApplication.ProtectedDataWillBecomeUnavailableMessage](/documentation/uikit/uiapplication/protecteddatawillbecomeunavailablemessage)
- [UIApplication.SignificantTimeChangeMessage](/documentation/uikit/uiapplication/significanttimechangemessage)
- [UIApplication.UserDidTakeScreenshotMessage](/documentation/uikit/uiapplication/userdidtakescreenshotmessage)
- [UIApplication.WillEnterForegroundMessage](/documentation/uikit/uiapplication/willenterforegroundmessage)
- [UIApplication.WillResignActiveMessage](/documentation/uikit/uiapplication/willresignactivemessage)
- [UIApplication.WillTerminateMessage](/documentation/uikit/uiapplication/willterminatemessage)

## Life cycle

- [Managing your app’s life cycle](/documentation/uikit/managing-your-app-s-life-cycle) Respond to system notifications when your app is in the foreground or background, and handle other significant system-related events.
- [Responding to the launch of your app](/documentation/uikit/responding-to-the-launch-of-your-app) Initialize your app’s data structures, prepare your app to run, and respond to any launch-time requests from the system.
- [UIApplicationDelegate](/documentation/uikit/uiapplicationdelegate) A set of methods to manage shared behaviors for your app.
- [Scenes](/documentation/uikit/scenes) Manage multiple instances of your app’s UI simultaneously, and direct resources to the appropriate instance of your UI.
- [Transitioning to the UIKit scene-based life cycle](/documentation/uikit/transitioning-to-the-uikit-scene-based-life-cycle) Adopt the scene-based life cycle to replace the app delegate life cycle in UIKit.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
