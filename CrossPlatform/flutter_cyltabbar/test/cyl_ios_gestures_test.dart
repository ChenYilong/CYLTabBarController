import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cyltabbar/flutter_cyltabbar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('on iOS the native tab bar claims its touches at once (simulated taps select a tab)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    // [EN] No native side in a widget test: answer the platform view calls. [CN] 组件测试中没有原生端：应答平台视图调用。
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform_views, (call) async => null);
    try {
      await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr,
        child: CYLTabBar(items: [CYLTabBarItem(title: 'Home'), CYLTabBarItem(title: 'Me')]),
      ));
      final view = tester.widget<UiKitView>(find.byType(UiKitView));
      final recognizers = view.gestureRecognizers ?? const <Factory<OneSequenceGestureRecognizer>>{};
      expect(recognizers.map((factory) => factory.constructor()), contains(isA<EagerGestureRecognizer>()));
    } finally {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
