import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../design_tokens.dart';

class VerifyScreen extends StatefulWidget {
  final String lang;
  final String email;
  final String debugCode;
  final bool emailDelivered;

  const VerifyScreen({
    super.key,
    required this.lang,
    required this.email,
    this.debugCode = '',
    this.emailDelivered = false,
  });

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _codeControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;
  String _currentCode = '';
  bool _emailDelivered = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeCtrl.forward();
    _currentCode = widget.debugCode;
    _emailDelivered = widget.emailDelivered;
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _cooldownTimer?.cancel();
    for (var c in _codeControllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _code => _codeControllers.map((c) => c.text).join();

  Future<void> _verify() async {
    final code = _code;
    if (code.length != 6) {
      setState(() => _error = widget.lang == 'tr' 
        ? '6 haneli kodu girin.' 
        : 'Enter the 6-digit code.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final uri = Uri.parse('${DS.baseUrl}/api/auth/verify');
      final response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'code': code}),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/avatar', (route) => false,
            arguments: widget.email);
        }
      } else {
        setState(() => _error = body['detail'] ?? 'Verification failed.');
      }
    } catch (e) {
      setState(() => _error = 'Connection error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;

    try {
      final response = await http.post(
        Uri.parse('${DS.baseUrl}/api/auth/resend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );
      final body = jsonDecode(response.body);
      if (body['debug_code'] != null) {
        setState(() => _currentCode = body['debug_code'] as String);
      }
    } catch (_) {}

    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
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
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                              blurRadius: 20, offset: const Offset(0, 8),
                            )],
                          ),
                          child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 24),
                        Text(tr ? 'E-posta Doğrulama' : 'Verify Your Email',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text(
                          _emailDelivered
                            ? (tr ? '${widget.email} adresine doğrulama kodu gönderildi'
                                  : 'Verification code sent to ${widget.email}')
                            : (tr ? '${widget.email} için doğrulama kodu oluşturuldu'
                                  : 'Verification code generated for ${widget.email}'),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // ── Show verification code if email wasn't delivered ──
                        if (!_emailDelivered && _currentCode.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34D399).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.key_rounded, color: Color(0xFF34D399), size: 18),
                                    SizedBox(width: 8),
                                    Text('Doğrulama Kodunuz',
                                      style: TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _currentCode,
                                  style: const TextStyle(
                                    fontSize: 32, fontWeight: FontWeight.w900,
                                    color: Colors.white, letterSpacing: 8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr ? '(E-posta gönderilemedi — kod burada gösterildi)' 
                                     : '(Email not sent — code shown here)',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        
                        if (_emailDelivered)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF818CF8), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tr ? 'Doğrulama kodu e-posta adresinize gönderildi! Spam klasörünü de kontrol edin.'
                                       : 'Verification code sent to your email! Check spam folder too.',
                                    style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 24),

                        // Code input boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (i) {
                            return Container(
                              width: 48, height: 56,
                              margin: EdgeInsets.only(right: i < 5 ? 8 : 0, left: i == 3 ? 8 : 0),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _focusNodes[i].hasFocus 
                                    ? const Color(0xFF6366F1) 
                                    : Colors.white.withValues(alpha: 0.12),
                                  width: _focusNodes[i].hasFocus ? 2 : 1,
                                ),
                              ),
                              child: TextField(
                                controller: _codeControllers[i],
                                focusNode: _focusNodes[i],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                                decoration: const InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) {
                                  if (val.isNotEmpty && i < 5) {
                                    _focusNodes[i + 1].requestFocus();
                                  }
                                  if (val.isEmpty && i > 0) {
                                    _focusNodes[i - 1].requestFocus();
                                  }
                                  if (_code.length == 6) _verify();
                                  setState(() {});
                                },
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 28),

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

                        // Verify button
                        SizedBox(
                          width: double.infinity, height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _verify,
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
                              : Text(tr ? 'Doğrula' : 'Verify',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Resend
                        GestureDetector(
                          onTap: _resendCooldown > 0 ? null : _resend,
                          child: Text(
                            _resendCooldown > 0
                              ? (tr ? '$_resendCooldown sn sonra tekrar gönder' : 'Resend in $_resendCooldown s')
                              : (tr ? 'Kodu tekrar gönder' : 'Resend Code'),
                            style: TextStyle(
                              color: _resendCooldown > 0 ? Colors.white30 : const Color(0xFF818CF8),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
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
