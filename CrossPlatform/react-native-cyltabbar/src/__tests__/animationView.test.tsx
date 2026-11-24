import { describe, expect, it, jest } from '@jest/globals';
import { readFileSync } from 'fs';
import { join } from 'path';

jest.mock('../CyltabbarAnimationViewNativeComponent', () => ({
  __esModule: true,
  default: 'CyltabbarAnimationView',
  Commands: { play: jest.fn(), stopAtProgress: jest.fn(), restart: jest.fn() },
}));

import { animationURLWithOptions, cylAnimatedItemCornerRadiusCapsule } from '../CYLAnimationView.native';

type Case = { input: string; file?: string; options: Record<string, string> };

const fixture = JSON.parse(
  readFileSync(join(__dirname, '../../../animated-item-fixtures/source-options.json'), 'utf8'),
) as { cases: Case[] };

describe('animationURLWithOptions against the shared source-options.json', () => {
  it('writes every case of the fixture so that its file and options read back the same', () => {
    const cases = fixture.cases.filter((c) => c.file !== undefined && !c.input.trim().startsWith('{'));
    expect(cases.length).toBeGreaterThanOrEqual(6);
    for (const c of cases) {
      const url = animationURLWithOptions(c.file!, c.options);
      const [file, fragment = ''] = url.split('#');
      expect(file).toBe(c.file);
      const read: Record<string, string> = {};
      for (const pair of fragment.split('&').filter(Boolean)) {
        const [name, ...value] = pair.split('=');
        read[decodeURIComponent(name!)] = decodeURIComponent(value.join('='));
      }
      expect(read).toEqual(c.options);
    }
  });

  it('sorts by name and drops empty values', () => {
    expect(animationURLWithOptions('a.riv', { b: 2, a: 'x y', c: '' })).toBe('a.riv#a=x%20y&b=2');
    expect(animationURLWithOptions('a.riv#old=1', {})).toBe('a.riv');
  });
});

describe('the item background props', () => {
  it('names the capsule constant 1000, as every platform does', () => {
    expect(cylAnimatedItemCornerRadiusCapsule).toBe(1000);
  });

  it('declares the five frozen names in the native spec, flat by default and the radius unset', () => {
    const spec = readFileSync(join(__dirname, '../CyltabbarAnimationViewNativeComponent.ts'), 'utf8');
    expect(spec).toContain("itemBackgroundStyle?: CodegenTypes.WithDefault<'flat' | 'liquidGlass', 'flat'>");
    expect(spec).toContain('itemBackgroundColor?: ColorValue');
    expect(spec).toContain('itemCornerRadius?: CodegenTypes.WithDefault<CodegenTypes.Float, -1>');
    expect(spec).toContain('itemBorderWidth?: CodegenTypes.WithDefault<CodegenTypes.Float, 0>');
    expect(spec).toContain('itemBorderColor?: ColorValue');
  });
});
