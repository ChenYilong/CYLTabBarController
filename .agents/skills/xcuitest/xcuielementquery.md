---
title: XCUIElementQuery
description: An object that defines the search criteria a test uses to identify UI elements.
source: https://developer.apple.com/documentation/xcuiautomation/xcuielementquery
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/xcuiautomation/xcuielementquery.json
timestamp: 2026-04-14T13:14:58.197Z
---

**Navigation:** [XCUIAutomation](/documentation/xcuiautomation)

**Class**

# XCUIElementQuery

**Available on:** iOS, iPadOS, Mac Catalyst, macOS, tvOS, visionOS, watchOS, Xcode 16.3+

> An object that defines the search criteria a test uses to identify UI elements.

```swift
@MainActor class XCUIElementQuery
```

## Discussion

Use element queries to find UI elements in your app that you interact with in the tests, to test for the presence of expected elements, or to discover elements to test their values.

For example, this test uses an element query to find the “Add Book” button, and after clicking the button, checks that there’s one button in an outline view cell titled “Untitled Book”. If the test can’t find the “Add Book” button, or there isn’t one “Untitled Book” cell, then the test fails.

```swift
@MainActor
func testClickingAddCreatesAnUntitledBook() throws {
    let app = XCUIApplication()
    app.launch()
    let list = app.windows["Reading Journal"]
    list.toolbars.children(matching: .button)["Add Book"].click()
    XCTAssertEqual(list.outlines["Sidebar"].cells.containing(.button, identifier:"Untitled Book").count, 1)
}
```

## Inherits From

- [NSObject](/documentation/ObjectiveC/NSObject-swift.class)

## Conforms To

- [CVarArg](/documentation/Swift/CVarArg)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Hashable](/documentation/Swift/Hashable)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [Sendable](/documentation/Swift/Sendable)
- [XCUIElementTypeQueryProvider](/documentation/xcuiautomation/xcuielementtypequeryprovider)

## Creating new queries

- [children(matching:)](/documentation/xcuiautomation/xcuielementquery/children(matching:)) Returns a new query that matches all direct children of the requested type.
- [descendants(matching:)](/documentation/xcuiautomation/xcuielementquery/descendants(matching:)) Returns a new query that matches all descendants of the requested type.
- [containing(_:)](/documentation/xcuiautomation/xcuielementquery/containing(_:)) Returns a new query that matches elements containing a descendant that meets the logical conditions of the provided predicate.
- [containing(_:identifier:)](/documentation/xcuiautomation/xcuielementquery/containing(_:identifier:)) Returns a new query that matches elements that contain a descendant of the requested type and an identifying property that matches a provided identifier.
- [matching(identifier:)](/documentation/xcuiautomation/xcuielementquery/matching(identifier:)) Returns a new query that matches elements that have an identifying property that matches a provided identifier.
- [matching(_:)](/documentation/xcuiautomation/xcuielementquery/matching(_:)) Returns a new query that matches elements that meet the logical conditions of the provided predicate.
- [matching(_:identifier:)](/documentation/xcuiautomation/xcuielementquery/matching(_:identifier:)) Returns a new query that matches elements of the requested type and have an identifying property that matches a provided identifier.

## Accessing matched elements

- [allElementsBoundByAccessibilityElement](/documentation/xcuiautomation/xcuielementquery/allelementsboundbyaccessibilityelement) Immediately evaluates the query and returns an array of elements bound to the resulting accessibility elements.
- [allElementsBoundByIndex](/documentation/xcuiautomation/xcuielementquery/allelementsboundbyindex) Immediately evaluates the query and returns an array of elements bound by the index of each result.
- [count](/documentation/xcuiautomation/xcuielementquery/count) Evaluates the query and returns the number of elements that match.
- [element](/documentation/xcuiautomation/xcuielementquery/element) The query’s single matching element.
- [element(boundBy:)](/documentation/xcuiautomation/xcuielementquery/element(boundby:)) Uses an index into the query’s results to determine which underlying accessibility element to use.
- [element(matching:)](/documentation/xcuiautomation/xcuielementquery/element(matching:)) Matches the predicate.
- [element(matching:identifier:)](/documentation/xcuiautomation/xcuielementquery/element(matching:identifier:)) Matches the provided element type and identifier.
- [subscript(_:)](/documentation/xcuiautomation/xcuielementquery/subscript(_:)) Returns a descendant element that matches a provided identifier.
- [element(at:)](/documentation/xcuiautomation/xcuielementquery/element(at:)) Returns an element that resolves to the index into the query’s result set.

## Debugging element queries

- [debugDescription](/documentation/xcuiautomation/xcuielementquery/debugdescription) Provides debugging information about the query.

## Identifying window buttons

- [XCUIIdentifierCloseWindow](/documentation/xcuiautomation/xcuiidentifierclosewindow) The identifier for a window’s close button.
- [XCUIIdentifierFullScreenWindow](/documentation/xcuiautomation/xcuiidentifierfullscreenwindow) The identifier for a window’s full-screen button.
- [XCUIIdentifierMinimizeWindow](/documentation/xcuiautomation/xcuiidentifierminimizewindow) The identifier for a window’s minimize button.
- [XCUIIdentifierZoomWindow](/documentation/xcuiautomation/xcuiidentifierzoomwindow) The identifier for a window’s zoom button.

## UI element queries

- [XCUIElementTypeQueryProvider](/documentation/xcuiautomation/xcuielementtypequeryprovider) A type that provides ready-made queries for locating descendant UI elements.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
