import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Shared Design System tokens used across all screens.
class DS {
  // ── Base URL ──
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {}
    return 'http://localhost:8000';
  }

  // ── Dark Theme Colors ──
  static const bg = Color(0xFF0F172A);           // Deep navy background
  static const surface = Color(0xFF1E293B);       // Card / surface
  static const surfaceAlt = Color(0xFF334155);    // Slightly lighter surface
  static const surfaceBorder = Color(0xFF334155); // Subtle borders

  static const deepBlue = Color(0xFF0F172A);
  static const indigo = Color(0xFF6366F1);
  static const indigoSoft = Color(0xFF312E81);    // Dark indigo tint
  static const textPrimary = Color(0xFFE2E8F0);   // Light text on dark bg
  static const textSecondary = Color(0xFF94A3B8);  // Muted text
  static const textMuted = Color(0xFF64748B);      // Very muted text

  static const emerald = Color(0xFF10B981);
  static const emeraldSoft = Color(0xFF064E3B);   // Dark emerald tint
  static const crimson = Color(0xFFEF4444);
  static const crimsonSoft = Color(0xFF7F1D1D);   // Dark crimson tint
  static const amber = Color(0xFFFBBF24);          // Warning / neutral amber
  static const neutral = Color(0xFF64748B);
  static const neutralSoft = Color(0xFF1E293B);

  // ── Gradients (dark theme) ──
  static const bullishGrad = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
  );
  static const bearishGrad = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF7F1D1D), Color(0xFF0F172A)],
  );
  static const neutralGrad = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );
  static const cardGrad = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF172033)],
  );

  // ── Shadows (subtle on dark) ──
  static List<BoxShadow> get neumorphicShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 12, offset: const Offset(0, 4),
    ),
  ];

  // ── Avatar Emoji Data ──
  static const Map<String, Map<String, dynamic>> avatarData = {
    'business_man':   {'emoji': '👨‍💼', 'color': Color(0xFF60A5FA), 'bg': Color(0xFF1E3A5F)},
    'business_woman': {'emoji': '👩‍💼', 'color': Color(0xFFC084FC), 'bg': Color(0xFF3B1F5E)},
    'classic_trader': {'emoji': '🎩', 'color': Color(0xFFFBBF24), 'bg': Color(0xFF3D2E0A)},
    'bull':           {'emoji': '🐂', 'color': Color(0xFF34D399), 'bg': Color(0xFF064E3B)},
    'bear':           {'emoji': '🐻', 'color': Color(0xFFF87171), 'bg': Color(0xFF7F1D1D)},
    'rocket':         {'emoji': '🚀', 'color': Color(0xFFFB923C), 'bg': Color(0xFF431407)},
    'diamond':        {'emoji': '💎', 'color': Color(0xFF22D3EE), 'bg': Color(0xFF164E63)},
    'moon':           {'emoji': '🌙', 'color': Color(0xFFA78BFA), 'bg': Color(0xFF312E81)},
  };

  static String getAvatarEmoji(String id) {
    return avatarData[id]?['emoji'] as String? ?? '👨‍💼';
  }

  static Color getAvatarColor(String id) {
    return avatarData[id]?['color'] as Color? ?? indigo;
  }

  static Color getAvatarBg(String id) {
    return avatarData[id]?['bg'] as Color? ?? surface;
  }

  static IconData getAvatarIcon(String id) {
    return Icons.person;
  }
}
