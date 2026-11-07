---
title: XCUIAutomation
source: https://developer.apple.com/documentation/xcuiautomation
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/index/xcuiautomation
timestamp: 2026-06-26T06:39:37.191Z
---

**Navigation:** [XCUIAutomation](/documentation/xcuiautomation)

## Essentials

- [Recording UI automation for testing](/documentation/xcuiautomation/recording-ui-automation-for-testing)
## UI element queries

- [XCUIElementQuery](/documentation/xcuiautomation/xcuielementquery)
### Creating new queries

- [func children(matching: XCUIElement.ElementType) -> XCUIElementQuery](/documentation/xcuiautomation/xcuielementquery/children(matching:))
- [func descendants(matching: XCUIElement.ElementType) -> XCUIElementQuery](/documentation/xcuiautomation/xcuielementquery/descendants(matching:))
- [func containing(NSPredicate) -> XCUIElementQuery](/documentation/xcuiautomation/xcuielementquery/containing(_:))
- [func containing(XCUIElement.ElementType, identifier: String?) -> XCUIElementQuery](/documentation/xcuiautomation/xcuielementquery/containing(_:identifier:))
- [func matching(identifier: String) -> XCUIElementQuery](/documentation/xcuiautomation/xcuielementquery/matching(identifier:))
- [func matching(NSPredicate) -> XCUIElementQuery](/documentation/xcuiautomation/xcuielementquery/matching(_:))
- [func matching(XCUIElement.ElementType, identifier: String?) -> XCUIElementQuery](/documentation/xcuiautomation/xcuielementquery/matching(_:identifier:))
### Accessing matched elements

- [var allElementsBoundByAccessibilityElement: [XCUIElement]](/documentation/xcuiautomation/xcuielementquery/allelementsboundbyaccessibilityelement)
- [var allElementsBoundByIndex: [XCUIElement]](/documentation/xcuiautomation/xcuielementquery/allelementsboundbyindex)
- [var count: Int](/documentation/xcuiautomation/xcuielementquery/count)
- [var element: XCUIElement](/documentation/xcuiautomation/xcuielementquery/element)
- [func element(boundBy: Int) -> XCUIElement](/documentation/xcuiautomation/xcuielementquery/element(boundby:))
- [func element(matching: NSPredicate) -> XCUIElement](/documentation/xcuiautomation/xcuielementquery/element(matching:))
- [func element(matching: XCUIElement.ElementType, identifier: String?) -> XCUIElement](/documentation/xcuiautomation/xcuielementquery/element(matching:identifier:))
- [subscript(String) -> XCUIElement](/documentation/xcuiautomation/xcuielementquery/subscript(_:))
- [func element(at: Int) -> XCUIElement](/documentation/xcuiautomation/xcuielementquery/element(at:))
### Debugging element queries

- [var debugDescription: String](/documentation/xcuiautomation/xcuielementquery/debugdescription)
### Identifying window buttons

- [let XCUIIdentifierCloseWindow: String](/documentation/xcuiautomation/xcuiidentifierclosewindow)
- [let XCUIIdentifierFullScreenWindow: String](/documentation/xcuiautomation/xcuiidentifierfullscreenwindow)
- [let XCUIIdentifierMinimizeWindow: String](/documentation/xcuiautomation/xcuiidentifierminimizewindow)
- [let XCUIIdentifierZoomWindow: String](/documentation/xcuiautomation/xcuiidentifierzoomwindow)

- [XCUIElementTypeQueryProvider](/documentation/xcuiautomation/xcuielementtypequeryprovider)
### Finding the first matching element

- [var firstMatch: XCUIElement](/documentation/xcuiautomation/xcuielementtypequeryprovider/firstmatch)
### Querying descendant elements

- [var activityIndicators: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/activityindicators)
- [var alerts: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/alerts)
- [var browsers: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/browsers)
- [var buttons: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/buttons)
- [var cells: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/cells)
- [var checkBoxes: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/checkboxes)
- [var collectionViews: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/collectionviews)
- [var colorWells: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/colorwells)
- [var comboBoxes: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/comboboxes)
- [var datePickers: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/datepickers)
- [var decrementArrows: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/decrementarrows)
- [var dialogs: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/dialogs)
- [var disclosureTriangles: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/disclosuretriangles)
- [var disclosedChildRows: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/disclosedchildrows)
- [var dockItems: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/dockitems)
- [var drawers: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/drawers)
- [var grids: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/grids)
- [var groups: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/groups)
- [var handles: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/handles)
- [var helpTags: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/helptags)
- [var icons: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/icons)
- [var images: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/images)
- [var incrementArrows: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/incrementarrows)
- [var keyboards: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/keyboards)
- [var keys: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/keys)
- [var layoutAreas: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/layoutareas)
- [var layoutItems: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/layoutitems)
- [var levelIndicators: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/levelindicators)
- [var links: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/links)
- [var maps: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/maps)
- [var mattes: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/mattes)
- [var menuBarItems: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/menubaritems)
- [var menuBars: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/menubars)
- [var menuButtons: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/menubuttons)
- [var menuItems: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/menuitems)
- [var menus: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/menus)
- [var navigationBars: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/navigationbars)
- [var otherElements: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/otherelements)
- [var outlineRows: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/outlinerows)
- [var outlines: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/outlines)
- [var pageIndicators: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/pageindicators)
- [var pickerWheels: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/pickerwheels)
- [var pickers: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/pickers)
- [var popUpButtons: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/popupbuttons)
- [var popovers: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/popovers)
- [var progressIndicators: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/progressindicators)
- [var radioButtons: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/radiobuttons)
- [var radioGroups: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/radiogroups)
- [var ratingIndicators: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/ratingindicators)
- [var relevanceIndicators: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/relevanceindicators)
- [var rulerMarkers: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/rulermarkers)
- [var rulers: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/rulers)
- [var scrollBars: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/scrollbars)
- [var scrollViews: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/scrollviews)
- [var searchFields: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/searchfields)
- [var secureTextFields: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/securetextfields)
- [var segmentedControls: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/segmentedcontrols)
- [var sheets: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/sheets)
- [var sliders: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/sliders)
- [var splitGroups: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/splitgroups)
- [var splitters: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/splitters)
- [var staticTexts: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/statictexts)
- [var statusBars: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/statusbars)
- [var statusItems: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/statusitems)
- [var steppers: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/steppers)
- [var switches: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/switches)
- [var tabBars: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/tabbars)
- [var tabGroups: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/tabgroups)
- [var tableColumns: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/tablecolumns)
- [var tableRows: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/tablerows)
- [var tables: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/tables)
- [var tabs: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/tabs)
- [var textFields: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/textfields)
- [var textViews: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/textviews)
- [var timelines: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/timelines)
- [var toggles: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/toggles)
- [var toolbarButtons: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/toolbarbuttons)
- [var toolbars: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/toolbars)
- [var touchBars: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/touchbars)
- [var valueIndicators: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/valueindicators)
- [var webViews: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/webviews)
- [var windows: XCUIElementQuery](/documentation/xcuiautomation/xcuielementtypequeryprovider/windows)

## UI elements

- [XCUIElement](/documentation/xcuiautomation/xcuielement)
### Querying element state

