import { describe, it, expect } from '@ohos/hypium';
import {
  CYLAnimatedItemColorInput, CYLAnimatedItemColorResolver, CYLAnimatedItemColorStates, CYLAnimatedItemContrast, CYLAnimatedItemContrastKindIcon, CYLAnimatedItemContrastKindText,
  CYLAnimatedItemContrastRGBA
} from 'cylanimateditem';

/**
 * [EN] The flat-fill contrast rule (iOS `contrastApplies` / `flatReferenceLuminance`, Android `CYLAnimatedItemFlatContrastTest`): in dark mode an item that draws a
 *      static flat fill lifts its colours against the fill over black; flat without a fill, a resource fill, light mode and the disabled look are not adapted; a
 *      light fill never turns a colour whiter.
 * [CN] 扁平填充对比度规则（对应 iOS `contrastApplies` / `flatReferenceLuminance`、Android `CYLAnimatedItemFlatContrastTest`）：深色模式下绘制静态扁平填充的条目按叠在黑色上的填充提亮颜色；
 *      没有填充、资源填充、浅色模式与禁用外观不调整；浅色填充绝不会让颜色变得更白。
 */
const GREY: string = '#FF3C3C43';
const DARK_FILL: string = '#FF1C1C1E';
const HALF_WHITE: string = '#80FFFFFF';
const HALF_DARK: string = '#801C1C1E';
const WHITE_FILL: string = '#FFFFFFFF';
const MID_GREY: string = '#FF8E8E93';
const TEXT: number = 4.5;
const ICON: number = 3;

function luminanceOf(color: ResourceColor): number {
  const c: CYLAnimatedItemContrastRGBA | undefined = CYLAnimatedItemContrast.components(color);
  return c === undefined ? 0 : CYLAnimatedItemContrast.relativeLuminance(c.red, c.green, c.blue);
}

function contrastOn(color: ResourceColor, fill: string): number {
  const reference: number | undefined = CYLAnimatedItemContrast.flatReferenceLuminance(fill);
  return CYLAnimatedItemContrast.contrastRatio(luminanceOf(color), reference === undefined ? 0 : reference);
}

function flatTitleInput(fill: ResourceColor | undefined, dark: boolean): CYLAnimatedItemColorInput {
  const input: CYLAnimatedItemColorInput = new CYLAnimatedItemColorInput();
  input.kind = CYLAnimatedItemContrastKindText;
  input.dark = dark;
  input.drawsGlass = false;
  input.flatFill = fill;
  input.own.normal = GREY;
  return input;
}

