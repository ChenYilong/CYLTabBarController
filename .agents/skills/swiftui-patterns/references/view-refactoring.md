# Behavior-Preserving View Refactoring

Load this reference when restructuring an existing SwiftUI view without an explicit
request to change its interface or behavior.

## Contents

- [Pin the Contract](#pin-the-contract)
- [Keep Body Declarative](#keep-body-declarative)
- [Preserve the Business Boundary](#preserve-the-business-boundary)
- [Verify the Refactor](#verify-the-refactor)

## Pin the Contract

A structure-only refactor preserves:

- layout, presentation, and navigation behavior;
- accessibility labels, values, actions, focus order, and identifiers;
- state ownership, bindings, and stable view identity;
- side-effect timing and cancellation behavior;
- domain behavior, error handling, and persistence semantics.

Record intentional changes separately. Do not let cleanup silently become a visual
redesign, navigation rewrite, or business-rule change.

Use the extraction signals in the main skill. Dedicated `View` types are the default
for sections with substantial layout or branching, their own state or lifecycle,
narrower dependencies, independent preview value, or enough complexity to obscure
the parent's data flow. Keep only genuinely small stateless fragments as computed
`some View` properties. Extensions and `// MARK:` headings organize a file; they do
not create view boundaries. Do not replace one oversized `body` with a screen-sized
extension made of computed `some View` fragments.

## Keep Body Declarative

Move non-trivial button actions and lifecycle closures to small named methods so
`body` reads as UI:

```swift
Button("Save", action: save)
    .disabled(isSaving)

.task(id: searchText) {
    await reload(for: searchText)
}

private func save() {
    Task { await editorService.validateAndSave(draft) }
}

private func reload(for query: String) async {
    results = await searchClient.results(for: query)
}
```

The view methods remain thin orchestration points. They may update view-owned loading,
selection, error, or presentation state around a service/model call.

## Preserve the Business Boundary

Validation, persistence, networking, retry/caching rules, and reusable loading policy
belong in services or models. Do not merely move a large inline closure into an equally
large private view method and call the refactor complete.

Keep reusable domain errors and their recovery policy with the service or model that
defines the operation. The view may translate those errors into presentation state,
but it should not become the owner of domain failure semantics.

Pass extracted subviews only the values, bindings, and actions they need. Preserve the
existing environment-versus-initializer ownership decision unless changing that
boundary is part of the request. If a child needs a cohesive feature-scoped observable
model, pass that model explicitly instead of replacing its interface with many
unrelated closures.

## Verify the Refactor

After each meaningful extraction:

1. Build the affected target and fix compiler errors before continuing.
2. Run existing unit, snapshot, and UI tests that cover the screen.
3. Render independently useful previews with deterministic fixtures and every required
   dependency installed.
4. Exercise the original interaction flow, including loading, error, cancellation,
   save/dismiss timing, navigation, focus, and accessibility behavior.
5. Review the diff for accidental constants, modifier-order, identity, or task-lifetime
   changes.

Preserve existing preview-rendering and snapshot-test CI gates. Compilation alone does
not prove that extracted views still compose or render correctly.

A cleaner file that changes behavior, weakens a required dependency, or no longer
builds is not a successful refactor.