- [func waitForExistence(timeout: TimeInterval) -> Bool](/documentation/xcuiautomation/xcuielement/waitforexistence(timeout:))
- [func waitForNonExistence(timeout: TimeInterval) -> Bool](/documentation/xcuiautomation/xcuielement/waitfornonexistence(timeout:))
- [func wait<V>(for: KeyPath<XCUIElement, V>, toEqual: V, timeout: TimeInterval) -> Bool](/documentation/xcuiautomation/xcuielement/wait(for:toequal:timeout:))
- [var exists: Bool](/documentation/xcuiautomation/xcuielement/exists)
- [var isHittable: Bool](/documentation/xcuiautomation/xcuielement/ishittable)
- [var debugDescription: String](/documentation/xcuiautomation/xcuielement/debugdescription)
### Querying descendant elements

- [func children(matching: XCUIElement.ElementType) -> XCUIElementQuery](/documentation/xcuiautomation/xcuielement/children(matching:))
- [func descendants(matching: XCUIElement.ElementType) -> XCUIElementQuery](/documentation/xcuiautomation/xcuielement/descendants(matching:))
### Typing text

- [func typeText(String)](/documentation/xcuiautomation/xcuielement/typetext(_:))
### Combining keystrokes

- [func typeKey(XCUIKeyboardKey, modifierFlags: XCUIElement.KeyModifierFlags)](/documentation/xcuiautomation/xcuielement/typekey(_:modifierflags:)-6gaoi)
- [func typeKey(String, modifierFlags: XCUIElement.KeyModifierFlags)](/documentation/xcuiautomation/xcuielement/typekey(_:modifierflags:)-9ubn)
- [XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey)
#### Modifier keys

- [static let command: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/command)
- [static let control: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/control)
- [static let option: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/option)
- [static let shift: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/shift)
- [static let rightCommand: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/rightcommand)
- [static let rightControl: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/rightcontrol)
- [static let rightOption: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/rightoption)
- [static let rightShift: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/rightshift)
#### Navigation keys

- [static let upArrow: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/uparrow)
- [static let downArrow: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/downarrow)
- [static let leftArrow: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/leftarrow)
- [static let rightArrow: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/rightarrow)
- [static let home: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/home)
- [static let end: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/end)
- [static let pageUp: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/pageup)
- [static let pageDown: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/pagedown)
- [static let help: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/help)
#### Function keys

- [static let secondaryFn: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/secondaryfn)
- [static let F1: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f1)
- [static let F2: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f2)
- [static let F3: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f3)
- [static let F4: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f4)
- [static let F5: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f5)
- [static let F6: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f6)
- [static let F7: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f7)
- [static let F8: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f8)
- [static let F9: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f9)
- [static let F10: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f10)
- [static let F11: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f11)
- [static let F12: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f12)
- [static let F13: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f13)
- [static let F14: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f14)
- [static let F15: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f15)
- [static let F16: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f16)
- [static let F17: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f17)
- [static let F18: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f18)
- [static let F19: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/f19)
#### Text-editing keys

- [static let capsLock: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/capslock)
- [static let delete: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/delete)
- [static let forwardDelete: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/forwarddelete)
- [static let space: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/space)
- [static let tab: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/tab)
#### Other keys

- [static let clear: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/clear)
- [static let enter: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/enter)
- [static let escape: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/escape)
- [static let `return`: XCUIKeyboardKey](/documentation/xcuiautomation/xcuikeyboardkey/return)
#### Initializers

- [init(String)](/documentation/xcuiautomation/xcuikeyboardkey/init(_:))
- [init(rawValue: String)](/documentation/xcuiautomation/xcuikeyboardkey/init(rawvalue:))

- [class func perform(withKeyModifiers: XCUIElement.KeyModifierFlags, block: () -> Void)](/documentation/xcuiautomation/xcuielement/perform(withkeymodifiers:block:))
- [XCUIElement.KeyModifierFlags](/documentation/xcuiautomation/xcuielement/keymodifierflags)
#### Flags for combination keys

- [static var command: XCUIElement.KeyModifierFlags](/documentation/xcuiautomation/xcuielement/keymodifierflags/command)
- [static var control: XCUIElement.KeyModifierFlags](/documentation/xcuiautomation/xcuielement/keymodifierflags/control)
- [static var option: XCUIElement.KeyModifierFlags](/documentation/xcuiautomation/xcuielement/keymodifierflags/option)
- [static var shift: XCUIElement.KeyModifierFlags](/documentation/xcuiautomation/xcuielement/keymodifierflags/shift)
- [static var capsLock: XCUIElement.KeyModifierFlags](/documentation/xcuiautomation/xcuielement/keymodifierflags/capslock)
- [static var function: XCUIElement.KeyModifierFlags](/documentation/xcuiautomation/xcuielement/keymodifierflags/function)
#### Initializers

- [init(rawValue: UInt)](/documentation/xcuiautomation/xcuielement/keymodifierflags/init(rawvalue:))
#### Legacy flags for combination keys

- [static var alphaShift: XCUIElement.KeyModifierFlags](/documentation/xcuiautomation/xcuielement/keymodifierflags/alphashift)
- [static var alternate: XCUIElement.KeyModifierFlags](/documentation/xcuiautomation/xcuielement/keymodifierflags/alternate)

### Moving the pointer

- [func hover()](/documentation/xcuiautomation/xcuielement/hover())
### Clicking

- [func click()](/documentation/xcuiautomation/xcuielement/click())
- [func click(forDuration: TimeInterval, thenDragTo: XCUIElement)](/documentation/xcuiautomation/xcuielement/click(forduration:thendragto:))
- [func click(forDuration: TimeInterval, thenDragTo: XCUIElement, withVelocity: XCUIGestureVelocity, thenHoldForDuration: TimeInterval)](/documentation/xcuiautomation/xcuielement/click(forduration:thendragto:withvelocity:thenholdforduration:))
- [func doubleClick()](/documentation/xcuiautomation/xcuielement/doubleclick())
- [func rightClick()](/documentation/xcuiautomation/xcuielement/rightclick())
### Scrolling

- [func scroll(byDeltaX: CGFloat, deltaY: CGFloat)](/documentation/xcuiautomation/xcuielement/scroll(bydeltax:deltay:))
### Tapping and pressing

- [func tap()](/documentation/xcuiautomation/xcuielement/tap())
- [func doubleTap()](/documentation/xcuiautomation/xcuielement/doubletap())
- [func press(forDuration: TimeInterval)](/documentation/xcuiautomation/xcuielement/press(forduration:))
- [func press(forDuration: TimeInterval, thenDragTo: XCUIElement)](/documentation/xcuiautomation/xcuielement/press(forduration:thendragto:))
- [func press(forDuration: TimeInterval, thenDragTo: XCUIElement, withVelocity: XCUIGestureVelocity, thenHoldForDuration: TimeInterval)](/documentation/xcuiautomation/xcuielement/press(forduration:thendragto:withvelocity:thenholdforduration:))
### Tapping multiple times

- [func twoFingerTap()](/documentation/xcuiautomation/xcuielement/twofingertap())
- [func tap(withNumberOfTaps: Int, numberOfTouches: Int)](/documentation/xcuiautomation/xcuielement/tap(withnumberoftaps:numberoftouches:))
### Performing gestures

- [func swipeLeft()](/documentation/xcuiautomation/xcuielement/swipeleft())
- [func swipeLeft(velocity: XCUIGestureVelocity)](/documentation/xcuiautomation/xcuielement/swipeleft(velocity:))
- [func swipeRight()](/documentation/xcuiautomation/xcuielement/swiperight())
- [func swipeRight(velocity: XCUIGestureVelocity)](/documentation/xcuiautomation/xcuielement/swiperight(velocity:))
- [func swipeUp()](/documentation/xcuiautomation/xcuielement/swipeup())
- [func swipeUp(velocity: XCUIGestureVelocity)](/documentation/xcuiautomation/xcuielement/swipeup(velocity:))
- [func swipeDown()](/documentation/xcuiautomation/xcuielement/swipedown())
- [func swipeDown(velocity: XCUIGestureVelocity)](/documentation/xcuiautomation/xcuielement/swipedown(velocity:))
- [func pinch(withScale: CGFloat, velocity: CGFloat)](/documentation/xcuiautomation/xcuielement/pinch(withscale:velocity:))
- [func rotate(CGFloat, withVelocity: CGFloat)](/documentation/xcuiautomation/xcuielement/rotate(_:withvelocity:))
- [XCUIGestureVelocity](/documentation/xcuiautomation/xcuigesturevelocity)
#### Creating a gesture velocity

