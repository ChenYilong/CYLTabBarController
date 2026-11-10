import { describe, expect, it, jest } from '@jest/globals';

jest.mock('../CyltabbarViewNativeComponent', () => 'CyltabbarView');

import { buildConfiguration } from '../CyltabbarView.native';

describe('buildConfiguration', () => {
  it('maps the icon rendering mode props (#787)', () => {
    const configuration = buildConfiguration({
      iconRenderingMode: 'template',
      iconColor: '#8E8E93',
      selectedIconColor: '#FF3B30',
      items: [
        { title: 'Home', image: 'home' },
        { title: 'Shop', image: 'shop', iconRenderingMode: 'original', iconColor: '#000000', selectedIconColor: '#FFFFFF' },
      ],
    });
    expect(configuration.CYLTabBarControllerIconRenderingMode).toBe('template');
    expect(configuration.CYLTabBarControllerIconColor).toBe('#8E8E93');
    expect(configuration.CYLTabBarControllerSelectedIconColor).toBe('#FF3B30');
    expect(configuration.CYLTabBarControllerTabBarItemsAttributes).toEqual([
      { CYLTabBarItemTitle: 'Home', CYLTabBarItemImage: 'home' },
      {
        CYLTabBarItemTitle: 'Shop',
        CYLTabBarItemImage: 'shop',
        CYLTabBarItemIconRenderingMode: 'original',
        CYLTabBarItemIconColor: '#000000',
        CYLTabBarItemSelectedIconColor: '#FFFFFF',
      },
    ]);
  });
});
