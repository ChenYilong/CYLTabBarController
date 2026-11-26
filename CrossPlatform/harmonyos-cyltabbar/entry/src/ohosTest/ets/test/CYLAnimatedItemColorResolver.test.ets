import { describe, it, expect } from '@ohos/hypium';
import {
  CYLAnimatedItemBackgroundStyle, CYLAnimatedItemColorInput, CYLAnimatedItemColorResolver, CYLAnimatedItemContrast, CYLAnimatedItemContrastKindText,
  CYLAnimatedItemContrastRGBA, CYLAnimatedItemEngines, CYLAnimatedItemLiquidGlassContentInset, CYLAnimatedItemPlayback, CYLAnimatedItemPlaybackDriver,
  CYLAnimatedItemPlayer, CYLAnimatedItemSource, CYLAnimatedItemStatics
} from 'cylanimateditem';

const DARK_TEXT: string = '#FF3C3C43';
const OWN: string = '#FF111111';
const SUBCLASS: string = '#FF222222';
const STACK: string = '#FF333333';
const SUBCLASS_BUILT_IN: string = '#FF444444';
const SUBCLASS_SELECTED: string = '#FF555555';
const PASSING: number = 4.49;
const ICON_PASSING: number = 2.99;

function rgbaOf(color: ResourceColor): CYLAnimatedItemContrastRGBA {
  const rgba: CYLAnimatedItemContrastRGBA | undefined = CYLAnimatedItemContrast.components(color);
  return rgba === undefined ? new CYLAnimatedItemContrastRGBA(0, 0, 0, 0) : rgba;
}

/** [EN] The contrast of a colour on the rendered glass (the reference the lift judges against). [CN] 颜色在实际渲染玻璃上的对比度（提亮所对照的参考）。 */
function renderedContrast(color: ResourceColor): number {
  const c: CYLAnimatedItemContrastRGBA = rgbaOf(color);
  return CYLAnimatedItemContrast.contrastRatio(CYLAnimatedItemContrast.relativeLuminance(c.red, c.green, c.blue),
    CYLAnimatedItemContrast.renderedGlassReferenceLuminance(undefined, undefined));
}

/** [EN] An input on drawn dark glass (or not), for the title or the icon. [CN] 绘制深色玻璃（或没有）上的输入，用于标题或图标。 */
function inputOf(kind: string, glassDark: boolean): CYLAnimatedItemColorInput {
  const input: CYLAnimatedItemColorInput = new CYLAnimatedItemColorInput();
  input.kind = kind;
  input.drawsGlass = glassDark;
  input.dark = glassDark;
  return input;
}

function titleOf(input: CYLAnimatedItemColorInput): ResourceColor {
  return CYLAnimatedItemColorResolver.resolvedTitleColor(input);
}

function iconOf(input: CYLAnimatedItemColorInput): ResourceColor {
  return CYLAnimatedItemColorResolver.resolvedIconColor(input);
}

/** [EN] A player that records what the driver asks. [CN] 记录驱动请求的播放器。 */
class RecordingPlayer extends CYLAnimatedItemPlayer {
  calls: string[] = [];

  constructor() {
    super('Test', new CYLAnimatedItemSource());
  }

  play(): void {
    this.calls.push('play');
  }

  stopAtProgress(progress: number): void {
    this.calls.push(`stop${progress}`);
  }
}

function playback(selected: boolean, lastFrame: boolean, token: number = 0): CYLAnimatedItemPlayback {
  return { selected: selected, speed: 1, loops: false, restartToken: token, showsLastFrameWhenSelected: lastFrame };
}

/**
 * [EN] The iOS tint unification on HarmonyOS: the rendered-glass floor of the lift, the ONE colour resolution (own > subclass-explicit > stack >
 *      subclass built-in > component built-in, adapted on drawn dark glass except the disabled look), the static helpers and the last-frame playback.
 * [CN] iOS tint 统一在鸿蒙上的实现：提亮的实际玻璃下限、唯一的颜色解析（自己的 > 子类显式 > 堆叠 > 子类内置 > 组件内置，除禁用外观外在绘制的深色玻璃上适配）、
 *      静态辅助函数与最后一帧播放。
 */