- [init(CGFloat)](/documentation/xcuiautomation/xcuigesturevelocity/init(_:))
- [init(rawValue: CGFloat)](/documentation/xcuiautomation/xcuigesturevelocity/init(rawvalue:))
#### Using typical gesture velocities

- [static let `default`: XCUIGestureVelocity](/documentation/xcuiautomation/xcuigesturevelocity/default)
- [static let fast: XCUIGestureVelocity](/documentation/xcuiautomation/xcuigesturevelocity/fast)
- [static let slow: XCUIGestureVelocity](/documentation/xcuiautomation/xcuigesturevelocity/slow)

### Interacting with sliders

- [var normalizedSliderPosition: CGFloat](/documentation/xcuiautomation/xcuielement/normalizedsliderposition)
- [func adjust(toNormalizedSliderPosition: CGFloat)](/documentation/xcuiautomation/xcuielement/adjust(tonormalizedsliderposition:))
### Interacting with pickers

- [func adjust(toPickerWheelValue: String)](/documentation/xcuiautomation/xcuielement/adjust(topickerwheelvalue:))
### Calculating coordinates

- [func coordinate(withNormalizedOffset: CGVector) -> XCUICoordinate](/documentation/xcuiautomation/xcuielement/coordinate(withnormalizedoffset:))
### Supporting types

- [XCUIElement.ElementType](/documentation/xcuiautomation/xcuielement/elementtype)
#### Enumeration cases

- [case activityIndicator](/documentation/xcuiautomation/xcuielement/elementtype/activityindicator)
- [case alert](/documentation/xcuiautomation/xcuielement/elementtype/alert)
- [case any](/documentation/xcuiautomation/xcuielement/elementtype/any)
- [case application](/documentation/xcuiautomation/xcuielement/elementtype/application)
- [case browser](/documentation/xcuiautomation/xcuielement/elementtype/browser)
- [case button](/documentation/xcuiautomation/xcuielement/elementtype/button)
- [case cell](/documentation/xcuiautomation/xcuielement/elementtype/cell)
- [case checkBox](/documentation/xcuiautomation/xcuielement/elementtype/checkbox)
- [case collectionView](/documentation/xcuiautomation/xcuielement/elementtype/collectionview)
- [case colorWell](/documentation/xcuiautomation/xcuielement/elementtype/colorwell)
- [case comboBox](/documentation/xcuiautomation/xcuielement/elementtype/combobox)
- [case datePicker](/documentation/xcuiautomation/xcuielement/elementtype/datepicker)
- [case decrementArrow](/documentation/xcuiautomation/xcuielement/elementtype/decrementarrow)
- [case dialog](/documentation/xcuiautomation/xcuielement/elementtype/dialog)
- [case disclosureTriangle](/documentation/xcuiautomation/xcuielement/elementtype/disclosuretriangle)
- [case dockItem](/documentation/xcuiautomation/xcuielement/elementtype/dockitem)
- [case drawer](/documentation/xcuiautomation/xcuielement/elementtype/drawer)
- [case grid](/documentation/xcuiautomation/xcuielement/elementtype/grid)
- [case group](/documentation/xcuiautomation/xcuielement/elementtype/group)
- [case handle](/documentation/xcuiautomation/xcuielement/elementtype/handle)
- [case helpTag](/documentation/xcuiautomation/xcuielement/elementtype/helptag)
- [case icon](/documentation/xcuiautomation/xcuielement/elementtype/icon)
- [case image](/documentation/xcuiautomation/xcuielement/elementtype/image)
- [case incrementArrow](/documentation/xcuiautomation/xcuielement/elementtype/incrementarrow)
- [case key](/documentation/xcuiautomation/xcuielement/elementtype/key)
- [case keyboard](/documentation/xcuiautomation/xcuielement/elementtype/keyboard)
- [case layoutArea](/documentation/xcuiautomation/xcuielement/elementtype/layoutarea)
- [case layoutItem](/documentation/xcuiautomation/xcuielement/elementtype/layoutitem)
- [case levelIndicator](/documentation/xcuiautomation/xcuielement/elementtype/levelindicator)
- [case link](/documentation/xcuiautomation/xcuielement/elementtype/link)
- [case map](/documentation/xcuiautomation/xcuielement/elementtype/map)
- [case matte](/documentation/xcuiautomation/xcuielement/elementtype/matte)
- [case menu](/documentation/xcuiautomation/xcuielement/elementtype/menu)
- [case menuBar](/documentation/xcuiautomation/xcuielement/elementtype/menubar)
- [case menuBarItem](/documentation/xcuiautomation/xcuielement/elementtype/menubaritem)
- [case menuButton](/documentation/xcuiautomation/xcuielement/elementtype/menubutton)
- [case menuItem](/documentation/xcuiautomation/xcuielement/elementtype/menuitem)
- [case navigationBar](/documentation/xcuiautomation/xcuielement/elementtype/navigationbar)
- [case other](/documentation/xcuiautomation/xcuielement/elementtype/other)
- [case outline](/documentation/xcuiautomation/xcuielement/elementtype/outline)
- [case outlineRow](/documentation/xcuiautomation/xcuielement/elementtype/outlinerow)
- [case pageIndicator](/documentation/xcuiautomation/xcuielement/elementtype/pageindicator)
- [case picker](/documentation/xcuiautomation/xcuielement/elementtype/picker)
- [case pickerWheel](/documentation/xcuiautomation/xcuielement/elementtype/pickerwheel)
- [case popUpButton](/documentation/xcuiautomation/xcuielement/elementtype/popupbutton)
- [case popover](/documentation/xcuiautomation/xcuielement/elementtype/popover)
- [case progressIndicator](/documentation/xcuiautomation/xcuielement/elementtype/progressindicator)
- [case radioButton](/documentation/xcuiautomation/xcuielement/elementtype/radiobutton)
- [case radioGroup](/documentation/xcuiautomation/xcuielement/elementtype/radiogroup)
- [case ratingIndicator](/documentation/xcuiautomation/xcuielement/elementtype/ratingindicator)
- [case relevanceIndicator](/documentation/xcuiautomation/xcuielement/elementtype/relevanceindicator)
- [case ruler](/documentation/xcuiautomation/xcuielement/elementtype/ruler)
- [case rulerMarker](/documentation/xcuiautomation/xcuielement/elementtype/rulermarker)
- [case scrollBar](/documentation/xcuiautomation/xcuielement/elementtype/scrollbar)
- [case scrollView](/documentation/xcuiautomation/xcuielement/elementtype/scrollview)
- [case searchField](/documentation/xcuiautomation/xcuielement/elementtype/searchfield)
- [case secureTextField](/documentation/xcuiautomation/xcuielement/elementtype/securetextfield)
- [case segmentedControl](/documentation/xcuiautomation/xcuielement/elementtype/segmentedcontrol)
- [case sheet](/documentation/xcuiautomation/xcuielement/elementtype/sheet)
- [case slider](/documentation/xcuiautomation/xcuielement/elementtype/slider)
- [case splitGroup](/documentation/xcuiautomation/xcuielement/elementtype/splitgroup)
- [case splitter](/documentation/xcuiautomation/xcuielement/elementtype/splitter)
- [case staticText](/documentation/xcuiautomation/xcuielement/elementtype/statictext)
- [case statusBar](/documentation/xcuiautomation/xcuielement/elementtype/statusbar)
- [case statusItem](/documentation/xcuiautomation/xcuielement/elementtype/statusitem)
- [case stepper](/documentation/xcuiautomation/xcuielement/elementtype/stepper)
- [case `switch`](/documentation/xcuiautomation/xcuielement/elementtype/switch)
- [case tab](/documentation/xcuiautomation/xcuielement/elementtype/tab)
- [case tabBar](/documentation/xcuiautomation/xcuielement/elementtype/tabbar)
- [case tabGroup](/documentation/xcuiautomation/xcuielement/elementtype/tabgroup)
- [case table](/documentation/xcuiautomation/xcuielement/elementtype/table)
- [case tableColumn](/documentation/xcuiautomation/xcuielement/elementtype/tablecolumn)
- [case tableRow](/documentation/xcuiautomation/xcuielement/elementtype/tablerow)
- [case textField](/documentation/xcuiautomation/xcuielement/elementtype/textfield)
- [case textView](/documentation/xcuiautomation/xcuielement/elementtype/textview)
- [case timeline](/documentation/xcuiautomation/xcuielement/elementtype/timeline)
- [case toggle](/documentation/xcuiautomation/xcuielement/elementtype/toggle)
- [case toolbar](/documentation/xcuiautomation/xcuielement/elementtype/toolbar)
- [case toolbarButton](/documentation/xcuiautomation/xcuielement/elementtype/toolbarbutton)
- [case touchBar](/documentation/xcuiautomation/xcuielement/elementtype/touchbar)
- [case valueIndicator](/documentation/xcuiautomation/xcuielement/elementtype/valueindicator)
- [case webView](/documentation/xcuiautomation/xcuielement/elementtype/webview)
- [case window](/documentation/xcuiautomation/xcuielement/elementtype/window)
#### Initializers

