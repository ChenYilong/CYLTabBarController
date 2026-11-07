---
title: UIApplicationDelegate
description: A set of methods to manage shared behaviors for your app.
source: https://developer.apple.com/documentation/uikit/uiapplicationdelegate
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uiapplicationdelegate.json
timestamp: 2026-06-26T06:39:36.918Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Protocol**

# UIApplicationDelegate

**Available on:** iOS, iPadOS, Mac Catalyst, tvOS, visionOS

> A set of methods to manage shared behaviors for your app.

```swift
@MainActor protocol UIApplicationDelegate : NSObjectProtocol
```

## Overview

Your app delegate object manages your app’s shared behaviors. The app delegate is effectively the root object of your app, and it works in conjunction with [UIApplication](/documentation/uikit/uiapplication) to manage some interactions with the system. Like the [UIApplication](/documentation/uikit/uiapplication) object, UIKit creates your app delegate object early in your app’s launch cycle so it’s always present.

Use your app delegate object to handle the following tasks:

- Initializing your app’s central data structures
- Configuring your app’s scenes
- Responding to notifications originating from outside the app, such as low-memory warnings, download completion notifications, and more
- Responding to events that target the app itself, and aren’t specific to your app’s scenes, views, or view controllers
- Registering for any required services at launch time, such as Apple Push Notification service

For more information about how you use the app delegate object to initialize your app at launch time, see [Responding to the launch of your app](/documentation/uikit/responding-to-the-launch-of-your-app).

### Life-cycle management in iOS 12 and earlier

In iOS 12 and earlier, you use your app delegate to manage major life cycle events in your app. Specifically, you use methods of the app delegate to update the state of your app when it enters the foreground or moves to the background.

- For information on what to do when your app enters the foreground, see [Preparing your UI to run in the foreground](/documentation/uikit/preparing-your-ui-to-run-in-the-foreground).
- For information on what to do when your app enters the background, see [Preparing your UI to run in the background](/documentation/uikit/preparing-your-ui-to-run-in-the-background).
- For general information about the life cycle of your app, see [Managing your app’s life cycle](/documentation/uikit/managing-your-app-s-life-cycle).

## Inherits From

- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)

## Initializing the app

- [application(_:willFinishLaunchingWithOptions:)](/documentation/uikit/uiapplicationdelegate/application(_:willfinishlaunchingwithoptions:)) Tells the delegate that the launch process has begun.
- [application(_:didFinishLaunchingWithOptions:)](/documentation/uikit/uiapplicationdelegate/application(_:didfinishlaunchingwithoptions:)) Tells the delegate that the launch process is almost done and the app is almost ready to run.
- [UIApplication.LaunchOptionsKey](/documentation/uikit/uiapplication/launchoptionskey) The keys you use to access values in the launch options dictionary that the system passes to your app at initialization.
- [didFinishLaunchingNotification](/documentation/uikit/uiapplication/didfinishlaunchingnotification) A notification that posts immediately after the app finishes launching.

## Configuring and discarding scenes

- [application(_:configurationForConnecting:options:)](/documentation/uikit/uiapplicationdelegate/application(_:configurationforconnecting:options:)) Retrieves the configuration data for UIKit to use when creating a new scene.
- [application(_:didDiscardSceneSessions:)](/documentation/uikit/uiapplicationdelegate/application(_:diddiscardscenesessions:)) Tells the delegate that the user closed one or more of the app’s scenes from the app switcher.

## Responding to app life-cycle events

