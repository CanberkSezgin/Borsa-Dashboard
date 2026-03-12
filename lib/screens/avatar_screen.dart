import 'package:flutter/material.dart';
import '../design_tokens.dart';

class AvatarScreen extends StatefulWidget {
  final String lang;
  final String email;
  final Function(String avatarId) onAvatarSelected;

  const AvatarScreen({
    super.key,
    required this.lang,
    required this.email,
    required this.onAvatarSelected,
  });

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> with SingleTickerProviderStateMixin {
  String? _selectedAvatar;
  late AnimationController _fadeCtrl;

  /// Each avatar: id, display (emoji or icon), label_en, label_tr, color, bg
  static const List<Map<String, dynamic>> avatars = [
    {'id': 'business_man', 'emoji': '👨‍💼', 'label_en': 'Business Man', 'label_tr': 'İş Adamı', 'color': Color(0xFF1E40AF), 'bg': Color(0xFFDBEAFE)},
    {'id': 'business_woman', 'emoji': '👩‍💼', 'label_en': 'Business Woman', 'label_tr': 'İş Kadını', 'color': Color(0xFF9333EA), 'bg': Color(0xFFF3E8FF)},
    {'id': 'classic_trader', 'emoji': '🎩', 'label_en': 'Classic Trader', 'label_tr': 'Klasik Tüccar', 'color': Color(0xFF92400E), 'bg': Color(0xFFFEF3C7)},
    {'id': 'bull', 'emoji': '🐂', 'label_en': 'Bull', 'label_tr': 'Boğa', 'color': Color(0xFF059669), 'bg': Color(0xFFD1FAE5)},
    {'id': 'bear', 'emoji': '🐻', 'label_en': 'Bear', 'label_tr': 'Ayı', 'color': Color(0xFFDC2626), 'bg': Color(0xFFFEE2E2)},
    {'id': 'rocket', 'emoji': '🚀', 'label_en': 'Rocket', 'label_tr': 'Roket', 'color': Color(0xFFEA580C), 'bg': Color(0xFFFFF7ED)},
    {'id': 'diamond', 'emoji': '💎', 'label_en': 'Diamond Hands', 'label_tr': 'Elmas', 'color': Color(0xFF0891B2), 'bg': Color(0xFFCFFAFE)},
    {'id': 'moon', 'emoji': '🌙', 'label_en': 'To The Moon', 'label_tr': 'Ay\'a Kadar', 'color': Color(0xFF4338CA), 'bg': Color(0xFFE0E7FF)},
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.lang == 'tr';
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/finance_bg.png', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0F172A).withValues(alpha: 0.85),
                  const Color(0xFF1E293B).withValues(alpha: 0.95),
                ],
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                              blurRadius: 20, offset: const Offset(0, 6),
                            )],
                          ),
                          child: const Icon(Icons.face_retouching_natural, color: Colors.white, size: 30),
                        ),
                        const SizedBox(height: 20),
                        Text(tr ? 'Avatarınızı Seçin' : 'Choose Your Avatar',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(tr ? 'Bu ikon profilinizde görünecek' : 'This icon will appear on your profile',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                        const SizedBox(height: 36),

                        // Avatar Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: avatars.length,
                          itemBuilder: (context, index) {
                            final av = avatars[index];
                            final isSelected = _selectedAvatar == av['id'];
                            return GestureDetector(
                              onTap: () => setState(() => _selectedAvatar = av['id']),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                decoration: BoxDecoration(
                                  color: isSelected
                                    ? (av['bg'] as Color).withValues(alpha: 0.9)
                                    : Colors.white.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                      ? (av['color'] as Color)
                                      : Colors.white.withValues(alpha: 0.12),
                                    width: isSelected ? 2.5 : 1,
                                  ),
                                  boxShadow: isSelected
                                    ? [BoxShadow(
                                        color: (av['color'] as Color).withValues(alpha: 0.35),
                                        blurRadius: 16, offset: const Offset(0, 4))]
                                    : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        Text(av['emoji'] as String,
                                          style: const TextStyle(fontSize: 32)),
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: av['color'] as Color,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.check, color: Colors.white, size: 10),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      tr ? av['label_tr'] as String : av['label_en'] as String,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected
                                          ? av['color'] as Color
                                          : Colors.white.withValues(alpha: 0.6),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // Continue button
                        SizedBox(
                          width: double.infinity, height: 52,
                          child: ElevatedButton(
                            onPressed: _selectedAvatar != null
                              ? () => widget.onAvatarSelected(_selectedAvatar!)
                              : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
                              disabledForegroundColor: Colors.white.withValues(alpha: 0.2),
                              elevation: _selectedAvatar != null ? 12 : 0,
                              shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(tr ? 'Devam Et' : 'Continue',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
