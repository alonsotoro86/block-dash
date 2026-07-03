import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../models/board.dart';
import '../models/piece.dart';
import '../theme/block_themes.dart';
import 'board_component.dart';
import 'draggable_piece_component.dart';
import 'effects/line_clear_flash.dart';

class _UndoSnapshot {
  final BoardModel boardCopy;
  final int score;
  final int slotIndex;
  final PieceShape shape;
  final int colorIndex;
  final Vector2 homePosition;

  _UndoSnapshot({
    required this.boardCopy,
    required this.score,
    required this.slotIndex,
    required this.shape,
    required this.colorIndex,
    required this.homePosition,
  });
}

/// The BlockDash game world: an 8x8 [BoardModel], a 3-piece tray, and all
/// the drag/placement/power-up logic. UI (score, coins, dialogs) lives in
/// Flutter widgets that subscribe to the callbacks below — this class has
/// no knowledge of Provider/AppState, keeping it independently testable.
class BlockDashGame extends FlameGame with TapCallbacks {
  BlockTheme currentTheme;

  final void Function(int totalScore, int delta) onScoreChanged;
  final void Function(int linesCleared, int comboStreak) onLinesCleared;
  final void Function(int finalScore) onGameOver;
  final void Function(int coinsEarned) onCoinsEarned;
  final Future<bool> Function(String powerUpId) onConsumePowerUp;

  BlockDashGame({
    required this.currentTheme,
    required this.onScoreChanged,
    required this.onLinesCleared,
    required this.onGameOver,
    required this.onCoinsEarned,
    required this.onConsumePowerUp,
  });

  late final BoardModel board;
  late final PieceBag bag;
  late BoardComponent boardComponent;
  final List<DraggablePieceComponent?> trayPieces = [null, null, null];
  final Random _random = Random();

  double cellSize = 32;
  int score = 0;
  String activePowerUp = '';
  _UndoSnapshot? _undoSnapshot;
  bool get canUndo => _undoSnapshot != null;
  bool _gameOverFired = false;

