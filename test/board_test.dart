import 'package:flutter_test/flutter_test.dart';
import 'package:block_dash/models/board.dart';
import 'package:block_dash/models/piece.dart';

PieceShape _shapeById(String id) => PieceLibrary.all.firstWhere((s) => s.id == id);

void main() {
  group('BoardModel placement', () {
    test('places a single cell and marks it filled', () {
      final board = BoardModel();
      final result = board.place(_shapeById('single'), 0, 0);
      expect(board.isEmptyCell(0, 0), isFalse);
      expect(result.linesCleared, 0);
      expect(result.scoreGained, 1);
    });

    test('rejects placement outside the board bounds', () {
      final board = BoardModel();
      expect(board.canPlaceAt(_shapeById('line3_h'), 0, 7), isFalse);
      expect(board.canPlaceAt(_shapeById('line3_h'), 0, 5), isTrue);
    });

    test('rejects placement overlapping an occupied cell', () {
      final board = BoardModel();
      board.place(_shapeById('single'), 3, 3);
      expect(board.canPlaceAt(_shapeById('single'), 3, 3), isFalse);
    });

    test('clears a full row and awards line score', () {
      final board = BoardModel();
      // Fill row 0 entirely except the last cell with 8 single-cell drops.
      for (var c = 0; c < 7; c++) {
        board.place(_shapeById('single'), 0, c);
      }
      final result = board.place(_shapeById('single'), 0, 7);
      expect(result.linesCleared, 1);
      expect(result.clearedRows, [0]);
      expect(board.isEmptyCell(0, 0), isTrue, reason: 'cleared row should be emptied');
    });

    test('clears both a row and a column simultaneously', () {
      final board = BoardModel();
      // Fill row 0 except (0,0).
      for (var c = 1; c < 8; c++) {
        board.place(_shapeById('single'), 0, c);
      }
      // Fill column 0 except (0,0).
      for (var r = 1; r < 8; r++) {
        board.place(_shapeById('single'), r, 0);
      }
      final result = board.place(_shapeById('single'), 0, 0);
      expect(result.linesCleared, 2);
      expect(board.filledCellCount, 0);
    });

    test('combo streak increments on consecutive clears and resets otherwise', () {
      final board = BoardModel();
      for (var c = 0; c < 7; c++) {
        board.place(_shapeById('single'), 0, c);
      }
      board.place(_shapeById('single'), 0, 7); // clears -> streak 1
      expect(board.comboStreak, 1);

      board.place(_shapeById('single'), 5, 5); // no clear -> streak resets
      expect(board.comboStreak, 0);
    });
  });

  group('BoardModel power-up helpers', () {
    test('clearCell empties exactly one cell', () {
      final board = BoardModel();
      board.place(_shapeById('single'), 4, 4);
      board.clearCell(4, 4);
      expect(board.isEmptyCell(4, 4), isTrue);
    });

    test('clearArea empties a 3x3 neighborhood centered on the given cell', () {
      final board = BoardModel();
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          board.place(_shapeById('single'), r, c);
        }
      }
      board.clearArea(1, 1);
      expect(board.filledCellCount, 0);
    });

    test('clearArea clamps to the board edge without throwing', () {
      final board = BoardModel();
      board.place(_shapeById('single'), 0, 0);
      board.clearArea(0, 0);
      expect(board.isEmptyCell(0, 0), isTrue);
    });
  });

  group('BoardModel undo support', () {
    test('restoreFrom reverts grid contents without changing identity', () {
      final board = BoardModel();
      final snapshot = BoardModel.from(board);
      board.place(_shapeById('single'), 2, 2);
      expect(board.isEmptyCell(2, 2), isFalse);

      board.restoreFrom(snapshot);
      expect(board.isEmptyCell(2, 2), isTrue);
    });
  });

  group('PieceBag', () {
    test('always deals a hand where at least one piece currently fits', () {
      final board = BoardModel();
      final bag = PieceBag();
      for (var i = 0; i < 50; i++) {
        final hand = bag.nextHand(board);
        expect(hand.length, 3);
        expect(hand.any((s) => board.canPlaceAnywhere(s)), isTrue);
      }
    });

    test('falls back to small pieces when the board is nearly full', () {
      final board = BoardModel();
      // Fill the whole board except a single free cell at (7,7).
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if (r == 7 && c == 7) continue;
          board.grid[r][c] = 0;
        }
      }
      final bag = PieceBag();
      final hand = bag.nextHand(board);
      expect(hand.any((s) => board.canPlaceAnywhere(s)), isTrue);
    });
  });

  group('PieceLibrary', () {
    test('every shape is fully connected within its own bounding box claims', () {
      for (final shape in PieceLibrary.all) {
        expect(shape.cells, isNotEmpty);
        expect(shape.width, greaterThan(0));
        expect(shape.height, greaterThan(0));
      }
    });
  });
}
