import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../models/board.dart';
import '../models/piece.dart';
import '../theme/block_themes.dart';

/// Renders the 8x8 grid: background cells + whatever is currently filled
/// in [board]. Pure render — all game logic lives in [BoardModel].
class BoardComponent extends PositionComponent {
  final BoardModel board;
  BlockTheme theme;
  double cellSize;

  /// While a piece is being dragged, these are the cells it would occupy
  /// if dropped right now (drawn as a green/red translucent preview).
  List<Point<int>>? previewCells;
  bool previewValid = false;

  BoardComponent({
    required this.board,
    required this.theme,
    required this.cellSize,
  }) : super(size: Vector2.all(cellSize * BoardModel.size));

  void setPreview(PieceShape? shape, int row, int col, bool valid) {
    if (shape == null) {
      previewCells = null;
      return;
    }
    previewCells = shape.cells.map((c) => Point(row + c.x, col + c.y)).toList();
    previewValid = valid;
  }

  void clearPreview() => previewCells = null;

  void updateCellSize(double newCellSize) {
    cellSize = newCellSize;
    size = Vector2.all(cellSize * BoardModel.size);
  }

  /// Converts a global (game-space) point to a grid (row, col), or null if
  /// outside the board bounds.
  (int row, int col)? globalToGrid(Vector2 globalPoint) {
    final local = globalPoint - position;
    final col = (local.x / cellSize).floor();
    final row = (local.y / cellSize).floor();
    if (row < 0 || row >= BoardModel.size || col < 0 || col >= BoardModel.size) {
      return null;
    }
    return (row, col);
  }

  Vector2 cellTopLeft(int row, int col) =>
      position + Vector2(col * cellSize, row * cellSize);

  @override
  void render(Canvas canvas) {
    final bgPaint = Paint()..color = theme.boardBackground;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(12),
      ),
      bgPaint,
    );

    final gridLinePaint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i <= BoardModel.size; i++) {
      canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, size.y), gridLinePaint);
      canvas.drawLine(Offset(0, i * cellSize), Offset(size.x, i * cellSize), gridLinePaint);
    }

    const inset = 2.0;
    for (var r = 0; r < BoardModel.size; r++) {
      for (var c = 0; c < BoardModel.size; c++) {
        final colorIndex = board.grid[r][c];
        if (colorIndex == null) continue;
        final color = theme.blockColors[colorIndex % theme.blockColors.length];
        final rect = Rect.fromLTWH(
          c * cellSize + inset,
          r * cellSize + inset,
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

    final preview = previewCells;
    if (preview != null) {
      final previewColor = previewValid
          ? const Color(0x9944D17A)
          : const Color(0x99E05656);
      for (final cell in preview) {
        if (cell.x < 0 || cell.x >= BoardModel.size || cell.y < 0 || cell.y >= BoardModel.size) {
          continue;
        }
        final rect = Rect.fromLTWH(
          cell.y * cellSize + inset,
          cell.x * cellSize + inset,
          cellSize - inset * 2,
          cellSize - inset * 2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          Paint()..color = previewColor,
        );
      }
    }
  }
}
