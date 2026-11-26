import cylAnimatedItemFallbackTest from './CYLAnimatedItemFallback.test';
import cylRiveLoopPolicyTest from './CYLRiveLoopPolicy.test';
import cylRiveOptionsTest from './CYLRiveOptions.test';
import cylTabBarHeightTest from './CYLTabBarHeight.test';
import demoTeardownTest from './DemoTeardown.test';
import cylGlassHighlightTest from './CYLGlassHighlight.test';
import cylAnimatedItemContrastTest from './CYLAnimatedItemContrast.test';

export default function testsuite() {
  cylAnimatedItemFallbackTest();
  cylRiveLoopPolicyTest();
  cylRiveOptionsTest();
  cylTabBarHeightTest();
  demoTeardownTest();
  cylGlassHighlightTest();
  cylAnimatedItemContrastTest();
}