export default function cylAnimatedItemFlatContrastTest() {
  describe('CYLAnimatedItemFlatContrast', () => {
    it('the flat reference is the fill over black; clear and resource fills have none', 0, () => {
      expect(Math.abs((CYLAnimatedItemContrast.flatReferenceLuminance(DARK_FILL) as number) - luminanceOf(DARK_FILL)) < 1e-9).assertTrue();
      expect(Math.abs((CYLAnimatedItemContrast.flatReferenceLuminance(HALF_WHITE) as number) - 0.216) < 0.003).assertTrue();
      expect(CYLAnimatedItemContrast.flatReferenceLuminance('#00FFFFFF') === undefined).assertTrue();
      expect(CYLAnimatedItemContrast.flatReferenceLuminance(undefined) === undefined).assertTrue();
      expect(CYLAnimatedItemContrast.flatReferenceLuminance($r('sys.color.font_primary')) === undefined).assertTrue();
    });

    it('a dark title on the dark flat fill reaches 4.5 in dark mode only', 0, () => {
      expect(contrastOn(GREY, DARK_FILL) < 2).assertTrue();
      const lifted: ResourceColor = CYLAnimatedItemColorResolver.resolvedTitleColor(flatTitleInput(DARK_FILL, true));
      expect(contrastOn(lifted, DARK_FILL) >= TEXT - 0.01).assertTrue();
      expect(CYLAnimatedItemColorResolver.resolvedTitleColor(flatTitleInput(DARK_FILL, false))).assertEqual(GREY);
    });

    it('flat without a fill is not adapted', 0, () => {
      expect(CYLAnimatedItemColorResolver.resolvedTitleColor(flatTitleInput(undefined, true))).assertEqual(GREY);
      expect(CYLAnimatedItemColorResolver.resolvedTitleColor(flatTitleInput('#00000000', true))).assertEqual(GREY);
    });

    it('a half-alpha white fill caps at white; a half-alpha dark fill reaches 4.5', 0, () => {
      const capped: ResourceColor = CYLAnimatedItemContrast.adaptedForContrastState(GREY, CYLAnimatedItemContrastKindText, false, true, undefined, undefined, HALF_WHITE);
      expect(luminanceOf(capped) > 0.99).assertTrue();
      expect(contrastOn(capped, HALF_WHITE) < TEXT).assertTrue();
      const dark: ResourceColor = CYLAnimatedItemContrast.adaptedForContrastState(GREY, CYLAnimatedItemContrastKindText, false, true, undefined, undefined, HALF_DARK);
      expect(contrastOn(dark, HALF_DARK) >= TEXT - 0.01).assertTrue();
    });

    it('a light fill never turns a mid-grey title white', 0, () => {
      const kept: ResourceColor = CYLAnimatedItemContrast.adaptedForContrastState(MID_GREY, CYLAnimatedItemContrastKindText, false, true, undefined, undefined, WHITE_FILL);
      expect(kept).assertEqual(MID_GREY);
    });

    it('an icon is lifted to 3', 0, () => {
      const icon: ResourceColor = CYLAnimatedItemContrast.adaptedForContrastState(GREY, CYLAnimatedItemContrastKindIcon, false, true, undefined, undefined, DARK_FILL);
      expect(contrastOn(icon, DARK_FILL) >= ICON - 0.01).assertTrue();
    });

    it('the disabled look of a built-in is not adapted on a flat fill', 0, () => {
      const input: CYLAnimatedItemColorInput = flatTitleInput(DARK_FILL, true);
      input.own.normal = '';
      input.enabled = false;
      const disabled: ResourceColor = CYLAnimatedItemColorResolver.resolvedTitleColor(input);
      expect(disabled).assertEqual(CYLAnimatedItemColorResolver.builtInColor('disabled', true));
    });

    it('a host role: explicit > subclass built-in > component built-in, adapted by its kind; the disabled built-in is not adapted', 0, () => {
      const input: CYLAnimatedItemColorInput = flatTitleInput(DARK_FILL, true);
      input.own.normal = '';
      const component: CYLAnimatedItemColorStates = new CYLAnimatedItemColorStates();
      expect(CYLAnimatedItemColorResolver.resolvedRoleColor(input, component)).assertEqual('');
      component.normal = GREY;
      component.disabled = GREY;
      expect(contrastOn(CYLAnimatedItemColorResolver.resolvedRoleColor(input, component), DARK_FILL) >= TEXT - 0.01).assertTrue();
      input.subclassBuiltIn.normal = MID_GREY;
      expect(CYLAnimatedItemColorResolver.resolvedRoleColor(input, component) === GREY).assertFalse();
      input.subclassExplicit.normal = '#FFFFFFFF';
      expect(CYLAnimatedItemColorResolver.resolvedRoleColor(input, component)).assertEqual('#FFFFFFFF');
      input.subclassExplicit.normal = '';
      input.enabled = false;
      expect(CYLAnimatedItemColorResolver.resolvedRoleColor(input, component)).assertEqual(GREY);
      input.subclassBuiltIn.disabled = MID_GREY;
      expect(CYLAnimatedItemColorResolver.resolvedRoleColor(input, component)).assertEqual(MID_GREY);
    });

    it('the subclass disabled built-in replaces the component disabled colour of the item title', 0, () => {
      const input: CYLAnimatedItemColorInput = flatTitleInput(DARK_FILL, true);
      input.own.normal = '';
      input.enabled = false;
      input.subclassBuiltIn.disabled = MID_GREY;
      expect(CYLAnimatedItemColorResolver.resolvedTitleColor(input)).assertEqual(MID_GREY);
    });

    it('glass keeps the glass reference (the flat fill is ignored)', 0, () => {
      const glass: ResourceColor = CYLAnimatedItemContrast.adaptedForContrastState(GREY, CYLAnimatedItemContrastKindText, true, true, undefined, undefined, WHITE_FILL);
      expect(glass).assertEqual(CYLAnimatedItemContrast.adaptedOnGlassState(GREY, CYLAnimatedItemContrastKindText, true, true, undefined, undefined));
    });
  });
}
