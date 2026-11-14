// The playback controls (Play all, speed slider, loop switch): what a screen reader says and what each control reports.
// 播放控件（全部播放、倍速滑块、循环开关）：读屏软件读出的内容，以及各控件的回调。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_cyltabbar_example/demo/cyl_demo_list.dart';
import 'package:flutter_cyltabbar_example/demo/cyl_playback_controls.dart';

void main() {
  Widget host({
    double speed = 1.5,
    bool loops = false,
    VoidCallback? onPlayAll,
    ValueChanged<double>? onSpeed,
    ValueChanged<bool>? onLoops,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CYLPlaybackControls(
          colors: const CYLDemoColors(false),
          tint: Colors.blue,
          speed: speed,
          loops: loops,
          onPlayAll: onPlayAll ?? () {},
          onSpeedChanged: onSpeed ?? (_) {},
          onLoopsChanged: onLoops ?? (_) {},
        ),
      ),
    );
  }

  test('the speed reads without trailing zeros', () {
    expect(cylSpeedText(1), '1');
    expect(cylSpeedText(1.5), '1.5');
    expect(cylSpeedText(0.25), '0.25');
    expect(cylSpeedText(3), '3');
  });

  testWidgets(
    'a screen reader finds Play all, Speed with its value, and Loop with its state',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(speed: 1.5, loops: true));
      final button = tester.getSemantics(find.text('Play all'));
      expect(button.label, 'Play all');
      expect(button.flagsCollection.isButton, isTrue);
      // One node each: the label with the value and the slider actions, the label with the toggled state.
      // 各占一个节点：标签加值与滑块操作，标签加开关状态。
      final merged = find.descendant(
        of: find.byType(CYLPlaybackControls),
        matching: find.byType(MergeSemantics),
      );
      // getSemanticsData() is the merged data of the node: what the platform gets. 合并后的数据：平台得到的内容。
      final speed = tester.getSemantics(merged.at(0)).getSemanticsData();
      expect(speed.label, 'Speed');
      expect(speed.value, '1.5 times');
      expect(speed.flagsCollection.isSlider, isTrue);
      final loop = tester.getSemantics(merged.at(1)).getSemanticsData();
      expect(loop.label, 'Loop');
      expect(loop.flagsCollection.isToggled.name, 'isTrue');
      expect(find.text('1.5×'), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets('the three controls report their changes', (tester) async {
    var playAll = 0;
    double? speed;
    bool? loops;
    await tester.pumpWidget(
      host(
        onPlayAll: () => playAll++,
        onSpeed: (value) => speed = value,
        onLoops: (value) => loops = value,
      ),
    );
    await tester.tap(find.text('Play all'));
    expect(playAll, 1);
    await tester.tap(find.byType(Switch));
    expect(loops, isTrue);
    await tester.tap(find.byType(Slider));
    expect(speed, isNotNull);
    expect(
      speed!,
      inInclusiveRange(cylPlaybackMinimumSpeed, cylPlaybackMaximumSpeed),
    );
  });
}
