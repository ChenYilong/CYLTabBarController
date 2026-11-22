import { describe, it, expect } from '@ohos/hypium';
import { cylRiveFileAndOptions } from 'cyltabbar';

/**
 * [EN] Rive options follow "?" (as CYLTabBarAnimationURLWithOptions writes them on HarmonyOS) or "#" (the fragment iOS,
 *      CYLTableViewPlaceHolder and the WeChat Mini Program use); the file part never keeps either.
 * [CN] Rive 选项跟在 "?"（鸿蒙端 CYLTabBarAnimationURLWithOptions 的写法）或 "#"（iOS、CYLTableViewPlaceHolder 与微信小程序使用的 fragment）之后；
 *      文件部分不包含二者。
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

    it('a path without options is the file', 0, () => {
      const parts = cylRiveFileAndOptions('house.riv');
      expect(parts[0]).assertEqual('house.riv');
      expect(Object.keys(parts[1]).length).assertEqual(0);
    });
  });
}
