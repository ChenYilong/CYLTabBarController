import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_cyltabbar/flutter_cyltabbar.dart';
import 'package:flutter_cyltabbar/src/cyl_animation_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake native side: records every call the widget sends and can call the widget back.
class _FakeChannel {
  _FakeChannel() : channel = const MethodChannel('flutter_cyltabbar/CYLAnimationView/7') {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add('${call.method}:${call.arguments}');
      return null;
    });
  }

  final MethodChannel channel;
  final List<String> calls = [];

  Future<void> callBack(String method) => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(MethodCall(method)),
        (_) {},
      );

  void dispose() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('animationURLWithOptions writes every case of the shared fixture so that it reads back the same', () {
    final fixture = jsonDecode(File('../animated-item-fixtures/source-options.json').readAsStringSync()) as Map<String, dynamic>;
    final cases = (fixture['cases'] as List).cast<Map<String, dynamic>>().where((c) => c['file'] != null && !(c['input'] as String).trim().startsWith('{'));
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

  test('the defaults: drives the playback, not selected, speed 1, no loop', () {
    const view = CYLAnimationView(file: 'a.riv', options: {'input': 'active'});
    expect(view.drivesAnimationPlayback, isTrue);
    expect(view.selected, isFalse);
    expect(view.animationSpeed, 1);
    expect(view.animationLoops, isFalse);
    expect(view.animationRestartToken, 0);
    expect(view.source, 'a.riv#input=active');
  });

  test('a changed parameter reaches the channel under its frozen method name, an unchanged one does not', () {
    final fake = _FakeChannel();
    addTearDown(fake.dispose);
    const first = CYLAnimationView(file: 'a.json');
    final bridge = CYLAnimationBridge(fake.channel, first);
    bridge.update(first, const CYLAnimationView(file: 'a.json'));
    expect(fake.calls, isEmpty);
    bridge.update(
      first,
      const CYLAnimationView(
        file: 'b.json',
        playing: true,
        selected: true,
        animationSpeed: 2,
        animationLoops: true,
        animationRestartToken: 4,
        drivesAnimationPlayback: false,
        iconSize: 32,
        tintColor: Color(0xFFFF0000),
      ),
    );
    expect(fake.calls, [
      'setSource:b.json',
      'setSelected:true',
      'setAnimationSpeed:2.0',
      'setAnimationLoops:true',
      'setAnimationRestartToken:4',
      'setDrivesAnimationPlayback:false',
      'setPlaying:true',
      'setIconSize:32.0',
      'setTintColor:4294901760',
    ]);
  });

  test('the controller sends play, stopAtProgress and restart, and does nothing before a view exists', () async {
    final fake = _FakeChannel();
    addTearDown(fake.dispose);
    final controller = CYLAnimationController();
    await controller.play();
    expect(controller.isAttached, isFalse);
    expect(fake.calls, isEmpty);
    final bridge = CYLAnimationBridge(fake.channel, CYLAnimationView(file: 'a.gif', controller: controller), controller);
    expect(controller.isAttached, isTrue);
    await controller.play();
    await controller.stopAtProgress(0.5);
    await controller.restart();
    expect(fake.calls, ['play:null', 'stopAtProgress:0.5', 'restart:null']);
    bridge.dispose();
    expect(controller.isAttached, isFalse);
  });

  test('the native callbacks reach the widget callbacks', () async {
    final fake = _FakeChannel();
    addTearDown(fake.dispose);
    final events = <String>[];
    CYLAnimationBridge(
      fake.channel,
      CYLAnimationView(
        file: 'a.gif',
        onAnimationLoaded: () => events.add('loaded'),
        onAnimationFailed: () => events.add('failed'),
        onAnimationEnd: () => events.add('end'),
      ),
    );
    await fake.callBack('onAnimationLoaded');
    await fake.callBack('onAnimationEnd');
    await fake.callBack('onAnimationFailed');
    expect(events, ['loaded', 'end', 'failed']);
  });
}
