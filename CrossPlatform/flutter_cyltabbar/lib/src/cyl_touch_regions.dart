import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// [EN] Lets its child take a pointer only inside [rects] (logical pixels, in the child's coordinates): the platform view of
///      `CYLTabBar` rises above the bar to show the plus button and the badges, and a touch in that transparent strip,
///      away from them, goes to the widgets below. Null [rects] (not reported yet) let the whole child take pointers.
/// [CN] 只让子组件在 [rects]（逻辑像素，子组件坐标）内接收指针：`CYLTabBar` 的平台视图高出 TabBar 以显示 PlusButton 与角标，落在该透明区域中、
///      不在它们上的触摸交给下方的组件。[rects] 为 null（尚未报告）时整个子组件接收指针。
class CYLTouchRegions extends SingleChildRenderObjectWidget {
  const CYLTouchRegions({super.key, required this.rects, super.child});

  final List<Rect>? rects;

  /// [EN] The rects a native view reports: a list of `[left, top, width, height]`. [CN] 原生视图报告的矩形：`[left, top, width, height]` 列表。
  static List<Rect> parse(Object? arguments) => [
        if (arguments is List)
          for (final rect in arguments)
            if (rect is List && rect.length == 4)
              Rect.fromLTWH((rect[0] as num).toDouble(), (rect[1] as num).toDouble(), (rect[2] as num).toDouble(),
                  (rect[3] as num).toDouble()),
      ];

  @override
  RenderCYLTouchRegions createRenderObject(BuildContext context) => RenderCYLTouchRegions(rects);

  @override
  void updateRenderObject(BuildContext context, RenderCYLTouchRegions renderObject) => renderObject.rects = rects;
}

/// [EN] The render object of [CYLTouchRegions]. [CN] [CYLTouchRegions] 的渲染对象。
class RenderCYLTouchRegions extends RenderProxyBox {
  RenderCYLTouchRegions(this.rects);

  List<Rect>? rects;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final rects = this.rects;
    if (rects != null && !rects.any((rect) => rect.contains(position))) return false;
    return super.hitTest(result, position: position);
  }
}
