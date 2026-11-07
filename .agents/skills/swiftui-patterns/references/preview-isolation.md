# Isolated Preview Construction

Use previews as deterministic compositions of a view's required inputs. A preview should render without launching the full app or reaching production services.

## Cover Meaningful States

Provide separate previews for the states that materially change the interface:

- loaded content with representative data
- meaningful loading or refreshing UI
- empty content and its primary recovery action
- recoverable and terminal error presentations when they differ

Skip state permutations that do not change layout, behavior, or accessibility.

## Install Required Dependencies

Keep production dependencies required. Install every environment value, observable model, action, and persistence container the view expects instead of making a dependency optional to silence a preview failure.

```swift
@MainActor
private struct ProfilePreview: View {
    let state: ProfileStore.State

    var body: some View {
        ProfileScreen()
            .environment(ProfileStore.preview(state: state))
            .environment(\.profileClient, .preview)
    }
}

#Preview("Loaded") {
    ProfilePreview(state: .loaded(.fixture))
}

#Preview("Loading") {
    ProfilePreview(state: .loading)
}

#Preview("Empty") {
    ProfilePreview(state: .empty)
}

#Preview("Error") {
    ProfilePreview(state: .failed(.fixture))
}
```

When a view requires SwiftData, use a seeded in-memory `ModelContainer`. Apply the same rule to caches and file stores: create isolated temporary or in-memory fixtures.

## Keep Fixtures Deterministic

- Use fixed identifiers, dates, locale-sensitive values, and image dimensions.
- Make preview clients return fixture results immediately or after a controlled delay.
- Keep fixtures small but representative enough to exercise wrapping, truncation, and empty/error affordances.
- Put reusable preview factories next to the model or in preview-only support code; do not hide them behind production singletons.

Never depend on live networking, authentication state, production databases, keychain contents, or global singleton state. These inputs make previews slow, flaky, order-dependent, or destructive.

## Review Checklist

- [ ] Loaded plus meaningful loading, empty, and error states are represented
- [ ] Fixtures are fixed and repeatable
- [ ] Every required environment dependency is installed
- [ ] Persistence is in-memory or temporary and seeded locally
- [ ] No live service, authentication, production data, keychain, or global singleton is required
- [ ] Required production dependencies remain nonoptional

> **Apple session:** [Visually edit SwiftUI views](https://sosumi.ai/videos/play/wwdc2020/10185)
