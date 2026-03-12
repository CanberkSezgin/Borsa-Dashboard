import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';

import 'design_tokens.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/verify_screen.dart';
import 'screens/avatar_screen.dart';

// ─────────────────────────────────────────────────────────────────
//  LOCALISATION
// ─────────────────────────────────────────────────────────────────
const Map<String, Map<String, String>> _l10n = {
  'en': {
    'appTitle': 'Borsa Dashboard',
    'searchHint': 'Enter ticker (e.g. AAPL)',
    'analyzeBtn': 'Analyze',
    'loading': 'Fetching data…',
    'errorPrefix': 'Error',
    'sentimentTitle': 'Sentiment Analysis',
    'uptrend': '▲ Upward Trend',
    'downtrend': '▼ Downward Trend',
    'neutral': '● Neutral',
    'score': 'Sentiment Score',
    'positive': 'Positive',
    'negative': 'Negative',
    'priceCard': 'Close Price',
    'rsiCard': 'RSI (14)',
    'macdCard': 'MACD',
    'overbought': 'Overbought',
    'oversold': 'Oversold',
    'technical': 'Technical Indicators',
    'recentNews': 'Recent Headlines',
    'noNews': 'No recent news available.',
    'confidence': 'CONFIDENCE',
    'retry': 'Try Again',
    'noData': 'No data returned from API.',
    'greeting_morning': 'Good morning',
    'greeting_afternoon': 'Good afternoon',
    'greeting_evening': 'Good evening',
    'logout': 'Logout',
    'profile': 'Profile',
  },
  'tr': {
    'appTitle': 'Borsa Paneli',
    'searchHint': 'Sembol girin (örn. AAPL)',
    'analyzeBtn': 'Analiz Et',
    'loading': 'Veri alınıyor…',
    'errorPrefix': 'Hata',
    'sentimentTitle': 'Duygu Analizi',
    'uptrend': '▲ Yükseliş Trendi',
    'downtrend': '▼ Düşüş Trendi',
    'neutral': '● Nötr',
    'score': 'Duygu Skoru',
    'positive': 'Pozitif',
    'negative': 'Negatif',
    'priceCard': 'Kapanış Fiyatı',
    'rsiCard': 'RSI (14)',
    'macdCard': 'MACD',
    'overbought': 'Aşırı Alım',
    'oversold': 'Aşırı Satım',
    'technical': 'Teknik Göstergeler',
    'recentNews': 'Son Haberler',
    'noNews': 'Yakın zamanda haber bulunamadı.',
    'confidence': 'GÜVEN',
    'retry': 'Tekrar Dene',
    'noData': 'API\'den veri gelmedi.',
    'greeting_morning': 'Günaydın',
    'greeting_afternoon': 'İyi öğlenler',
    'greeting_evening': 'İyi akşamlar',
    'logout': 'Çıkış Yap',
    'profile': 'Profil',
  },
};

// ─────────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────────
String _pad(int n) => n.toString().padLeft(2, '0');

String _getGreeting(String lang) {
  final hour = DateTime.now().hour;
  if (hour < 12) return _l10n[lang]!['greeting_morning']!;
  if (hour < 18) return _l10n[lang]!['greeting_afternoon']!;
  return _l10n[lang]!['greeting_evening']!;
}

// ─────────────────────────────────────────────────────────────────
//  MARKET MARQUEE COMPONENT
// ─────────────────────────────────────────────────────────────────
class _MarketMarquee extends StatefulWidget {
  final List<dynamic> items;
  const _MarketMarquee({required this.items});

  @override
  State<_MarketMarquee> createState() => _MarketMarqueeState();
}

