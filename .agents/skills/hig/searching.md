---
title: Searching
description: People use various search techniques to find content on their device, within an app, and within a document or file.
source: https://developer.apple.com/design/human-interface-guidelines/searching
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/design/human-interface-guidelines/searching.json
timestamp: 2026-06-26T06:39:36.282Z
---

**Navigation:** [Human Interface Guidelines](/design/human-interface-guidelines)

**article**

# Searching

> People use various search techniques to find content on their device, within an app, and within a document or file.

![A sketch of a magnifying glass, suggesting the search for information. The image is overlaid with rectangular and circular grid lines and is tinted orange to subtly reflect the orange in the original six-color Apple logo.](https://docs-assets.developer.apple.com/published/d80bc4d95013730b824dc7956f912b4d/patterns-searching-intro%402x.png)

To search for content within an app, people generally expect to use a [Search fields](/design/human-interface-guidelines/search-fields). When it makes sense, you can personalize the search experience by using what you know about how people interact with your app. For example, you might display recent searches, search suggestions, completions, or corrections based on terms people searched earlier in your app.

In some cases, people appreciate the ability to scope a search or filter the results. For example, people might want to search for items by specifying attributes like creation date, file size, or file type. For guidance, see [Scope bars and tokens](/design/human-interface-guidelines/search-fields#Scope-bars-and-tokens). You can also help people find content within an open document or file by implementing ways to find content in a window or page in your iOS, iPadOS, or macOS app.

In iOS, iPadOS, and macOS, Spotlight helps people find content across all apps in the system and on the web. When you index and provide information about your app’s content, people can use Spotlight to find content your app contains without opening it first. For guidance, see [Systemwide search](/design/human-interface-guidelines/searching#Systemwide-search).

## Best practices

**If search is important, give it a primary position in your app or view.** For example, in the Notes app, a search field is in the bottom toolbar alongside other important actions. In apps that use tab bars, like Photos and Apple TV, search is a dedicated tab.

**Aim to make your app’s content searchable through a single location.** People appreciate having one clearly identified location they can use to find anything they’re looking for in your app. For apps with clearly distinct sections, it may still be useful to offer a local search. For example, search acts as a filter on the current view when searching your songs and albums in the iOS Music app.

**Clearly display the current scope of a search.** Use a descriptive placeholder text, a [Scope bars and tokens](/design/human-interface-guidelines/search-fields#Scope-bars-and-tokens), or a title to help reinforce what someone is currently searching. For example, in the Mail app there is always a clear reference to the mailbox someone is searching.

**Provide suggestions to make searching easier.** When you display a personʼs recent searches before they start typing or offer predictive search suggestions while they’re typing, you can help people search faster and type less. For developer guidance, see [searchSuggestions(_:)](/documentation/SwiftUI/View/searchSuggestions(_:)).

**Take privacy into consideration before displaying search history.** People might not appreciate having their search history appear where others might see it. If you do show search history, provide a way for people to clear it if they want.

## Systemwide search

**Make your app’s content searchable in Spotlight.** You can share content with Spotlight by making it indexable and specifying descriptive attributes known as *metadata*. Spotlight extracts, stores, and organizes this information to allow for fast, comprehensive searches.

**Define metadata for custom file types you handle.** Supply a Spotlight File Importer plug-in that describes the types of metadata your file format contains. For developer guidance, see [CSImportExtension](/documentation/CoreSpotlight/CSImportExtension).

**Use Spotlight to offer advanced file-search capabilities within the context of your app.** For example, you might include a button that instantly initiates a Spotlight search based on the current selection. You might then display a custom view that presents the search results or a filtered subset of them.

**Prefer using the system-provided open and save views.** The system-provided open and save views generally include a built-in search field that people can use to search and filter the entire system. For related guidance, see [File management](/design/human-interface-guidelines/file-management).

**Implement a Quick Look generator if your app produces custom file types.** A Quick Look generator helps Spotlight and other apps show previews of your documents. For developer guidance, see [Quick Look](/documentation/QuickLook).

## Platform considerations

*No additional considerations for iOS, iPadOS, macOS, tvOS, visionOS, or watchOS.*

## Resources

#### Related

[Search fields](/design/human-interface-guidelines/search-fields)

#### Developer documentation

[Adding your app’s content to Spotlight indexes](/documentation/CoreSpotlight/adding-your-app-s-content-to-spotlight-indexes) — Core Spotlight

#### Videos

- [Design intuitive search experiences](https://developer.apple.com/videos/play/wwdc2026/292) - Explore new patterns and best practices when implementing search in your app. Discover how search plays a key role in helping people find and navigate content, and find out how to integrate search across different navigation models and Apple platforms.

## Change log

| Date | Changes |
| --- | --- |
| June 8, 2026 | Updated terminology and refined best practices. |
| June 9, 2025 | Updated best practices with general guidance from Search fields, and reorganized guidance for systemwide search. |

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All Human Interface Guidelines belong to Apple Inc.*