- [init?(rawValue: UInt)](/documentation/xcuiautomation/xcuielement/elementtype/init(rawvalue:))

- [XCUIElement.SizeClass](/documentation/xcuiautomation/xcuielement/sizeclass)
#### Enumeration cases

- [case regular](/documentation/xcuiautomation/xcuielement/sizeclass/regular)
- [case compact](/documentation/xcuiautomation/xcuielement/sizeclass/compact)
- [case unspecified](/documentation/xcuiautomation/xcuielement/sizeclass/unspecified)
#### Initializers

- [init?(rawValue: Int)](/documentation/xcuiautomation/xcuielement/sizeclass/init(rawvalue:))

- [XCUIElement.AttributeName](/documentation/xcuiautomation/xcuielement/attributename)
#### Keys

- [static let children: XCUIElement.AttributeName](/documentation/xcuiautomation/xcuielement/attributename/children)
- [static let elementType: XCUIElement.AttributeName](/documentation/xcuiautomation/xcuielement/attributename/elementtype)
- [static let enabled: XCUIElement.AttributeName](/documentation/xcuiautomation/xcuielement/attributename/enabled)
- [static let frame: XCUIElement.AttributeName](/documentation/xcuiautomation/xcuielement/attributename/frame)
- [static let hasFocus: XCUIElement.AttributeName](/documentation/xcuiautomation/xcuielement/attributename/hasfocus)
- [static let horizontalSizeClass: XCUIElement.AttributeName](/documentation/xcuiautomation/xcuielement/attributename/horizontalsizeclass)
- [static let identifier: XCUIElement.AttributeName](/documentation/xcuiautomation/xcuielement/attributename/identifier)
- [static let label: XCUIElement.AttributeName](/documentation/xcuiautomation/xcuielement/attributename/label)
- [static let placeholderValue: XCUIElement.AttributeName](/documentation/xcuiautomation/xcuielement/attributename/placeholdervalue)
- [static let selected: XCUIElement.AttributeName](/documentation/xcuiautomation/xcuielement/attributename/selected)
- [static let title: XCUIElement.AttributeName](/documentation/xcuiautomation/xcuielement/attributename/title)
- [static let value: XCUIElement.AttributeName](/documentation/xcuiautomation/xcuielement/attributename/value)
- [static let verticalSizeClass: XCUIElement.AttributeName](/documentation/xcuiautomation/xcuielement/attributename/verticalsizeclass)
#### Initializers

- [init(rawValue: String)](/documentation/xcuiautomation/xcuielement/attributename/init(rawvalue:))

### Deprecated methods

- [func swipeDown(withVelocity: XCUIGestureVelocity)](/documentation/xcuiautomation/xcuielement/swipedown(withvelocity:))
- [func swipeUp(withVelocity: XCUIGestureVelocity)](/documentation/xcuiautomation/xcuielement/swipeup(withvelocity:))
- [func swipeLeft(withVelocity: XCUIGestureVelocity)](/documentation/xcuiautomation/xcuielement/swipeleft(withvelocity:))
- [func swipeRight(withVelocity: XCUIGestureVelocity)](/documentation/xcuiautomation/xcuielement/swiperight(withvelocity:))

- [XCUIElementAttributes](/documentation/xcuiautomation/xcuielementattributes)
### Identity

- [var identifier: String](/documentation/xcuiautomation/xcuielementattributes/identifier)
- [var elementType: XCUIElement.ElementType](/documentation/xcuiautomation/xcuielementattributes/elementtype)
- [XCUIElement.ElementType](/documentation/xcuiautomation/xcuielement/elementtype)
#### Enumeration cases

