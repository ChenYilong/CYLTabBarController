---
title: UIButton
description: A control that executes your custom code in response to user interactions.
source: https://developer.apple.com/documentation/uikit/uibutton
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/documentation/uikit/uibutton.json
timestamp: 2026-06-26T06:39:36.929Z
---

**Navigation:** [UIKit](/documentation/uikit)

**Class**

# UIButton

**Available on:** iOS 2.0+, iPadOS 2.0+, Mac Catalyst 13.1+, tvOS, visionOS 1.0+

> A control that executes your custom code in response to user interactions.

```swift
@MainActor class UIButton
```

## Overview

When you tap a button, or select a button that has focus, the button performs any actions attached to it. You communicate the purpose of a button using a text label, an image, or both. The appearance of buttons is configurable, so you can tint buttons or format titles to match the design of your app. You can add buttons to your interface programmatically or using Interface Builder.

![A screenshot showing three buttons. The first button shows the label “Button”. The second button shows an image of a plus sign in a circle. The third button shows an image of a lowercase “i” in a circle.](https://docs-assets.developer.apple.com/published/abe7c4c3472254b2d40bb7dc8bfb8d5b/media-2557338.png)

When adding a button to your interface, perform the following steps:

- Set the type of the button at creation time.
- Supply a title string or image; size the button appropriately for your content.
- Connect one or more action methods to the button.
- Set up Auto Layout rules to govern the size and position of the button in your interface.
- Provide accessibility information and localized strings.

> **Important:** An app built with Mac Catalyst running in macOS 11 throws an exception when calling a button’s [addGestureRecognizer(_:)](/documentation/uikit/uiview/addgesturerecognizer(_:)) method when [buttonType](/documentation/uikit/uibutton/buttontype-swift.property) is [UIButton.ButtonType.system](/documentation/uikit/uibutton/buttontype-swift.enum/system) and the user interface idiom is [UIUserInterfaceIdiom.mac](/documentation/uikit/uiuserinterfaceidiom/mac).

### Respond to button taps

Buttons use the target-action design pattern to notify your app when the user taps the button. Rather than handle touch events directly, you assign action methods to the button and designate which events trigger calls to your methods. At runtime, the button handles all incoming touch events and calls your methods in response.

You connect a button to your action method using the [addTarget(_:action:for:)](/documentation/uikit/uicontrol/addtarget(_:action:for:)) method or by creating a connection in Interface Builder. The signature of an action method takes one of three forms, as shown in the following code. Choose the form that provides the information that you need to respond to the button tap.

### Swift

```swift
@IBAction func doSomething()
@IBAction func doSomething(sender: UIButton)
@IBAction func doSomething(sender: UIButton, forEvent event: UIEvent)
```

### Objective-C

```objc
- (IBAction)doSomething;
- (IBAction)doSomething:(id)sender;
- (IBAction)doSomething:(id)sender forEvent:(UIEvent*)event;
```

### Configure a button’s appearance

A button’s type defines its basic appearance and behavior. You specify the type of a button at creation time using the [init(type:)](/documentation/uikit/uibutton/init(type:)) method or in your storyboard file. After creating a button, you can’t change its type. The most commonly used button types are the Custom and System types, but use the other types when appropriate.

> **Note:** To configure the appearance of all buttons in your app, use the appearance proxy object. The [UIButton](/documentation/uikit/uibutton) class implements the [appearance()](/documentation/uikit/uiappearance/appearance()) class method, which you can use to fetch the appearance proxy for all buttons in your app.

#### Configure button states

Buttons have five states that define their appearance: default, highlighted, focused, selected, and disabled. When you add a button to your interface, it’s in the default state initially, which means the button is enabled and the user isn’t interacting with it. As the user interacts with the button, its state changes to the other values. For example, when the user taps a button with a title, the button moves to the highlighted state.

When configuring a button either programmatically or in Interface Builder, you specify attributes for each state separately. In Interface Builder, use the State Config control in the Attributes inspector to choose the appropriate state and then configure the other attributes. If you don’t specify attributes for a particular state, the [UIButton](/documentation/uikit/uibutton) class provides a reasonable default behavior. For example, a disabled button is normally dimmed and doesn’t display a highlight when tapped. Other properties of this class, such as the [adjustsImageWhenHighlighted](/documentation/uikit/uibutton/adjustsimagewhenhighlighted) and [adjustsImageWhenDisabled](/documentation/uikit/uibutton/adjustsimagewhendisabled) properties, let you alter the default behavior in specific cases.

#### Provide content

The content of a button consists of a title string or image that you specify. The content you specify is used to configure the [UILabel](/documentation/uikit/uilabel) and [UIImageView](/documentation/uikit/uiimageview) object managed by the button itself. You can access these objects using the [titleLabel](/documentation/uikit/uibutton/titlelabel) or [imageView](/documentation/uikit/uibutton/imageview) properties and modify their values directly. The methods of this class also provide a convenient shortcut for configuring the appearance of your string or image.

Normally, you configure a button using either a title or an image and size the button accordingly. Buttons can also have a background image, which is positioned behind the content you specify. It’s possible to specify both an image and a title for buttons, which results in the appearance shown in the following image. You can access the current content of a button using the indicated properties.

![Providing a title and image for a button.](https://docs-assets.developer.apple.com/published/b18fd0e1e20cf9a7e61095bb304cda2c/media-3081016%402x.png)

When setting the content of a button, you must specify the title, image, and appearance attributes for each state separately. If you don’t customize the content for a particular state, the button uses the values associated with the Default state and adds any appropriate customizations. For example, in the highlighted state, an image-based button draws a highlight on top of the default image if no custom image is provided.

#### Customize tint color

You can specify a custom button tint using the [tintColor](/documentation/uikit/uibutton/tintcolor) property. This property sets the color of the button image and text. If you don’t explicitly set a tint color, the button uses its superview’s tint color.

#### Specify edge insets

Use insets to add or remove space around the content in your custom or system buttons. You can specify separate insets for your button’s title ([titleEdgeInsets](/documentation/uikit/uibutton/titleedgeinsets)), image ([imageEdgeInsets](/documentation/uikit/uibutton/imageedgeinsets)), and both the title and image together ([contentEdgeInsets](/documentation/uikit/uibutton/contentedgeinsets)). When applied, insets affect the corresponding content rectangle of the button, which the Auto Layout engine uses to determine the button’s position.

There should be no reason for you to adjust the edge insets for info, contact, or disclosure buttons.

### Configure button attributes in Interface Builder

The following table lists the core attributes that you configure for buttons in Interface Builder.

| Attribute | Description |
| --- | --- |
| Type | The button type. This attribute determines the default settings for many other button attributes. The value of this attribute can’t be changed at runtime, but you can access it using the [buttonType](/documentation/uikit/uibutton/buttontype-swift.property) property. |
| State Config | The state selector. After selecting a value in this control, changes to the button’s attributes apply to the specified state. |
| Title | The button’s title. You can specify a button’s title as a plain string or attributed string. |
| (Title Font and Attributes) | The font and other attributes to apply to the button’s title string. The specific configuration options depends on whether you specified a plain string or attributed string for the button’s title. For a plain string, you can customize the font, text color, and shadow color. For an attributed string, you can specify alignment, text direction, indentation, hyphenation, and many other options. |
| Image | The button’s foreground image. Typically, you use template images for a button’s foreground, but you may specify any image in your Xcode project. |
| Background | The button’s background image. The background image is displayed behind its title and foreground image. |

The following table lists attributes that affect the button’s appearance.

| Attribute | Description |
| --- | --- |
| Shadow Offset | The offsets and behavior of the button’s shadow. Shadows affect title strings only. Enable the Reverses on Highlight option to change the highlighting of the shadow when the button state changes to or from the highlighted state. ![Image](https://docs-assets.developer.apple.com/published/67dc4b07a8d84366d4cc0e812eb40b4a/spacer.png) Configure the offsets programmatically using the [shadowOffset](/documentation/uikit/uilabel/shadowoffset) property of the button’s [titleLabel](/documentation/uikit/uibutton/titlelabel) object. Configure the highlighting behavior using the [reversesTitleShadowWhenHighlighted](/documentation/uikit/uibutton/reversestitleshadowwhenhighlighted) property. |
| Drawing | The drawing behavior of the button. ![Image](https://docs-assets.developer.apple.com/published/67dc4b07a8d84366d4cc0e812eb40b4a/spacer.png) When the Shows Touch On Highlight ([showsTouchWhenHighlighted](/documentation/uikit/uibutton/showstouchwhenhighlighted)) option is enabled, the button adds a white glow to the part of a button that the user touches. ![Image](https://docs-assets.developer.apple.com/published/67dc4b07a8d84366d4cc0e812eb40b4a/spacer.png) When the Highlighted Adjusts Image ([adjustsImageWhenHighlighted](/documentation/uikit/uibutton/adjustsimagewhenhighlighted)) option is enabled, button images get darker when it’s in the highlighted state. ![Image](https://docs-assets.developer.apple.com/published/67dc4b07a8d84366d4cc0e812eb40b4a/spacer.png) When the Disabled Adjusts Image ([adjustsImageWhenDisabled](/documentation/uikit/uibutton/adjustsimagewhendisabled)) option is enabled, the image is dimmed when the button is disabled. |
| Line Break | The line breaking options for the button’s text. Use this attribute to define how the button’s title is modified to fit the available space. |

The following table lists the edge inset attributes for buttons. Use edge inset buttons to alter the rectangle for the button’s content.

| Attribute | Description |
| --- | --- |
| Edge | The edge insets to configure. You can specify separate edge insets for the button’s overall content, its title, and its image. |
| Inset | The inset values. Positive values shrink the corresponding edge, moving it closer to the center of the button. Negative values expand the edge, moving it away from the center of the button. Access these values at runtime using the [contentEdgeInsets](/documentation/uikit/uibutton/contentedgeinsets), [titleEdgeInsets](/documentation/uikit/uibutton/titleedgeinsets), and [imageEdgeInsets](/documentation/uikit/uibutton/imageedgeinsets) properties. |

For information about the button’s inherited Interface Builder attributes, see [UIControl](/documentation/uikit/uicontrol) and [UIView](/documentation/uikit/uiview).

### Support localization

To internationalize a button, specify a localized string for the button’s title text. (You may also localize a button’s image as appropriate.)

When using storyboards to build your interface, use Xcode’s base internationalization feature to configure the localizations your project supports. When you add a localization, Xcode creates a strings file for that localization. When configuring your interface programmatically, use the system’s built-in support for loading localized strings and resources. For more information about internationalizing your interface, see [Internationalization and Localization Guide](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/Introduction/Introduction.html#//apple_ref/doc/uid/10000171i).

### Make buttons accessible

Buttons are accessible by default. The default accessibility traits for a button are Button and User Interaction Enabled.

The accessibility label, traits, and hint are spoken back to the user when VoiceOver is enabled on a device. The button’s title overwrites its accessibility label; even if you set a custom value for the label, VoiceOver speaks the value of the title. VoiceOver speaks this information when a user taps the button once. For example, when a user taps the Options button in Camera, VoiceOver speaks the following:

- `"Options. Button. Shows additional camera options."`

For more information about making iOS controls accessible, see the accessibility information in [UIControl](/documentation/uikit/uicontrol). For general information about making your interface accessible, see [Accessibility Programming Guide for iOS](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/iPhoneAccessibility/Introduction/Introduction.html#//apple_ref/doc/uid/TP40008785).

## Inherits From

- [UIControl](/documentation/uikit/uicontrol)

## Conforms To

- [CALayerDelegate](/documentation/QuartzCore/CALayerDelegate)
- [CLBodyIdentifiable](/documentation/CoreLocation/CLBodyIdentifiable)
- [CMBodyIdentifiable](/documentation/CoreMotion/CMBodyIdentifiable)
- [CVarArg](/documentation/Swift/CVarArg)
- [Copyable](/documentation/Swift/Copyable)
- [CustomDebugStringConvertible](/documentation/Swift/CustomDebugStringConvertible)
- [CustomStringConvertible](/documentation/Swift/CustomStringConvertible)
- [Equatable](/documentation/Swift/Equatable)
- [Escapable](/documentation/Swift/Escapable)
- [Hashable](/documentation/Swift/Hashable)
- [NSCoding](/documentation/Foundation/NSCoding)
- [NSObjectProtocol](/documentation/ObjectiveC/NSObjectProtocol)
- [NSTouchBarProvider](/documentation/AppKit/NSTouchBarProvider)
- [Sendable](/documentation/Swift/Sendable)
- [SendableMetatype](/documentation/Swift/SendableMetatype)
- [UIAccessibilityContentSizeCategoryImageAdjusting](/documentation/uikit/uiaccessibilitycontentsizecategoryimageadjusting)
- [UIAccessibilityIdentification](/documentation/uikit/uiaccessibilityidentification)
- [UIActivityItemsConfigurationProviding](/documentation/uikit/uiactivityitemsconfigurationproviding)
- [UIAppearance](/documentation/uikit/uiappearance)
- [UIAppearanceContainer](/documentation/uikit/uiappearancecontainer)
- [UIContextMenuInteractionDelegate](/documentation/uikit/uicontextmenuinteractiondelegate)
- [UICoordinateSpace](/documentation/uikit/uicoordinatespace)
- [UIDynamicItem](/documentation/uikit/uidynamicitem)
- [UIFocusEnvironment](/documentation/uikit/uifocusenvironment)
- [UIFocusItem](/documentation/uikit/uifocusitem)
- [UIFocusItemContainer](/documentation/uikit/uifocusitemcontainer)
- [UILargeContentViewerItem](/documentation/uikit/uilargecontentvieweritem)
- [UIPasteConfigurationSupporting](/documentation/uikit/uipasteconfigurationsupporting)
- [UIPopoverPresentationControllerSourceItem](/documentation/uikit/uipopoverpresentationcontrollersourceitem)
- [UIResponderStandardEditActions](/documentation/uikit/uiresponderstandardeditactions)
- [UISpringLoadedInteractionSupporting](/documentation/uikit/uispringloadedinteractionsupporting)
- [UITraitChangeObservable](/documentation/uikit/uitraitchangeobservable-67e94)
- [UITraitEnvironment](/documentation/uikit/uitraitenvironment)
- [UIUserActivityRestoring](/documentation/uikit/uiuseractivityrestoring)

## Creating buttons

- [init(frame:)](/documentation/uikit/uibutton/init(frame:)) Creates a new button with the specified frame.
- [init(frame:primaryAction:)](/documentation/uikit/uibutton/init(frame:primaryaction:)) Creates a new button with the specified frame, registers the primary action event, and sets the title and image to the action’s title and image.
- [init(coder:)](/documentation/uikit/uibutton/init(coder:)) Creates a new button with data in an unarchiver.

## Creating buttons of a specific type

- [init(type:)](/documentation/uikit/uibutton/init(type:)) Creates and returns a new button of the specified type.
- [init(type:primaryAction:)](/documentation/uikit/uibutton/init(type:primaryaction:)) Creates a new button with the specified type, registers the primary action event, and sets the title and image to the action’s title and image.
- [UIButton.ButtonType](/documentation/uikit/uibutton/buttontype-swift.enum) Specifies the style of a button.

## Creating system buttons

- [systemButton(with:target:action:)](/documentation/uikit/uibutton/systembutton(with:target:action:)) Creates and returns a system type button with specified image, target, and action.

## Creating buttons from a configuration object

- [init(configuration:primaryAction:)](/documentation/uikit/uibutton/init(configuration:primaryaction:)) Creates a new button with the specified configuration and registers the primary action event.
- [UIButton.Configuration](/documentation/uikit/uibutton/configuration-swift.struct) A configuration that specifies the appearance and behavior of a button and its contents.

## Managing the appearance with a configuration object

- [configuration](/documentation/uikit/uibutton/configuration-5rlyb) The configuration for the button’s appearance.
- [automaticallyUpdatesConfiguration](/documentation/uikit/uibutton/automaticallyupdatesconfiguration) A Boolean value that determines whether the button configuration changes when button’s state changes.
- [setNeedsUpdateConfiguration()](/documentation/uikit/uibutton/setneedsupdateconfiguration()) Requests the system update the button configuration.
- [updateConfiguration()](/documentation/uikit/uibutton/updateconfiguration()) Updates the button configuration in response to a button state change.
- [configurationUpdateHandler](/documentation/uikit/uibutton/configurationupdatehandler-swift.property) A closure that executes when the button state changes.
- [UIButton.ConfigurationUpdateHandler](/documentation/uikit/uibutton/configurationupdatehandler-swift.typealias) A closure to update the configuration of a button.

## Managing the title

- [titleLabel](/documentation/uikit/uibutton/titlelabel) A view that displays the value of the `currentTitle` property for a button.
- [title(for:)](/documentation/uikit/uibutton/title(for:)) Returns the title associated with the specified state.
- [setTitle(_:for:)](/documentation/uikit/uibutton/settitle(_:for:)) Sets the title to use for the specified state.
- [attributedTitle(for:)](/documentation/uikit/uibutton/attributedtitle(for:)) Returns the styled title associated with the specified state.
- [setAttributedTitle(_:for:)](/documentation/uikit/uibutton/setattributedtitle(_:for:)) Sets the styled title to use for the specified state.
- [titleColor(for:)](/documentation/uikit/uibutton/titlecolor(for:)) Returns the title color used for a state.
- [setTitleColor(_:for:)](/documentation/uikit/uibutton/settitlecolor(_:for:)) Sets the color of the title to use for the specified state.
- [titleShadowColor(for:)](/documentation/uikit/uibutton/titleshadowcolor(for:)) Returns the shadow color of the title used for a state.
- [setTitleShadowColor(_:for:)](/documentation/uikit/uibutton/settitleshadowcolor(_:for:)) Sets the color of the title shadow to use for the specified state.

## Managing images and tint color

- [backgroundImage(for:)](/documentation/uikit/uibutton/backgroundimage(for:)) Returns the background image used for a button state.
- [image(for:)](/documentation/uikit/uibutton/image(for:)) Returns the image used for a button state.
- [setBackgroundImage(_:for:)](/documentation/uikit/uibutton/setbackgroundimage(_:for:)) Sets the background image to use for the specified button state.
- [setImage(_:for:)](/documentation/uikit/uibutton/setimage(_:for:)) Sets the image to use for the specified state.
- [preferredSymbolConfigurationForImage(in:)](/documentation/uikit/uibutton/preferredsymbolconfigurationforimage(in:)) Returns the preferred symbol configuration for a button state.
- [setPreferredSymbolConfiguration(_:forImageIn:)](/documentation/uikit/uibutton/setpreferredsymbolconfiguration(_:forimagein:)) Sets the preferred symbol configuration for a button state.
- [tintColor](/documentation/uikit/uibutton/tintcolor) The tint color to apply to the button title and image.

## Specifying the role

- [role](/documentation/uikit/uibutton/role-swift.property) The role of the button.
- [UIButton.Role](/documentation/uikit/uibutton/role-swift.enum) Constants that describe the role of the button.

## Specifying the behavioral style

- [behavioralStyle](/documentation/uikit/uibutton/behavioralstyle) The style that determines how the button behaves.
- [preferredBehavioralStyle](/documentation/uikit/uibutton/preferredbehavioralstyle) The preferred behavioral style.
- [UIBehavioralStyle](/documentation/uikit/uibehavioralstyle) Constants that indicate how a control behaves in apps built with Mac Catalyst.

## Getting the current state

- [buttonType](/documentation/uikit/uibutton/buttontype-swift.property) The button type.
- [currentTitle](/documentation/uikit/uibutton/currenttitle) The current title that is displayed on the button.
- [currentAttributedTitle](/documentation/uikit/uibutton/currentattributedtitle) The current styled title that is displayed on the button.
- [currentTitleColor](/documentation/uikit/uibutton/currenttitlecolor) The color used to display the title.
- [currentTitleShadowColor](/documentation/uikit/uibutton/currenttitleshadowcolor) The color of the title’s shadow.
- [currentImage](/documentation/uikit/uibutton/currentimage) The current image displayed on the button.
- [currentBackgroundImage](/documentation/uikit/uibutton/currentbackgroundimage) The current background image displayed on the button.
- [currentPreferredSymbolConfiguration](/documentation/uikit/uibutton/currentpreferredsymbolconfiguration) The current symbol size, style, and weight.
- [imageView](/documentation/uikit/uibutton/imageview) The button’s image view.
- [subtitleLabel](/documentation/uikit/uibutton/subtitlelabel) The label that displays the text of the subtitle.

## Supporting pointer interactions

- [isPointerInteractionEnabled](/documentation/uikit/uibutton/ispointerinteractionenabled) A Boolean that enables pointer interaction.
- [isHovered](/documentation/uikit/uibutton/ishovered) A Boolean value that indicates whether a pointer effect is active.
- [pointerStyleProvider](/documentation/uikit/uibutton/pointerstyleprovider-y4eb) A closure that returns the pointer style to use when the pointer hovers over the button.
- [UIButton.PointerStyleProvider](/documentation/uikit/uibutton/pointerstyleprovider-swift.typealias) A type alias defining a closure that returns a pointer style to apply to a button.
- [UIButtonPointerStyleProvider](/documentation/uikit/uibuttonpointerstyleprovider) A type alias defining a block that returns a pointer style to apply to a button.

## Supporting menu and toggle buttons

- [menu](/documentation/uikit/uibutton/menu) A menu that the button displays.
- [isHeld](/documentation/uikit/uibutton/isheld) A Boolean value that indicates whether the button menu is visible.
- [changesSelectionAsPrimaryAction](/documentation/uikit/uibutton/changesselectionasprimaryaction) A Boolean value that indicates whether the button tracks a selection, either through a menu or a toggle.
- [preferredMenuElementOrder](/documentation/uikit/uibutton/preferredmenuelementorder) The preferred menu-element ordering strategy for the menu.

## Deprecated

- [Deprecated symbols](/documentation/uikit/uibutton-deprecated-symbols) Symbols that buttons no longer support.

## Controls

- [Responding to control-based events using target-action](/documentation/uikit/responding-to-control-based-events-using-target-action) Handle user input by connecting buttons, sliders, and other controls to your app’s code using the target-action design pattern.
- [UIControl](/documentation/uikit/uicontrol) The base class for controls, which are visual elements that convey a specific action or intention in response to user interactions.
- [UIColorWell](/documentation/uikit/uicolorwell) A control that displays a color picker.
- [UIDatePicker](/documentation/uikit/uidatepicker) A control for inputting date and time values.
- [UIPageControl](/documentation/uikit/uipagecontrol) A control that displays a horizontal series of dots, each of which corresponds to a page in the app’s document or other data-model entity.
- [UISegmentedControl](/documentation/uikit/uisegmentedcontrol) A horizontal control that consists of multiple segments, each segment functioning as a discrete button.
- [UISlider](/documentation/uikit/uislider) A control for selecting a single value from a continuous range of values.
- [UIStepper](/documentation/uikit/uistepper) A control for incrementing or decrementing a value.
- [UISwitch](/documentation/uikit/uiswitch) A control that offers a binary choice, such as on/off.

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
