import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../design_tokens.dart';

class RegisterScreen extends StatefulWidget {
  final String lang;

  const RegisterScreen({super.key, required this.lang});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  double get _passwordStrength {
    final p = _passwordCtrl.text;
    if (p.isEmpty) return 0;
    double s = 0;
    if (p.length >= 6) s += 0.25;
    if (p.length >= 10) s += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(p)) s += 0.25;
    if (RegExp(r'[0-9!@#\$%^&*]').hasMatch(p)) s += 0.25;
    return s;
  }

  Color get _strengthColor {
    final s = _passwordStrength;
    if (s <= 0.25) return const Color(0xFFF87171);
    if (s <= 0.5) return const Color(0xFFFBBF24);
    if (s <= 0.75) return const Color(0xFFFBBF24);
    return const Color(0xFF34D399);
  }

  String get _strengthLabel {
    final s = _passwordStrength;
    if (s == 0) return '';
    final tr = widget.lang == 'tr';
    if (s <= 0.25) return tr ? 'Zayıf' : 'Weak';
    if (s <= 0.5) return tr ? 'Orta' : 'Fair';
    if (s <= 0.75) return tr ? 'İyi' : 'Good';
    return tr ? 'Güçlü' : 'Strong';
  }

  Future<void> _register() async {
    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = widget.lang == 'tr' 
        ? 'Tüm alanlar gereklidir.' 
        : 'All fields are required.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final uri = Uri.parse('${DS.baseUrl}/api/auth/register');
      final response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (mounted) {
          final debugCode = body['debug_code'] as String? ?? '';
          final emailDelivered = body['data']?['email_delivered'] as bool? ?? false;
          Navigator.pushNamed(context, '/verify', arguments: {
            'email': email,
            'debug_code': debugCode,
            'email_delivered': emailDelivered,
          });
        }
      } else {
        setState(() => _error = body['detail'] ?? 'Registration failed.');
      }
    } catch (e) {
      setState(() => _error = 'Connection error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.lang == 'tr';
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Finance background ──
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
          // ── Content ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white.withValues(alpha: 0.6), size: 20),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Logo
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
                          child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 20),
                        Text(tr ? 'Hesap Oluştur' : 'Create Account',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(tr ? 'Yatırım yolculuğunuza başlayın' : 'Start your investment journey',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                        const SizedBox(height: 36),

                        // Username
                        _buildField(controller: _usernameCtrl,
                          hint: tr ? 'Kullanıcı adı' : 'Username',
                          icon: Icons.person_outline_rounded),
                        const SizedBox(height: 14),

                        // Email
                        _buildField(controller: _emailCtrl,
                          hint: tr ? 'E-posta adresi' : 'Email address',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 14),

                        // Password
                        _buildField(controller: _passwordCtrl,
                          hint: tr ? 'Şifre (min 6 karakter)' : 'Password (min 6 chars)',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscure,
                          onChanged: (_) => setState(() {}),
                          suffix: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white38, size: 20),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          )),
                        
                        // Password strength
                        if (_passwordCtrl.text.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _passwordStrength,
                                  minHeight: 4,
                                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation(_strengthColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(_strengthLabel,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _strengthColor)),
                          ]),
                        ],
                        const SizedBox(height: 24),

                        // Error
                        if (_error != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: DS.crimson.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: DS.crimson.withValues(alpha: 0.3)),
                            ),
                            child: Text(_error!,
                              style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center),
                          ),

                        // Register button
                        SizedBox(
                          width: double.infinity, height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              elevation: 12,
                              shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _loading
                              ? const SizedBox(width: 24, height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : Text(tr ? 'Kayıt Ol' : 'Create Account',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(tr ? 'Zaten hesabınız var mı? ' : 'Already have an account? ',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(tr ? 'Giriş Yap' : 'Sign In',
                                style: const TextStyle(color: Color(0xFF818CF8), fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                          ],
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

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 20),
          suffixIcon: suffix,
          filled: true, fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
