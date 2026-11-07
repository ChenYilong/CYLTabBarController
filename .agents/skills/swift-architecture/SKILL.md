---
name: swift-architecture
description: "Selects, reviews, and migrates Apple-platform app architectures across MV with Observation, MVVM, MVI, TCA, Clean Architecture, Coordinator, and legacy VIPER. Use when choosing module and dependency boundaries, escalating a feature beyond simple SwiftUI MV, planning incremental architecture migration, or auditing state ownership and test seams."
---

# Swift Architecture

Choose the smallest architecture that makes state ownership, dependencies, side effects, and tests explicit. Default new SwiftUI features to MV; escalate only for observed complexity.

## Contents

- [Scope Boundary](#scope-boundary)
- [Decision Workflow](#decision-workflow)
- [Pattern Selection](#pattern-selection)
- [MV Default](#mv-default)
- [Escalation Signals](#escalation-signals)
- [Migration](#migration)
- [Common Mistakes](#common-mistakes)
- [Review Checklist](#review-checklist)
- [References](#references)

## Scope Boundary

This skill owns pattern selection, module boundaries, dependency direction, migration strategy, and architecture-level test seams. Route SwiftUI property-wrapper wiring and view composition to `swiftui-patterns`, navigation APIs and route models to `swiftui-navigation`, isolation diagnostics to `swift-concurrency`, and test syntax/fixtures to `swift-testing`.

## Decision Workflow

1. Record the feature's state owner, inputs, outputs, dependencies, side effects, navigation handoffs, and current tests.
2. Identify the concrete pressure: complex state machine, shared derived state, dependency control, feature composition, team ownership, or UIKit navigation.
3. Select the smallest pattern that addresses that pressure; write down what it adds and what remains unchanged.
4. Implement one vertical slice with injected dependencies and observable state transitions.
5. Run existing behavior tests plus state-transition and dependency-failure tests. If behavior changes, restore the fixture, fix the smallest boundary, and rerun before migrating another slice.

## Pattern Selection

| Pattern | Choose when | Main cost |
|---|---|---|
| MV | SwiftUI feature has straightforward state and orchestration | Logic can drift into large views without decomposition |
| MVVM | Presentation logic needs an independently testable adapter | Extra layer can become a forwarding shell |
| MVI | A feature is best modeled as explicit state + intents + reducer/effects | Boilerplate and centralized transition design |
| TCA | Many composable features need deterministic effects, dependencies, and testing | Framework learning and architectural commitment |
| Clean Architecture | Large product needs strict dependency direction across domain/data/UI | Protocol and mapping overhead |
| Coordinator | UIKit or hybrid navigation needs a separate flow owner | Another lifecycle and routing owner |
| VIPER | Maintaining an existing UIKit module with established VIPER boundaries | Very high ceremony; poor default for new SwiftUI work |

Use Coordinator alongside another state pattern when navigation complexity is the pressure; it is not a replacement for domain/state architecture.

## MV Default

Keep views as state expressions and put business operations in observable models and injected services:

```swift
@MainActor
@Observable
final class TripStore {
    private let client: TripClient
    var trips: [Trip] = []
    var error: Error?

    init(client: TripClient) { self.client = client }

    func load() async {
        do { trips = try await client.fetchTrips() }
        catch { self.error = error }
    }
}

struct TripList: View {
    @State private var store: TripStore

    init(client: TripClient) {
        _store = State(initialValue: TripStore(client: client))
    }

    var body: some View {
        List(store.trips) { Text($0.name) }
            .task { await store.load() }
    }
}
```

Load [Architecture Pattern Recipes](references/architecture-patterns.md) for MVVM, MVI, TCA, Clean Architecture, Coordinator, and VIPER structure.

## Escalation Signals

- Choose MVVM when substantial presentation transformation must be tested without rendering and the adapter has real behavior.
- Choose MVI when transitions, invalid states, and effects need one auditable reducer-like path.
- Choose TCA when feature composition, dependency overrides, cancellation, and deterministic effect tests recur across modules.
- Choose Clean Architecture when independent domain rules and dependency direction matter across multiple delivery/data layers.
- Add Coordinator for UIKit/hybrid route ownership, deep flow composition, or conditional navigation outside view controllers.
- Keep VIPER for compatible legacy modules or deliberate migrations; do not start a new SwiftUI feature with it by habit.

Do not escalate merely because a view is long. First extract subviews, services, and focused observable models.

## Migration

Migrate one feature boundary at a time:

1. Freeze behavior with tests and a dependency/state inventory.
2. Introduce the target boundary around existing operations.
3. Move one state transition or dependency at a time without rewriting UI and persistence simultaneously.
4. Compare behavior, navigation, cancellation, error, and persistence results after each slice.
5. Remove the old path only after no callers or tests depend on it.

For `ObservableObject` to Observation, preserve the same owner and mutation isolation before replacing wrappers. For MVVM to MV, delete forwarding view-model members only after views bind to the same model/service behavior. For TCA adoption, wrap one feature's state/actions/effects and migrate dependencies incrementally.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Pattern chosen by popularity | Tie it to an observed feature pressure. |
| View model only forwards properties | Remove it and use MV. |
| One object owns navigation, networking, formatting, persistence, and UI state | Split by responsibility and dependency direction. |
| TCA or Clean Architecture applied to trivial screens | Start with MV and preserve an escalation seam. |
| Coordinator used as a state architecture | Keep it focused on route/lifecycle ownership. |
| Multiple patterns mixed inside one feature | Define one local state/effect model and migrate at feature boundaries. |
| Big-bang migration | Move one tested vertical slice and rerun the same proof matrix. |

## Review Checklist

- [ ] Choice is justified by concrete feature/team pressures
- [ ] State owner, mutation path, dependencies, effects, and navigation owner are explicit
- [ ] Dependencies are injected and replaceable in tests
- [ ] Pattern cost is proportional to feature complexity
- [ ] UI mechanics, navigation APIs, isolation, and test syntax route to sibling skills
- [ ] Migration preserves behavior one vertical slice at a time
- [ ] Failure, cancellation, navigation, and persistence behavior are verified after each slice
- [ ] No forwarding-only layers or god objects remain

## References

- Detailed pattern structures: [references/architecture-patterns.md](references/architecture-patterns.md)
- Apple: [Observation](https://sosumi.ai/documentation/observation) · [Migrating from ObservableObject to Observable](https://sosumi.ai/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)
- TCA: [ComposableArchitecture](https://sosumi.ai/external/https://swiftpackageindex.com/pointfreeco/swift-composable-architecture/main/documentation/composablearchitecture)
