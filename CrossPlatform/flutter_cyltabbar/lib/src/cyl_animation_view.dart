import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const String _viewType = 'flutter_cyltabbar/CYLAnimationView';

/// The URL of [file] with [options] in its fragment, sorted by name, like `CYLTabBarAnimationURLWithOptions()`.
String animationURLWithOptions(String file, [Map<String, Object> options = const {}]) {
  final base = file.split('#').first;
  final names = options.keys.where((name) => '${options[name]}'.isNotEmpty).toList()..sort();
  if (names.isEmpty) return base;
  return '$base#${names.map((name) => '${Uri.encodeComponent(name)}=${Uri.encodeComponent('${options[name]}')}').join('&')}';
}

/// An animation played by CYLTabBarController's own engine (the one of the tab icons), whatever its library: Rive,
/// Lottie, PAG or GIF, when the app has that library (iOS subspec or Swift package, Android dependency).
///
/// [file] is a file name in the app (the iOS main bundle, the Android assets), a path or a URL.
class CYLAnimationView extends StatefulWidget {
  const CYLAnimationView({super.key, required this.file, this.options = const {}, this.playing = false});

  final String file;

  /// Options of the file, e.g. Rive's `artboard`, `stateMachine`, `input`, `duration`.
  final Map<String, Object> options;

  final bool playing;

  @override
  State<CYLAnimationView> createState() => _CYLAnimationViewState();
}

class _CYLAnimationViewState extends State<CYLAnimationView> {
  MethodChannel? _channel;

  String get _source => animationURLWithOptions(widget.file, widget.options);

  @override
  void didUpdateWidget(CYLAnimationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_source != animationURLWithOptions(oldWidget.file, oldWidget.options)) {
      _channel?.invokeMethod<void>('setSource', _source);
    }
    if (widget.playing != oldWidget.playing) {
      _channel?.invokeMethod<void>('setPlaying', widget.playing);
    }
  }

  void _created(int id) => _channel = MethodChannel('$_viewType/$id');

  @override
  Widget build(BuildContext context) {
    final params = {'source': _source, 'playing': widget.playing};
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: _viewType,
          creationParams: params,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _created,
        );
      case TargetPlatform.android:
        return PlatformViewLink(
          viewType: _viewType,
          surfaceFactory: (context, controller) => AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          ),
          onCreatePlatformView: (platformParams) {
            final controller = PlatformViewsService.initExpensiveAndroidView(
              id: platformParams.id,
              viewType: _viewType,
              layoutDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
              creationParams: params,
              creationParamsCodec: const StandardMessageCodec(),
            );
            controller
              ..addOnPlatformViewCreatedListener(platformParams.onPlatformViewCreated)
              ..addOnPlatformViewCreatedListener(_created)
              ..create();
            return controller;
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
