import { describe, it, expect, afterEach } from '@ohos/hypium';
import { Driver, ON } from '@kit.TestKit';
import { CYLAnimatedItemEngines } from 'cyltabbar';

/**
 * [EN] The x86_64 fallback path of cylanimateditem on a real device or emulator (cylanimateditem/README.md, "x86_64
 *      emulator"). The expectations follow the device: on the x86_64 emulator PAG and Rive are unsupported and their
 *      items show the still image; on an arm64 device they are supported. Run (x86_64 emulator):
 *      hvigorw --mode module -p module=entry@ohosTest -p isOhosTest=true -p buildMode=emulatorTest -p product=default assembleHap,
 *      install entry/build/default/outputs/ohosTest/entry-ohosTest-unsigned.hap and the emulator app HAP, then
 *      hdc shell aa test -b com.cyl.tabbar.harmony -m entry_test -s unittest OpenHarmonyTestRunner -s timeout 15000
 * [CN] cylanimateditem 的 x86_64 回退路径在真机或模拟器上的测试。期望随设备而定：x86_64 模拟器上 PAG 与 Rive 不受支持，其条目显示静态图片；
 *      arm64 设备上受支持。
 */
function onArm64(): boolean {
  return CYLAnimatedItemEngines.deviceAbis().indexOf('arm64-v8a') >= 0;
}

export default function cylAnimatedItemFallbackTest() {
  describe('CYLAnimatedItemFallback', () => {
    afterEach(() => {
      CYLAnimatedItemEngines.setDeviceAbis(undefined);
    });

    it('reads the device ABIs from deviceInfo', 0, () => {
      expect(CYLAnimatedItemEngines.deviceAbis().length > 0).assertTrue();
    });

    it('PAG and Rive need arm64-v8a, Lottie SVGA and GIF need no native library', 0, () => {
      expect(CYLAnimatedItemEngines.requiredNativeAbis('PAG').join(',')).assertEqual('arm64-v8a');
      expect(CYLAnimatedItemEngines.requiredNativeAbis('Rive').join(',')).assertEqual('arm64-v8a');
      expect(CYLAnimatedItemEngines.requiredNativeAbis('Lottie').length).assertEqual(0);
      expect(CYLAnimatedItemEngines.isSupportedOnDevice('Lottie')).assertTrue();
      expect(CYLAnimatedItemEngines.isSupportedOnDevice('SVGA')).assertTrue();
      expect(CYLAnimatedItemEngines.isSupportedOnDevice('GIF')).assertTrue();
    });

    it('this device: PAG and Rive are supported exactly when it has arm64-v8a', 0, () => {
      CYLAnimatedItemEngines.register('Rive');
      expect(CYLAnimatedItemEngines.isSupportedOnDevice('Rive')).assertEqual(onArm64());
      expect(CYLAnimatedItemEngines.isSupportedOnDevice('PAG')).assertEqual(onArm64());
      expect(CYLAnimatedItemEngines.canPlay('icons.riv')).assertEqual(onArm64());
      expect(CYLAnimatedItemEngines.unsupportedReason('icons.riv').length > 0).assertEqual(!onArm64());
    });

    it('a simulated x86_64 device: Rive does not play and says why; arm64 plays it', 0, () => {
      CYLAnimatedItemEngines.register('Rive');
      CYLAnimatedItemEngines.setDeviceAbis(['x86_64']);
      expect(CYLAnimatedItemEngines.canPlay('icons.riv')).assertFalse();
      expect(CYLAnimatedItemEngines.unsupportedReason('icons.riv'))
        .assertEqual('Rive needs a native library built for arm64-v8a; this device has x86_64');
      CYLAnimatedItemEngines.setDeviceAbis(['arm64-v8a']);
      expect(CYLAnimatedItemEngines.canPlay('icons.riv')).assertTrue();
      expect(CYLAnimatedItemEngines.unsupportedReason('icons.riv')).assertEqual('');
    });

    it('an app engine with a native library follows the same rule', 0, () => {
      CYLAnimatedItemEngines.setDeviceAbis(['x86_64']);
      CYLAnimatedItemEngines.register('CYLTestNative', ['cyltestnative'], 'a test package', ['arm64-v8a']);
      expect(CYLAnimatedItemEngines.canPlay('a.cyltestnative')).assertFalse();
      CYLAnimatedItemEngines.setRequiredNativeAbis('CYLTestNative', []);
      expect(CYLAnimatedItemEngines.canPlay('a.cyltestnative')).assertTrue();
      CYLAnimatedItemEngines.unregister('CYLTestNative');
    });

    it('UI: the Rive item builds no engine view without arm64-v8a and shows its still image; Lottie builds one', 0,
      async (done: Function) => {
        const driver = Driver.create();
        await driver.delayMs(1500);
        const riveItem = await driver.findComponent(ON.id('cyl-test-rive-item'));
        const lottieItem = await driver.findComponent(ON.id('cyl-test-lottie-item'));
        expect(riveItem !== null && riveItem !== undefined).assertTrue();
        expect(lottieItem !== null && lottieItem !== undefined).assertTrue();
        const riveEngine = await driver.findComponent(ON.id('cyl-test-engine-Rive'));
        const lottieEngine = await driver.findComponent(ON.id('cyl-test-engine-Lottie'));
        expect(riveEngine !== null && riveEngine !== undefined).assertEqual(onArm64());
        expect(lottieEngine !== null && lottieEngine !== undefined).assertTrue();
        const rect = await riveItem.getBounds();
        expect(rect.right - rect.left > 0 && rect.bottom - rect.top > 0).assertTrue();
        done();
      });
  });
}