- [case activityIndicator](/documentation/xcuiautomation/xcuielement/elementtype/activityindicator)
- [case alert](/documentation/xcuiautomation/xcuielement/elementtype/alert)
- [case any](/documentation/xcuiautomation/xcuielement/elementtype/any)
- [case application](/documentation/xcuiautomation/xcuielement/elementtype/application)
- [case browser](/documentation/xcuiautomation/xcuielement/elementtype/browser)
- [case button](/documentation/xcuiautomation/xcuielement/elementtype/button)
- [case cell](/documentation/xcuiautomation/xcuielement/elementtype/cell)
- [case checkBox](/documentation/xcuiautomation/xcuielement/elementtype/checkbox)
- [case collectionView](/documentation/xcuiautomation/xcuielement/elementtype/collectionview)
- [case colorWell](/documentation/xcuiautomation/xcuielement/elementtype/colorwell)
- [case comboBox](/documentation/xcuiautomation/xcuielement/elementtype/combobox)
- [case datePicker](/documentation/xcuiautomation/xcuielement/elementtype/datepicker)
- [case decrementArrow](/documentation/xcuiautomation/xcuielement/elementtype/decrementarrow)
- [case dialog](/documentation/xcuiautomation/xcuielement/elementtype/dialog)
- [case disclosureTriangle](/documentation/xcuiautomation/xcuielement/elementtype/disclosuretriangle)
- [case dockItem](/documentation/xcuiautomation/xcuielement/elementtype/dockitem)
- [case drawer](/documentation/xcuiautomation/xcuielement/elementtype/drawer)
- [case grid](/documentation/xcuiautomation/xcuielement/elementtype/grid)
- [case group](/documentation/xcuiautomation/xcuielement/elementtype/group)
- [case handle](/documentation/xcuiautomation/xcuielement/elementtype/handle)
- [case helpTag](/documentation/xcuiautomation/xcuielement/elementtype/helptag)
- [case icon](/documentation/xcuiautomation/xcuielement/elementtype/icon)
- [case image](/documentation/xcuiautomation/xcuielement/elementtype/image)
- [case incrementArrow](/documentation/xcuiautomation/xcuielement/elementtype/incrementarrow)
- [case key](/documentation/xcuiautomation/xcuielement/elementtype/key)
- [case keyboard](/documentation/xcuiautomation/xcuielement/elementtype/keyboard)
- [case layoutArea](/documentation/xcuiautomation/xcuielement/elementtype/layoutarea)
- [case layoutItem](/documentation/xcuiautomation/xcuielement/elementtype/layoutitem)
- [case levelIndicator](/documentation/xcuiautomation/xcuielement/elementtype/levelindicator)
- [case link](/documentation/xcuiautomation/xcuielement/elementtype/link)
- [case map](/documentation/xcuiautomation/xcuielement/elementtype/map)
- [case matte](/documentation/xcuiautomation/xcuielement/elementtype/matte)
- [case menu](/documentation/xcuiautomation/xcuielement/elementtype/menu)
- [case menuBar](/documentation/xcuiautomation/xcuielement/elementtype/menubar)
- [case menuBarItem](/documentation/xcuiautomation/xcuielement/elementtype/menubaritem)
- [case menuButton](/documentation/xcuiautomation/xcuielement/elementtype/menubutton)
- [case menuItem](/documentation/xcuiautomation/xcuielement/elementtype/menuitem)
- [case navigationBar](/documentation/xcuiautomation/xcuielement/elementtype/navigationbar)
- [case other](/documentation/xcuiautomation/xcuielement/elementtype/other)
- [case outline](/documentation/xcuiautomation/xcuielement/elementtype/outline)
- [case outlineRow](/documentation/xcuiautomation/xcuielement/elementtype/outlinerow)
- [case pageIndicator](/documentation/xcuiautomation/xcuielement/elementtype/pageindicator)
- [case picker](/documentation/xcuiautomation/xcuielement/elementtype/picker)
- [case pickerWheel](/documentation/xcuiautomation/xcuielement/elementtype/pickerwheel)
- [case popUpButton](/documentation/xcuiautomation/xcuielement/elementtype/popupbutton)
- [case popover](/documentation/xcuiautomation/xcuielement/elementtype/popover)
- [case progressIndicator](/documentation/xcuiautomation/xcuielement/elementtype/progressindicator)
- [case radioButton](/documentation/xcuiautomation/xcuielement/elementtype/radiobutton)
- [case radioGroup](/documentation/xcuiautomation/xcuielement/elementtype/radiogroup)
- [case ratingIndicator](/documentation/xcuiautomation/xcuielement/elementtype/ratingindicator)
- [case relevanceIndicator](/documentation/xcuiautomation/xcuielement/elementtype/relevanceindicator)
- [case ruler](/documentation/xcuiautomation/xcuielement/elementtype/ruler)
- [case rulerMarker](/documentation/xcuiautomation/xcuielement/elementtype/rulermarker)
- [case scrollBar](/documentation/xcuiautomation/xcuielement/elementtype/scrollbar)
- [case scrollView](/documentation/xcuiautomation/xcuielement/elementtype/scrollview)
- [case searchField](/documentation/xcuiautomation/xcuielement/elementtype/searchfield)
- [case secureTextField](/documentation/xcuiautomation/xcuielement/elementtype/securetextfield)
- [case segmentedControl](/documentation/xcuiautomation/xcuielement/elementtype/segmentedcontrol)
- [case sheet](/documentation/xcuiautomation/xcuielement/elementtype/sheet)
- [case slider](/documentation/xcuiautomation/xcuielement/elementtype/slider)
- [case splitGroup](/documentation/xcuiautomation/xcuielement/elementtype/splitgroup)
- [case splitter](/documentation/xcuiautomation/xcuielement/elementtype/splitter)
- [case staticText](/documentation/xcuiautomation/xcuielement/elementtype/statictext)
- [case statusBar](/documentation/xcuiautomation/xcuielement/elementtype/statusbar)
- [case statusItem](/documentation/xcuiautomation/xcuielement/elementtype/statusitem)
- [case stepper](/documentation/xcuiautomation/xcuielement/elementtype/stepper)
- [case `switch`](/documentation/xcuiautomation/xcuielement/elementtype/switch)
- [case tab](/documentation/xcuiautomation/xcuielement/elementtype/tab)
- [case tabBar](/documentation/xcuiautomation/xcuielement/elementtype/tabbar)
- [case tabGroup](/documentation/xcuiautomation/xcuielement/elementtype/tabgroup)
- [case table](/documentation/xcuiautomation/xcuielement/elementtype/table)
- [case tableColumn](/documentation/xcuiautomation/xcuielement/elementtype/tablecolumn)
- [case tableRow](/documentation/xcuiautomation/xcuielement/elementtype/tablerow)
- [case textField](/documentation/xcuiautomation/xcuielement/elementtype/textfield)
- [case textView](/documentation/xcuiautomation/xcuielement/elementtype/textview)
- [case timeline](/documentation/xcuiautomation/xcuielement/elementtype/timeline)
- [case toggle](/documentation/xcuiautomation/xcuielement/elementtype/toggle)
- [case toolbar](/documentation/xcuiautomation/xcuielement/elementtype/toolbar)
- [case toolbarButton](/documentation/xcuiautomation/xcuielement/elementtype/toolbarbutton)
- [case touchBar](/documentation/xcuiautomation/xcuielement/elementtype/touchbar)
- [case valueIndicator](/documentation/xcuiautomation/xcuielement/elementtype/valueindicator)
- [case webView](/documentation/xcuiautomation/xcuielement/elementtype/webview)
- [case window](/documentation/xcuiautomation/xcuielement/elementtype/window)
#### Initializers

- [init?(rawValue: UInt)](/documentation/xcuiautomation/xcuielement/elementtype/init(rawvalue:))

### Value

- [var value: Any?](/documentation/xcuiautomation/xcuielementattributes/value)
- [var placeholderValue: String?](/documentation/xcuiautomation/xcuielementattributes/placeholdervalue)
- [var title: String](/documentation/xcuiautomation/xcuielementattributes/title)
- [var label: String](/documentation/xcuiautomation/xcuielementattributes/label)
### Interaction state

- [var hasFocus: Bool](/documentation/xcuiautomation/xcuielementattributes/hasfocus)
- [var isEnabled: Bool](/documentation/xcuiautomation/xcuielementattributes/isenabled)
- [var isSelected: Bool](/documentation/xcuiautomation/xcuielementattributes/isselected)
### Size

- [var frame: CGRect](/documentation/xcuiautomation/xcuielementattributes/frame)
- [var horizontalSizeClass: XCUIElement.SizeClass](/documentation/xcuiautomation/xcuielementattributes/horizontalsizeclass)
- [var verticalSizeClass: XCUIElement.SizeClass](/documentation/xcuiautomation/xcuielementattributes/verticalsizeclass)
- [XCUIElement.SizeClass](/documentation/xcuiautomation/xcuielement/sizeclass)
#### Enumeration cases

- [case regular](/documentation/xcuiautomation/xcuielement/sizeclass/regular)
- [case compact](/documentation/xcuiautomation/xcuielement/sizeclass/compact)
- [case unspecified](/documentation/xcuiautomation/xcuielement/sizeclass/unspecified)
#### Initializers