class _MarketMarqueeState extends State<_MarketMarquee> {
  late ScrollController _scrollController;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startScrolling();
  }

  void _startScrolling() {
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        if (currentScroll >= maxScroll) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(currentScroll + 1);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: DS.textMuted.withValues(alpha: 0.1), width: 1)),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final item = widget.items[index % widget.items.length];
          final symbol = item['symbol'] as String;
          final price = (item['price'] as num).toDouble();
          final change = (item['change_pct'] as num).toDouble();
          final isPositive = change >= 0;
          final color = isPositive ? DS.emerald : DS.crimson;
          final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(symbol, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: DS.textSecondary)),
              const SizedBox(width: 8),
              Text(price.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: DS.deepBlue)),
              const SizedBox(width: 4),
              Icon(icon, size: 12, color: color),
              Text('${change.abs().toStringAsFixed(2)}%', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: color)),
            ]),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────────────────────────
void main() {
  runApp(const BorsaApp());
}

class BorsaApp extends StatefulWidget {
  const BorsaApp({super.key});

  @override
  State<BorsaApp> createState() => _BorsaAppState();
}

class _BorsaAppState extends State<BorsaApp> {
  String _lang = 'en';
  String? _token;
  Map<String, dynamic>? _currentUser;

  void _toggleLang() => setState(() => _lang = _lang == 'en' ? 'tr' : 'en');

  void _handleLogin(String token, Map<String, dynamic> user) {
    setState(() {
      _token = token;
      _currentUser = user;
    });
  }

  void _handleLogout() {
    setState(() {
      _token = null;
      _currentUser = null;
    });
  }