export default function cylAnimatedItemColorResolverTest() {
  describe('CYLAnimatedItemColorResolver', () => {
    it('the rendered reference is max(model, floor) and the model is unchanged', 0, () => {
      const share: number = CYLAnimatedItemContrast.renderedDarkGlassWhiteShare;
      const floor: number = CYLAnimatedItemContrast.relativeLuminance(share, share, share);
      const model: number = CYLAnimatedItemContrast.relativeLuminance(0.14, 0.14, 0.14);
      expect(CYLAnimatedItemContrast.glassReferenceLuminance(undefined, undefined)).assertEqual(model);
      expect(floor > model).assertTrue();
      expect(CYLAnimatedItemContrast.renderedGlassReferenceLuminance(undefined, undefined)).assertEqual(floor);
      // A bright tint is above the floor: the model decides.
      const bright: string = '#FFFFFFFF';
      expect(CYLAnimatedItemContrast.renderedGlassReferenceLuminance(bright, 1)).assertEqual(CYLAnimatedItemContrast.glassReferenceLuminance(bright, 1));
    });

    it('an explicit #3C3C43 title on drawn dark glass reaches 4.5 against the rendered glass', 0, () => {
      const input: CYLAnimatedItemColorInput = inputOf(CYLAnimatedItemContrastKindText, true);
      input.subclassExplicit.normal = DARK_TEXT;
      const lifted: ResourceColor = titleOf(input);
      expect(lifted === DARK_TEXT).assertFalse();
      expect(renderedContrast(lifted) >= PASSING).assertTrue();
      expect(renderedContrast(DARK_TEXT) < PASSING).assertTrue();
    });

    it('adaptedOnGlassState follows the drawn glass and the mode only', 0, () => {
      expect(CYLAnimatedItemContrast.adaptedOnGlassState(DARK_TEXT, CYLAnimatedItemContrastKindText, false, true, undefined, undefined)).assertEqual(DARK_TEXT);
      expect(CYLAnimatedItemContrast.adaptedOnGlassState(DARK_TEXT, CYLAnimatedItemContrastKindText, true, false, undefined, undefined)).assertEqual(DARK_TEXT);
      expect(CYLAnimatedItemContrast.adaptedOnGlassState(DARK_TEXT, CYLAnimatedItemContrastKindText, true, true, undefined, undefined) === DARK_TEXT)
        .assertFalse();
    });

    it('own beats subclass-explicit beats stack beats subclass built-in beats the component built-in (flat: nothing adapted)', 0, () => {
      const input: CYLAnimatedItemColorInput = inputOf(CYLAnimatedItemContrastKindText, false);
      expect(typeof titleOf(input) === 'object').assertTrue();
      input.subclassBuiltIn.normal = SUBCLASS_BUILT_IN;
      expect(titleOf(input)).assertEqual(SUBCLASS_BUILT_IN);
      input.stack.normal = STACK;
      expect(titleOf(input)).assertEqual(STACK);
      input.subclassExplicit.normal = SUBCLASS;
      expect(titleOf(input)).assertEqual(SUBCLASS);
      input.own.normal = OWN;
      expect(titleOf(input)).assertEqual(OWN);
      // The icon has its own resolution with the same order.
      const icon: CYLAnimatedItemColorInput = inputOf(CYLAnimatedItemContrastKindText, false);
      icon.subclassBuiltIn.normal = SUBCLASS_BUILT_IN;
      expect(iconOf(icon)).assertEqual(SUBCLASS_BUILT_IN);
      icon.stack.normal = STACK;
      expect(iconOf(icon)).assertEqual(STACK);
      icon.subclassExplicit.normal = SUBCLASS;
      expect(iconOf(icon)).assertEqual(SUBCLASS);
      icon.own.normal = OWN;
      expect(iconOf(icon)).assertEqual(OWN);
    });

    it('every level is adapted on drawn dark glass: title 4.5, icon 3', 0, () => {
      const levels: string[] = ['own', 'subclassExplicit', 'stack', 'subclassBuiltIn'];
      levels.forEach((level: string) => {
        const title: CYLAnimatedItemColorInput = inputOf(CYLAnimatedItemContrastKindText, true);
        const icon: CYLAnimatedItemColorInput = inputOf(CYLAnimatedItemContrastKindText, true);
        [title, icon].forEach((input: CYLAnimatedItemColorInput) => {
          if (level === 'own') {
            input.own.normal = DARK_TEXT;
          } else if (level === 'subclassExplicit') {
            input.subclassExplicit.normal = DARK_TEXT;
          } else if (level === 'stack') {
            input.stack.normal = DARK_TEXT;
          } else {
            input.subclassBuiltIn.normal = DARK_TEXT;
          }
        });
        expect(renderedContrast(titleOf(title)) >= PASSING).assertTrue();
        const iconColor: ResourceColor = iconOf(icon);
        expect(renderedContrast(iconColor) >= ICON_PASSING).assertTrue();
        // The icon is lifted to 3, not to 4.5: it is less light than the title.
        expect(rgbaOf(iconColor).red <= rgbaOf(titleOf(title)).red).assertTrue();
      });
    });

    it('a missing selected subclass value falls back to the normal one, the disabled one does not', 0, () => {
      const input: CYLAnimatedItemColorInput = inputOf(CYLAnimatedItemContrastKindText, false);
      input.selected = true;
      input.subclassExplicit.normal = SUBCLASS;
      expect(titleOf(input)).assertEqual(SUBCLASS);
      input.subclassExplicit.selected = SUBCLASS_SELECTED;
      expect(titleOf(input)).assertEqual(SUBCLASS_SELECTED);
      input.enabled = false;
      // Disabled: no fallback to the normal one, the component's disabled look.
      expect(titleOf(input)).assertEqual(CYLAnimatedItemColorResolver.builtInColor('disabled', false));
      input.subclassExplicit.disabled = STACK;
      expect(titleOf(input)).assertEqual(STACK);
    });

    it('the subclass built-in level has a selected value that falls back to the normal one, and is not used while disabled', 0, () => {
      const input: CYLAnimatedItemColorInput = inputOf(CYLAnimatedItemContrastKindText, false);
      input.subclassBuiltIn.normal = SUBCLASS_BUILT_IN;
      input.selected = true;
      expect(titleOf(input)).assertEqual(SUBCLASS_BUILT_IN);
      input.subclassBuiltIn.selected = SUBCLASS_SELECTED;
      expect(titleOf(input)).assertEqual(SUBCLASS_SELECTED);
      input.enabled = false;
      expect(titleOf(input)).assertEqual(CYLAnimatedItemColorResolver.builtInColor('disabled', false));
    });

    it('the disabled look is not adapted on drawn dark glass, an explicit disabled colour is', 0, () => {
      const input: CYLAnimatedItemColorInput = inputOf(CYLAnimatedItemContrastKindText, true);
      input.enabled = false;
      expect(titleOf(input)).assertEqual(CYLAnimatedItemColorResolver.builtInColor('disabled', true));
      expect(iconOf(input)).assertEqual(CYLAnimatedItemColorResolver.builtInColor('disabled', true));
      input.subclassExplicit.disabled = DARK_TEXT;
      expect(titleOf(input) === DARK_TEXT).assertFalse();
    });

    it('component built-in colours: normal white keeps its resource, selected blue is adapted on drawn dark glass only', 0, () => {
      const normal: CYLAnimatedItemColorInput = inputOf(CYLAnimatedItemContrastKindText, true);
      expect(typeof titleOf(normal) === 'object').assertTrue();
      const selected: CYLAnimatedItemColorInput = inputOf(CYLAnimatedItemContrastKindText, true);
      selected.selected = true;
      const lifted: ResourceColor = titleOf(selected);
      expect(typeof lifted === 'string').assertTrue();
      expect(renderedContrast(lifted) >= PASSING).assertTrue();
      // Flat or light: the resource, as before.
      const flat: CYLAnimatedItemColorInput = inputOf(CYLAnimatedItemContrastKindText, false);
      flat.selected = true;
      expect(typeof titleOf(flat) === 'object').assertTrue();
      const lightGlass: CYLAnimatedItemColorInput = inputOf(CYLAnimatedItemContrastKindText, true);
      lightGlass.dark = false;
      lightGlass.selected = true;
      expect(typeof titleOf(lightGlass) === 'object').assertTrue();
    });

    it('a dynamic colour (a resource) is never adapted', 0, () => {
      const resource: ResourceColor = $r('sys.color.font_secondary');
      const input: CYLAnimatedItemColorInput = inputOf(CYLAnimatedItemContrastKindText, true);
      input.subclassBuiltIn.normal = resource;
      expect(titleOf(input) === resource).assertTrue();
      input.subclassExplicit.normal = resource;
      expect(titleOf(input) === resource).assertTrue();
    });

    it('isSet treats undefined and blank text as not set', 0, () => {
      expect(CYLAnimatedItemColorResolver.isSet(undefined)).assertFalse();
      expect(CYLAnimatedItemColorResolver.isSet('')).assertFalse();
      expect(CYLAnimatedItemColorResolver.isSet('  ')).assertFalse();
      expect(CYLAnimatedItemColorResolver.isSet('#FF000000')).assertTrue();
      expect(CYLAnimatedItemColorResolver.isSet(0xFF000000)).assertTrue();
    });

    it('resolvedContentHorizontalInset and isAnimationEngineAvailable forward to what exists', 0, () => {
      expect(CYLAnimatedItemStatics.resolvedContentHorizontalInset(-1, CYLAnimatedItemBackgroundStyle.liquidGlass))
        .assertEqual(CYLAnimatedItemLiquidGlassContentInset);
      expect(CYLAnimatedItemStatics.resolvedContentHorizontalInset(-1, CYLAnimatedItemBackgroundStyle.flat)).assertEqual(0);
      expect(CYLAnimatedItemStatics.resolvedContentHorizontalInset(0, CYLAnimatedItemBackgroundStyle.liquidGlass)).assertEqual(0);
      expect(CYLAnimatedItemStatics.resolvedContentHorizontalInset(6, CYLAnimatedItemBackgroundStyle.flat)).assertEqual(6);
      expect(CYLAnimatedItemStatics.isAnimationEngineAvailable()).assertEqual(CYLAnimatedItemEngines.registeredTypes().length > 0);
    });

    it('a selected item rests on the last frame with showsLastFrameWhenSelected, and a restart still plays', 0, () => {
      const player: RecordingPlayer = new RecordingPlayer();
      const driver: CYLAnimatedItemPlaybackDriver = new CYLAnimatedItemPlaybackDriver();
      driver.attach(player, playback(true, true));
      expect(player.calls.join(',')).assertEqual('stop1');
      driver.update(playback(false, true));
      driver.update(playback(true, true));
      expect(player.calls.join(',')).assertEqual('stop1,stop0,stop1');
      driver.update(playback(true, true, 1));
      expect(player.calls[player.calls.length - 1]).assertEqual('play');
    });

    it('without the option a selected item plays, and turning the option on or off while selected follows', 0, () => {
      const player: RecordingPlayer = new RecordingPlayer();
      const driver: CYLAnimatedItemPlaybackDriver = new CYLAnimatedItemPlaybackDriver();
      driver.attach(player, playback(true, false));
      expect(player.calls.join(',')).assertEqual('play');
      driver.update(playback(true, true));
      expect(player.calls[player.calls.length - 1]).assertEqual('stop1');
      driver.update(playback(true, false));
      expect(player.calls[player.calls.length - 1]).assertEqual('play');
    });
  });
}
