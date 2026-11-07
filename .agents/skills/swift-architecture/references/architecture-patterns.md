# Architecture Pattern Recipes

Load this reference after the main skill selects a pattern. Keep feature behavior and dependency contracts stable while adopting these structures.

## Contents

- [MVVM](#mvvm)
- [MVI](#mvi)
- [TCA](#tca)
- [Clean Architecture](#clean-architecture)
- [Coordinator](#coordinator)
- [VIPER](#viper)

## MVVM

Use a view model only when it owns presentation behavior rather than forwarding a model:

```swift
@MainActor @Observable
final class CheckoutViewModel {
    private let pricing: PricingService
    var items: [LineItem] = []
    var promoCode = ""

    var total: Decimal { pricing.total(for: items, promoCode: promoCode) }

    init(pricing: PricingService) { self.pricing = pricing }
}
```

Inject the service, test transformations and error states directly, and keep view-only focus/layout state in the view.

## MVI

Define explicit state, user intents, and one transition/effect boundary:

```swift
struct SearchState: Equatable {
    var query = ""
    var results: [Result] = []
    var isLoading = false
}

enum SearchIntent { case queryChanged(String), submitted, response([Result]) }

@MainActor @Observable
final class SearchStore {
    private(set) var state = SearchState()
    func send(_ intent: SearchIntent) { /* reduce and launch bounded effects */ }
}
```

Test every state/intent pair, effect cancellation, and stale-response handling.

## TCA

Model each feature with state, actions, a reducer body, and injected dependencies. Compose child reducers at feature boundaries and test with `TestStore`. Keep navigation state in the feature only when the route belongs to that feature. Check the current Composable Architecture documentation before copying macro or testing syntax because package APIs evolve independently of Apple SDKs.

## Clean Architecture

Dependency direction points inward:

```text
UI / presenters -> use cases -> domain entities
data adapters   -> repository protocols <- use cases
```

Keep domain types independent of SwiftUI, persistence, and networking. Introduce mapping only where it protects a real boundary; avoid one protocol per concrete type without a substitution need.

## Coordinator

Use a coordinator as the route and child-flow owner in UIKit or hybrid apps:

```swift
@MainActor
protocol Coordinator: AnyObject {
    var children: [Coordinator] { get set }
    func start()
}
```

Retain child coordinators for the flow lifetime, remove them on completion, and keep business state in the feature model rather than the coordinator.

## VIPER

Preserve existing responsibilities during maintenance:

- View renders and forwards user events.
- Interactor owns use-case logic.
- Presenter maps results to view state.
- Entity contains domain data.
- Router owns UIKit navigation and module assembly.

When migrating away, replace one module boundary at a time and keep adapters until upstream callers use the new feature interface.
