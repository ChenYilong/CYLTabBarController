import { describe, it, expect } from '@ohos/hypium';
import { CYLLiquidGlass, CYLLiquidGlassSurface, CYLAnimatedItemBackgroundModifier, CYLAnimatedItemBackgroundStyle } from 'cylanimateditem';

/**
 * [EN] The light of the Liquid Glass of cylanimateditem (the hairline rim and the sheen, Android `CYLGlassHighlight`): the rim is lit from the
 *      top left (bright top and left, dim bottom and right) in both modes, the sheen runs from a bright top to a clear middle, and the mode
 *      comes from AppStorage `cyl_colorMode`.
 * [CN] cylanimateditem 液态玻璃的光（细边与高光，Android `CYLGlassHighlight`）：细边光从左上来（上边、左边明亮，下边、右边暗淡），两种模式都是；
 *      高光从明亮的顶部到透明的中部；模式取自 AppStorage 的 `cyl_colorMode`。
 */
export default function cylGlassHighlightTest() {
  describe('CYLGlassHighlight', () => {
    it('an item has the uniform Android rim and no sheen, in light and dark', 0, () => {
      const light: EdgeColors = CYLLiquidGlass.rimEdgeColors(CYLLiquidGlassSurface.item, false);
      expect(light.top).assertEqual('#29000000');
      expect(light.left).assertEqual(light.bottom);
      expect(light.right).assertEqual(light.top);
      const dark: EdgeColors = CYLLiquidGlass.rimEdgeColors(CYLLiquidGlassSurface.item, true);
      expect(dark.top).assertEqual('#38FFFFFF');
      expect(dark.bottom).assertEqual(dark.top);
      expect(CYLLiquidGlass.sheenColors(CYLLiquidGlassSurface.item, false).length).assertEqual(0);
      expect(CYLLiquidGlass.sheenColors(CYLLiquidGlassSurface.item, true).length).assertEqual(0);
    });

    it('a plate is lit from the top left in light and dark', 0, () => {
      const light: EdgeColors = CYLLiquidGlass.rimEdgeColors(CYLLiquidGlassSurface.plate, false);
      expect(light.top).assertEqual(light.left);
      expect(light.bottom).assertEqual(light.right);
      expect(light.top).assertEqual('#E6FFFFFF');
      expect(light.bottom).assertEqual('#2E000000');
      const dark: EdgeColors = CYLLiquidGlass.rimEdgeColors(CYLLiquidGlassSurface.plate, true);
      expect(dark.top).assertEqual('#8CFFFFFF');
      expect(dark.bottom).assertEqual('#24FFFFFF');
    });

    it('a plate has the sheen: bright at the top, clear in the middle, in both modes', 0, () => {
      [false, true].forEach((dark: boolean) => {
        const stops: Array<[ResourceColor, number]> = CYLLiquidGlass.sheenColors(CYLLiquidGlassSurface.plate, dark);
        expect(stops.length).assertEqual(4);
        expect(stops[0][1]).assertEqual(0);
        expect(stops[stops.length - 1][1]).assertEqual(1);
        expect(stops[2][0]).assertEqual('#00FFFFFF');
      });
      expect(CYLLiquidGlass.sheenColors(CYLLiquidGlassSurface.plate, false)[0][0]).assertEqual('#66FFFFFF');
      expect(CYLLiquidGlass.sheenColors(CYLLiquidGlassSurface.plate, true)[0][0]).assertEqual('#2EFFFFFF');
    });

    it('the plate factory sets the surface, a modifier is an item by default', 0, () => {
      expect(new CYLAnimatedItemBackgroundModifier(CYLAnimatedItemBackgroundStyle.liquidGlass, '').surface).assertEqual(CYLLiquidGlassSurface.item);
      expect(CYLAnimatedItemBackgroundModifier.plate(CYLAnimatedItemBackgroundStyle.liquidGlass, '').surface).assertEqual(CYLLiquidGlassSurface.plate);
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
