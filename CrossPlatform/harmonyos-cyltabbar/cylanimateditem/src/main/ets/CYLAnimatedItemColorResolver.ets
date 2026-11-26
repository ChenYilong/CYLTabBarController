import { CYLAnimatedItemContrast, CYLAnimatedItemContrastKindIcon, CYLAnimatedItemContrastKindText } from './CYLAnimatedItemContrast';
import { cylAnimatedItemBuiltInColor, CYLAnimatedItemBuiltInColor } from './CYLAnimatedItemColors';

/** [EN] A colour per state, '' = not set. [CN] 各状态的颜色，'' 表示未设置。 */
export class CYLAnimatedItemColorStates {
  normal: ResourceColor = '';
  selected: ResourceColor = '';
  disabled: ResourceColor = '';
}

/**
 * [EN] Everything the colour resolution looks at, as plain values (so it is unit tested without a view): the four levels of the host side per state
 *      (`own`: the integrator's `titleColor` / `iconColor` ...; `subclassExplicit`: the `subclass...Color` props; `stack`: what the stack passes down;
 *      `subclassBuiltIn`: the `builtIn...Color` props, normal and selected only), the item state and the glass the colour is judged against.
 * [CN] 颜色解析所看的全部内容，均为普通值（因此无需视图即可单元测试）：宿主一侧每个状态的四个层级（`own`：集成方的 `titleColor` / `iconColor` 等；
 *      `subclassExplicit`：`subclass...Color` 属性；`stack`：堆叠传下的颜色；`subclassBuiltIn`：`builtIn...Color` 属性，只有普通与选中），条目状态，以及颜色所对照的玻璃。
 */
export class CYLAnimatedItemColorInput {
  /** [EN] `CYLAnimatedItemContrastKindText` (title, 4.5) or `CYLAnimatedItemContrastKindIcon` (icon and animation tint, 3). [CN] 标题（4.5）或图标与动画着色（3）。 */
  kind: string = CYLAnimatedItemContrastKindText;
  own: CYLAnimatedItemColorStates = new CYLAnimatedItemColorStates();
  subclassExplicit: CYLAnimatedItemColorStates = new CYLAnimatedItemColorStates();
  stack: CYLAnimatedItemColorStates = new CYLAnimatedItemColorStates();
  subclassBuiltIn: CYLAnimatedItemColorStates = new CYLAnimatedItemColorStates();
  selected: boolean = false;
  enabled: boolean = true;
  /** [EN] The item's resolved colour mode. [CN] 条目解析后的颜色模式。 */
  dark: boolean = false;
  /** [EN] The item's `drawsLiquidGlass`. [CN] 条目的 `drawsLiquidGlass`。 */
  drawsGlass: boolean = false;
  /** [EN] The glass tint (the item's background colour), undefined when none. [CN] 玻璃着色（条目的背景色），没有时为 undefined。 */
  glassTint: ResourceColor | undefined = undefined;
  /** [EN] The item's `itemGlassTintAlpha` (-1 = default). [CN] 条目的 `itemGlassTintAlpha`（-1 为默认）。 */
  tintAlpha: number | undefined = undefined;
  /**
   * [EN] The fill a FLAT item draws now (the pressed colour, the countdown fill, else the item's background colour), undefined for none; ignored while glass is drawn.
   * [CN] 扁平条目当前绘制的填充（按下颜色、倒计时填充，否则条目背景色），没有时为 undefined；绘制玻璃时忽略。
   */
  flatFill: ResourceColor | undefined = undefined;
}

/**
 * [EN] The ONE resolution of every title and icon colour of an item (iOS `CYLAnimatedItemView.resolvedBuiltInColor` and the explicit levels),
 *      static and pure so a hypium test can pin it. Precedence: the item's own colour of the state > the subclass-explicit colour (a missing selected
 *      value falls back to the normal one) > the stack-inherited colour > the subclass built-in colour (normal / selected; a missing selected one
 *      falls back to the normal one) > the component built-in colour of the state. Every level is adapted on the DRAWN dark Liquid Glass, or in dark mode on a
 *      static flat fill (`flatFill`, since 2026-11-27) (title 4.5:1, icon and animation tint 3:1) except the disabled look of the built-in levels; dynamic colours (a resource) are never adapted, the component
 *      built-in is judged by its constant of the mode and keeps its `sys.color` resource when that already passes. The integrator's own props are
 *      never written.
 * [CN] 条目所有标题与图标颜色的唯一解析（iOS `CYLAnimatedItemView.resolvedBuiltInColor` 与显式各层），静态且纯逻辑，hypium 测试可以固定它。优先级：条目自己该状态的颜色 >
 *      子类显式颜色（缺少选中值时回退到普通值）> 堆叠继承的颜色 > 子类内置颜色（普通 / 选中；缺少选中值时回退到普通值）> 组件该状态的内置颜色。除内置层的禁用外观外，
 *      每一层在真正绘制的深色液态玻璃上都会适配（标题 4.5:1，图标与动画着色 3:1）；动态颜色（资源）从不适配，组件内置色按其该模式的常量判断，已满足时保留 `sys.color` 资源。
 *      集成方自己的属性从不被写入。
 */
export class CYLAnimatedItemColorResolver {
  /** [EN] Whether a colour is set: not undefined and not '' (after trimming a string). [CN] 颜色是否已设置：不是 undefined，也不是 ''（字符串 trim 之后）。 */
  static isSet(color: ResourceColor | undefined): boolean {
    if (color === undefined) {
      return false;
    }
    return typeof color === 'string' ? (color as string).trim() !== '' : true;
  }

