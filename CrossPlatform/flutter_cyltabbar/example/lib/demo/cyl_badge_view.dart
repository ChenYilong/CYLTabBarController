// A badge on a widget, drawn by Flutter: the Dart twin of `UIView+CYLBadgeExtention` for the demo list's badge samples
// (UITableViewCell+CYLBadgeExtention.m). Same defaults as `CYLBadgeAppearance`: red, bold 9 pt text, dot radius 4,
// margin 8, maximum 99; centered 2 pt right of the host's top-right corner, moved by the sample's position.
// Flutter 绘制的角标：`UIView+CYLBadgeExtention` 的 Dart 版本，用于演示列表的角标样例。默认值与 `CYLBadgeAppearance` 相同：红色、粗体
// 9pt 文字、红点半径 4、边距 8、最大值 99；中心位于宿主右上角右侧 2pt，可按样例的位置移动。
import 'dart:math';

import 'package:flutter/material.dart';

/// One sample of demo-list.json's `badgeSamples`. demo-list.json 中 `badgeSamples` 的一项。
class CYLBadgeSample {
  CYLBadgeSample(Map<String, dynamic> json)
    : value = json['value'] as String? ?? '',
      animation = json['animation'] as String?,
      reduceMotion = json['reduceMotion'] == true,
      maximum = json['maximum'] as int? ?? 99,
      color = json['color'] as String?,
      textColor = json['textColor'] as String?,
      italic = json['italic'] == true,
      fontSize = (json['fontSize'] as num?)?.toDouble() ?? 9,
      borderColor = json['borderColor'] as String?,
      borderWidth = (json['borderWidth'] as num?)?.toDouble() ?? 0,
      radius = (json['radius'] as num?)?.toDouble() ?? 4,
      margin = (json['margin'] as num?)?.toDouble() ?? 8,
      cornerRadius = (json['cornerRadius'] as num?)?.toDouble(),
      position = json['position'] as String?;

  final String value;
  final String? animation;
  final bool reduceMotion;
  final int maximum;
  final String? color;
  final String? textColor;
  final bool italic;
  final double fontSize;
  final String? borderColor;
  final double borderWidth;
  final double radius;
  final double margin;
  final double? cornerRadius;
  final String? position;

  /// Numbers above the maximum become "99+". 数值超过最大值时显示为「99+」。
  String get text {
    final number = int.tryParse(value);
    return number != null && number > maximum ? '$maximum+' : value;
  }
}

Color hexColor(String hex) =>
    Color(int.parse('FF${hex.substring(1)}', radix: 16));

class CYLBadgeView extends StatefulWidget {
  const CYLBadgeView({super.key, required this.sample, required this.hostSize});
  final CYLBadgeSample sample;
  final double hostSize;

  @override
  State<CYLBadgeView> createState() => _BadgeViewState();
}

