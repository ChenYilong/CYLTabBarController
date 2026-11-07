# Deep links and navigation

## Contents

- [Intent](#intent)
- [Core patterns](#core-patterns)
- [Example: router entry points](#example-router-entry-points)
- [Example: attach to a root view](#example-attach-to-a-root-view)
- [Design choices to keep](#design-choices-to-keep)
- [Pitfalls](#pitfalls)
- [Universal Links](#universal-links)
- [Custom URL Schemes](#custom-url-schemes)
- [NSUserActivity Continuation (Handoff)](#nsuseractivity-continuation-handoff)

## Intent

Route external URLs into in-app destinations while falling back to system handling when needed.

## Core patterns

- Centralize URL handling in the router (`handle(url:)`, `handleDeepLink(url:)`).
- Inject an `OpenURLAction` handler that delegates to the router.
- Use `.onOpenURL` for Universal Links and custom URL schemes.
- Use `.onContinueUserActivity` for Handoff and other declared user activity types.
- Let the router decide whether to navigate or open externally.

## Example: router entry points

```swift
@MainActor
final class RouterPath {
  var path: [Route] = []
  var urlHandler: ((URL) -> OpenURLAction.Result)?

  func handle(url: URL) -> OpenURLAction.Result {
    guard let route = parseInternal(url), isAuthorized(route), destinationExists(route) else {
      return urlHandler?(url) ?? .systemAction
    }
    path.append(route) // Commit only after every validation passes.
    return .handled
  }

  func handleDeepLink(url: URL) -> OpenURLAction.Result {
    guard let route = parseInternal(url), isAuthorized(route), destinationExists(route) else {
      return .discarded
    }
    path.append(route)
    return .handled
  }
}
```

## Example: attach to a root view

```swift
extension View {
  func withLinkRouter(_ router: RouterPath) -> some View {
    self
      .environment(
        \.openURL,
        OpenURLAction { url in
          router.handle(url: url)
        }
      )
      .onOpenURL { url in
        router.handleDeepLink(url: url)
      }
  }
}
```

## Design choices to keep

- Keep URL parsing and decision logic inside the router.
- Avoid handling deep links in multiple places; one entry point is enough.
- Always provide a fallback to `@Environment(\.openURL)` via `OpenURLAction`.

## Pitfalls

- Parse and validate before mutating any tab or navigation path. Invalid links
  must leave current navigation unchanged.
- Avoid blocking UI while resolving remote links; use `Task`.

## Universal Links

Universal links let iOS open your app when a user taps a standard HTTPS URL, with no custom scheme required. They require server-side configuration and an Associated Domains entitlement.

### Apple App Site Association (AASA)

Host a JSON file at `https://example.com/.well-known/apple-app-site-association` (no file extension, served with `Content-Type: application/json`):

```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["TEAMID.com.example.app"],
        "components": [
          { "/": "/items/*", "comment": "Match item detail paths" },
          { "/": "/profile/*" }
        ]
      }
    ]
  }
}
```

Key rules:
- AASA must be served over HTTPS with a valid certificate; do not redirect the AASA request.
- On iOS 14+, Apple's CDN retrieves and caches AASA files. Devices download the file on install and normally check again about once per week; there is no direct CDN invalidation. Reinstall the app or use developer mode while testing changes.
- Use `components` (modern) over the legacy `paths` array.

### Associated Domains entitlement

In your app's `.entitlements` file (or Signing & Capabilities in Xcode), add:

```text
com.apple.developer.associated-domains = [
    "applinks:example.com",
    "applinks:www.example.com"
]
```

For development/testing, prefix with `applinks:example.com?mode=developer` to bypass CDN-backed retrieval.

### Handling Universal Links in SwiftUI

SwiftUI receives Universal Links directly as URLs. Handle them with `.onOpenURL`:

```swift
@main
struct MyApp: App {
    @State private var router = Router()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
                .onOpenURL { url in
                    router.handle(url: url)
                }
        }
    }
}
```

> **Docs:** [Supporting universal links](https://sosumi.ai/documentation/xcode/supporting-universal-links-in-your-app)

## Custom URL Schemes

Custom URL schemes (e.g., `myapp://`) let other apps or websites open your app. They do not require server configuration but offer no fallback if the app is not installed.

### Registering in Info.plist

Add `CFBundleURLTypes` to your target's Info.plist:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>myapp</string>
    </array>
    <key>CFBundleURLName</key>
    <string>com.example.myapp</string>
  </dict>
</array>
```

### Handling with .onOpenURL

```swift
.onOpenURL { url in
    // url.scheme == "myapp"
    // url.host == "items", url.pathComponents for routing
    guard url.scheme == "myapp" else { return }
    router.handle(url: url)
}
```

Prefer universal links over custom schemes for publicly shared links — they provide a better UX (web fallback) and are more secure (domain-verified).

## NSUserActivity Continuation (Handoff)

Handoff lets users start an activity on one device and continue it on another. SwiftUI provides `.onContinueUserActivity` and `.userActivity` modifiers.

### Advertising an activity

```swift
struct ItemDetailView: View {
    let item: Item

    var body: some View {
        ScrollView { /* content */ }
            .userActivity("com.example.viewItem") { activity in
                activity.title = item.title
                activity.isEligibleForHandoff = true
                activity.isEligibleForSearch = true
                activity.targetContentIdentifier = item.id.uuidString
                activity.webpageURL = URL(string: "https://example.com/items/\(item.id)")
            }
    }
}
```

### Receiving a continued activity

```swift
.onContinueUserActivity("com.example.viewItem") { activity in
    guard let id = activity.targetContentIdentifier else { return }
    router.navigate(to: .item(id: id))
}
```

Key rules:
- Activity types must be declared in `Info.plist` under `NSUserActivityTypes`.
- Set `isEligibleForHandoff = true` and optionally `isEligibleForSearch` / `isEligibleForPrediction`.
- Provide a `webpageURL` as fallback when the app is not installed on the receiving device.
- Do not use the browsing-web user activity hook as the primary SwiftUI Universal Link handler; use `.onOpenURL` for Universal Links.
