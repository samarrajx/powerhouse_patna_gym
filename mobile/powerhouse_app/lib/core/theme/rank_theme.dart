import 'package:flutter/material.dart';

class RankTheme {
  static Color getRankColor(String? rank) {
    switch (rank?.toUpperCase()) {
      case 'E':
        return const Color(0xFF6B7280);
      case 'D':
        return const Color(0xFF9CA3AF);
      case 'C':
        return const Color(0xFF22C55E);
      case 'B':
        return const Color(0xFF3B82F6);
      case 'A':
        return const Color(0xFF8B5CF6);
      case 'S':
        return const Color(0xFFFF6A00);
      default:
        return const Color(0xFF9CA3AF); // Neutral Grey
    }
  }
}
