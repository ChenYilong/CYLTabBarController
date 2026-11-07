---
title: Feedback
description: Feedback helps people know what’s happening, discover what they can do next, understand the results of actions, and avoid mistakes.
source: https://developer.apple.com/design/human-interface-guidelines/feedback
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/design/human-interface-guidelines/feedback.json
timestamp: 2026-04-14T13:14:14.446Z
---

**Navigation:** [Human Interface Guidelines](/design/human-interface-guidelines)

**article**

# Feedback

> Feedback helps people know what’s happening, discover what they can do next, understand the results of actions, and avoid mistakes.

![A sketch of a pointer surrounded by a circular set of short lines, suggesting a response to a mouse click. The image is overlaid with rectangular and circular grid lines and is tinted orange to subtly reflect the orange in the original six-color Apple logo.](https://docs-assets.developer.apple.com/published/d7e2c91a509e05b5e8ee422c6fea86b3/patterns-feedback-intro%402x.png)

Providing clear, consistent feedback as people interact with your app or game can make it feel intuitive and encourage deeper exploration. Feedback can communicate several different things, such as:

- The current status of something
- The success or failure of an important task or action
- A warning about an action that can have negative consequences
- An opportunity to correct a mistake or problematic situation

The most effective feedback tends to match the significance of the information to the way it’s delivered. For example, it often works well to display status information in a passive way so that people can view it when they need it. In contrast, a warning about possible data loss needs to interrupt people so they have a chance to avoid the problem.

## Best practices

**Make sure all feedback is accessible.** When you use multiple ways to provide feedback, you reach more people and give them the opportunity to receive the feedback in ways that work for them. For example, when you provide feedback using color, text, sound, and haptics, people can receive it whether they silence their device, look away from the screen, or use VoiceOver. (For guidance on providing haptic feedback, see [Playing haptics](/design/human-interface-guidelines/playing-haptics).)

**Consider integrating status feedback into your interface.** When status feedback is available near the items it describes, people get important information without having to take action or leave their current context. For example, Mail in iOS and iPadOS describes the most recent update and displays the number of unread messages in the toolbar of the mailbox screen, making the information unobtrusive but easy for people to check when they’re interested.

**Use alerts to deliver critical — and ideally actionable — information.** By design, alerts disrupt the current context, so you need to match the importance of the information to the level of interruption. Alerts can lose their impact if you use them too often or to deliver unimportant information. For guidance, see [Alerts](/design/human-interface-guidelines/alerts).

**Warn people when they initiate a task that can cause data loss that’s unexpected and irreversible.** In contrast, don’t warn people when data loss is the expected result of their action. For example, the Finder doesn’t warn people every time they throw away a file because deleting the file is the expected result.

**When it makes sense, confirm that a significant action or task has completed.** For example, people appreciate getting feedback that confirms a successful Apple Pay transaction. It’s generally best to reserve this type of confirmation for activities that are sufficiently important — because people typically expect their action or task to succeed, they only need to know when it doesn’t.

**Show people when a command can’t be carried out and help them understand why.** For example, if people request directions without specifying a destination, Maps tells them that it can’t provide directions to and from the same location.

## Platform considerations

*No additional considerations for iOS, iPadOS, macOS, tvOS, or visionOS.*

### watchOS

**Avoid displaying an indeterminate progress indicator — such as a loading indicator — in a watchOS app.** An animated indicator can make people think they need to continue paying attention to the display, which isn’t a good user experience. To provide a better experience, reassure people that they’ll receive a notification when the process completes.

## Resources

#### Related

[Playing audio](/design/human-interface-guidelines/playing-audio)

[Playing haptics](/design/human-interface-guidelines/playing-haptics)

[Motion](/design/human-interface-guidelines/motion)

#### Developer documentation

[Animation and haptics](/documentation/UIKit/animation-and-haptics) — UIKit

#### Videos

- [Designing Fluid Interfaces](https://developer.apple.com/videos/play/wwdc2018/803) - Discover the techniques used to create the fluid gestural interface of iPhone X. Learn how to design with gestures and motion that feel intuitive and natural, making your app a delight to use.
- [Essential Design Principles](https://developer.apple.com/videos/play/wwdc2017/802) - Design principles are the key to understanding how design serves human needs for safety, meaning, achievement and beauty. Learn what these principles are and how they can help you design more welcoming, understandable, empowering and gratifying user experiences.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All Human Interface Guidelines belong to Apple Inc.*
