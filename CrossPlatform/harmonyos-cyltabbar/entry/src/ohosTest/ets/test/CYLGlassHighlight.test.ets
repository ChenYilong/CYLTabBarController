import { describe, it, expect } from '@ohos/hypium';
import { CYLLiquidGlass, CYLAnimatedItemBackgroundModifier } from 'cylanimateditem';

/**
 * [EN] The light of the Liquid Glass of cylanimateditem (the hairline rim and the sheen, Android `CYLGlassHighlight`): the rim is lit from the
 *      top left (bright top and left, dim bottom and right) in both modes, the sheen runs from a bright top to a clear middle, and the mode
 *      comes from AppStorage `cyl_colorMode`.
 * [CN] cylanimateditem 液态玻璃的光（细边与高光，Android `CYLGlassHighlight`）：细边光从左上来（上边、左边明亮，下边、右边暗淡），两种模式都是；
 *      高光从明亮的顶部到透明的中部；模式取自 AppStorage 的 `cyl_colorMode`。
 */
export default function cylGlassHighlightTest() {
  describe('CYLGlassHighlight', () => {
    it('the rim is lit from the top left in light and dark', 0, () => {
      const light: EdgeColors = CYLLiquidGlass.rimEdgeColors(false);
      expect(light.top).assertEqual(light.left);
      expect(light.bottom).assertEqual(light.right);
      expect(light.top).assertEqual('#E6FFFFFF');
      expect(light.bottom).assertEqual('#2E000000');
      const dark: EdgeColors = CYLLiquidGlass.rimEdgeColors(true);
      expect(dark.top).assertEqual(dark.left);
      expect(dark.bottom).assertEqual(dark.right);
      expect(dark.top).assertEqual('#8CFFFFFF');
      expect(dark.bottom).assertEqual('#24FFFFFF');
    });

    it('the sheen is bright at the top and clear in the middle, in both modes', 0, () => {
      [false, true].forEach((dark: boolean) => {
        const stops: Array<[ResourceColor, number]> = CYLLiquidGlass.sheenColors(dark);
        expect(stops.length).assertEqual(4);
        expect(stops[0][1]).assertEqual(0);
        expect(stops[stops.length - 1][1]).assertEqual(1);
        expect(stops[2][0]).assertEqual('#00FFFFFF');
      });
      expect(CYLLiquidGlass.sheenColors(false)[0][0]).assertEqual('#66FFFFFF');
      expect(CYLLiquidGlass.sheenColors(true)[0][0]).assertEqual('#2EFFFFFF');
    });

    it('the default glass tint follows the mode: frosted light, white 14 percent in dark', 0, () => {
      const before: string | undefined = AppStorage.get<string>('cyl_colorMode');
      AppStorage.setOrCreate('cyl_colorMode', 'dark');
      expect(CYLAnimatedItemBackgroundModifier.defaultGlassTint()).assertEqual('#24FFFFFF');
      AppStorage.setOrCreate('cyl_colorMode', 'light');
      expect(CYLAnimatedItemBackgroundModifier.defaultGlassTint()).assertEqual('#80E1DEDC');
      AppStorage.setOrCreate('cyl_colorMode', before ?? 'light');
    });

    it('the mode comes from AppStorage cyl_colorMode', 0, () => {
      const before: string | undefined = AppStorage.get<string>('cyl_colorMode');
      AppStorage.setOrCreate('cyl_colorMode', 'dark');
      expect(CYLLiquidGlass.isDark()).assertTrue();
      AppStorage.setOrCreate('cyl_colorMode', 'light');
      expect(CYLLiquidGlass.isDark()).assertFalse();
      AppStorage.setOrCreate('cyl_colorMode', before ?? 'light');
    });
  });
}
