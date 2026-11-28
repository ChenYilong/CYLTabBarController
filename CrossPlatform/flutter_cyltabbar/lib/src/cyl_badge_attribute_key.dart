/// The style keys of a badge, the same strings as iOS' `CYLBadgeAttributeKey` and the host view's `badgeAttributes`
/// (docs/Animated-Item-Badge-CrossPlatform.md, phase 2). Values are numbers or strings (`#RRGGBB` colors, `{x, y}` offsets);
/// the native side ignores unknown keys and types.
///
/// Written statically, not run on a device yet.
class CYLBadgeAttributeKey {
  const CYLBadgeAttributeKey._();

  /// The badge text.
  static const value = 'value';

  /// The background color.
  static const color = 'color';

  /// One of the 10 names: `none`, `scale`, `shake`, `bounce`, `breathe`, `leftRightOnce`, `rightLeftOnce`, `fadeInOnce`,
  /// `rollingOnce`, `scaleOnce`.
  static const animation = 'animation';

  /// The radius.
  static const radius = 'radius';

  /// The offset from the icon's top-trailing corner, `{x, y}`.
  static const centerOffset = 'centerOffset';

  /// The text color.
  static const textColor = 'textColor';

  /// The font size.
  static const font = 'font';

  /// The border color.
  static const borderColor = 'borderColor';

  /// The border width.
  static const borderWidth = 'borderWidth';

  /// The number above which "99+" style text shows.
  static const maximumNumber = 'maximumNumber';

  /// Whether Reduce Motion stops the animation.
  static const respectsReduceMotion = 'respectsReduceMotion';
}