  @override
  Future<void> onLoad() async {
    board = BoardModel();
    bag = PieceBag();
    boardComponent = BoardComponent(board: board, theme: currentTheme, cellSize: cellSize);
    add(boardComponent);
    startNewGame();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isLoaded) return;
    const margin = 16.0;
    final boardPixels = size.x - margin * 2;
    cellSize = boardPixels / BoardModel.size;
    boardComponent.updateCellSize(cellSize);
    boardComponent.position = Vector2(margin, margin);
    _relayoutTray(margin, boardPixels);
  }

  double get _trayCellSize => cellSize * 0.8;
  double get _trayTop => boardComponent.position.y + boardComponent.size.y + 28;

  Vector2 _traySlotPosition(int slotIndex, PieceShape shape, double margin, double boardPixels) {
    final slotWidth = boardPixels / 3;
    final slotCenterX = margin + slotWidth * slotIndex + slotWidth / 2;
    final pieceWidth = shape.width * _trayCellSize;
    final pieceHeight = shape.height * _trayCellSize;
    final slotHeight = _trayCellSize * 5;
    return Vector2(
      slotCenterX - pieceWidth / 2,
      _trayTop + (slotHeight - pieceHeight) / 2,
    );
  }

  void _relayoutTray(double margin, double boardPixels) {
    for (var i = 0; i < trayPieces.length; i++) {
      final piece = trayPieces[i];
      if (piece == null) continue;
      final home = _traySlotPosition(i, piece.shape, margin, boardPixels);
      piece.position = home;
      piece.homePosition.setFrom(home);
    }
  }

  void startNewGame() {
    board.reset();
    score = 0;
    _undoSnapshot = null;
    _gameOverFired = false;
    activePowerUp = '';
    for (final piece in trayPieces) {
      piece?.removeFromParent();
    }
    trayPieces.setAll(0, [null, null, null]);
    onScoreChanged(0, 0);
    _dealNewHand();
  }

  void _dealNewHand() {
    final hand = bag.nextHand(board);
    const margin = 16.0;
    final boardPixels = cellSize * BoardModel.size;
    for (var i = 0; i < hand.length; i++) {
      final shape = hand[i];
      final home = _traySlotPosition(i, shape, margin, boardPixels);
      final piece = DraggablePieceComponent(
        shape: shape,
        colorIndex: _random.nextInt(currentTheme.blockColors.length),
        theme: currentTheme,
        cellSize: _trayCellSize,
        homePosition: home,
        boardOrigin: () => boardComponent.position,
        canPlaceAt: board.canPlaceAt,
        onPlaced: _onPiecePlaced,
        onDragBegin: () {},
        onDragMove: _onPieceDragMove,
        onDragFinished: () => boardComponent.clearPreview(),
      );
      trayPieces[i] = piece;
      add(piece);
    }
  }

  void _onPieceDragMove(PieceShape shape, int row, int col) {
    boardComponent.setPreview(shape, row, col, board.canPlaceAt(shape, row, col));
  }

  void _onPiecePlaced(DraggablePieceComponent piece, int row, int col) {
    final slotIndex = trayPieces.indexOf(piece);

    _undoSnapshot = _UndoSnapshot(
      boardCopy: BoardModel.from(board),
      score: score,
      slotIndex: slotIndex,
      shape: piece.shape,
      colorIndex: piece.colorIndex,
      homePosition: piece.homePosition.clone(),
    );

    // Snap the piece's on-screen position to the exact target cell before
    // it disappears, avoiding a visible jump.
    piece.position = boardComponent.position + Vector2(col * cellSize, row * cellSize);

    final result = board.place(piece.shape, row, col, colorIndex: piece.colorIndex);
    piece.removeFromParent();
    if (slotIndex != -1) trayPieces[slotIndex] = null;

    score += result.scoreGained;
    onScoreChanged(score, result.scoreGained);

    if (result.linesCleared > 0) {
      _spawnClearFlashes(result.clearedRows, result.clearedCols);
      onLinesCleared(result.linesCleared, board.comboStreak);
      final comboBonus = board.comboStreak > 1 ? (board.comboStreak - 1) * 3 : 0;
      final coins = result.linesCleared * 5 + comboBonus;
      onCoinsEarned(coins);
    }

    if (trayPieces.every((p) => p == null)) {
      _dealNewHand();
    }

    _checkGameOver();
  }

  void _spawnClearFlashes(List<int> rows, List<int> cols) {
    for (final r in rows) {
      add(
        LineClearFlash(
          position: boardComponent.position + Vector2(0, r * cellSize),
          size: Vector2(boardComponent.size.x, cellSize),
        ),
      );
    }
    for (final c in cols) {
      add(
        LineClearFlash(
          position: boardComponent.position + Vector2(c * cellSize, 0),
          size: Vector2(cellSize, boardComponent.size.y),
        ),
      );
    }
  }

  void _checkGameOver() {
    if (_gameOverFired) return;
    final remainingShapes =
        trayPieces.where((p) => p != null).map((p) => p!.shape).toList();
    if (remainingShapes.isEmpty) return;
    final anyFits = remainingShapes.any((s) => board.canPlaceAnywhere(s));
    if (!anyFits) {
      _gameOverFired = true;
      onGameOver(score);
    }
  }

  // ---- Power-ups (charge/coin cost is enforced by AppState via
  // onConsumePowerUp before the effect is applied) ----

  void armPowerUp(String type) {
    activePowerUp = activePowerUp == type ? '' : type;
  }

  Future<void> _handleBoardTap(int row, int col) async {
    if (activePowerUp.isEmpty) return;
    final type = activePowerUp;
    final consumed = await onConsumePowerUp(type);
    if (!consumed) return;
    if (type == 'hammer') {
      board.clearCell(row, col);
    } else if (type == 'bomb') {
      board.clearArea(row, col);
    }
    activePowerUp = '';
  }

  Future<bool> useSwap() async {
    final consumed = await onConsumePowerUp('swap');
    if (!consumed) return false;
    for (final piece in trayPieces) {
      piece?.removeFromParent();
    }
    trayPieces.setAll(0, [null, null, null]);
    _dealNewHand();
    return true;
  }

  Future<bool> useUndo() async {
    final snap = _undoSnapshot;
    if (snap == null) return false;
    final consumed = await onConsumePowerUp('undo');
    if (!consumed) return false;

    board.restoreFrom(snap.boardCopy);
    score = snap.score;
    onScoreChanged(score, 0);
    _gameOverFired = false;

    final piece = DraggablePieceComponent(
      shape: snap.shape,
      colorIndex: snap.colorIndex,
      theme: currentTheme,
      cellSize: _trayCellSize,
      homePosition: snap.homePosition,
      boardOrigin: () => boardComponent.position,
      canPlaceAt: board.canPlaceAt,
      onPlaced: _onPiecePlaced,
      onDragBegin: () {},
      onDragMove: _onPieceDragMove,
      onDragFinished: () => boardComponent.clearPreview(),
    );
    trayPieces[snap.slotIndex] = piece;
    add(piece);
    _undoSnapshot = null;
    return true;
  }

  void applyTheme(BlockTheme theme) {
    currentTheme = theme;
    boardComponent.theme = theme;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (activePowerUp.isEmpty) return;
    final local = event.localPosition - boardComponent.position;
    final row = (local.y / cellSize).floor();
    final col = (local.x / cellSize).floor();
    if (row < 0 || row >= BoardModel.size || col < 0 || col >= BoardModel.size) return;
    _handleBoardTap(row, col);
  }
}
