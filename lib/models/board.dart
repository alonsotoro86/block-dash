import 'dart:math';

import 'piece.dart';

/// Result of placing a piece: how many rows/cols cleared and the score
/// awarded, so the UI layer can animate/display it.
class PlacementResult {
  final int cellsPlaced;
  final int linesCleared;
  final int scoreGained;
  final List<int> clearedRows;
  final List<int> clearedCols;

  const PlacementResult({
    required this.cellsPlaced,
    required this.linesCleared,
    required this.scoreGained,
    required this.clearedRows,
    required this.clearedCols,
  });
}

/// Pure game-logic model for the 8x8 board. No Flutter/Flame dependency,
/// so it's trivially unit-testable.
class BoardModel {
  static const int size = 8;

  /// grid[row][col] == null -> empty, otherwise holds a theme color-index
  /// used purely for rendering variety.
  late List<List<int?>> grid;

  /// Running combo streak: increments each placement that clears at least
  /// one line, resets to 0 on a placement that clears none.
  int comboStreak = 0;

  BoardModel() {
    grid = List.generate(size, (_) => List<int?>.filled(size, null));
  }

  BoardModel.from(BoardModel other)
      : grid = other.grid.map((row) => List<int?>.from(row)).toList(),
        comboStreak = other.comboStreak;

  bool isEmptyCell(int row, int col) => grid[row][col] == null;

  /// Clears the grid in place (keeps the same object identity, so any
  /// component holding a reference to this board keeps working).
  void reset() {
    grid = List.generate(size, (_) => List<int?>.filled(size, null));
    comboStreak = 0;
  }

  /// Copies another board's contents into this one in place (used to
  /// implement the Undo power-up without swapping object identity).
  void restoreFrom(BoardModel other) {
    grid = other.grid.map((row) => List<int?>.from(row)).toList();
    comboStreak = other.comboStreak;
  }

  bool canPlaceAt(PieceShape shape, int row, int col) {
    for (final cell in shape.cells) {
      final r = row + cell.x;
      final c = col + cell.y;
      if (r < 0 || r >= size || c < 0 || c >= size) return false;
      if (grid[r][c] != null) return false;
    }
    return true;
  }

  /// Returns true if [shape] fits somewhere, anywhere, on the current board.
  bool canPlaceAnywhere(PieceShape shape) {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (canPlaceAt(shape, r, c)) return true;
      }
    }
    return false;
  }

  /// Places [shape] at [row]/[col] (caller must have validated with
  /// [canPlaceAt]), clears any full rows/columns, and returns the score
  /// breakdown.
  PlacementResult place(PieceShape shape, int row, int col, {int colorIndex = 0}) {
    for (final cell in shape.cells) {
      grid[row + cell.x][col + cell.y] = colorIndex;
    }

    final fullRows = <int>[];
    final fullCols = <int>[];
    for (var r = 0; r < size; r++) {
      if (grid[r].every((cell) => cell != null)) fullRows.add(r);
    }
    for (var c = 0; c < size; c++) {
      if (grid.every((row) => row[c] != null)) fullCols.add(c);
    }

    for (final r in fullRows) {
      for (var c = 0; c < size; c++) {
        grid[r][c] = null;
      }
    }
    for (final c in fullCols) {
      for (var r = 0; r < size; r++) {
        grid[r][c] = null;
      }
    }

    final linesCleared = fullRows.length + fullCols.length;
    comboStreak = linesCleared > 0 ? comboStreak + 1 : 0;

    // Scoring: 1 point/cell placed + 10 points/line, with a combo
    // multiplier for multiple simultaneous lines and back-to-back streaks.
    final placementScore = shape.cellCount;
    var lineScore = 0;
    if (linesCleared > 0) {
      final simultaneousMultiplier = switch (linesCleared) {
        1 => 1,
        2 => 3,
        3 => 5,
        _ => 8,
      };
      final streakMultiplier = 1 + (comboStreak - 1) * 0.5;
      lineScore = (linesCleared * 10 * simultaneousMultiplier * streakMultiplier).round();
    }

    return PlacementResult(
      cellsPlaced: shape.cellCount,
      linesCleared: linesCleared,
      scoreGained: placementScore + lineScore,
      clearedRows: fullRows,
      clearedCols: fullCols,
    );
  }

  /// Clears a single cell (used by the Hammer power-up).
  void clearCell(int row, int col) => grid[row][col] = null;

  /// Clears a 3x3 area centered on (row, col), clamped to the board bounds
  /// (used by the Bomb power-up).
  void clearArea(int row, int col) {
    for (var r = row - 1; r <= row + 1; r++) {
      for (var c = col - 1; c <= col + 1; c++) {
        if (r >= 0 && r < size && c >= 0 && c < size) grid[r][c] = null;
      }
    }
  }

  int get filledCellCount =>
      grid.fold(0, (sum, row) => sum + row.where((c) => c != null).length);
}

/// Generates hands of 3 pieces with weighted randomness, while avoiding
/// dealing a hand that is immediately unplayable when the board still has
/// room (mirrors the "fair bag" anti-frustration behaviour of the original).
class PieceBag {
  final Random _random;

  PieceBag({Random? random}) : _random = random ?? Random();

  PieceShape _weightedPick() {
    final entries = PieceLibrary.all;
    final totalWeight =
        entries.fold<int>(0, (sum, s) => sum + PieceLibrary.weightOf(s));
    var roll = _random.nextInt(totalWeight);
    for (final shape in entries) {
      final w = PieceLibrary.weightOf(shape);
      if (roll < w) return shape;
      roll -= w;
    }
    return entries.first;
  }

  /// Produces 3 pieces. Tries a bounded number of times to guarantee at
  /// least one of the three fits somewhere on [board]; falls back to
  /// smaller pieces if the board is nearly full.
  List<PieceShape> nextHand(BoardModel board) {
    const maxAttempts = 30;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final hand = [_weightedPick(), _weightedPick(), _weightedPick()];
      if (hand.any((s) => board.canPlaceAnywhere(s))) return hand;
    }
    // Board is almost full: force small pieces so the player gets a fair
    // last chance instead of an unavoidable game over.
    final small = PieceLibrary.all.where((s) => s.cellCount <= 2).toList();
    return [small[0], small[_random.nextInt(small.length)], small[_random.nextInt(small.length)]];
  }
}
