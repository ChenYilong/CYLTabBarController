import { describe, expect, it, jest } from '@jest/globals';
import { readFileSync } from 'fs';
import { join } from 'path';

jest.mock('../CyltabbarAnimationViewNativeComponent', () => ({
  __esModule: true,
  default: 'CyltabbarAnimationView',
  Commands: { play: jest.fn(), stopAtProgress: jest.fn(), restart: jest.fn() },
}));

import { Commands } from '../CyltabbarAnimationViewNativeComponent';
import { animationURLWithOptions, animationViewHandle, nativeAnimationProps } from '../CYLAnimationView.native';

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

describe('nativeAnimationProps', () => {
  it('maps the contract props, with drivesAnimationPlayback true and playing false by default', () => {
    const props = nativeAnimationProps({
      file: 'house.riv',
      options: { input: 'active' },
      selected: true,
      animationSpeed: 2,
      animationLoops: true,
      animationRestartToken: 3,
      iconSize: 32,
      tintColor: '#FF0000',
    });
    expect(props).toMatchObject({
      source: 'house.riv#input=active',
      playing: false,
      selected: true,
      animationSpeed: 2,
      animationLoops: true,
      animationRestartToken: 3,
      drivesAnimationPlayback: true,
      iconSize: 32,
      tintColor: '#FF0000',
    });
    expect(nativeAnimationProps({ file: 'a.gif', drivesAnimationPlayback: false, playing: true })).toMatchObject({
      drivesAnimationPlayback: false,
      playing: true,
    });
  });

  it('turns the events into plain callbacks and leaves them out when not given', () => {
    const onAnimationEnd = jest.fn();
    const props = nativeAnimationProps({ file: 'a.gif', onAnimationEnd });
    props.onAnimationEnd?.({ nativeEvent: {} } as never);
    expect(onAnimationEnd).toHaveBeenCalledTimes(1);
    expect(onAnimationEnd).toHaveBeenCalledWith();
    expect(props.onAnimationLoaded).toBeUndefined();
    expect(props.onAnimationFailed).toBeUndefined();
  });
});

describe('animationViewHandle', () => {
  it('sends play, stopAtProgress and restart to the native view', () => {
    const native = { name: 'native' } as never;
    const handle = animationViewHandle(() => native);
    handle.play();
    handle.stopAtProgress(0.5);
    handle.restart();
    expect(Commands.play).toHaveBeenCalledWith(native);
    expect(Commands.stopAtProgress).toHaveBeenCalledWith(native, 0.5);
    expect(Commands.restart).toHaveBeenCalledWith(native);
  });

  it('does nothing before the native view exists', () => {
    jest.clearAllMocks();
    const handle = animationViewHandle(() => null);
    handle.play();
    handle.stopAtProgress(1);
    handle.restart();
    expect(Commands.play).not.toHaveBeenCalled();
    expect(Commands.stopAtProgress).not.toHaveBeenCalled();
    expect(Commands.restart).not.toHaveBeenCalled();
  });
});