  /**
   * [EN] The colour of the state in `states`: disabled, else selected, else normal; with `selectedFallsBack` a missing selected value is the normal one.
   *      '' when the state has none.
   * [CN] `states` 中当前状态的颜色：禁用，否则选中，否则普通；`selectedFallsBack` 为 true 时缺少选中值则取普通值。该状态没有时为 ''。
   */
  static pick(states: CYLAnimatedItemColorStates, selected: boolean, enabled: boolean, selectedFallsBack: boolean): ResourceColor {
    if (!enabled) {
      return states.disabled;
    }
    if (selected) {
      return CYLAnimatedItemColorResolver.isSet(states.selected) || !selectedFallsBack ? states.selected : states.normal;
    }
    return states.normal;
  }

  /** [EN] A built-in colour as a resource colour (the `sys.color` resource, else the constant). [CN] 内置颜色，作为资源颜色（`sys.color` 资源，否则为常量）。 */
  static builtInColor(role: string, dark: boolean): ResourceColor {
    const builtIn: CYLAnimatedItemBuiltInColor = cylAnimatedItemBuiltInColor(role, dark);
    if (builtIn.resource === 'font_primary') {
      return $r('sys.color.font_primary');
    }
    if (builtIn.resource === 'interactive_active') {
      return $r('sys.color.interactive_active');
    }
    if (builtIn.resource === 'font_secondary') {
      return $r('sys.color.font_secondary');
    }
    return builtIn.color;
  }

  private static adapt(color: ResourceColor, input: CYLAnimatedItemColorInput): ResourceColor {
    return CYLAnimatedItemContrast.adaptedForContrastState(color, input.kind, input.drawsGlass, input.dark, input.glassTint, input.tintAlpha,
      input.flatFill);
  }

  /**
   * [EN] The EXPLICIT colour of the current state (own, then subclass-explicit, then stack), adapted; '' when none of the three is set.
   * [CN] 当前状态的显式颜色（自己的、子类显式、堆叠），已适配；三者都未设置时为 ''。
   */
  static explicitColor(input: CYLAnimatedItemColorInput): ResourceColor {
    const own: ResourceColor = CYLAnimatedItemColorResolver.pick(input.own, input.selected, input.enabled, false);
    if (CYLAnimatedItemColorResolver.isSet(own)) {
      return CYLAnimatedItemColorResolver.adapt(own, input);
    }
    const subclass: ResourceColor = CYLAnimatedItemColorResolver.pick(input.subclassExplicit, input.selected, input.enabled, true);
    if (CYLAnimatedItemColorResolver.isSet(subclass)) {
      return CYLAnimatedItemColorResolver.adapt(subclass, input);
    }
    const stack: ResourceColor = CYLAnimatedItemColorResolver.pick(input.stack, input.selected, input.enabled, false);
    return CYLAnimatedItemColorResolver.isSet(stack) ? CYLAnimatedItemColorResolver.adapt(stack, input) : '';
  }

  /**
   * [EN] The BUILT-IN colour of the current state (subclass built-in, then component built-in), adapted except for the disabled look.
   * [CN] 当前状态的内置颜色（子类内置，然后组件内置），除禁用外观外已适配。
   */
  static builtInLevelColor(input: CYLAnimatedItemColorInput): ResourceColor {
    const role: string = !input.enabled ? 'disabled' : (input.selected ? 'selected' : 'normal');
    if (input.enabled) {
      const subclass: ResourceColor = CYLAnimatedItemColorResolver.pick(input.subclassBuiltIn, input.selected, true, true);
      if (CYLAnimatedItemColorResolver.isSet(subclass)) {
        return CYLAnimatedItemColorResolver.adapt(subclass, input);
      }
    }
    const resource: ResourceColor = CYLAnimatedItemColorResolver.builtInColor(role, input.dark);
    if (!input.enabled) {
      return resource;
    }
    const constant: string = cylAnimatedItemBuiltInColor(role, input.dark).color;
    const adapted: ResourceColor = CYLAnimatedItemColorResolver.adapt(constant, input);
    return adapted === constant ? resource : adapted;
  }

  /** [EN] The effective colour of `input.kind`: explicit, else built-in. [CN] `input.kind` 的生效颜色：显式，否则内置。 */
  private static resolved(input: CYLAnimatedItemColorInput): ResourceColor {
    const explicit: ResourceColor = CYLAnimatedItemColorResolver.explicitColor(input);
    return CYLAnimatedItemColorResolver.isSet(explicit) ? explicit : CYLAnimatedItemColorResolver.builtInLevelColor(input);
  }

  /** [EN] The effective TITLE colour (4.5:1 on drawn dark glass). [CN] 生效的标题颜色（深色绘制玻璃上 4.5:1）。 */
  static resolvedTitleColor(input: CYLAnimatedItemColorInput): ResourceColor {
    input.kind = CYLAnimatedItemContrastKindText;
    return CYLAnimatedItemColorResolver.resolved(input);
  }

  /** [EN] The effective ICON colour (3:1 on drawn dark glass), also the colour of the "title" animation tint. [CN] 生效的图标颜色（深色绘制玻璃上 3:1），也是 "title" 动画着色所用的颜色。 */
  static resolvedIconColor(input: CYLAnimatedItemColorInput): ResourceColor {
    input.kind = CYLAnimatedItemContrastKindIcon;
    return CYLAnimatedItemColorResolver.resolved(input);
  }
}
