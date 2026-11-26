import { describe, it, expect } from '@ohos/hypium';
import { CYLAnimatedItemContrast, CYLAnimatedItemContrastRGBA } from 'cylanimateditem';

const DARK_TEXT: string = '#FF3C3C43';
const TEAL: string = '#FF30B0C7';
const DARK_TEAL: string = '#FF004040';
const BRIGHT: string = '#FF99E6FF';
const WHITE: string = '#FFFFFFFF';
const TINT: string = '#CC3399FF';
const PASSING: number = 4.49;
const ICON_PASSING: number = 2.99;
const HUE_ACCURACY: number = 0.01;
const ALPHA_ACCURACY: number = 0.005;
const ARGB_NUMBER: number = 0xFF3C3C43;

function rgbaOf(color: ResourceColor): CYLAnimatedItemContrastRGBA {
  const rgba: CYLAnimatedItemContrastRGBA | undefined = CYLAnimatedItemContrast.components(color);
  return rgba === undefined ? new CYLAnimatedItemContrastRGBA(0, 0, 0, 0) : rgba;
}

function contrastOf(color: ResourceColor, glassTint: ResourceColor | undefined = undefined, tintAlpha: number | undefined = undefined): number {
  const c: CYLAnimatedItemContrastRGBA = rgbaOf(color);
  return CYLAnimatedItemContrast.contrastRatio(CYLAnimatedItemContrast.relativeLuminance(c.red, c.green, c.blue),
    CYLAnimatedItemContrast.glassReferenceLuminance(glassTint, tintAlpha));
}

function hueOf(color: ResourceColor): number {
  const c: CYLAnimatedItemContrastRGBA = rgbaOf(color);
  return CYLAnimatedItemContrast.hslFromRGB(c.red, c.green, c.blue).hue;
}

function text(color: ResourceColor): ResourceColor {
  return CYLAnimatedItemContrast.adjustedColor(color, undefined, undefined, CYLAnimatedItemContrast.minimumTextContrast);
}

function icon(color: ResourceColor): ResourceColor {
  return CYLAnimatedItemContrast.adjustedColor(color, undefined, undefined, CYLAnimatedItemContrast.minimumIconContrast);
}

/**
 * [EN] The dark Liquid Glass colour adaptation (ClassifyMenu's CYLIconContrast rule, 3:1 icon, 4.5:1 text): a dark explicit colour is lightened with its
 *      hue and alpha kept; a passing colour, white, a resource are returned as they are; the function is pure.
 * [CN] 深色液态玻璃颜色适配（ClassifyMenu 的 CYLIconContrast 规则，图标 3:1、文字 4.5:1）：过暗的显式颜色被提亮并保持色相与透明度；已满足的颜色、白色、资源原样返回；纯函数。
 */
export default function cylAnimatedItemContrastTest() {
  describe('CYLAnimatedItemContrast', () => {
    it('the constants are the ClassifyMenu rule', 0, () => {
      expect(CYLAnimatedItemContrast.minimumIconContrast).assertEqual(3);
      expect(CYLAnimatedItemContrast.minimumTextContrast).assertEqual(4.5);
      expect(CYLAnimatedItemContrast.frostedGlassWhiteAlpha).assertEqual(0.14);
      expect(CYLAnimatedItemContrast.defaultGlassTintShare).assertEqual(0.75);
      expect(CYLAnimatedItemContrast.lightnessStep).assertEqual(0.005);
    });

    it('dark text on the default dark glass becomes lighter and passes 4.5', 0, () => {
      const lifted: ResourceColor = text(DARK_TEXT);
      expect(lifted === DARK_TEXT).assertFalse();
      expect(contrastOf(DARK_TEXT) < PASSING).assertTrue();
      expect(contrastOf(lifted) >= PASSING).assertTrue();
      expect(rgbaOf(lifted).red > rgbaOf(DARK_TEXT).red).assertTrue();
    });

    it('a dark icon reaches 3:1 with its hue kept and alpha kept', 0, () => {
      [TEAL, DARK_TEAL].forEach((color: string) => {
        const lifted: ResourceColor = icon(color);
        expect(contrastOf(lifted) >= ICON_PASSING).assertTrue();
        expect(Math.abs(hueOf(lifted) - hueOf(color)) < HUE_ACCURACY).assertTrue();
      });
      const half: ResourceColor = icon('#80004040');
      expect(Math.abs(rgbaOf(half).alpha - 0x80 / 255) < ALPHA_ACCURACY).assertTrue();
      expect(contrastOf(half) >= ICON_PASSING).assertTrue();
    });

    it('black is lifted to a gray and never above white', 0, () => {
      const lifted: ResourceColor = text('#FF000000');
      expect(contrastOf(lifted) >= PASSING).assertTrue();
      expect(rgbaOf(lifted).red <= 1).assertTrue();
    });

    it('a light colour, white and a passing colour are returned unchanged', 0, () => {
      expect(text(WHITE)).assertEqual(WHITE);
      expect(icon(WHITE)).assertEqual(WHITE);
      expect(contrastOf(BRIGHT) >= PASSING).assertTrue();
      expect(text(BRIGHT)).assertEqual(BRIGHT);
      expect(icon(BRIGHT)).assertEqual(BRIGHT);
    });

    it('an explicit glass tint raises the reference and the colour still passes', 0, () => {
      const lifted: ResourceColor = CYLAnimatedItemContrast.adjustedColor(DARK_TEXT, TINT, undefined, CYLAnimatedItemContrast.minimumTextContrast);
      expect(contrastOf(lifted, TINT, undefined) >= PASSING).assertTrue();
      // [EN] At tint alpha 1 this tint is so bright that even white cannot reach 4.5 and the rule never goes above white: the colour improves as far as it can. [CN] 着色透明度为 1 时这个着色太亮，连白色也达不到 4.5，而规则不会超过白色：颜色只提升到极限。
      const selected: ResourceColor = CYLAnimatedItemContrast.adjustedColor(DARK_TEXT, TINT, 1, CYLAnimatedItemContrast.minimumTextContrast);
      expect(contrastOf(selected, TINT, 1) >= contrastOf(DARK_TEXT, TINT, 1)).assertTrue();
      expect(CYLAnimatedItemContrast.glassReferenceLuminance(TINT, 1) > CYLAnimatedItemContrast.glassReferenceLuminance(TINT, undefined)).assertTrue();
      // Alpha 0 is the frosted default.
      expect(CYLAnimatedItemContrast.glassReferenceLuminance('#00000000', undefined))
        .assertEqual(CYLAnimatedItemContrast.glassReferenceLuminance(undefined, undefined));
    });

    it('unset, a resource and a Color constant style input are returned as they are', 0, () => {
      expect(text('')).assertEqual('');
      const resource: ResourceColor = $r('sys.color.font_primary');
      expect(text(resource) === resource).assertTrue();
      expect(CYLAnimatedItemContrast.components(resource) === undefined).assertTrue();
      expect(text('not a colour')).assertEqual('not a colour');
    });

    it('a number colour stays a number and is lightened', 0, () => {
      const lifted: ResourceColor = text(ARGB_NUMBER);
      expect(typeof lifted === 'number').assertTrue();
      expect(contrastOf(lifted) >= PASSING).assertTrue();
      // A number with no alpha byte (a Color constant) is not touched.
      expect(text(1)).assertEqual(1);
    });

    it('the pure function gives the same output for the same input', 0, () => {
      expect(text(TEAL)).assertEqual(text(TEAL));
      expect(icon(DARK_TEAL)).assertEqual(icon(DARK_TEAL));
    });
  });
}
