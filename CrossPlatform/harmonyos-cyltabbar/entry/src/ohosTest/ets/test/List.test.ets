import cylAnimatedItemFallbackTest from './CYLAnimatedItemFallback.test';
import cylRiveLoopPolicyTest from './CYLRiveLoopPolicy.test';
import cylRiveOptionsTest from './CYLRiveOptions.test';
import cylTabBarHeightTest from './CYLTabBarHeight.test';
import demoTeardownTest from './DemoTeardown.test';

export default function testsuite() {
  cylAnimatedItemFallbackTest();
  cylRiveLoopPolicyTest();
  cylRiveOptionsTest();
  cylTabBarHeightTest();
  demoTeardownTest();
}