- [applicationDidBecomeActive(_:)](/documentation/uikit/uiapplicationdelegate/applicationdidbecomeactive(_:)) Tells the delegate that the app has become active.
- [applicationWillResignActive(_:)](/documentation/uikit/uiapplicationdelegate/applicationwillresignactive(_:)) Tells the delegate that the app is about to become inactive.
- [applicationDidEnterBackground(_:)](/documentation/uikit/uiapplicationdelegate/applicationdidenterbackground(_:)) Tells the delegate that the app is now in the background.
- [applicationWillEnterForeground(_:)](/documentation/uikit/uiapplicationdelegate/applicationwillenterforeground(_:)) Tells the delegate that the app is about to enter the foreground.
- [applicationWillTerminate(_:)](/documentation/uikit/uiapplicationdelegate/applicationwillterminate(_:)) Tells the delegate when the app is about to terminate.
- [didBecomeActiveNotification](/documentation/uikit/uiapplication/didbecomeactivenotification) A notification that posts when the app becomes active.
- [didEnterBackgroundNotification](/documentation/uikit/uiapplication/didenterbackgroundnotification) A notification that posts when the app enters the background.
- [willEnterForegroundNotification](/documentation/uikit/uiapplication/willenterforegroundnotification) A notification that posts shortly before an app leaves the background state on its way to becoming the active app.
- [willResignActiveNotification](/documentation/uikit/uiapplication/willresignactivenotification) A notification that posts when the app is no longer active and loses focus.
- [willTerminateNotification](/documentation/uikit/uiapplication/willterminatenotification) A notification that posts when the app is about to terminate.

## Responding to environment changes

- [applicationProtectedDataDidBecomeAvailable(_:)](/documentation/uikit/uiapplicationdelegate/applicationprotecteddatadidbecomeavailable(_:)) Tells the delegate that protected files are available now.
- [applicationProtectedDataWillBecomeUnavailable(_:)](/documentation/uikit/uiapplicationdelegate/applicationprotecteddatawillbecomeunavailable(_:)) Tells the delegate that the protected files are about to become unavailable.
- [applicationDidReceiveMemoryWarning(_:)](/documentation/uikit/uiapplicationdelegate/applicationdidreceivememorywarning(_:)) Tells the delegate when the app receives a memory warning from the system.
- [applicationSignificantTimeChange(_:)](/documentation/uikit/uiapplicationdelegate/applicationsignificanttimechange(_:)) Tells the delegate when there is a significant change in the time.
- [protectedDataDidBecomeAvailableNotification](/documentation/uikit/uiapplication/protecteddatadidbecomeavailablenotification) A notification that posts when the protected files become available for your code to access.
- [protectedDataWillBecomeUnavailableNotification](/documentation/uikit/uiapplication/protecteddatawillbecomeunavailablenotification) A notification that posts shortly before protected files are locked down and become inaccessible.
- [didReceiveMemoryWarningNotification](/documentation/uikit/uiapplication/didreceivememorywarningnotification) A notification that posts when the app receives a warning from the operating system about low memory availability.
- [significantTimeChangeNotification](/documentation/uikit/uiapplication/significanttimechangenotification) A notification that posts when there’s a significant change in time.

## Managing app state restoration

- [application(_:shouldSaveSecureApplicationState:)](/documentation/uikit/uiapplicationdelegate/application(_:shouldsavesecureapplicationstate:)) Asks the delegate whether to securely preserve the app’s state.
- [application(_:shouldRestoreSecureApplicationState:)](/documentation/uikit/uiapplicationdelegate/application(_:shouldrestoresecureapplicationstate:)) Asks the delegate whether to restore the app’s saved state.
- [application(_:viewControllerWithRestorationIdentifierPath:coder:)](/documentation/uikit/uiapplicationdelegate/application(_:viewcontrollerwithrestorationidentifierpath:coder:)) Asks the delegate to provide the specified view controller.
- [application(_:willEncodeRestorableStateWith:)](/documentation/uikit/uiapplicationdelegate/application(_:willencoderestorablestatewith:)) Tells your delegate to save any high-level state information at the beginning of the state preservation process.
- [application(_:didDecodeRestorableStateWith:)](/documentation/uikit/uiapplicationdelegate/application(_:diddecoderestorablestatewith:)) Tells your delegate to restore any high-level state information as part of the state restoration process.
- [stateRestorationBundleVersionKey](/documentation/uikit/uiapplication/staterestorationbundleversionkey) The version of your app responsible for creating the restoration archive.
- [stateRestorationSystemVersionKey](/documentation/uikit/uiapplication/staterestorationsystemversionkey) The version of the system on which your app created the restoration archive.
- [stateRestorationTimestampKey](/documentation/uikit/uiapplication/staterestorationtimestampkey) The time your app created the restoration archive.
- [stateRestorationUserInterfaceIdiomKey](/documentation/uikit/uiapplication/staterestorationuserinterfaceidiomkey) The user interface idiom that was in effect when your app created the restoration archive.
- [stateRestorationViewControllerStoryboardKey](/documentation/uikit/uiapplication/staterestorationviewcontrollerstoryboardkey) A reference to the storyboard that contains the view controller.

