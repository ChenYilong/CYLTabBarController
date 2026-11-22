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

/// Plays an animation by hand, for a [CYLAnimationView] whose `drivesAnimationPlayback` is false (the cross-platform engine
/// contract, docs/Animated-Item.md): the commands `play`, `stopAtProgress` and `restart` of the native view. Give it to the
/// view's `controller`; a command before the view exists does nothing.
class CYLAnimationController {
  MethodChannel? _channel;

  void _attach(MethodChannel? channel) => _channel = channel;

  /// Plays from the current progress.
  Future<void> play() async => _channel?.invokeMethod<void>('play');

  /// Stops and shows the frame at [progress], 0 (the first frame) to 1 (the last).
  Future<void> stopAtProgress(double progress) async => _channel?.invokeMethod<void>('stopAtProgress', progress);

  /// Plays again from the start.
  Future<void> restart() async => _channel?.invokeMethod<void>('restart');
}

/// An animation played by CYLTabBarController's own engine (the one of the tab icons), whatever its library: Rive,
/// Lottie, PAG, GIF or SVGA, when the app has that library (iOS subspec or Swift package, Android dependency).
///
/// [file] is a file name in the app (the iOS main bundle, the Android assets), a path or a URL.
///
/// The names follow the cross-platform engine contract (docs/Animated-Item.md, "Engine API across platforms"): [selected],
/// [animationSpeed], [animationLoops], [animationRestartToken], [drivesAnimationPlayback], [iconSize], [tintColor], the
/// callbacks [onAnimationLoaded], [onAnimationFailed], [onAnimationEnd] and the [controller]'s commands. Both native halves
/// wrap `CYLAnimatedItemView`; there is no engine logic in Dart.
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
    this.controller,
    this.onAnimationLoaded,
    this.onAnimationFailed,
    this.onAnimationEnd,
  });

  final String file;

  /// Options of the file, e.g. Rive's `artboard`, `stateMachine`, `input`, `duration`.
  final Map<String, Object> options;

  final bool playing;

  /// Whether the item is selected: a selected item rests on its last frame, an unselected one on its first.
  final bool selected;

  /// The playback rate, 1 is the file's own speed.
  final double animationSpeed;

  /// Whether the animation plays again after each pass.
  final bool animationLoops;

  /// Plays again from the start when it changes (the value at creation is not a restart).
  final int animationRestartToken;

  /// true (default): the view applies the default playback rules; false: the host plays through the [controller].
  final bool drivesAnimationPlayback;

  /// The icon's side in logical pixels; null fills the view.
  final double? iconSize;

  /// Tints the icon and an animation that takes a tint.
  final Color? tintColor;

  final CYLAnimationController? controller;

  /// The animation is in place (a local file once parsed, a download once it arrived).
  final VoidCallback? onAnimationLoaded;

  /// The animation cannot play: a missing or corrupted file, a parse error, a failed download.
  final VoidCallback? onAnimationFailed;

  /// A play-once pass ended (not on a stop, not while looping).
  final VoidCallback? onAnimationEnd;

  @override
  State<CYLAnimationView> createState() => _CYLAnimationViewState();
}

class _CYLAnimationViewState extends State<CYLAnimationView> {
  MethodChannel? _channel;

  String get _source => animationURLWithOptions(widget.file, widget.options);

  @override
  void didUpdateWidget(CYLAnimationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._attach(null);
      widget.controller?._attach(_channel);
    }
    final channel = _channel;
    if (channel == null) return;
    // The contract's order: the rules first, then the file, then what plays.
    if (widget.drivesAnimationPlayback != oldWidget.drivesAnimationPlayback) {
      channel.invokeMethod<void>('setDrivesAnimationPlayback', widget.drivesAnimationPlayback);
    }
    if (widget.animationSpeed != oldWidget.animationSpeed) {
      channel.invokeMethod<void>('setAnimationSpeed', widget.animationSpeed);
    }
    if (widget.animationLoops != oldWidget.animationLoops) {
      channel.invokeMethod<void>('setAnimationLoops', widget.animationLoops);
    }
    if (widget.iconSize != oldWidget.iconSize) {
      channel.invokeMethod<void>('setIconSize', widget.iconSize);
    }
    if (widget.tintColor != oldWidget.tintColor) {
      channel.invokeMethod<void>('setTintColor', widget.tintColor?.toARGB32());
    }
    if (widget.selected != oldWidget.selected) {
      channel.invokeMethod<void>('setSelected', widget.selected);
    }
    if (_source != animationURLWithOptions(oldWidget.file, oldWidget.options)) {
      channel.invokeMethod<void>('setSource', _source);
    }
    if (widget.animationRestartToken != oldWidget.animationRestartToken) {
      channel.invokeMethod<void>('setAnimationRestartToken', widget.animationRestartToken);
    }
    if (widget.playing != oldWidget.playing) {
      channel.invokeMethod<void>('setPlaying', widget.playing);
    }
  }

  @override
  void dispose() {
    widget.controller?._attach(null);
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  void _created(int id) {
    final channel = MethodChannel('$_viewType/$id');
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onAnimationLoaded':
          widget.onAnimationLoaded?.call();
        case 'onAnimationFailed':
          widget.onAnimationFailed?.call();
        case 'onAnimationEnd':
          widget.onAnimationEnd?.call();
      }
      return null;
    });
    _channel = channel;
    widget.controller?._attach(channel);
  }

  @override
  Widget build(BuildContext context) {
    final params = <String, Object?>{
      'source': _source,
      'playing': widget.playing,
      'selected': widget.selected,
      'animationSpeed': widget.animationSpeed,
      'animationLoops': widget.animationLoops,
      'animationRestartToken': widget.animationRestartToken,
      'drivesAnimationPlayback': widget.drivesAnimationPlayback,
      if (widget.iconSize != null) 'iconSize': widget.iconSize,
      if (widget.tintColor != null) 'tintColor': widget.tintColor!.toARGB32(),
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
