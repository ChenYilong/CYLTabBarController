import { describe, it, expect } from '@ohos/hypium';
import { CYLLiquidGlass, CYLAnimatedItemBackgroundModifier } from 'cylanimateditem';
import { CYLLiquidGlassCapsuleEdge } from 'cyltabbar';

/**
 * [EN] The one liquid glass config of cylanimateditem (the hairline rim and the sheen), shared by tags, cards and the tab bar capsule: the rim is the
 *      Android hairline, the same on every edge, the sheen runs from a bright top to a clear middle, and the mode comes from AppStorage `cyl_colorMode`.
 * [CN] cylanimateditem 唯一的液态玻璃配置（细边与高光），标签、卡片与 TabBar 胶囊共用：细边是 Android 的细边，四条边相同；高光从明亮的顶部到透明的中部；
 *      模式取自 AppStorage 的 `cyl_colorMode`。
 */
export default function cylGlassHighlightTest() {
  describe('CYLGlassHighlight', () => {
    it('the rim is the Android bright hairline, the same on every edge, in light and dark', 0, () => {
      const light: EdgeColors = CYLLiquidGlass.rimEdgeColors(false);
      expect(light.top).assertEqual('#B3FFFFFF');
      expect(light.right).assertEqual(light.top);
      expect(light.bottom).assertEqual(light.top);
      expect(light.left).assertEqual(light.top);
      const dark: EdgeColors = CYLLiquidGlass.rimEdgeColors(true);
      expect(dark.top).assertEqual('#38FFFFFF');
      expect(dark.right).assertEqual(dark.top);
      expect(dark.bottom).assertEqual(dark.top);
      expect(dark.left).assertEqual(dark.top);
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

    it('the tab bar capsule reads the same rim and sheen as a tag, in light and dark', 0, () => {
      [false, true].forEach((dark: boolean) => {
        const tag: EdgeColors = CYLLiquidGlass.rimEdgeColors(dark);
        const capsule: EdgeColors = CYLLiquidGlassCapsuleEdge.rim(dark);
        expect(capsule.top).assertEqual(tag.top);
        expect(capsule.right).assertEqual(tag.right);
        expect(capsule.bottom).assertEqual(tag.bottom);
        expect(capsule.left).assertEqual(tag.left);
        const tagSheen: Array<[ResourceColor, number]> = CYLLiquidGlass.sheenColors(dark);
        const capsuleSheen: Array<[ResourceColor, number]> = CYLLiquidGlassCapsuleEdge.sheen(dark);
        expect(capsuleSheen.length).assertEqual(tagSheen.length);
        capsuleSheen.forEach((stop: [ResourceColor, number], index: number) => {
          expect(stop[0]).assertEqual(tagSheen[index][0]);
          expect(stop[1]).assertEqual(tagSheen[index][1]);
        });
      });
      expect(CYLLiquidGlassCapsuleEdge.rimWidth()).assertEqual(CYLLiquidGlass.RIM_WIDTH);
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

    it('with cyl_colorMode unset the system dark / light mode decides; an explicit key wins', 0, () => {
      const key: string | undefined = AppStorage.get<string>('cyl_colorMode');
      const system: number | undefined = AppStorage.get<number>('colorMode');
      CYLLiquidGlass.trackSystemColorMode();
      AppStorage.delete('cyl_colorMode');
      AppStorage.setOrCreate('colorMode', ColorMode.DARK);
      expect(CYLLiquidGlass.isDark()).assertTrue();
      expect(CYLAnimatedItemBackgroundModifier.defaultGlassTint()).assertEqual('#24FFFFFF');
      AppStorage.setOrCreate('colorMode', ColorMode.LIGHT);
      expect(CYLLiquidGlass.isDark()).assertFalse();
      expect(CYLAnimatedItemBackgroundModifier.defaultGlassTint()).assertEqual('#80E1DEDC');
      AppStorage.setOrCreate('cyl_colorMode', 'light');
      AppStorage.setOrCreate('colorMode', ColorMode.DARK);
      expect(CYLLiquidGlass.isDark()).assertFalse();
      expect(CYLAnimatedItemBackgroundModifier.defaultGlassTint()).assertEqual('#80E1DEDC');
      AppStorage.setOrCreate('cyl_colorMode', 'dark');
      AppStorage.setOrCreate('colorMode', ColorMode.LIGHT);
      expect(CYLLiquidGlass.isDark()).assertTrue();
      expect(CYLAnimatedItemBackgroundModifier.defaultGlassTint()).assertEqual('#24FFFFFF');
      if (key === undefined) {
        AppStorage.delete('cyl_colorMode');
      } else {
        AppStorage.setOrCreate('cyl_colorMode', key);
      }
      AppStorage.setOrCreate('colorMode', system ?? ColorMode.LIGHT);
    });
  });
}