## Downloading data in the background

- [application(_:handleEventsForBackgroundURLSession:completionHandler:)](/documentation/uikit/uiapplicationdelegate/application(_:handleeventsforbackgroundurlsession:completionhandler:)) Tells the delegate that events related to a URL session are waiting to be processed.
- [UIBackgroundFetchResult](/documentation/uikit/uibackgroundfetchresult) Constants that indicate the result of a background fetch operation.

## Handling remote notification registration

- [application(_:didRegisterForRemoteNotificationsWithDeviceToken:)](/documentation/uikit/uiapplicationdelegate/application(_:didregisterforremotenotificationswithdevicetoken:)) Tells the delegate that the app successfully registered with Apple Push Notification service (APNs).
- [application(_:didFailToRegisterForRemoteNotificationsWithError:)](/documentation/uikit/uiapplicationdelegate/application(_:didfailtoregisterforremotenotificationswitherror:)) Tells the delegate when Apple Push Notification service cannot successfully complete the registration process.
- [application(_:didReceiveRemoteNotification:fetchCompletionHandler:)](/documentation/uikit/uiapplicationdelegate/application(_:didreceiveremotenotification:fetchcompletionhandler:)) Tells the app that a remote notification arrived that indicates there is data to be fetched.

## Continuing user activity and handling quick actions

- [application(_:willContinueUserActivityWithType:)](/documentation/uikit/uiapplicationdelegate/application(_:willcontinueuseractivitywithtype:)) Tells the delegate if your app takes responsibility for notifying users when a continuation activity takes longer than expected.
- [application(_:continue:restorationHandler:)](/documentation/uikit/uiapplicationdelegate/application(_:continue:restorationhandler:)) Tells the delegate that the data for continuing an activity is available.
- [application(_:didUpdate:)](/documentation/uikit/uiapplicationdelegate/application(_:didupdate:)) Tells the delegate that the activity was updated.
- [application(_:didFailToContinueUserActivityWithType:error:)](/documentation/uikit/uiapplicationdelegate/application(_:didfailtocontinueuseractivitywithtype:error:)) Tells the delegate that the activity couldn’t be continued.
- [application(_:performActionFor:completionHandler:)](/documentation/uikit/uiapplicationdelegate/application(_:performactionfor:completionhandler:)) Tells the delegate that the user selected a Home screen quick action for your app, except when you’ve intercepted the interaction in a launch method.

## Interacting with WatchKit

- [application(_:handleWatchKitExtensionRequest:reply:)](/documentation/uikit/uiapplicationdelegate/application(_:handlewatchkitextensionrequest:reply:)) Asks the delegate to respond to a request from a paired watchOS app.

## Interacting with HealthKit

- [applicationShouldRequestHealthAuthorization(_:)](/documentation/uikit/uiapplicationdelegate/applicationshouldrequesthealthauthorization(_:)) Tells the delegate when your app should ask the user for access to his or her HealthKit data.

## Opening a URL-specified resource

