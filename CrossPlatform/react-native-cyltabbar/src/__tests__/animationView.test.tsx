import { describe, expect, it, jest } from '@jest/globals';
import { readFileSync } from 'fs';
import { join } from 'path';

jest.mock('../CyltabbarAnimationViewNativeComponent', () => ({
  __esModule: true,
  default: 'CyltabbarAnimationView',
  Commands: { play: jest.fn(), stopAtProgress: jest.fn(), restart: jest.fn() },
}));

// The component only needs `useRef` and `useImperativeHandle` here; calling it directly returns the element it renders.
jest.mock('react', () => ({
  ...(jest.requireActual('react') as object),
  useRef: () => ({ current: null }),
  useImperativeHandle: () => {},
}));

import { CYLAnimationView, animationURLWithOptions, cylAnimatedItemCornerRadiusCapsule } from '../CYLAnimationView.native';

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
    expect(spec).toContain('itemContentHorizontalInset?: CodegenTypes.WithDefault<CodegenTypes.Float, -1>');
    expect(spec).toContain('itemBorderWidth?: CodegenTypes.WithDefault<CodegenTypes.Float, 0>');
    expect(spec).toContain('itemBorderColor?: ColorValue');
  });
});

describe('onResourceMissing', () => {
  it('declares the event with the frozen payload in the native spec', () => {
    const spec = readFileSync(join(__dirname, '../CyltabbarAnimationViewNativeComponent.ts'), 'utf8');
    expect(spec).toContain('onResourceMissing?: CodegenTypes.DirectEventHandler<ResourceMissingEvent>');
    expect(spec).toContain('Readonly<{ resource: string; reason: string }>');
  });

  it('passes resource and reason from the native event through unchanged', () => {
    const heard: Array<{ resource: string; reason: string }> = [];
    const element = CYLAnimationView({ file: 'home.pag', onResourceMissing: (event) => heard.push(event) }) as unknown as {
      props: { onResourceMissing?: (event: { nativeEvent: { resource: string; reason: string } }) => void };
    };
    element.props.onResourceMissing?.({ nativeEvent: { resource: 'home.pag', reason: 'not found' } });
    element.props.onResourceMissing?.({ nativeEvent: { resource: 'a.riv', reason: 'engine library missing' } });
    expect(heard).toEqual([
      { resource: 'home.pag', reason: 'not found' },
      { resource: 'a.riv', reason: 'engine library missing' },
    ]);
  });

  it('sends no handler to the native view when the prop is not given', () => {
    const element = CYLAnimationView({ file: 'home.pag' }) as unknown as { props: { onResourceMissing?: unknown } };
    expect(element.props.onResourceMissing).toBeUndefined();
  });
});

describe('the v2 tint props', () => {
  type Sent = {
    tintColor?: unknown;
    animationTint?: string;
    animationDarkTint?: string;
    animationRenderingMode?: string;
    selected?: boolean;
    enabled?: boolean;
  };
  const sent = (props: Record<string, unknown>) =>
    (CYLAnimationView({ file: 'a.json', ...props } as never) as unknown as { props: Sent }).props;

  it('forwards animationTint, animationDarkTint and animationRenderingMode by their native names', () => {
    const props = sent({ animationTint: 'title', animationDarkTint: '#FFFFFF', animationRenderingMode: 'alwaysTemplate', tintColor: '#FF0000' });
    expect(props.animationTint).toBe('title');
    expect(props.animationDarkTint).toBe('#FFFFFF');
    expect(props.animationRenderingMode).toBe('alwaysTemplate');
    expect(props.tintColor).toBe('#FF0000');
  });

  it('sends alwaysOriginal as is', () => {
    expect(sent({ animationRenderingMode: 'alwaysOriginal' }).animationRenderingMode).toBe('alwaysOriginal');
  });

  it('forces nothing when the props are undefined: no tint, automatic mode', () => {
    const props = sent({});
    expect(props.tintColor).toBeUndefined();
    expect('tintColor' in props && props.tintColor !== undefined).toBe(false);
    expect(props.animationTint).toBeUndefined();
    expect(props.animationDarkTint).toBeUndefined();
    expect(props.animationRenderingMode).toBe('automatic');
  });

  it('resets when a prop goes from set to undefined or empty (the native side then gets undefined, i.e. nil)', () => {
    expect(sent({ animationTint: '#112233', tintColor: 'red' }).animationTint).toBe('#112233');
    const reset = sent({ animationTint: undefined, animationDarkTint: '', tintColor: undefined, animationRenderingMode: undefined });
    expect(reset.animationTint).toBeUndefined();
    expect(reset.animationDarkTint).toBeUndefined();
    expect(reset.tintColor).toBeUndefined();
    expect(reset.animationRenderingMode).toBe('automatic');
  });

  it('keeps passing selected through', () => {
    expect(sent({ selected: true }).selected).toBe(true);
    expect(sent({}).selected).toBeUndefined();
  });

  it('writes the URL option renderingMode= like any other option', () => {
    expect(animationURLWithOptions('a.json', { renderingMode: 'alwaysOriginal' })).toBe('a.json#renderingMode=alwaysOriginal');
    expect(animationURLWithOptions('a.riv', { tint: 'title', renderingMode: 'alwaysTemplate' })).toBe('a.riv#renderingMode=alwaysTemplate&tint=title');
    expect(animationURLWithOptions('a.json', { renderingMode: '' })).toBe('a.json');
  });

  it('declares the three props in the native spec with automatic as the default and tintColor optional', () => {
    const spec = readFileSync(join(__dirname, '../CyltabbarAnimationViewNativeComponent.ts'), 'utf8');
    expect(spec).toContain('tintColor?: ColorValue');
    expect(spec).toContain('animationTint?: string');
    expect(spec).toContain('animationDarkTint?: string');
    expect(spec).toContain("animationRenderingMode?: CodegenTypes.WithDefault<'automatic' | 'alwaysTemplate' | 'alwaysOriginal', 'automatic'>");
  });
});
