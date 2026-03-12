import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../design_tokens.dart';

class LoginScreen extends StatefulWidget {
  final String lang;
  final VoidCallback onToggleLang;
  final Function(String token, Map<String, dynamic> user) onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.lang,
    required this.onToggleLang,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
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
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = widget.lang == 'tr' 
        ? 'E-posta ve şifre gereklidir.' 
        : 'Email and password are required.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final uri = Uri.parse('${DS.baseUrl}/api/auth/login');
      final response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final data = body['data'];
        widget.onLoginSuccess(data['token'], data['user']);
        // FIX: Pop all pushed routes so the MaterialApp's home widget takes over
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        setState(() => _error = body['detail'] ?? 'Login failed.');
      }
    } catch (e) {
      setState(() => _error = 'Connection error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Finance background ──
          Image.asset(
            'assets/images/finance_bg.png',
            fit: BoxFit.cover,
          ),
          // ── Dark overlay for readability ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
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
                        // ── Premium Logo ──
                        _buildPremiumLogo(),
                        const SizedBox(height: 20),
                        const Text(
                          'BORSA DASHBOARD',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 40, height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.lang == 'tr' ? 'Hesabınıza giriş yapın' : 'Sign in to your account',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                        ),
                        const SizedBox(height: 48),

                        // Email field
                        _buildField(
                          controller: _emailCtrl,
                          hint: widget.lang == 'tr' ? 'E-posta adresi' : 'Email address',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        _buildField(
                          controller: _passwordCtrl,
                          hint: widget.lang == 'tr' ? 'Şifre' : 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscure,
                          suffix: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white38, size: 20),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
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
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
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
                              : Text(widget.lang == 'tr' ? 'Giriş Yap' : 'Sign In',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(widget.lang == 'tr' ? 'Hesabınız yok mu? ' : "Don't have an account? ",
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/register'),
                              child: const Text('Sign Up',
                                style: TextStyle(color: Color(0xFF818CF8), fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Language toggle
                        GestureDetector(
                          onTap: widget.onToggleLang,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: Text(widget.lang == 'en' ? '🇹🇷 Türkçe' : '🇬🇧 English',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7))),
                          ),
                        ),
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

  /// Premium compound logo: stacked chart + candlestick elements
  Widget _buildPremiumLogo() {
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA78BFA)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 10)),
          BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2), blurRadius: 60, offset: const Offset(0, 20)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background candlestick bars
          Positioned(
            left: 14, bottom: 18,
            child: Row(
              children: [
                _bar(22, const Color(0xFF34D399)),
                const SizedBox(width: 4),
                _bar(16, const Color(0xFFFBBF24)),
                const SizedBox(width: 4),
                _bar(28, const Color(0xFF34D399)),
                const SizedBox(width: 4),
                _bar(12, const Color(0xFFF87171)),
                const SizedBox(width: 4),
                _bar(20, const Color(0xFF34D399)),
              ],
            ),
          ),
          // Trend line overlay
          const Icon(Icons.trending_up_rounded, color: Colors.white, size: 32),
        ],
      ),
    );
  }

  Widget _bar(double height, Color color) {
    return Container(
      width: 6, height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(3),
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
        onSubmitted: (_) => _login(),
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
