import { describe, it, expect } from '@ohos/hypium';
import { cylIconRenderingMode, cylStaticIconTintColor, CYLFlatDesignTintColor, CYLFlatDesignUnselectedColor } from 'cyltabbar';

/**
 * [EN] The tint of a static tab icon (docs/Tab-Item-Colors.md, #787): a template icon takes the bar's selected / unselected tint without
 *      explicit icon colors (flat style: system blue / gray), an explicit icon color wins, an original icon is never tinted, and the
 *      automatic mode (the default) tints only with an explicit color.
 * [CN] 静态 Tab 图标的着色：模板图标在没有显式图标颜色时取 TabBar 的选中 / 未选中着色（扁平样式：系统蓝 / 灰），显式图标颜色优先，
 *      original 图标从不着色，automatic（默认）只有显式颜色时才着色。
 */
export default function cylIconRenderingModeTest() {
  describe('CYLIconRenderingMode', () => {
    it('normalizes the mode: case-insensitive, unknown is automatic', 0, () => {
      expect(cylIconRenderingMode('template')).assertEqual('template');
      expect(cylIconRenderingMode('Template')).assertEqual('template');
      expect(cylIconRenderingMode('ORIGINAL')).assertEqual('original');
      expect(cylIconRenderingMode('automatic')).assertEqual('automatic');
      expect(cylIconRenderingMode('bogus')).assertEqual('automatic');
      expect(cylIconRenderingMode(undefined)).assertEqual('automatic');
    });

    it('template without icon colors: the selected icon is the selected tint, the unselected one the unselected tint', 0, () => {
      expect(cylStaticIconTintColor('template', undefined, CYLFlatDesignTintColor)).assertEqual(CYLFlatDesignTintColor);
      expect(cylStaticIconTintColor('template', undefined, CYLFlatDesignUnselectedColor)).assertEqual(CYLFlatDesignUnselectedColor);
    });

    it('template with an explicit icon color: the explicit color wins', 0, () => {
      expect(cylStaticIconTintColor('template', '#FF2D55', CYLFlatDesignTintColor)).assertEqual('#FF2D55');
    });

    it('original: never tinted, even with an explicit icon color', 0, () => {
      expect(cylStaticIconTintColor('original', undefined, CYLFlatDesignTintColor)).assertEqual('');
      expect(cylStaticIconTintColor('original', '#FF2D55', CYLFlatDesignTintColor)).assertEqual('');
    });

    it('automatic (and unset): tinted only by an explicit icon color', 0, () => {
      expect(cylStaticIconTintColor('automatic', undefined, CYLFlatDesignTintColor)).assertEqual('');
      expect(cylStaticIconTintColor(undefined, undefined, CYLFlatDesignTintColor)).assertEqual('');
      expect(cylStaticIconTintColor(undefined, '#FF2D55', CYLFlatDesignTintColor)).assertEqual('#FF2D55');
    });

  });
}
