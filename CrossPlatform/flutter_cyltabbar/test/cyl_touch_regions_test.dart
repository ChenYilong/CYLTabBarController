import 'package:flutter/widgets.dart';
import 'package:flutter_cyltabbar/src/cyl_touch_regions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the rects a native view reports', () {
    expect(CYLTouchRegions.parse([
      [0, 20, 390, 63],
      [160, 0, 70.5, 60],
      'ignored',
    ]), const [Rect.fromLTWH(0, 20, 390, 63), Rect.fromLTWH(160, 0, 70.5, 60)]);
    expect(CYLTouchRegions.parse(null), isEmpty);
  });

  testWidgets('the transparent strip passes taps to the widgets below', (tester) async {
    final taps = <String>[];
    Widget app(List<Rect>? rects) => Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(children: [
            Positioned.fill(child: GestureDetector(onTap: () => taps.add('below'), behavior: HitTestBehavior.opaque)),
            Positioned(
              left: 0,
              top: 0,
              width: 400,
              height: 100,
              child: CYLTouchRegions(
                rects: rects,
                child: GestureDetector(onTap: () => taps.add('bar'), behavior: HitTestBehavior.opaque),
              ),
            ),
          ]),
        );
    // [EN] The bar from y 20, the plus button rising to y 0 in the middle. [CN] TabBar 从 y 20 开始，PlusButton 在中间升到 y 0。
    await tester.pumpWidget(app(const [Rect.fromLTWH(0, 20, 400, 80), Rect.fromLTWH(170, 0, 60, 60)]));
    await tester.tapAt(const Offset(10, 10));
    await tester.tapAt(const Offset(200, 10));
    await tester.tapAt(const Offset(10, 50));
    expect(taps, ['below', 'bar', 'bar']);
    // [EN] Before the native view reports its rects, the whole view takes taps. [CN] 原生视图报告矩形之前，整个视图接收点击。
    taps.clear();
    await tester.pumpWidget(app(null));
    await tester.tapAt(const Offset(10, 10));
    expect(taps, ['bar']);
  });
}
