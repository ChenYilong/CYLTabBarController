import { describe, it, expect } from '@ohos/hypium';
import { CYLLiquidGlass, CYLAnimatedItemBackgroundModifier } from 'cylanimateditem';

/**
 * [EN] The liquid glass recipe of cylanimateditem for tags, section cards and items, the Android one: a hairline rim (black 16% light, white 22% dark, 1 vp,
 *      the same on every edge), no sheen, and the default tint that follows the mode (AppStorage `cyl_colorMode`). The tab bar capsule keeps its own light.
 * [CN] cylanimateditem 的液态玻璃配方（标签、分组卡片、条目），与 Android 相同：细边（浅色黑 16%、深色白 22%，1 vp，四边相同）、没有高光、随模式
 *      （AppStorage `cyl_colorMode`）变化的默认着色。TabBar 胶囊保留自己的光。
 */
export default function cylGlassHighlightTest() {
  describe('CYLGlassHighlight', () => {
    it('the rim is the Android hairline, the same on every edge, no sheen', 0, () => {
      expect(CYLLiquidGlass.rimColor(false)).assertEqual('#29000000');
      expect(CYLLiquidGlass.rimColor(true)).assertEqual('#38FFFFFF');
      expect(CYLLiquidGlass.RIM_WIDTH).assertEqual(1);
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