- [init?(rawValue: Int)](/documentation/xcuiautomation/xcuielement/sizeclass/init(rawvalue:))


- [XCUIElementSnapshot](/documentation/xcuiautomation/xcuielementsnapshot)
### Inspecting attributes

- [var children: [any XCUIElementSnapshot]](/documentation/xcuiautomation/xcuielementsnapshot/children)
- [var dictionaryRepresentation: [XCUIElement.AttributeName : Any]](/documentation/xcuiautomation/xcuielementsnapshot/dictionaryrepresentation)

- [XCUIElementSnapshotProviding](/documentation/xcuiautomation/xcuielementsnapshotproviding)
### Providing snapshots

- [func snapshot() throws -> any XCUIElementSnapshot](/documentation/xcuiautomation/xcuielementsnapshotproviding/snapshot())

- [XCUICoordinate](/documentation/xcuiautomation/xcuicoordinate)
### Getting coordinate properties

- [var referencedElement: XCUIElement](/documentation/xcuiautomation/xcuicoordinate/referencedelement)
- [var screenPoint: CGPoint](/documentation/xcuiautomation/xcuicoordinate/screenpoint)
### Moving the pointer

- [func hover()](/documentation/xcuiautomation/xcuicoordinate/hover())
### Clicking

- [func click()](/documentation/xcuiautomation/xcuicoordinate/click())
- [func click(forDuration: TimeInterval, thenDragTo: XCUICoordinate)](/documentation/xcuiautomation/xcuicoordinate/click(forduration:thendragto:))
- [func click(forDuration: TimeInterval, thenDragTo: XCUICoordinate, withVelocity: XCUIGestureVelocity, thenHoldForDuration: TimeInterval)](/documentation/xcuiautomation/xcuicoordinate/click(forduration:thendragto:withvelocity:thenholdforduration:))
- [func doubleClick()](/documentation/xcuiautomation/xcuicoordinate/doubleclick())
- [func rightClick()](/documentation/xcuiautomation/xcuicoordinate/rightclick())
### Scrolling

- [func scroll(byDeltaX: CGFloat, deltaY: CGFloat)](/documentation/xcuiautomation/xcuicoordinate/scroll(bydeltax:deltay:))
### Tapping and pressing

- [func tap()](/documentation/xcuiautomation/xcuicoordinate/tap())
- [func doubleTap()](/documentation/xcuiautomation/xcuicoordinate/doubletap())
- [func press(forDuration: TimeInterval)](/documentation/xcuiautomation/xcuicoordinate/press(forduration:))
- [func press(forDuration: TimeInterval, thenDragTo: XCUICoordinate)](/documentation/xcuiautomation/xcuicoordinate/press(forduration:thendragto:))
- [func press(forDuration: TimeInterval, thenDragTo: XCUICoordinate, withVelocity: XCUIGestureVelocity, thenHoldForDuration: TimeInterval)](/documentation/xcuiautomation/xcuicoordinate/press(forduration:thendragto:withvelocity:thenholdforduration:))
### Performing gestures

- [func swipeLeft()](/documentation/xcuiautomation/xcuicoordinate/swipeleft())
- [func swipeLeft(velocity: XCUIGestureVelocity)](/documentation/xcuiautomation/xcuicoordinate/swipeleft(velocity:))
- [func swipeRight()](/documentation/xcuiautomation/xcuicoordinate/swiperight())
- [func swipeRight(velocity: XCUIGestureVelocity)](/documentation/xcuiautomation/xcuicoordinate/swiperight(velocity:))
- [func swipeUp()](/documentation/xcuiautomation/xcuicoordinate/swipeup())
- [func swipeUp(velocity: XCUIGestureVelocity)](/documentation/xcuiautomation/xcuicoordinate/swipeup(velocity:))
- [func swipeDown()](/documentation/xcuiautomation/xcuicoordinate/swipedown())
- [func swipeDown(velocity: XCUIGestureVelocity)](/documentation/xcuiautomation/xcuicoordinate/swipedown(velocity:))
### Creating relative coordinates

- [func withOffset(CGVector) -> XCUICoordinate](/documentation/xcuiautomation/xcuicoordinate/withoffset(_:))

## Application lifecycle

- [XCUIApplication](/documentation/xcuiautomation/xcuiapplication)
### Creating an application proxy

- [init()](/documentation/xcuiautomation/xcuiapplication/init())
- [init(bundleIdentifier: String)](/documentation/xcuiautomation/xcuiapplication/init(bundleidentifier:))
- [init(url: URL)](/documentation/xcuiautomation/xcuiapplication/init(url:)-90e7z)
### Launching the application

- [func launch()](/documentation/xcuiautomation/xcuiapplication/launch())
- [var launchArguments: [String]](/documentation/xcuiautomation/xcuiapplication/launcharguments)
- [var launchEnvironment: [String : String]](/documentation/xcuiautomation/xcuiapplication/launchenvironment)
- [func open(URL)](/documentation/xcuiautomation/xcuiapplication/open(_:))
### Activating the application

- [func activate()](/documentation/xcuiautomation/xcuiapplication/activate())
### Terminating the application

- [func terminate()](/documentation/xcuiautomation/xcuiapplication/terminate())
### Determining application state

- [var state: XCUIApplication.State](/documentation/xcuiautomation/xcuiapplication/state-swift.property)
- [XCUIApplication.State](/documentation/xcuiautomation/xcuiapplication/state-swift.enum)
#### Enumeration cases

- [case unknown](/documentation/xcuiautomation/xcuiapplication/state-swift.enum/unknown)
- [case notRunning](/documentation/xcuiautomation/xcuiapplication/state-swift.enum/notrunning)
- [case runningBackgroundSuspended](/documentation/xcuiautomation/xcuiapplication/state-swift.enum/runningbackgroundsuspended)
- [case runningBackground](/documentation/xcuiautomation/xcuiapplication/state-swift.enum/runningbackground)
- [case runningForeground](/documentation/xcuiautomation/xcuiapplication/state-swift.enum/runningforeground)
#### Initializers

- [init?(rawValue: UInt)](/documentation/xcuiautomation/xcuiapplication/state-swift.enum/init(rawvalue:))

### Waiting for an application state

- [func wait(for: XCUIApplication.State, timeout: TimeInterval) -> Bool](/documentation/xcuiautomation/xcuiapplication/wait(for:timeout:))
### Resetting authorization status

- [func resetAuthorizationStatus(for: XCUIProtectedResource)](/documentation/xcuiautomation/xcuiapplication/resetauthorizationstatus(for:))
- [XCUIProtectedResource](/documentation/xcuiautomation/xcuiprotectedresource)
#### Protected resources