  void _handleAvatarSelected(String avatarId) {
    // Update avatar on server (fire and forget)
    if (_token != null) {
      http.put(
        Uri.parse('${DS.baseUrl}/api/auth/avatar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': _token, 'avatar_id': avatarId}),
      );
    }
    setState(() {
      if (_currentUser != null) {
        _currentUser!['avatar_id'] = avatarId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _l10n[_lang]!['appTitle']!,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: DS.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: DS.indigo,
          brightness: Brightness.light,
          surface: DS.surface,
          onSurface: DS.textPrimary,
        ),
        fontFamily: 'Roboto',
      ),
      home: _token == null
        ? LoginScreen(
            lang: _lang,
            onToggleLang: _toggleLang,
            onLoginSuccess: _handleLogin,
          )
        : HomeScreen(
            lang: _lang,
            onToggleLang: _toggleLang,
            user: _currentUser!,
            token: _token!,
            onLogout: _handleLogout,
            onAvatarChanged: _handleAvatarSelected,
          ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/register':
            return MaterialPageRoute(
              builder: (_) => RegisterScreen(lang: _lang),
            );
          case '/verify':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => VerifyScreen(
                lang: _lang,
                email: args['email'] as String,
                debugCode: args['debug_code'] as String? ?? '',
                emailDelivered: args['email_delivered'] as bool? ?? false,
              ),
            );
          case '/avatar':
            final email = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (ctx) => AvatarScreen(
                lang: _lang,
                email: email,
                onAvatarSelected: (avatarId) {
                  // After avatar selection during registration, go to login
                  Navigator.pushNamedAndRemoveUntil(
                    ctx, '/login', (route) => false,
                  );
                },
              ),
            );
          case '/login':
            return MaterialPageRoute(
              builder: (_) => LoginScreen(
                lang: _lang,
                onToggleLang: _toggleLang,
                onLoginSuccess: _handleLogin,
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final String lang;
  final VoidCallback onToggleLang;
  final Map<String, dynamic> user;
  final String token;
  final VoidCallback onLogout;
  final Function(String) onAvatarChanged;

  const HomeScreen({
    super.key,
    required this.lang,
    required this.onToggleLang,
    required this.user,
    required this.token,
    required this.onLogout,
    required this.onAvatarChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _tickerCtrl = TextEditingController();

  bool _loading = false;
  String _selectedRange = '1M';
  String? _error;
  Map<String, dynamic>? _data;
  List<dynamic>? _dataList;
  Map<String, dynamic>? _forecast;
  List<Map<String, dynamic>>? _recentNews;
  List<dynamic> _marketSummary = [];

  Timer? _refreshTimer;
  DateTime? _lastFetchTime;

  String t(String key) => _l10n[widget.lang]![key] ?? key;

  @override
  void initState() {
    super.initState();
    _fetchMarketSummary();
  }

  Future<void> _fetchMarketSummary() async {
    try {
      final uri = Uri.parse('${DS.baseUrl}/api/market_summary');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (mounted) {
          setState(() => _marketSummary = body['data'] as List<dynamic>);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tickerCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyze({bool isAutoRefresh = false}) async {
    final ticker = _tickerCtrl.text.trim().toUpperCase();
    if (ticker.isEmpty) return;

    if (!isAutoRefresh) {
      _refreshTimer?.cancel();
      setState(() {
        _loading = true; _error = null;
        _data = null; _dataList = null;
        _forecast = null; _recentNews = null;
        _lastFetchTime = null;
      });
    }

    try {
      final uri = Uri.parse('${DS.baseUrl}/api/analyze/$ticker?range=$_selectedRange');
      final response = await http.get(uri).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final dataList = body['data'] as List<dynamic>?;

        if (dataList == null || dataList.isEmpty) {
          setState(() => _error = t('noData'));
        } else {
          setState(() {
            _data = dataList.last as Map<String, dynamic>;
            _dataList = dataList;
            _forecast = body['forecast'] as Map<String, dynamic>?;
            _recentNews = (body['recent_news'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>).toList();
            _lastFetchTime = DateTime.now();
          });
          if (!isAutoRefresh) {
            _refreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
              _analyze(isAutoRefresh: true);
            });
          }
        }
      } else {
        final body = jsonDecode(response.body);
        setState(() => _error = '${t('errorPrefix')}: ${body['detail'] ?? response.statusCode}');
      }
    } catch (e) {
      if (!isAutoRefresh) setState(() => _error = '${t('errorPrefix')}: $e');
    } finally {
      if (!isAutoRefresh) setState(() => _loading = false);
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final avatarId = widget.user['avatar_id'] as String? ?? 'business_man';
        final username = widget.user['username'] as String? ?? 'User';
        final email = widget.user['email'] as String? ?? '';
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(28),
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DS.getAvatarBg(avatarId),
                    shape: BoxShape.circle,
                  ),
                  child: Text(DS.getAvatarEmoji(avatarId),
                    style: const TextStyle(fontSize: 36)),
                ),
                const SizedBox(height: 16),
                Text(username,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: DS.deepBlue)),
                const SizedBox(height: 4),
                Text(email,
                  style: const TextStyle(fontSize: 13, color: DS.textSecondary)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onLogout();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(t('logout')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DS.crimson,
                      side: const BorderSide(color: DS.crimson),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarId = widget.user['avatar_id'] as String? ?? 'business_man';
    final username = widget.user['username'] as String? ?? 'User';

    return Scaffold(
      backgroundColor: DS.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar with Profile ──
            _buildAppBar(avatarId, username),
            if (_marketSummary.isNotEmpty)
              _MarketMarquee(items: _marketSummary),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Welcome greeting
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Text(
                            '${_getGreeting(widget.lang)}, $username 👋',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: DS.deepBlue,
                            ),
                          ),
                        ),

                        _SearchBar(
                          controller: _tickerCtrl,
                          hint: t('searchHint'),
                          buttonLabel: t('analyzeBtn'),
                          onSearch: _analyze,
                          loading: _loading,
                        ),
                        const SizedBox(height: 32),

                        if (_loading)
                          Center(child: Column(children: [
                            const CircularProgressIndicator(color: DS.indigo),
                            const SizedBox(height: 16),
                            Text(t('loading'), style: const TextStyle(color: DS.textSecondary, fontWeight: FontWeight.w600)),
                          ])),

                        if (_error != null)
                          _ErrorCard(message: _error!, onRetry: _analyze, lang: widget.lang),

                        if (_data != null) ...[
                          if (_forecast != null) ...[
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: _ForecastCard(
                                key: ValueKey('forecast_${_lastFetchTime?.millisecondsSinceEpoch}'),
                                forecast: _forecast!, lang: widget.lang,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: _SentimentCard(
                              key: ValueKey('sentiment_${_lastFetchTime?.millisecondsSinceEpoch}'),
                              data: _data!, lang: widget.lang,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 600),
                            child: _ProChartSection(
                              key: ValueKey('chart_${_selectedRange}_${_lastFetchTime?.millisecondsSinceEpoch}'),
                              dataList: _dataList!, forecast: _forecast,
                              lang: widget.lang, selectedRange: _selectedRange,
                              onRangeChanged: (val) {
                                setState(() => _selectedRange = val);
                                _analyze();
                              },
                            ),
                          ),
                          if (_recentNews != null) ...[
                            const SizedBox(height: 32),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 700),
                              child: _RecentNewsSection(
                                key: ValueKey('news_${_lastFetchTime?.millisecondsSinceEpoch}'),
                                news: _recentNews!, lang: widget.lang,
                              ),
                            ),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(String avatarId, String username) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            _l10n[widget.lang]!['appTitle']!.toUpperCase(),
            style: const TextStyle(
              color: DS.deepBlue, fontSize: 16,
              fontWeight: FontWeight.w800, letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          if (_lastFetchTime != null)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.sync, color: DS.textMuted, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${_pad(_lastFetchTime!.hour)}:${_pad(_lastFetchTime!.minute)}:${_pad(_lastFetchTime!.second)}',
                  style: const TextStyle(color: DS.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ]),
            ),
          GestureDetector(
            onTap: widget.onToggleLang,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: DS.neumorphicShadow,
              ),
              child: Text(
                widget.lang == 'en' ? 'TR' : 'EN',
                style: const TextStyle(color: DS.deepBlue, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          // Profile avatar
          GestureDetector(
            onTap: _showProfileDialog,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: DS.getAvatarBg(avatarId),
                shape: BoxShape.circle,
                border: Border.all(color: DS.getAvatarColor(avatarId).withValues(alpha: 0.3), width: 2),
                boxShadow: DS.neumorphicShadow,
              ),
              child: Text(DS.getAvatarEmoji(avatarId),
                style: const TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  PREMIUM CARD PRIMITIVE (Neumorphic)
// ─────────────────────────────────────────────────────────────────
class _PremiumCard extends StatelessWidget {
  final Widget child;
  final Gradient? customGradient;

  const _PremiumCard({required this.child, this.customGradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: customGradient ?? DS.cardGrad,
        boxShadow: DS.neumorphicShadow,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  SEARCH BAR
// ─────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String buttonLabel;
  final VoidCallback onSearch;
  final bool loading;

  const _SearchBar({
    required this.controller, required this.hint,
    required this.buttonLabel, required this.onSearch, required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            boxShadow: DS.neumorphicShadow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            style: const TextStyle(fontWeight: FontWeight.w600, color: DS.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: DS.textMuted, fontWeight: FontWeight.normal),
              prefixIcon: const Icon(Icons.search, color: DS.textMuted),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      ElevatedButton(
        onPressed: loading ? null : onSearch,
        style: ElevatedButton.styleFrom(
          backgroundColor: DS.indigo,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: DS.indigo.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
        child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────
//  ERROR CARD
// ─────────────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String lang;

  const _ErrorCard({required this.message, required this.onRetry, required this.lang});

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      customGradient: DS.bearishGrad,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: DS.crimsonSoft, shape: BoxShape.circle),
            child: const Icon(Icons.error_outline, color: DS.crimson, size: 28),
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: DS.crimson, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(_l10n[lang]!['retry']!),
            style: OutlinedButton.styleFrom(
              foregroundColor: DS.crimson,
              side: const BorderSide(color: DS.crimson),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  FORECAST CARD
// ─────────────────────────────────────────────────────────────────
class _ForecastCard extends StatelessWidget {
  final Map<String, dynamic> forecast;
  final String lang;

  const _ForecastCard({super.key, required this.forecast, required this.lang});

  @override
  Widget build(BuildContext context) {
    final label = forecast['forecast_label'] as String? ?? 'Unknown';
    final score = (forecast['prediction_score'] as num?)?.toDouble() ?? 0.0;
    final isBullish = label.toLowerCase().contains("up") || label.toLowerCase().contains("bull");

    final gradient = isBullish ? DS.bullishGrad : DS.bearishGrad;
    final accentColor = isBullish ? DS.emerald : DS.crimson;
    final trendIcon = isBullish ? Icons.trending_up : Icons.trending_down;
    final confidencePct = score * 100;

    return _PremiumCard(
      customGradient: gradient,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(trendIcon, color: accentColor, size: 36),
              const SizedBox(width: 8),
              Text(label.toUpperCase(),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                  color: accentColor, letterSpacing: 1.5)),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${_l10n[lang]!['confidence']}: ',
                style: const TextStyle(fontSize: 13, color: DS.textSecondary,
                  fontWeight: FontWeight.w700, letterSpacing: 1)),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: confidencePct),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => Text('${val.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 16, color: accentColor, fontWeight: FontWeight.w800)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  SENTIMENT CARD
// ─────────────────────────────────────────────────────────────────
class _SentimentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String lang;

  const _SentimentCard({super.key, required this.data, required this.lang});
  String t(String key) => _l10n[lang]![key] ?? key;

  @override
  Widget build(BuildContext context) {
    final score = (data['Sentiment_Score'] as num?)?.toDouble() ?? 0.0;
    final positive = (data['Sent_Positive'] as num?)?.toDouble() ?? 0.0;
    final negative = (data['Sent_Negative'] as num?)?.toDouble() ?? 0.0;

    final isPositive = score > 0.05;
    final isNegative = score < -0.05;

    final gradient = isPositive ? DS.bullishGrad : (isNegative ? DS.bearishGrad : DS.neutralGrad);
    final accentColor = isPositive ? DS.emerald : (isNegative ? DS.crimson : DS.neutral);
    final trendLabel = isPositive ? t('uptrend') : (isNegative ? t('downtrend') : t('neutral'));
    final trendIcon = isPositive ? Icons.trending_up : (isNegative ? Icons.trending_down : Icons.trending_flat);

    return _PremiumCard(
      customGradient: gradient,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t('sentimentTitle').toUpperCase(),
            style: const TextStyle(color: DS.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Row(children: [
            Icon(trendIcon, color: accentColor, size: 28),
            const SizedBox(width: 8),
            Text(trendLabel, style: TextStyle(color: accentColor, fontSize: 22, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 24),
          Text(t('score'), style: const TextStyle(color: DS.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: score),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => Text(val.toStringAsFixed(3),
              style: TextStyle(color: accentColor, fontSize: 36, fontWeight: FontWeight.w900, height: 1)),
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: ((score + 1) / 2).clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: val, minHeight: 8,
                backgroundColor: accentColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(children: [
            _ScorePill(label: t('positive'), value: positive, color: DS.emerald),
            const SizedBox(width: 12),
            _ScorePill(label: t('negative'), value: negative, color: DS.crimson),
          ]),
        ]),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ScorePill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 6),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value * 100),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (_, val, __) => Text('$label  ${val.toStringAsFixed(1)}%',
            style: const TextStyle(color: DS.deepBlue, fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  PRO CHART SECTION
// ─────────────────────────────────────────────────────────────────
class _ProChartSection extends StatelessWidget {
  final List<dynamic> dataList;
  final Map<String, dynamic>? forecast;
  final String lang;
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;

  const _ProChartSection({
    super.key, required this.dataList, this.forecast,
    required this.lang, required this.selectedRange, required this.onRangeChanged,
  });

  String t(String key) => _l10n[lang]![key] ?? key;

  @override
  Widget build(BuildContext context) {
    if (dataList.isEmpty) return const SizedBox.shrink();

    final List<FlSpot> spots = [];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < dataList.length; i++) {
      final point = dataList[i];
      final close = (point['Close'] as num?)?.toDouble() ?? 0.0;
      if (close > 0) {
        spots.add(FlSpot(i.toDouble(), close));
        if (close < minY) minY = close;
        if (close > maxY) maxY = close;
      }
    }

    FlSpot? predSpot;
    Color predColor = DS.neutral;

    if (forecast != null && forecast!['target_price'] != null && spots.isNotEmpty) {
      final targetPrice = (forecast!['target_price'] as num).toDouble();
      final lastX = spots.last.x;
      predSpot = FlSpot(lastX + 1, targetPrice);
      if (targetPrice < minY) minY = targetPrice;
      if (targetPrice > maxY) maxY = targetPrice;

      final label = forecast!['forecast_label'] as String? ?? '';
      final isBullish = label.toLowerCase().contains("up") || label.toLowerCase().contains("bull");
      predColor = isBullish ? DS.emerald : DS.crimson;
    }

    final yPadding = (maxY - minY) * 0.1;
    if (yPadding == 0) { minY -= 1; maxY += 1; }
    else { minY -= yPadding; maxY += yPadding; }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(children: [
            Text(t('technical').toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                color: DS.textMuted, letterSpacing: 1.5)),
            const Spacer(),
            if (forecast != null)
              Row(children: [
                Container(width: 8, height: 2, color: predColor),
                const SizedBox(width: 4),
                Text('AI TARGET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: predColor)),
              ]),
          ]),
        ),

        // Time range toggles
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: ['1D', '1W', '1M', '1Y'].map((r) {
              final isActive = r == selectedRange;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onRangeChanged(r),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? DS.indigo.withValues(alpha: 0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(r, style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                        color: isActive ? DS.indigo : DS.textMuted,
                      )),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        _PremiumCard(
          child: Container(
            height: 280,
            padding: const EdgeInsets.only(right: 24, left: 16, top: 32, bottom: 16),
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: predSpot != null ? spots.last.x + 1 : spots.last.x,
                minY: minY, maxY: maxY,
                gridData: FlGridData(
                  show: true, drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: DS.textMuted.withValues(alpha: 0.15), strokeWidth: 1, dashArray: [5, 5]),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, reservedSize: 42,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text('\$${value.toStringAsFixed(0)}',
                          style: const TextStyle(color: DS.textMuted, fontWeight: FontWeight.w600, fontSize: 11)),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots, isCurved: true, curveSmoothness: 0.2,
                    color: DS.deepBlue, barWidth: 3, isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [DS.deepBlue.withValues(alpha: 0.15), DS.deepBlue.withValues(alpha: 0.0)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  if (predSpot != null && spots.isNotEmpty)
                    LineChartBarData(
                      spots: [spots.last, predSpot],
                      isCurved: false, color: predColor, barWidth: 3,
                      isStrokeCapRound: true, dashArray: [5, 5],
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          if (index == 1) {
                            return FlDotCirclePainter(
                              radius: 5, color: Colors.white,
                              strokeWidth: 3, strokeColor: predColor);
                          }
                          return FlDotCirclePainter(radius: 0, color: Colors.transparent);
                        },
                      ),
                    ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) =>
                      LineTooltipItem('\$${spot.y.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))).toList(),
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  RECENT NEWS SECTION
// ─────────────────────────────────────────────────────────────────
class _RecentNewsSection extends StatelessWidget {
  final List<Map<String, dynamic>> news;
  final String lang;

  const _RecentNewsSection({super.key, required this.news, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(_l10n[lang]!['recentNews']!.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
              color: DS.textMuted, letterSpacing: 1.5)),
        ),
        if (news.isEmpty)
          _PremiumCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(_l10n[lang]!['noNews']!, style: const TextStyle(color: DS.textMuted))),
            ),
          )
        else
          ...news.map((item) {
            final title = item['title'] as String? ?? '';
            final publisher = item['publisher'] as String? ?? '';
            final link = item['link'] as String? ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PremiumCard(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: link.isNotEmpty ? () => launchUrl(Uri.parse(link)) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: DS.surfaceAlt, borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: const Icon(Icons.article_rounded, color: DS.deepBlue, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(title,
                              style: const TextStyle(color: DS.textPrimary, fontSize: 14,
                                fontWeight: FontWeight.w600, height: 1.4)),
                            if (publisher.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(publisher.toUpperCase(),
                                  style: const TextStyle(color: DS.textMuted, fontSize: 10,
                                    fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                              ),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
