import 'dart:convert';
import 'dart:io';

import 'package:flutter_cyltabbar/flutter_cyltabbar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the file URL carries its options sorted by name, percent-encoded, empty values left out', () {
    expect(animationURLWithOptions('icons.riv'), 'icons.riv');
    expect(
      animationURLWithOptions('icons.riv#old=1', {'stateMachine': 'State Machine 1', 'artboard': 'CHAT', 'input': ''}),
      'icons.riv#artboard=CHAT&stateMachine=State%20Machine%201',
    );
  });

  test('animationURLWithOptions writes every case of the shared fixture so that it reads back the same', () {
    final fixture = jsonDecode(File('../animated-item-fixtures/source-options.json').readAsStringSync()) as Map<String, dynamic>;
    final cases = (fixture['cases'] as List)
        .cast<Map<String, dynamic>>()
        .where((c) => c['file'] != null && !(c['input'] as String).trim().startsWith('{'));
    expect(cases.length, greaterThanOrEqualTo(6));
    for (final c in cases) {
      final options = (c['options'] as Map).cast<String, Object>();
      final url = animationURLWithOptions(c['file'] as String, options);
      final parts = url.split('#');
      expect(parts.first, c['file']);
      final read = <String, String>{};
      if (parts.length > 1) {
        for (final pair in parts[1].split('&').where((p) => p.isNotEmpty)) {
          final index = pair.indexOf('=');
          read[Uri.decodeComponent(pair.substring(0, index))] = Uri.decodeComponent(pair.substring(index + 1));
        }
      }
      expect(read, options.map((k, v) => MapEntry(k, '$v')));
    }
  });

  test('the defaults: drives the playback, not selected, speed 1, no loop, no restart', () {
    const view = CYLAnimationView(file: 'a.riv');
    expect(view.drivesAnimationPlayback, isTrue);
    expect(view.selected, isFalse);
    expect(view.animationSpeed, 1);
    expect(view.animationLoops, isFalse);
    expect(view.animationRestartToken, 0);
    expect(view.showsImageWhenAnimationEnds, isFalse);
    expect(view.image, isNull);
    expect(view.playing, isFalse);
  });

  test('the item background defaults: flat, no color, radius unset, no border', () {
    const view = CYLAnimationView(file: 'a.riv');
    expect(view.itemBackgroundStyle, CYLAnimatedItemBackgroundStyle.flat);
    expect(view.itemBackgroundColor, isNull);
    expect(view.itemCornerRadius, isNull);
    expect(view.itemBorderWidth, 0);
    expect(view.itemBorderColor, isNull);
  });

  test('the capsule constant is 1000 and the style names are the frozen strings', () {
    expect(cylAnimatedItemCornerRadiusCapsule, 1000);
    expect(CYLAnimatedItemBackgroundStyle.values.map((style) => style.name), ['flat', 'liquidGlass']);
  });

  test('commands before the view exists do nothing', () async {
    final controller = CYLAnimationController();
    await controller.play();
    await controller.stopAtProgress(0.5);
    await controller.restart();
  });
}