- [case location](/documentation/xcuiautomation/xcuiprotectedresource/location)
- [case userTracking](/documentation/xcuiautomation/xcuiprotectedresource/usertracking)
- [case contacts](/documentation/xcuiautomation/xcuiprotectedresource/contacts)
- [case calendar](/documentation/xcuiautomation/xcuiprotectedresource/calendar)
- [case reminders](/documentation/xcuiautomation/xcuiprotectedresource/reminders)
- [case photos](/documentation/xcuiautomation/xcuiprotectedresource/photos)
- [case bluetooth](/documentation/xcuiautomation/xcuiprotectedresource/bluetooth)
- [case localNetwork](/documentation/xcuiautomation/xcuiprotectedresource/localnetwork)
- [case microphone](/documentation/xcuiautomation/xcuiprotectedresource/microphone)
- [case camera](/documentation/xcuiautomation/xcuiprotectedresource/camera)
- [case health](/documentation/xcuiautomation/xcuiprotectedresource/health)
- [case homeKit](/documentation/xcuiautomation/xcuiprotectedresource/homekit)
- [case mediaLibrary](/documentation/xcuiautomation/xcuiprotectedresource/medialibrary)
- [case keyboardNetwork](/documentation/xcuiautomation/xcuiprotectedresource/keyboardnetwork)
- [case systemRootDirectory](/documentation/xcuiautomation/xcuiprotectedresource/systemrootdirectory)
- [case userDesktopDirectory](/documentation/xcuiautomation/xcuiprotectedresource/userdesktopdirectory)
- [case userDocumentsDirectory](/documentation/xcuiautomation/xcuiprotectedresource/userdocumentsdirectory)
- [case userDownloadsDirectory](/documentation/xcuiautomation/xcuiprotectedresource/userdownloadsdirectory)
- [case focus](/documentation/xcuiautomation/xcuiprotectedresource/focus)
- [case removableVolumes](/documentation/xcuiautomation/xcuiprotectedresource/removablevolumes)
- [case networkVolumes](/documentation/xcuiautomation/xcuiprotectedresource/networkvolumes)
- [case appleEvents](/documentation/xcuiautomation/xcuiprotectedresource/appleevents)
#### Initializers

- [init?(rawValue: Int)](/documentation/xcuiautomation/xcuiprotectedresource/init(rawvalue:))

### Performing an accessibility audit

- [func performAccessibilityAudit(for: XCUIAccessibilityAuditType, ((XCUIAccessibilityAuditIssue) throws -> Bool)?) throws](/documentation/xcuiautomation/xcuiapplication/performaccessibilityaudit(for:_:))
- [XCUIAccessibilityAuditType](/documentation/xcuiautomation/xcuiaccessibilityaudittype)
#### Accessibility audit type creation

- [init(rawValue: UInt64)](/documentation/xcuiautomation/xcuiaccessibilityaudittype/init(rawvalue:))
#### Accessibility audit types

- [static var action: XCUIAccessibilityAuditType](/documentation/xcuiautomation/xcuiaccessibilityaudittype/action)
- [static var all: XCUIAccessibilityAuditType](/documentation/xcuiautomation/xcuiaccessibilityaudittype/all)
- [static var contrast: XCUIAccessibilityAuditType](/documentation/xcuiautomation/xcuiaccessibilityaudittype/contrast)
- [static var dynamicType: XCUIAccessibilityAuditType](/documentation/xcuiautomation/xcuiaccessibilityaudittype/dynamictype)
- [static var elementDetection: XCUIAccessibilityAuditType](/documentation/xcuiautomation/xcuiaccessibilityaudittype/elementdetection)
- [static var hitRegion: XCUIAccessibilityAuditType](/documentation/xcuiautomation/xcuiaccessibilityaudittype/hitregion)
- [static var parentChild: XCUIAccessibilityAuditType](/documentation/xcuiautomation/xcuiaccessibilityaudittype/parentchild)
- [static var sufficientElementDescription: XCUIAccessibilityAuditType](/documentation/xcuiautomation/xcuiaccessibilityaudittype/sufficientelementdescription)
- [static var textClipped: XCUIAccessibilityAuditType](/documentation/xcuiautomation/xcuiaccessibilityaudittype/textclipped)
- [static var trait: XCUIAccessibilityAuditType](/documentation/xcuiautomation/xcuiaccessibilityaudittype/trait)

- [XCUIAccessibilityAuditIssue](/documentation/xcuiautomation/xcuiaccessibilityauditissue)
#### Type and description

- [var auditType: XCUIAccessibilityAuditType](/documentation/xcuiautomation/xcuiaccessibilityauditissue/audittype)
- [var compactDescription: String](/documentation/xcuiautomation/xcuiaccessibilityauditissue/compactdescription)
- [var detailedDescription: String](/documentation/xcuiautomation/xcuiaccessibilityauditissue/detaileddescription)
#### UI element

- [var element: XCUIElement?](/documentation/xcuiautomation/xcuiaccessibilityauditissue/element)

### Initializers

- [init(URL: URL)](/documentation/xcuiautomation/xcuiapplication/init(url:)-6ga10)

## Screenshots

- [XCUIScreen](/documentation/xcuiautomation/xcuiscreen)
### Device screens

- [class var main: XCUIScreen](/documentation/xcuiautomation/xcuiscreen/main)
- [class var screens: [XCUIScreen]](/documentation/xcuiautomation/xcuiscreen/screens)

- [XCUIScreenshot](/documentation/xcuiautomation/xcuiscreenshot)
### Screenshot representations

- [var image: UIImage](/documentation/xcuiautomation/xcuiscreenshot/image)
- [var pngRepresentation: Data](/documentation/xcuiautomation/xcuiscreenshot/pngrepresentation)

- [XCUIScreenshotProviding](/documentation/xcuiautomation/xcuiscreenshotproviding)
### Taking a Screenshot

- [func screenshot() -> XCUIScreenshot](/documentation/xcuiautomation/xcuiscreenshotproviding/screenshot())

## Device simulation

- [XCUIDevice](/documentation/xcuiautomation/xcuidevice)
### Accessing the current device

- [class var shared: XCUIDevice](/documentation/xcuiautomation/xcuidevice/shared)
- [var supportsPointerInteraction: Bool](/documentation/xcuiautomation/xcuidevice/supportspointerinteraction)
- [var supportsHandGestures: Bool](/documentation/xcuiautomation/xcuidevice/supportshandgestures)
### Interacting with buttons and the Digital Crown

- [func press(XCUIDevice.Button)](/documentation/xcuiautomation/xcuidevice/press(_:))
- [func hasHardwareButton(XCUIDevice.Button) -> Bool](/documentation/xcuiautomation/xcuidevice/hashardwarebutton(_:))
- [XCUIDevice.Button](/documentation/xcuiautomation/xcuidevice/button)
#### Device buttons

- [case home](/documentation/xcuiautomation/xcuidevice/button/home)
- [case volumeUp](/documentation/xcuiautomation/xcuidevice/button/volumeup)
- [case volumeDown](/documentation/xcuiautomation/xcuidevice/button/volumedown)
- [case action](/documentation/xcuiautomation/xcuidevice/button/action)
- [case camera](/documentation/xcuiautomation/xcuidevice/button/camera)
#### Initializers

- [init?(rawValue: Int)](/documentation/xcuiautomation/xcuidevice/button/init(rawvalue:))

- [func rotateDigitalCrown(delta: CGFloat)](/documentation/xcuiautomation/xcuidevice/rotatedigitalcrown(delta:))
- [func rotateDigitalCrown(delta: CGFloat, velocity: XCUIGestureVelocity)](/documentation/xcuiautomation/xcuidevice/rotatedigitalcrown(delta:velocity:))
### Performing gestures

- [func perform(handGesture: XCUIDeviceHandGesture)](/documentation/xcuiautomation/xcuidevice/perform(handgesture:))
- [XCUIDeviceHandGesture](/documentation/xcuiautomation/xcuidevicehandgesture)
#### Hand gestures

- [case doubleTap](/documentation/xcuiautomation/xcuidevicehandgesture/doubletap)
#### Enumeration Cases

- [case flick](/documentation/xcuiautomation/xcuidevicehandgesture/flick)
#### Initializers

- [init?(rawValue: Int)](/documentation/xcuiautomation/xcuidevicehandgesture/init(rawvalue:))

### Rotating and changing location

- [var orientation: UIDeviceOrientation](/documentation/xcuiautomation/xcuidevice/orientation)
- [var location: XCUILocation?](/documentation/xcuiautomation/xcuidevice/location)
- [XCUILocation](/documentation/xcuiautomation/xcuilocation)
#### Creating a location

