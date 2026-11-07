---
title: Onboarding
description: Onboarding can help people get a quick start using your app or game.
source: https://developer.apple.com/design/human-interface-guidelines/onboarding
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/design/human-interface-guidelines/onboarding.json
timestamp: 2026-04-14T13:14:18.327Z
---

**Navigation:** [Human Interface Guidelines](/design/human-interface-guidelines)

**article**

# Onboarding

> Onboarding can help people get a quick start using your app or game.

![A sketch of a waving hand, suggesting a gesture of welcoming. The image is overlaid with rectangular and circular grid lines and is tinted orange to subtly reflect the orange in the original six-color Apple logo.](https://docs-assets.developer.apple.com/published/044d56043e30ee77f306a8613041311b/patterns-onboarding-intro%402x.png)

Ideally, people can understand your app or game simply by experiencing it, but if onboarding is necessary, design a flow that’s fast, fun, and optional. When available, onboarding occurs after [Launching](/design/human-interface-guidelines/launching) is complete — it isn’t part of the launch experience.

## Best practices

**Teach through interactivity.** People tend to grasp and retain information better when they can actually perform the task they’re learning about instead of just viewing instructional material. As much as possible, provide an interactive onboarding experience where people can safely test an action, discover a feature, or try out a game mechanic.

**Consider providing a collection of context-specific tips instead of a single onboarding flow.** Integrating contextually relevant tips into your experience can help people learn about their current task while they make progress in your app or game. A context-specific tip can also help people learn better because it lets them concentrate on a single action or task before encountering new information. When you have instructional content that refers to a specific area of the interface, display these instructions near that area. For developer guidance, see [TipKit](/documentation/TipKit).

**If you need to present a prerequisite onboarding flow, design a brief, enjoyable experience that doesn’t require people to memorize a lot of information.** When onboarding is quick and entertaining, people are more likely to complete it. In contrast, if you try to teach too much, people can feel overwhelmed and may be less likely to remember what they learned.

**If it makes sense to offer a separate tutorial, consider making it optional.** If you let people skip the tutorial when they first launch your app or game, don’t present it again on subsequent launches, but make sure it’s easy for people to find if they want to view it later. For example, you could make the tutorial available in a help, account, or settings area within your app or game.

**Keep onboarding content focused on the experience you provide.** People enter your onboarding flow to learn about your app or game; they don’t need to learn how to use the system or the device.

## Additional content

**Briefly display a splash screen if necessary.** If you need to include a splash screen, design a beautiful graphic that communicates succinctly. Aim to display your splash screen just long enough for people to absorb the information at a glance without feeling that it’s delaying their experience.

**Don’t let large downloads hinder onboarding.** People want to start using your app or game immediately after first launching it, whether they participate in an onboarding flow or skip it. Consider including enough media and other content in your software package to prevent people from having to wait for downloads to complete before they can start interacting with your app or game. For guidance, see [Launching](/design/human-interface-guidelines/launching).

**Avoid displaying licensing details within your onboarding flow.** Let the App Store display agreements and disclaimers so people can read them before downloading your app or game. If you must include these items within the onboarding flow, integrate them in a balanced way that doesn’t disrupt the experience.

## Additional requests

**Postpone nonessential setup flows or customization steps.** Provide reasonable default settings so most people can immediately start interacting with your app or game without performing additional configuration.

**If your app or game needs access to private data or resources before it can function, consider integrating the permission request into your onboarding flow.** In this scenario, making the request during your onboarding flow gives you the opportunity to show people why your app or game needs their permission and the benefits of granting it. Otherwise, present a permission request when people first access the specific function that relies on private data or resources. For guidance, see [Requesting permission](/design/human-interface-guidelines/privacy#Requesting-permission).

**Prefer letting people experience your app or game before prompting them for ratings or purchases.** People can be more likely to respond positively to such requests when they’ve had a chance to become engaged with your app or game.

## Platform considerations

*No additional considerations for iOS, iPadOS, macOS, tvOS, visionOS, or watchOS.*

## Resources

#### Related

[Launching](/design/human-interface-guidelines/launching)

[Feedback](/design/human-interface-guidelines/feedback)

[Offering help](/design/human-interface-guidelines/offering-help)

#### Videos

- [Discoverable design](https://developer.apple.com/videos/play/wwdc2021/10126) - Discover how you can create interactive, memorable experiences to onboard people into your app. We’ll take you through discoverable design practices and learn how you can craft explorable, fun interfaces that help people grasp the possibilities of your app at a glance. We’ll also show you how to apply this methodology to personalize your content and make your app easy to customize.
- [Designing Award Winning Apps and Games](https://developer.apple.com/videos/play/wwdc2019/802) - Through stories, interviews, and artifacts we will uncover valuable design processes, techniques, and best practices of Apple Design Award winning apps and games.
- [Love at First Launch](https://developer.apple.com/videos/play/wwdc2017/816) - Engage people from the first moment they open your app, and keep them coming back for more. Learn tips on how to make a compelling first impression, methods for teaching new users about your app, and best practices when asking users for more information.

## Change log

| Date | Changes |
| --- | --- |
| June 10, 2024 | Clarified different approaches to onboarding and added a guideline on displaying a splash screen. |
| June 21, 2023 | Updated to include guidance for visionOS. |

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All Human Interface Guidelines belong to Apple Inc.*
