import 'dart:convert';
import 'dart:io';

import 'package:flutter_cyltabbar/flutter_cyltabbar.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';

void main() {
  tintTests();
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
    expect(view.itemContentHorizontalInset, isNull, reason: 'unset: the glass constant on glass, 0 on flat (the partner of the radius)');
    expect(view.itemBorderWidth, 0);
    expect(view.itemBorderColor, isNull);
  });

  test('the capsule constant is 1000 and the style names are the frozen strings', () {
    expect(cylAnimatedItemCornerRadiusCapsule, 1000);
    expect(CYLAnimatedItemBackgroundStyle.values.map((style) => style.name), ['flat', 'liquidGlass']);
  });

  test('the glass content inset is a named constant, not a literal at the call site', () {
    expect(cylAnimatedItemLiquidGlassContentInset, 14);
  });

  test('commands before the view exists do nothing', () async {
    final controller = CYLAnimationController();
    await controller.play();
    await controller.stopAtProgress(0.5);
    await controller.restart();
  });

  test('onResourceMissing is optional and has the frozen signature', () {
    const view = CYLAnimationView(file: 'a.riv');
    expect(view.onResourceMissing, isNull);
    void callback(String resource, String reason) {}
    expect(CYLAnimationView(file: 'a.riv', onResourceMissing: callback).onResourceMissing, same(callback));
  });
}

void tintTests() {
  group('tint spec v2', () {
    test('defaults: nothing forced, rendering mode automatic', () {
      const view = CYLAnimationView(file: 'a.json');
      expect(view.tintColor, isNull);
      expect(view.animationTint, isNull);
      expect(view.animationDarkTint, isNull);
      expect(view.animationRenderingMode, CYLAnimationRenderingMode.automatic);
      expect(CYLAnimationRenderingMode.values.map((m) => m.name), ['automatic', 'alwaysTemplate', 'alwaysOriginal']);
    });

    test('creation params carry the tint keys, null when unset', () {
      final params = cylAnimationCreationParams(const CYLAnimationView(file: 'a.json'));
      for (final key in ['tintColor', 'animationTint', 'animationDarkTint']) {
        expect(params.containsKey(key), isTrue, reason: key);
        expect(params[key], isNull, reason: key);
      }
      expect(params['animationRenderingMode'], 'automatic');
      expect(params['source'], 'a.json');
    });

    test('creation params map the values', () {
      final params = cylAnimationCreationParams(const CYLAnimationView(
        file: 'a.json',
        tintColor: Color(0xFF112233),
        animationTint: 'title',
        animationDarkTint: '#FFFFFF',
        animationRenderingMode: CYLAnimationRenderingMode.alwaysTemplate,
      ));
      expect(params['tintColor'], 0xFF112233);
      expect(params['animationTint'], 'title');
      expect(params['animationDarkTint'], '#FFFFFF');
      expect(params['animationRenderingMode'], 'alwaysTemplate');
      expect(params['source'], 'a.json#renderingMode=alwaysTemplate');
    });

    test('renderingMode URL option: written when not automatic, an option in options wins', () {
      String source(CYLAnimationView v) => cylAnimationCreationParams(v)['source'] as String;
      expect(source(const CYLAnimationView(file: 'a.json', animationRenderingMode: CYLAnimationRenderingMode.alwaysOriginal)),
          'a.json#renderingMode=alwaysOriginal');
      expect(
          source(const CYLAnimationView(
              file: 'a.json', options: {'renderingMode': 'alwaysTemplate'}, animationRenderingMode: CYLAnimationRenderingMode.alwaysOriginal)),
          'a.json#renderingMode=alwaysTemplate');
    });

    test('updates: a changed value is sent, set to null is sent as null (reset)', () {
      const none = CYLAnimationView(file: 'a.json');
      const set = CYLAnimationView(
        file: 'a.json',
        tintColor: Color(0xFF112233),
        animationTint: '#FF0000',
        animationDarkTint: '#00FF00',
        animationRenderingMode: CYLAnimationRenderingMode.alwaysTemplate,
      );
      expect(cylAnimationTintUpdates(none, none), isEmpty);
      final up = {for (final u in cylAnimationTintUpdates(none, set)) u.key: u.value};
      expect(up, {
        'setTintColor': 0xFF112233,
        'setAnimationTint': '#FF0000',
        'setAnimationDarkTint': '#00FF00',
        'setAnimationRenderingMode': 'alwaysTemplate',
      });
      final down = cylAnimationTintUpdates(set, none);
      expect(down.map((u) => u.key), ['setTintColor', 'setAnimationTint', 'setAnimationDarkTint', 'setAnimationRenderingMode']);
      expect(down.map((u) => u.value), [null, null, null, 'automatic']);
      expect(down.first.value, isNull);
    });
  });
}
