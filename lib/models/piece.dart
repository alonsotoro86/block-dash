import 'dart:math';

/// A single block-piece shape, defined as a set of (row, col) offsets
/// relative to its top-left bounding box cell. Pieces are never rotated
/// by the player (matches the original Block Blast! ruleset).
class PieceShape {
  final String id;
  final List<Point<int>> cells;

  const PieceShape(this.id, this.cells);

  int get width => cells.map((c) => c.y).reduce(max) + 1;
  int get height => cells.map((c) => c.x).reduce(max) + 1;
  int get cellCount => cells.length;
}

/// Library of every piece shape available in the game, grouped roughly by
/// size. Row = cells[i].x, Col = cells[i].y.
class PieceLibrary {
  PieceLibrary._();

  static const List<PieceShape> all = [
    // --- 1 cell ---
    PieceShape('single', [Point(0, 0)]),

    // --- 2 cells ---
    PieceShape('domino_h', [Point(0, 0), Point(0, 1)]),
    PieceShape('domino_v', [Point(0, 0), Point(1, 0)]),

    // --- 3 cells: line ---
    PieceShape('line3_h', [Point(0, 0), Point(0, 1), Point(0, 2)]),
    PieceShape('line3_v', [Point(0, 0), Point(1, 0), Point(2, 0)]),

    // --- 3 cells: corner (L-tromino), 4 rotations ---
    PieceShape('corner3_0', [Point(0, 0), Point(0, 1), Point(1, 0)]),
    PieceShape('corner3_1', [Point(0, 0), Point(0, 1), Point(1, 1)]),
    PieceShape('corner3_2', [Point(0, 1), Point(1, 0), Point(1, 1)]),
    PieceShape('corner3_3', [Point(0, 0), Point(1, 0), Point(1, 1)]),

    // --- 4 cells: line ---
    PieceShape('line4_h', [Point(0, 0), Point(0, 1), Point(0, 2), Point(0, 3)]),
    PieceShape('line4_v', [Point(0, 0), Point(1, 0), Point(2, 0), Point(3, 0)]),

    // --- 4 cells: square ---
    PieceShape('square4', [Point(0, 0), Point(0, 1), Point(1, 0), Point(1, 1)]),

    // --- 4 cells: L-tetromino, 4 rotations ---
    PieceShape('lTetro_0', [Point(0, 0), Point(1, 0), Point(2, 0), Point(2, 1)]),
    PieceShape('lTetro_1', [Point(0, 0), Point(0, 1), Point(0, 2), Point(1, 0)]),
    PieceShape('lTetro_2', [Point(0, 0), Point(0, 1), Point(1, 1), Point(2, 1)]),
    PieceShape('lTetro_3', [Point(1, 0), Point(1, 1), Point(1, 2), Point(0, 2)]),

    // --- 4 cells: J-tetromino, 4 rotations ---
    PieceShape('jTetro_0', [Point(0, 1), Point(1, 1), Point(2, 0), Point(2, 1)]),
    PieceShape('jTetro_1', [Point(0, 0), Point(1, 0), Point(1, 1), Point(1, 2)]),
    PieceShape('jTetro_2', [Point(0, 0), Point(0, 1), Point(1, 0), Point(2, 0)]),
    PieceShape('jTetro_3', [Point(0, 0), Point(0, 1), Point(0, 2), Point(1, 2)]),

    // --- 4 cells: S/Z tetromino, 2 orientations each ---
    PieceShape('sTetro_h', [Point(0, 1), Point(0, 2), Point(1, 0), Point(1, 1)]),
    PieceShape('sTetro_v', [Point(0, 0), Point(1, 0), Point(1, 1), Point(2, 1)]),
    PieceShape('zTetro_h', [Point(0, 0), Point(0, 1), Point(1, 1), Point(1, 2)]),
    PieceShape('zTetro_v', [Point(0, 1), Point(1, 0), Point(1, 1), Point(2, 0)]),

    // --- 4 cells: T-tetromino, 4 rotations ---
    PieceShape('tTetro_0', [Point(0, 0), Point(0, 1), Point(0, 2), Point(1, 1)]),
    PieceShape('tTetro_1', [Point(0, 1), Point(1, 0), Point(1, 1), Point(2, 1)]),
    PieceShape('tTetro_2', [Point(1, 0), Point(1, 1), Point(1, 2), Point(0, 1)]),
    PieceShape('tTetro_3', [Point(0, 0), Point(1, 0), Point(1, 1), Point(2, 0)]),

    // --- 5 cells: line ---
    PieceShape('line5_h', [Point(0, 0), Point(0, 1), Point(0, 2), Point(0, 3), Point(0, 4)]),
    PieceShape('line5_v', [Point(0, 0), Point(1, 0), Point(2, 0), Point(3, 0), Point(4, 0)]),

    // --- 5 cells: plus / cross (signature big piece) ---
    PieceShape('plus5', [Point(0, 1), Point(1, 0), Point(1, 1), Point(1, 2), Point(2, 1)]),

    // --- 5 cells: P-pentomino, 4 rotations ---
    PieceShape('pPento_0', [Point(0, 0), Point(0, 1), Point(1, 0), Point(1, 1), Point(2, 0)]),
    PieceShape('pPento_1', [Point(0, 0), Point(0, 1), Point(0, 2), Point(1, 0), Point(1, 1)]),
    PieceShape('pPento_2', [Point(0, 1), Point(1, 0), Point(1, 1), Point(2, 0), Point(2, 1)]),
    PieceShape('pPento_3', [Point(0, 0), Point(0, 1), Point(1, 1), Point(1, 2), Point(0, 2)]),

    // --- 9 cells: 3x3 square (big bonus piece, low weight) ---
    PieceShape('square9', [
      Point(0, 0), Point(0, 1), Point(0, 2),
      Point(1, 0), Point(1, 1), Point(1, 2),
      Point(2, 0), Point(2, 1), Point(2, 2),
    ]),
  ];

  /// Spawn weight per piece: smaller pieces are more common, the 3x3 is rare.
  static int weightOf(PieceShape shape) {
    if (shape.cellCount <= 2) return 10;
    if (shape.cellCount <= 4) return 8;
    if (shape.cellCount == 5) return 5;
    return 1; // square9
  }
}
