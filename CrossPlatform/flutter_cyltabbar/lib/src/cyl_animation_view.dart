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

/// The commands of a [CYLAnimationView]: pass one as `controller:`; the commands do nothing before the view exists.
class CYLAnimationController {
  MethodChannel? _channel;

  /// Plays from the current progress.
  Future<void> play() async => _channel?.invokeMethod<void>('play');

  /// Stops and shows [progress] (0 to 1) as a still frame.
  Future<void> stopAtProgress(double progress) async => _channel?.invokeMethod<void>('stopAtProgress', progress);

  /// Plays again from the start.
  Future<void> restart() async => _channel?.invokeMethod<void>('restart');

  /// Whether a view is attached.
  bool get isAttached => _channel != null;
}

/// The channel of one native animation view: sends the parameters that changed and turns the native callbacks into the
/// widget's. Frozen names: `setSource`, `setSelected`, `setAnimationSpeed`, `setAnimationLoops`,
/// `setAnimationRestartToken`, `setDrivesAnimationPlayback`, `setPlaying`, `setIconSize`, `setTintColor`; the callbacks
/// `onAnimationLoaded`, `onAnimationFailed`, `onAnimationEnd`.
@visibleForTesting
class CYLAnimationBridge {
  CYLAnimationBridge(this.channel, this.widget, [this.controller]) {
    controller?._channel = channel;
    channel.setMethodCallHandler(_handle);
  }

  final MethodChannel channel;
  CYLAnimationView widget;
  CYLAnimationController? controller;

  Future<dynamic> _handle(MethodCall call) async {
    switch (call.method) {
      case 'onAnimationLoaded':
        widget.onAnimationLoaded?.call();
      case 'onAnimationFailed':
        widget.onAnimationFailed?.call();
      case 'onAnimationEnd':
        widget.onAnimationEnd?.call();
    }
    return null;
  }

  /// Sends what differs between [old] and the current widget.
  void update(CYLAnimationView old, CYLAnimationView current) {
    widget = current;
    void send(String method, Object? argument) => channel.invokeMethod<void>(method, argument);
    if (current.source != old.source) send('setSource', current.source);
    if (current.selected != old.selected) send('setSelected', current.selected);
    if (current.animationSpeed != old.animationSpeed) send('setAnimationSpeed', current.animationSpeed);
    if (current.animationLoops != old.animationLoops) send('setAnimationLoops', current.animationLoops);
    if (current.animationRestartToken != old.animationRestartToken) send('setAnimationRestartToken', current.animationRestartToken);
    if (current.drivesAnimationPlayback != old.drivesAnimationPlayback) send('setDrivesAnimationPlayback', current.drivesAnimationPlayback);
    if (current.playing != old.playing) send('setPlaying', current.playing);
    if (current.iconSize != old.iconSize) send('setIconSize', current.iconSize);
    if (current.tintColor != old.tintColor) send('setTintColor', current.tintColor?.toARGB32());
    if (current.controller != old.controller) {
      old.controller?._channel = null;
      current.controller?._channel = channel;
    }
  }

  void dispose() {
    channel.setMethodCallHandler(null);
    controller?._channel = null;
  }
}

/// An animation played by CYLTabBarController's own engine (the one of the tab icons), whatever its library: Rive,
/// Lottie, PAG, GIF or SVGA, when the app has that library (iOS subspec or Swift package, Android dependency).
///
/// [file] is a file name in the app (the iOS main bundle, the Android assets), a path or a URL.
class CYLAnimationView extends StatefulWidget {
  const CYLAnimationView({
    super.key,
    required this.file,
    this.options = const {},
    this.playing = false,
    this.selected = false,
    this.animationSpeed = 1,
    this.animationLoops = false,
    this.animationRestartToken = 0,
    this.drivesAnimationPlayback = true,
    this.iconSize,
    this.tintColor,
    this.onAnimationLoaded,
    this.onAnimationFailed,
    this.onAnimationEnd,
    this.controller,
  });

  final String file;

  /// Options of the file, e.g. Rive's `artboard`, `stateMachine`, `input`, `duration`.
  final Map<String, Object> options;

  /// Plays when true, stops when false.
  final bool playing;

  /// Whether the item is selected: with [drivesAnimationPlayback], selected plays once from the start, unselected rests.
  final bool selected;

  /// The speed, 1 by default; 0 or less keeps the file's own speed.
  final double animationSpeed;

  /// Whether the animation loops.
  final bool animationLoops;

  /// Restarts the animation from the start whenever it changes (the value at creation is not a restart).
  final int animationRestartToken;

  /// True by default. False: the view applies none of the default rules and the host plays through [controller].
  final bool drivesAnimationPlayback;

  /// The icon size in logical pixels; null fills the view.
  final double? iconSize;

  /// The tint of the icon (where the engine takes one).
  final Color? tintColor;

  /// The engine loaded the file.
  final VoidCallback? onAnimationLoaded;

  /// The engine could not load the file: the still image or the placeholder stays.
  final VoidCallback? onAnimationFailed;

  /// A pass that does not loop reached its end.
  final VoidCallback? onAnimationEnd;

  /// `play()`, `stopAtProgress(progress)` and `restart()`.
  final CYLAnimationController? controller;

  /// [file] with [options] in its fragment: what the native view receives.
  String get source => animationURLWithOptions(file, options);

  @override
  State<CYLAnimationView> createState() => _CYLAnimationViewState();
}

class _CYLAnimationViewState extends State<CYLAnimationView> {
  CYLAnimationBridge? _bridge;

  @override
  void didUpdateWidget(CYLAnimationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _bridge?.update(oldWidget, widget);
  }

  @override
  void dispose() {
    _bridge?.dispose();
    super.dispose();
  }

  void _created(int id) => _bridge = CYLAnimationBridge(MethodChannel('$_viewType/$id'), widget, widget.controller);

  @override
  Widget build(BuildContext context) {
    final params = <String, Object?>{
      'source': widget.source,
      'playing': widget.playing,
      'selected': widget.selected,
      'animationSpeed': widget.animationSpeed,
      'animationLoops': widget.animationLoops,
      'animationRestartToken': widget.animationRestartToken,
      'drivesAnimationPlayback': widget.drivesAnimationPlayback,
      'iconSize': widget.iconSize,
      'tintColor': widget.tintColor?.toARGB32(),
    };
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
