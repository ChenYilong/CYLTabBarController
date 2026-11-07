---
title: Steppers
description: A stepper is a two-segment control that people use to increase or decrease an incremental value.
source: https://developer.apple.com/design/human-interface-guidelines/steppers
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/design/human-interface-guidelines/steppers.json
timestamp: 2026-04-14T13:14:22.391Z
---

**Navigation:** [Human Interface Guidelines](/design/human-interface-guidelines)

**article**

# Steppers

> A stepper is a two-segment control that people use to increase or decrease an incremental value.

![A stylized representation of a stepper control. The image is tinted red to subtly reflect the red in the original six-color Apple logo.](https://docs-assets.developer.apple.com/published/78add8837be3be97de897bf330b30ec9/components-stepper-intro%402x.png)

A stepper sits next to a field that displays its current value, because the stepper itself doesn’t display a value.

## Best practices

**Make the value that a stepper affects obvious.** A stepper itself doesn’t display any values, so make sure people know which value they’re changing when they use a stepper.

**Consider pairing a stepper with a text field when large value changes are likely.** Steppers work well by themselves for making small changes that require a few taps or clicks. By contrast, people appreciate the option to use a field to enter specific values, especially when the values they use can vary widely. On a printing screen, for example, it can help to have both a stepper and a text field to set the number of copies.

## Platform considerations

*No additional considerations for iOS, iPadOS, or visionOS. Not supported in watchOS or tvOS.*

### macOS

**For large value ranges, consider supporting Shift-click to change the value quickly.** If your app benefits from larger changes in a stepper’s value, it can be useful to let people Shift-click the stepper to change the value by more than the default increment (by 10 times the default, for example).

## Resources

#### Related

[Pickers](/design/human-interface-guidelines/pickers)

[Text fields](/design/human-interface-guidelines/text-fields)

#### Developer documentation

[UIStepper](/documentation/UIKit/UIStepper) — UIKit

[NSStepper](/documentation/AppKit/NSStepper) — AppKit

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All Human Interface Guidelines belong to Apple Inc.*
