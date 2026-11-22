import { describe, it, expect } from '@ohos/hypium';
import {
  CYLRiveIcon, CYLRiveLoopPolicy, CYLRiveAnimationBuilder, cylRegisterRiveEngine, CYLAnimatedItemEngines, CYLTabBarAnimationOptionRiveArtboard,
  cylRiveNextNumber, cylRiveIsSupported
} from 'cyltabbar';

/**
 * [EN] The Rive engine module (cylanimateditemrive) as the app sees it through cyltabbar: every moved name is still exported
 *      (this file compiling is the re-export test), the loop policy defaults to the tab bar's, a loop while playing schedules
 *      the next pass without a selection, and registering Rive with the engine registry follows the device's ABIs.
 * [CN] 应用通过 cyltabbar 看到的 Rive 引擎模块（cylanimateditemrive）：移动过的名称仍然导出（本文件能编译即重新导出的测试）、
 *      循环策略默认为 Tab 栏的策略、播放中的循环无需选中也会安排下一遍、向引擎注册表注册 Rive 遵循设备的 ABI。
 */
export default function cylRiveLoopPolicyTest() {
  describe('CYLRiveLoopPolicy', () => {
    it('re-exports what moved out of cyltabbar', 0, () => {
      expect(CYLTabBarAnimationOptionRiveArtboard).assertEqual('artboard');
      expect(cylRiveNextNumber('3,4,5', 5)).assertEqual(3);
      expect(typeof CYLRiveIcon !== 'undefined').assertTrue();
      expect(typeof CYLRiveAnimationBuilder !== 'undefined').assertTrue();
    });

    it('the default policy is the tab one: loops only while selected', 0, () => {
      expect(CYLRiveLoopPolicy.isActive(CYLRiveLoopPolicy.WhileSelected, false, false)).assertFalse();
      expect(CYLRiveLoopPolicy.schedulesNextPass(CYLRiveLoopPolicy.WhileSelected, true, false, false)).assertFalse();
      expect(CYLRiveLoopPolicy.schedulesNextPass(CYLRiveLoopPolicy.WhileSelected, true, true, false)).assertTrue();
      expect(CYLRiveLoopPolicy.updateAction(CYLRiveLoopPolicy.WhileSelected, false, false, false)).assertEqual(CYLRiveLoopPolicy.Stop);
    });

    it('loop while playing schedules the next pass without a selection', 0, () => {
      expect(CYLRiveLoopPolicy.updateAction(CYLRiveLoopPolicy.WhilePlaying, false, false, false)).assertEqual(CYLRiveLoopPolicy.Play);
      expect(CYLRiveLoopPolicy.schedulesNextPass(CYLRiveLoopPolicy.WhilePlaying, true, false, false)).assertTrue();
      expect(CYLRiveLoopPolicy.schedulesNextPass(CYLRiveLoopPolicy.WhilePlaying, false, false, false)).assertFalse();
      expect(CYLRiveLoopPolicy.schedulesNextPass(CYLRiveLoopPolicy.WhilePlaying, true, false, true)).assertFalse();
    });

    it('cylRegisterRiveEngine registers Rive and keeps its ABIs (the x86_64 debug kit included)', 0, () => {
      const before: string = CYLAnimatedItemEngines.requiredNativeAbis('Rive').join(',');
      cylRegisterRiveEngine();
      expect(CYLAnimatedItemEngines.isRegistered('Rive')).assertTrue();
      expect(CYLAnimatedItemEngines.requiredNativeAbis('Rive').join(',')).assertEqual(before);
      expect(CYLAnimatedItemEngines.requiredNativeAbis('Rive').includes('arm64-v8a')).assertTrue();
      expect(cylRiveIsSupported()).assertEqual(CYLAnimatedItemEngines.isSupportedOnDevice('Rive'));
    });
  });
}
