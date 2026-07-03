import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

/// A brief flash rectangle spawned over a cleared row/column, then removed.
class LineClearFlash extends PositionComponent with HasPaint {
  LineClearFlash({required Vector2 position, required Vector2 size})
      : super(position: position, size: size, anchor: Anchor.topLeft) {
    paint.color = const Color(0xFFFFFFFF);
    add(OpacityEffect.fadeOut(EffectController(duration: 0.35)));
    add(RemoveEffect(delay: 0.35));
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}
