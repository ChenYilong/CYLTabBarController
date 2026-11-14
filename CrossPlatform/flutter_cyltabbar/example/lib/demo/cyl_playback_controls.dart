// The playback controls AGENTS.md asks of every example that shows tab icon animations ("Animated icon examples: Play all,
// speed slider, loop switch"). AGENTS.md 要求每个展示 Tab 图标动画的示例提供的播放控件（「全部播放」、倍速滑块、循环开关）。
import 'package:flutter/material.dart';

import 'cyl_demo_list.dart';
import 'cyl_localization.dart';

/// The speed range of the slider, in steps of 0.05.
/// 滑块的速度范围，步长 0.05。
const double cylPlaybackMinimumSpeed = 0.25;
const double cylPlaybackMaximumSpeed = 3;
const int cylPlaybackSteps = 55;

/// The speed as text without trailing zeros: "1.5".
/// 不带多余 0 的速度文字："1.5"。
String cylSpeedText(double speed) {
  final text = speed.toStringAsFixed(2);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Play all, a speed slider and a loop switch for the tab icon animations of the tab bar. They combine into one playback
/// policy, applied live: Play all restarts every icon from progress 0 ([onPlayAll], `CYLTabBar.playAllRequest`), the slider
/// sets `CYLTabBar.animationSpeed`, the switch sets `CYLTabBar.animationLoops`. TalkBack and VoiceOver read the button as
/// "Play all", the slider as "Speed, 1.5 times" and the switch as "Loop, on".
/// 为 TabBar 的 Tab 图标动画提供「全部播放」、倍速滑块与循环开关，三者组合成一个实时生效的播放策略。TalkBack 与 VoiceOver
/// 把按钮读作「全部播放」，滑块读作「倍速，1.5 倍」，开关读作「循环播放，开」。
class CYLPlaybackControls extends StatelessWidget {
  const CYLPlaybackControls({
    super.key,
    required this.colors,
    required this.tint,
    required this.speed,
    required this.loops,
    required this.onPlayAll,
    required this.onSpeedChanged,
    required this.onLoopsChanged,
  });

  final CYLDemoColors colors;
  final Color tint;
  final double speed;
  final bool loops;
  final VoidCallback onPlayAll;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<bool> onLoopsChanged;

  @override
  Widget build(BuildContext context) {
    final speedText = cylSpeedText(speed);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              t('Playback').toUpperCase(),
              style: TextStyle(fontSize: 13, color: colors.secondaryLabel),
            ),
          ),
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: onPlayAll,
                      child: Text(t('Play all'), style: TextStyle(fontSize: 17, color: tint)),
                    ),
                  ),
                  Row(
                    children: [
                      ExcludeSemantics(
                        child: Text(t('Speed'), style: TextStyle(fontSize: 17, color: colors.label)),
                      ),
                      Expanded(
                        child: Semantics(
                          label: t('Speed'),
                          child: Slider(
                            value: speed.clamp(cylPlaybackMinimumSpeed, cylPlaybackMaximumSpeed),
                            min: cylPlaybackMinimumSpeed,
                            max: cylPlaybackMaximumSpeed,
                            divisions: cylPlaybackSteps,
                            activeColor: tint,
                            onChanged: onSpeedChanged,
                            semanticFormatterCallback: (value) =>
                                t('{speed} times', {'speed': cylSpeedText(value)}),
                          ),
                        ),
                      ),
                      ExcludeSemantics(
                        child: SizedBox(
                          width: 48,
                          child: Text(
                            '$speedText×',
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 17, color: colors.secondaryLabel),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t('Loop'), style: TextStyle(fontSize: 17, color: colors.label)),
                    value: loops,
                    activeThumbColor: tint,
                    onChanged: onLoopsChanged,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
