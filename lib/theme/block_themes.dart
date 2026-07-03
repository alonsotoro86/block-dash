import 'package:flutter/material.dart';

/// A visual theme applied to the board blocks. Unlockable with coins.
class BlockTheme {
  final String id;
  final String name;
  final List<Color> blockColors;
  final Color background;
  final Color boardBackground;
  final int unlockCost;

  const BlockTheme({
    required this.id,
    required this.name,
    required this.blockColors,
    required this.background,
    required this.boardBackground,
    required this.unlockCost,
  });
}

class BlockThemes {
  BlockThemes._();

  static const List<BlockTheme> all = [
    BlockTheme(
      id: 'classic',
      name: 'Clásico',
      blockColors: [
        Color(0xFFEF5350),
        Color(0xFF42A5F5),
        Color(0xFFFFCA28),
        Color(0xFF66BB6A),
        Color(0xFFAB47BC),
        Color(0xFFFF7043),
      ],
      background: Color(0xFF1B1F3B),
      boardBackground: Color(0xFF262B52),
      unlockCost: 0,
    ),
    BlockTheme(
      id: 'neon',
      name: 'Neón',
      blockColors: [
        Color(0xFF00E5FF),
        Color(0xFFFF4081),
        Color(0xFF76FF03),
        Color(0xFFFFEA00),
        Color(0xFFE040FB),
        Color(0xFF18FFFF),
      ],
      background: Color(0xFF0D0221),
      boardBackground: Color(0xFF1A0B3D),
      unlockCost: 500,
    ),
    BlockTheme(
      id: 'fruit',
      name: 'Frutas',
      blockColors: [
        Color(0xFFE53935),
        Color(0xFFFB8C00),
        Color(0xFFFDD835),
        Color(0xFF43A047),
        Color(0xFF8E24AA),
        Color(0xFFD81B60),
      ],
      background: Color(0xFF2E1F0E),
      boardBackground: Color(0xFF4A3A22),
      unlockCost: 800,
    ),
    BlockTheme(
      id: 'space',
      name: 'Espacio',
      blockColors: [
        Color(0xFF7986CB),
        Color(0xFF4FC3F7),
        Color(0xFF9575CD),
        Color(0xFF4DB6AC),
        Color(0xFFBA68C8),
        Color(0xFF64B5F6),
      ],
      background: Color(0xFF03060F),
      boardBackground: Color(0xFF0B1026),
      unlockCost: 1200,
    ),
  ];

  static BlockTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);
}
