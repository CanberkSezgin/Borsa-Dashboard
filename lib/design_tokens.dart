import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Shared Design System tokens used across all screens.
class DS {
  // ── Base URL ──
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {}
    return 'http://127.0.0.1:8000';
  }

  // ── Colors ──
  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F7FA);
  static const surfaceAlt = Color(0xFFF1F5F9);

  static const deepBlue = Color(0xFF0F172A);
  static const indigo = Color(0xFF6366F1);
  static const indigoSoft = Color(0xFFEEF2FF);
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF94A3B8);

  static const emerald = Color(0xFF10B981);
  static const emeraldSoft = Color(0xFFD1FAE5);
  static const crimson = Color(0xFFEF4444);
  static const crimsonSoft = Color(0xFFFEE2E2);
  static const neutral = Color(0xFF64748B);
  static const neutralSoft = Color(0xFFF1F5F9);

  // ── Gradients ──
  static const bullishGrad = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
  );
  static const bearishGrad = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFFEF2F2), Color(0xFFFFF1F2)],
  );
  static const neutralGrad = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
  );
  static const cardGrad = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
  );

  // ── Shadows ──
  static List<BoxShadow> get neumorphicShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16, offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 4, offset: const Offset(0, 2),
    ),
  ];

  // ── Avatar data ──
  static const List<Map<String, dynamic>> avatarList = [
    {'id': 'business_man', 'icon': 'person', 'color': Color(0xFF1E40AF), 'bg': Color(0xFFDBEAFE)},
    {'id': 'business_woman', 'icon': 'person_4', 'color': Color(0xFF9333EA), 'bg': Color(0xFFF3E8FF)},
    {'id': 'classic_trader', 'icon': 'face_2', 'color': Color(0xFF92400E), 'bg': Color(0xFFFEF3C7)},
    {'id': 'bull', 'icon': 'trending_up', 'color': Color(0xFF059669), 'bg': Color(0xFFD1FAE5)},
    {'id': 'bear', 'icon': 'trending_down', 'color': Color(0xFFDC2626), 'bg': Color(0xFFFEE2E2)},
    {'id': 'rocket', 'icon': 'rocket_launch', 'color': Color(0xFFEA580C), 'bg': Color(0xFFFFF7ED)},
    {'id': 'diamond', 'icon': 'diamond', 'color': Color(0xFF0891B2), 'bg': Color(0xFFCFFAFE)},
    {'id': 'moon', 'icon': 'nightlight', 'color': Color(0xFF4338CA), 'bg': Color(0xFFE0E7FF)},
  ];

  static IconData getAvatarIcon(String id) {
    switch (id) {
      case 'business_man': return Icons.person;
      case 'business_woman': return Icons.person_4;
      case 'classic_trader': return Icons.face_2;
      case 'bull': return Icons.trending_up_rounded;
      case 'bear': return Icons.trending_down_rounded;
      case 'rocket': return Icons.rocket_launch_rounded;
      case 'diamond': return Icons.diamond_rounded;
      case 'moon': return Icons.nightlight_rounded;
      default: return Icons.person;
    }
  }

  static Color getAvatarColor(String id) {
    for (var av in avatarList) {
      if (av['id'] == id) return av['color'] as Color;
    }
    return deepBlue;
  }

  static Color getAvatarBg(String id) {
    for (var av in avatarList) {
      if (av['id'] == id) return av['bg'] as Color;
    }
    return surface;
  }
}
