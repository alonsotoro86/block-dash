import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/services.dart' show HapticFeedback;

import '../models/piece.dart';
import '../theme/block_themes.dart';

/// A single piece sitting in the tray, draggable onto the board.
///
/// Coordinates note: this component and [BoardComponent] are both direct
/// children of the same game root, so their `position` fields share one
/// coordinate space — no extra conversion is needed between them.
class DraggablePieceComponent extends PositionComponent with DragCallbacks {
  final PieceShape shape;
  final int colorIndex;
  final BlockTheme theme;
  final double cellSize;
  final Vector2 homePosition;
  final Vector2 Function() boardOrigin;

  /// How far the piece visually lifts above the fingertip while dragging,
  /// so the player can see what they're placing.
  static final _liftOffset = Vector2(0, -70);

  final bool Function(PieceShape shape, int row, int col) canPlaceAt;
  final void Function(DraggablePieceComponent piece, int row, int col) onPlaced;
  final void Function() onDragBegin;
  final void Function(PieceShape shape, int row, int col) onDragMove;
  final void Function() onDragFinished;

  bool _placed = false;

  DraggablePieceComponent({
    required this.shape,
    required this.colorIndex,
    required this.theme,
    required this.cellSize,
    required this.homePosition,
    required this.boardOrigin,
    required this.canPlaceAt,
    required this.onPlaced,
    required this.onDragBegin,
    required this.onDragMove,
    required this.onDragFinished,
  }) : super(
          position: homePosition.clone(),
          size: Vector2(shape.width * cellSize, shape.height * cellSize),
          anchor: Anchor.topLeft,
        );

  (int row, int col) _anchoredGridGuess() {
    final unliftedTopLeft = position - _liftOffset - boardOrigin();
    return (
      (unliftedTopLeft.y / cellSize).round(),
      (unliftedTopLeft.x / cellSize).round(),
    );
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    priority = 100;
    onDragBegin();
    add(ScaleEffect.to(Vector2.all(1.08), EffectController(duration: 0.08)));
    position += _liftOffset;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_placed) return;
    position += event.localDelta;
    final (row, col) = _anchoredGridGuess();
    onDragMove(shape, row, col);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (_placed) return;
    final (row, col) = _anchoredGridGuess();
    if (canPlaceAt(shape, row, col)) {
      _placed = true;
      onPlaced(this, row, col);
    } else {
      _snapHome();
    }
    onDragFinished();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    if (!_placed) _snapHome();
    onDragFinished();
  }

  void _snapHome() {
    HapticFeedback.selectionClick();
    add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.12)));
    add(
      MoveToEffect(
        homePosition.clone(),
        EffectController(duration: 0.18, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    const inset = 3.0;
    final color = theme.blockColors[colorIndex % theme.blockColors.length];
    for (final cell in shape.cells) {
      final rect = Rect.fromLTWH(
        cell.y * cellSize + inset,
        cell.x * cellSize + inset,
        cellSize - inset * 2,
        cellSize - inset * 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..color = color,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(4)),
        Paint()..color = color.withValues(alpha: 0.55),
      );
    }
  }
}
