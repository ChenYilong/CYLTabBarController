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

  test('commands before the view exists do nothing', () async {
    final controller = CYLAnimationController();
    await controller.play();
    await controller.stopAtProgress(0.5);
    await controller.restart();
  });
}