- [init(location: CLLocation)](/documentation/xcuiautomation/xcuilocation/init(location:))
#### Determining the location

- [var location: CLLocation](/documentation/xcuiautomation/xcuilocation/location)
- [var debugDescription: String](/documentation/xcuiautomation/xcuilocation/debugdescription)

### Interacting with the OS

- [var system: XCUISystem](/documentation/xcuiautomation/xcuidevice/system)
- [var appearance: XCUIDevice.Appearance](/documentation/xcuiautomation/xcuidevice/appearance-swift.property)
- [XCUIDevice.Appearance](/documentation/xcuiautomation/xcuidevice/appearance-swift.enum)
#### Appearances

- [case unspecified](/documentation/xcuiautomation/xcuidevice/appearance-swift.enum/unspecified)
- [case light](/documentation/xcuiautomation/xcuidevice/appearance-swift.enum/light)
- [case dark](/documentation/xcuiautomation/xcuidevice/appearance-swift.enum/dark)
#### Initializers

- [init?(rawValue: Int)](/documentation/xcuiautomation/xcuidevice/appearance-swift.enum/init(rawvalue:))

### Interacting with Siri

- [var siriService: XCUISiriService](/documentation/xcuiautomation/xcuidevice/siriservice)
### Deprecated

- [init()](/documentation/xcuiautomation/xcuidevice/init())
### Instance Properties

- [var voiceOverService: XCUIVoiceOverService](/documentation/xcuiautomation/xcuidevice/voiceoverservice)

- [XCUISystem](/documentation/xcuiautomation/xcuisystem)
### Opening items in applications by URL

- [func open(URL)](/documentation/xcuiautomation/xcuisystem/open(_:))

- [XCUISiriService](/documentation/xcuiautomation/xcuisiriservice)
### Siri activation

- [func activate(voiceRecognitionText: String)](/documentation/xcuiautomation/xcuisiriservice/activate(voicerecognitiontext:))
### Siri proxy state

- [var debugDescription: String](/documentation/xcuiautomation/xcuisiriservice/debugdescription)

## Remote control simulation

- [XCUIRemote](/documentation/xcuiautomation/xcuiremote)
### Accessing the simulated remote

- [class var shared: XCUIRemote](/documentation/xcuiautomation/xcuiremote/shared)
### Pressing remote buttons

- [func press(XCUIRemote.Button)](/documentation/xcuiautomation/xcuiremote/press(_:))
- [func press(XCUIRemote.Button, forDuration: TimeInterval)](/documentation/xcuiautomation/xcuiremote/press(_:forduration:))
- [XCUIRemoteButton](/documentation/xcuiautomation/xcuiremote/button)
#### Remote buttons

- [case up](/documentation/xcuiautomation/xcuiremotebutton/up)
- [case down](/documentation/xcuiautomation/xcuiremotebutton/down)
- [case left](/documentation/xcuiautomation/xcuiremotebutton/left)
- [case right](/documentation/xcuiautomation/xcuiremotebutton/right)
- [case select](/documentation/xcuiautomation/xcuiremotebutton/select)
- [case menu](/documentation/xcuiautomation/xcuiremotebutton/menu)
- [case playPause](/documentation/xcuiautomation/xcuiremotebutton/playpause)
- [case home](/documentation/xcuiautomation/xcuiremotebutton/home)
- [case pageUp](/documentation/xcuiautomation/xcuiremotebutton/pageup)
- [case pageDown](/documentation/xcuiautomation/xcuiremotebutton/pagedown)
- [case guide](/documentation/xcuiautomation/xcuiremotebutton/guide)
- [case fourColors](/documentation/xcuiautomation/xcuiremotebutton/fourcolors)
- [case oneTwoThree](/documentation/xcuiautomation/xcuiremotebutton/onetwothree)
- [case tvProvider](/documentation/xcuiautomation/xcuiremotebutton/tvprovider)
#### Initializers

- [init?(rawValue: UInt)](/documentation/xcuiautomation/xcuiremotebutton/init(rawvalue:))


## UI testing availability

- [var XCUI_UI_TESTING_AVAILABLE: Int32](/documentation/xcuiautomation/xcui_ui_testing_available)
## Classes

- [XCUIVoiceOverService](/documentation/xcuiautomation/xcuivoiceoverservice)
### Classes

- [XCUIVoiceOverService.Output](/documentation/xcuiautomation/xcuivoiceoverservice/output)
#### Instance Properties

- [var utterance: String](/documentation/xcuiautomation/xcuivoiceoverservice/output/utterance)

### Structures

- [XCUIVoiceOverService.Error](/documentation/xcuiautomation/xcuivoiceoverservice/error)
#### Type Properties

- [static var errorDomain: String](/documentation/xcuiautomation/xcuivoiceoverservice/error/errordomain)
- [static var failedToStart: XCUIVoiceOverService.Error.Code](/documentation/xcuiautomation/xcuivoiceoverservice/error/failedtostart)
- [static var failedToStop: XCUIVoiceOverService.Error.Code](/documentation/xcuiautomation/xcuivoiceoverservice/error/failedtostop)
- [static var noSpeech: XCUIVoiceOverService.Error.Code](/documentation/xcuiautomation/xcuivoiceoverservice/error/nospeech)
- [static var notRunning: XCUIVoiceOverService.Error.Code](/documentation/xcuiautomation/xcuivoiceoverservice/error/notrunning)
#### Enumerations

- [XCUIVoiceOverService.Error.Code](/documentation/xcuiautomation/xcuivoiceoverservice/error/code)
##### Enumeration Cases

- [case failedToStart](/documentation/xcuiautomation/xcuivoiceoverservice/error/code/failedtostart)
- [case failedToStop](/documentation/xcuiautomation/xcuivoiceoverservice/error/code/failedtostop)
- [case noSpeech](/documentation/xcuiautomation/xcuivoiceoverservice/error/code/nospeech)
- [case notRunning](/documentation/xcuiautomation/xcuivoiceoverservice/error/code/notrunning)
##### Initializers

- [init?(rawValue: Int)](/documentation/xcuiautomation/xcuivoiceoverservice/error/code/init(rawvalue:))


### Instance Properties

- [var debugDescription: String](/documentation/xcuiautomation/xcuivoiceoverservice/debugdescription)
- [var isEnabled: Bool](/documentation/xcuiautomation/xcuivoiceoverservice/isenabled)
### Instance Methods

- [func currentSpeech() throws -> XCUIVoiceOverService.Output](/documentation/xcuiautomation/xcuivoiceoverservice/currentspeech())
- [func disable() throws](/documentation/xcuiautomation/xcuivoiceoverservice/disable())
- [func enable() throws](/documentation/xcuiautomation/xcuivoiceoverservice/enable())
- [func moveBackward() throws -> XCUIVoiceOverService.Output](/documentation/xcuiautomation/xcuivoiceoverservice/movebackward())
- [func moveForward() throws -> XCUIVoiceOverService.Output](/documentation/xcuiautomation/xcuivoiceoverservice/moveforward())
- [func moveIn() throws -> XCUIVoiceOverService.Output](/documentation/xcuiautomation/xcuivoiceoverservice/movein())
- [func moveOut() throws -> XCUIVoiceOverService.Output](/documentation/xcuiautomation/xcuivoiceoverservice/moveout())

## Variables

- [let XCUIVoiceOverServiceErrorDomain: String](/documentation/xcuiautomation/xcuivoiceoverserviceerrordomain)

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
