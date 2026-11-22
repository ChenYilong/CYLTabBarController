import { describe, it, expect } from '@ohos/hypium';
import { CYLTabBarAnimationURLWithOptions, cylRiveFileAndOptions } from 'cyltabbar';

/**
 * [EN] CYLTabBarAnimationURLWithOptions writes Rive options into the fragment ("#", sorted, percent-encoded), as on iOS and
 *      Android; cylRiveFileAndOptions reads them after "#" or after "?" (the earlier HarmonyOS form, still in the
 *      configuration files); the file part never keeps either.
 * [CN] CYLTabBarAnimationURLWithOptions 把 Rive 选项写入 fragment（"#"，按名称排序，百分号编码），与 iOS、Android 相同；cylRiveFileAndOptions
 *      读取 "#" 或 "?"（鸿蒙之前的写法，配置文件仍在使用）之后的选项；文件部分不包含二者。
 */
export default function cylRiveOptionsTest() {
  describe('CYLRiveOptions', () => {
    it('reads options after "?"', 0, () => {
      const parts = cylRiveFileAndOptions('icons.riv?artboard=CHAT&stateMachine=CHAT_Interactivity');
      expect(parts[0]).assertEqual('icons.riv');
      expect(parts[1]['artboard']).assertEqual('CHAT');
      expect(parts[1]['stateMachine']).assertEqual('CHAT_Interactivity');
    });

    it('reads options after "#", percent-decoded', 0, () => {
      const parts = cylRiveFileAndOptions('success.riv#stateMachine=State%20Machine%201&triggerInput=Trigger%20explosion');
      expect(parts[0]).assertEqual('success.riv');
      expect(parts[1]['stateMachine']).assertEqual('State Machine 1');
      expect(parts[1]['triggerInput']).assertEqual('Trigger explosion');
    });

    it('reads both when "?" and "#" are present', 0, () => {
      const parts = cylRiveFileAndOptions('icons.riv?artboard=CHAT#input=active');
      expect(parts[0]).assertEqual('icons.riv');
      expect(parts[1]['artboard']).assertEqual('CHAT');
      expect(parts[1]['input']).assertEqual('active');
    });

    it('keeps an unencoded color value whole', 0, () => {
      const parts = cylRiveFileAndOptions('icons.riv?artboard=CHAT&tint=#FF3B30');
      expect(parts[1]['artboard']).assertEqual('CHAT');
      expect(parts[1]['tint']).assertEqual('#FF3B30');
    });

    it('a path without options is the file', 0, () => {
      const parts = cylRiveFileAndOptions('house.riv');
      expect(parts[0]).assertEqual('house.riv');
      expect(Object.keys(parts[1]).length).assertEqual(0);
    });

    it('writes the options into the fragment, sorted and percent-encoded', 0, () => {
      const url = CYLTabBarAnimationURLWithOptions('rive/icons.riv',
        { 'stateMachine': 'CHAT_Interactivity', 'artboard': 'CHAT', 'tint': '#FF3B30', 'input': '' });
      expect(url).assertEqual('rive/icons.riv#artboard=CHAT&stateMachine=CHAT_Interactivity&tint=%23FF3B30');
      const parts = cylRiveFileAndOptions(url);
      expect(parts[0]).assertEqual('rive/icons.riv');
      expect(parts[1]['tint']).assertEqual('#FF3B30');
      expect(parts[1]['input']).assertEqual(undefined);
    });

    it('replaces a fragment the URL had; no options gives the file', 0, () => {
      expect(CYLTabBarAnimationURLWithOptions('a.riv#artboard=OLD', { 'artboard': 'NEW' })).assertEqual('a.riv#artboard=NEW');
      expect(CYLTabBarAnimationURLWithOptions('a.riv#artboard=OLD', {})).assertEqual('a.riv');
    });
  });
}