- [application(_:open:options:)](/documentation/uikit/uiapplicationdelegate/application(_:open:options:)) Asks the delegate to open a resource specified by a URL, and provides a dictionary of launch options.
- [UIApplication.OpenURLOptionsKey](/documentation/uikit/uiapplication/openurloptionskey) Keys you use to access values in the options dictionary when opening a URL.

## Disallowing specified app extension types

- [application(_:shouldAllowExtensionPointIdentifier:)](/documentation/uikit/uiapplicationdelegate/application(_:shouldallowextensionpointidentifier:)) Asks the delegate to grant permission to use app extensions that are based on a specified extension point identifier.
- [UIApplication.ExtensionPointIdentifier](/documentation/uikit/uiapplication/extensionpointidentifier) A structure that identifies types of extensions.
- [keyboard](/documentation/uikit/uiapplication/extensionpointidentifier/keyboard) The identifier for custom keyboards.

## Handling SiriKit intents

- [application(_:handlerFor:)](/documentation/uikit/uiapplicationdelegate/application(_:handlerfor:)) Asks the delegate for an intent handler capable of handling the specified intent.

## Handling CloudKit invitations

- [application(_:userDidAcceptCloudKitShareWith:)](/documentation/uikit/uiapplicationdelegate/application(_:userdidacceptcloudkitsharewith:)) Tells the delegate that the app now has access to shared information in CloudKit.

## Localizing keyboard shortcuts

- [applicationShouldAutomaticallyLocalizeKeyCommands(_:)](/documentation/uikit/uiapplicationdelegate/applicationshouldautomaticallylocalizekeycommands(_:)) Returns a Boolean value that tells the system whether to remap menu shortcuts to support localized keyboards.

## Managing interface geometry

- [application(_:supportedInterfaceOrientationsFor:)](/documentation/uikit/uiapplicationdelegate/application(_:supportedinterfaceorientationsfor:)) Asks the delegate for the interface orientations to use for the view controllers in the specified window.
- [UIInterfaceOrientation](/documentation/uikit/uiinterfaceorientation) Constants that specify the orientation of the app’s user interface.
- [UIInterfaceOrientationMask](/documentation/uikit/uiinterfaceorientationmask) Constants that specify a view controller’s supported interface orientations.
- [invalidInterfaceOrientationException](/documentation/uikit/uiapplication/invalidinterfaceorientationexception) An exception that’s thrown if a view controller or the app returns an invalid set of supported interface orientations.

## Providing a window for storyboarding

- [window](/documentation/uikit/uiapplicationdelegate/window) The window to use when presenting a storyboard.

## Providing the main entry point

- [main()](/documentation/uikit/uiapplicationdelegate/main()) Provides the top-level entry point for the app.

## Deprecated

- [applicationDidFinishLaunching(_:)](/documentation/uikit/uiapplicationdelegate/applicationdidfinishlaunching(_:)) Tells the delegate when the app has finished launching.
- [Deprecated symbols](/documentation/uikit/uiapplicationdelegate-deprecated-symbols) Symbols that are no longer supported.

## Life cycle

- [Managing your app’s life cycle](/documentation/uikit/managing-your-app-s-life-cycle) Respond to system notifications when your app is in the foreground or background, and handle other significant system-related events.
- [Responding to the launch of your app](/documentation/uikit/responding-to-the-launch-of-your-app) Initialize your app’s data structures, prepare your app to run, and respond to any launch-time requests from the system.
- [UIApplication](/documentation/uikit/uiapplication) The centralized point of control and coordination for apps running in iOS.
- [Scenes](/documentation/uikit/scenes) Manage multiple instances of your app’s UI simultaneously, and direct resources to the appropriate instance of your UI.
- [Transitioning to the UIKit scene-based life cycle](/documentation/uikit/transitioning-to-the-uikit-scene-based-life-cycle) Adopt the scene-based life cycle to replace the app delegate life cycle in UIKit.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