class _BadgeViewState extends State<CYLBadgeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  final _key = GlobalKey();
  Size _size = Size.zero;

  String get _animation {
    final name = widget.sample.animation ?? '';
    if (widget.sample.reduceMotion &&
        MediaQuery.maybeDisableAnimationsOf(context) == true) {
      return '';
    }
    return name;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _start();
  }

  /// The timing of each animation, as the CAAnimation factories of the library. 与库中 CAAnimation 工厂方法对应的时长。
  void _start() {
    final name = _animation;
    _controller.stop();
    _controller.value = 0;
    if (name.isEmpty) return;
    const forever = {
      'scale': 1200,
      'breathe': 1200,
      'shake': 800,
      'bounce': 800,
      'rotation': 2000,
      'springForever': 1000,
    };
    const times = {
      'shake3': (3, 333),
      'bounce3': (3, 333),
      'scale3': (3, 1000),
      'blink3': (3, 800),
      'flip2': (2, 500),
    };
    if (forever.containsKey(name)) {
      _controller.duration = Duration(milliseconds: forever[name]!);
      _controller.repeat();
    } else if (times.containsKey(name)) {
      final (count, duration) = times[name]!;
      _controller.duration = Duration(milliseconds: duration * count);
      _controller.forward();
      _repeatCount = count;
    } else {
      _controller.duration = const Duration(milliseconds: 400);
      _controller.forward();
    }
  }

  int _repeatCount = 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The transform or opacity of the badge at progress `t`. 进度 `t` 时角标的变换或透明度。
  Widget _animated(Widget child, double t) {
    final name = _animation;
    final width = _size.width;
    final cycle = (t * _repeatCount) % 1;
    final swing = sin(cycle * 2 * pi);
    switch (name) {
      case 'scale':
        return Transform.scale(scale: 1 + 0.2 * sin(t * pi), child: child);
      case 'breathe':
        return Opacity(opacity: 1 - 0.7 * sin(t * pi), child: child);
      case 'shake':
        return Transform.translate(
          offset: Offset(sin(t * 2 * pi) * width / 4, 0),
          child: child,
        );
      case 'shake3':
        return Transform.translate(
          offset: Offset(swing * width / 4, 0),
          child: child,
        );
      case 'bounce':
        return Transform.translate(
          offset: Offset(0, sin(t * 2 * pi) * 4),
          child: child,
        );
      case 'bounce3':
        return Transform.translate(offset: Offset(0, swing * 4), child: child);
      case 'rotation':
      case 'rollingOnce':
        return Transform.rotate(angle: t * 2 * pi, child: child);
      case 'springForever':
      case 'springOnce':
        return Transform.scale(
          scale:
              Curves.elasticOut.transform(
                    name == 'springOnce' ? t : t.clamp(0, 1),
                  ) *
                  0.5 +
              0.5,
          child: child,
        );
      case 'scale3':
        return Transform.scale(
          scale: 1.4 - 0.8 * (0.5 - 0.5 * cos(cycle * 2 * pi)),
          child: child,
        );
      case 'blink3':
        return Opacity(opacity: 0.5 + 0.5 * cos(cycle * 2 * pi), child: child);
      case 'flip2':
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.005)
            ..rotateY(cycle * pi),
          child: child,
        );
      case 'leftRightOnce':
        return Transform.translate(
          offset: Offset(-width * (1 - t), 0),
          child: child,
        );
      case 'rightLeftOnce':
        return Transform.translate(
          offset: Offset(width * (1 - t), 0),
          child: child,
        );
      case 'fadeInOnce':
        return Opacity(opacity: t, child: child);
      case 'scaleOnce':
        return Transform.scale(scale: t, child: child);
      default:
        return child;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sample = widget.sample;
    final text = sample.text;
    final isDot = text.isEmpty;
    final height = isDot
        ? sample.radius * 2
        : (sample.fontSize * 1.2).ceilToDouble() + sample.margin;
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final border = sample.borderColor == null
        ? null
        : Border.all(
            color: sample.borderColor == 'dynamic'
                ? (dark ? Colors.white : Colors.black)
                : hexColor(sample.borderColor!),
            width: sample.borderWidth,
          );
    final badge = Container(
      key: _key,
      height: height,
      constraints: BoxConstraints(minWidth: height),
      padding: EdgeInsets.symmetric(horizontal: isDot ? 0 : sample.margin / 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: sample.color == null
            ? const Color(0xFFFF0000)
            : hexColor(sample.color!),
        borderRadius: BorderRadius.circular(sample.cornerRadius ?? height / 2),
        border: border,
      ),
      child: isDot
          ? null
          : Text(
              text,
              style: TextStyle(
                fontSize: sample.fontSize,
                height: 1.2,
                color: sample.textColor == null
                    ? Colors.white
                    : hexColor(sample.textColor!),
                fontWeight: sample.italic ? FontWeight.w400 : FontWeight.w700,
                fontStyle: sample.italic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = _key.currentContext?.size;
      if (mounted && size != null && size != _size) {
        setState(() => _size = size);
      }
    });
    // `CYLBadgeHelperCenterOffset`: from the top-right corner to the other corners. 从右上角移到其他角。
    final host = widget.hostSize;
    final offset = switch (sample.position) {
      'topLeft' => Offset(-(host + 4), 0),
      'bottomLeft' => Offset(-(host + 4), host),
      'bottomRight' => Offset(0, host),
      _ => Offset.zero,
    };
    return Positioned(
      left: host + 2 + offset.dx - _size.width / 2,
      top: offset.dy - _size.height / 2,
      child: Opacity(
        opacity: _size == Size.zero ? 0 : 1,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => _animated(child!, _controller.value),
          child: badge,
        ),
      ),
    );
  }
}
