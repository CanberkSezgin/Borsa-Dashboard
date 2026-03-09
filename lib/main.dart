import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────
//  DESIGN TOKENS — Premium Light Theme
// ─────────────────────────────────────────────────────────────────
class _DS {
  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F7FA);
  static const surfaceAlt = Color(0xFFF1F5F9);
  
  static const deepBlue = Color(0xFF0F172A);
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF94A3B8);

  static const emerald = Color(0xFF10B981);
  static const emeraldSoft = Color(0xFFD1FAE5);
  static const crimson = Color(0xFFEF4444);
  static const crimsonSoft = Color(0xFFFEE2E2);
  static const neutral = Color(0xFF64748B);
  static const neutralSoft = Color(0xFFF1F5F9);

  static const bullishGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
  );
  static const bearishGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFEF2F2), Color(0xFFFFF1F2)],
  );
  static const neutralGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
  );
  static const cardGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
  );

  static List<BoxShadow> get neumorphicShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
}

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
  },
};

// ─────────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────────
String get _baseUrl {
  if (kIsWeb) return 'http://127.0.0.1:8000';
  try {
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
  } catch (_) {}
  return 'http://127.0.0.1:8000';
}

String _pad(int n) => n.toString().padLeft(2, '0');

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

  void _toggleLang() =>
      setState(() => _lang = _lang == 'en' ? 'tr' : 'en');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _l10n[_lang]!['appTitle']!,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _DS.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _DS.deepBlue,
          brightness: Brightness.light,
          surface: _DS.surface,
          onSurface: _DS.textPrimary,
        ),
        fontFamily: 'Roboto',
      ),
      home: HomeScreen(lang: _lang, onToggleLang: _toggleLang),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final String lang;
  final VoidCallback onToggleLang;

  const HomeScreen({super.key, required this.lang, required this.onToggleLang});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _tickerCtrl = TextEditingController(text: 'AAPL');
  
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _forecast; 
  List<String>? _recentNews; 

  Timer? _refreshTimer; 
  DateTime? _lastFetchTime; 

  String t(String key) => _l10n[widget.lang]![key] ?? key;

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
        _loading = true;
        _error = null;
        _data = null;
        _forecast = null;
        _recentNews = null;
        _lastFetchTime = null;
      });
    }

    try {
      final uri = Uri.parse('$_baseUrl/api/analyze/$ticker');
      final response = await http.get(uri).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final dataList = body['data'] as List<dynamic>?;

        if (dataList == null || dataList.isEmpty) {
          setState(() => _error = t('noData'));
        } else {
          setState(() {
            _data = dataList.last as Map<String, dynamic>;
            _forecast = body['forecast'] as Map<String, dynamic>?;
            _recentNews = (body['recent_news'] as List<dynamic>?)?.map((e) => e.toString()).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DS.bg,
      body: SafeArea(
        child: Column(
          children: [
            _PremiumAppBar(
              lang: widget.lang,
              onToggleLang: widget.onToggleLang,
              lastFetchTime: _lastFetchTime,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SearchBar(
                          controller: _tickerCtrl,
                          hint: t('searchHint'),
                          buttonLabel: t('analyzeBtn'),
                          onSearch: _analyze,
                          loading: _loading,
                        ),
                        const SizedBox(height: 32),

                        if (_loading)
                          Center(
                            child: Column(
                              children: [
                                const CircularProgressIndicator(color: _DS.deepBlue),
                                const SizedBox(height: 16),
                                Text(t('loading'), style: const TextStyle(color: _DS.textSecondary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),

                        if (_error != null)
                          _ErrorCard(message: _error!, onRetry: _analyze, lang: widget.lang),

                        if (_data != null) ...[
                          if (_forecast != null) ...[
                             AnimatedSwitcher(
                               duration: const Duration(milliseconds: 500),
                               child: _ForecastCard(
                                 key: ValueKey('forecast_${_lastFetchTime?.millisecondsSinceEpoch}'),
                                 forecast: _forecast!,
                                 lang: widget.lang,
                               ),
                             ),
                             const SizedBox(height: 16),
                          ],
                          
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: _SentimentCard(
                              key: ValueKey('sentiment_${_lastFetchTime?.millisecondsSinceEpoch}'),
                              data: _data!,
                              lang: widget.lang,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 600),
                            child: _TechnicalSection(
                               key: ValueKey('tech_${_lastFetchTime?.millisecondsSinceEpoch}'),
                               data: _data!,
                               lang: widget.lang,
                            ),
                          ),

                          if (_recentNews != null) ...[
                             const SizedBox(height: 32),
                             AnimatedSwitcher(
                                duration: const Duration(milliseconds: 700),
                                child: _RecentNewsSection(
                                  key: ValueKey('news_${_lastFetchTime?.millisecondsSinceEpoch}'),
                                  news: _recentNews!,
                                  lang: widget.lang,
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
        gradient: customGradient ?? _DS.cardGrad,
        boxShadow: _DS.neumorphicShadow,
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
//  PREMIUM APP BAR
// ─────────────────────────────────────────────────────────────────
class _PremiumAppBar extends StatelessWidget {
  final String lang;
  final VoidCallback onToggleLang;
  final DateTime? lastFetchTime;

  const _PremiumAppBar({required this.lang, required this.onToggleLang, this.lastFetchTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _DS.deepBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            _l10n[lang]!['appTitle']!.toUpperCase(),
            style: const TextStyle(
              color: _DS.deepBlue,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          if (lastFetchTime != null)
            Padding(
               padding: const EdgeInsets.only(right: 14),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                    const Icon(Icons.sync, color: _DS.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${_pad(lastFetchTime!.hour)}:${_pad(lastFetchTime!.minute)}:${_pad(lastFetchTime!.second)}',
                      style: const TextStyle(
                        color: _DS.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                 ],
               ),
            ),
          GestureDetector(
            onTap: onToggleLang,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: _DS.neumorphicShadow,
              ),
              child: Text(
                lang == 'en' ? 'TR' : 'EN',
                style: const TextStyle(
                  color: _DS.deepBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
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
    required this.controller,
    required this.hint,
    required this.buttonLabel,
    required this.onSearch,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              boxShadow: _DS.neumorphicShadow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
              style: const TextStyle(fontWeight: FontWeight.w600, color: _DS.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: _DS.textMuted, fontWeight: FontWeight.normal),
                prefixIcon: const Icon(Icons.search, color: _DS.textMuted),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: loading ? null : onSearch,
          style: ElevatedButton.styleFrom(
            backgroundColor: _DS.deepBlue,
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: _DS.deepBlue.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ],
    );
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
      customGradient: _DS.bearishGrad,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(
               color: _DS.crimsonSoft,
               shape: BoxShape.circle,
             ),
             child: const Icon(Icons.error_outline, color: _DS.crimson, size: 28),
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _DS.crimson, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(_l10n[lang]!['retry']!),
            style: OutlinedButton.styleFrom(
              foregroundColor: _DS.crimson,
              side: const BorderSide(color: _DS.crimson),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  FORECAST CARD (MINIMALIST)
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

    final Gradient gradient = isBullish ? _DS.bullishGrad : _DS.bearishGrad;
    final Color accentColor = isBullish ? _DS.emerald : _DS.crimson;
    final IconData trendIcon = isBullish ? Icons.trending_up : Icons.trending_down;

    final confidencePct = score * 100;

    return _PremiumCard(
      customGradient: gradient,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(trendIcon, color: accentColor, size: 36),
                const SizedBox(width: 8),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_l10n[lang]!['confidence']}: ',
                  style: const TextStyle(
                    fontSize: 13,
                    color: _DS.textSecondary, 
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: confidencePct),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (_, val, __) => Text(
                    '${val.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
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

    final Gradient gradient = isPositive ? _DS.bullishGrad : (isNegative ? _DS.bearishGrad : _DS.neutralGrad);
    final Color accentColor = isPositive ? _DS.emerald : (isNegative ? _DS.crimson : _DS.neutral);

    final String trendLabel = isPositive ? t('uptrend') : (isNegative ? t('downtrend') : t('neutral'));
    final IconData trendIcon = isPositive ? Icons.trending_up : (isNegative ? Icons.trending_down : Icons.trending_flat);

    return _PremiumCard(
      customGradient: gradient,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(t('sentimentTitle').toUpperCase(),
                  style: const TextStyle(
                      color: _DS.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Icon(trendIcon, color: accentColor, size: 28),
              const SizedBox(width: 8),
              Text(trendLabel,
                  style: TextStyle(
                      color: accentColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 24),
            Row(
               crossAxisAlignment: CrossAxisAlignment.end,
               children: [
                  Expanded(
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(t('score'), style: const TextStyle(color: _DS.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                         const SizedBox(height: 4),
                         TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: score),
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeOutCubic,
                            builder: (_, val, __) => Text(
                              val.toStringAsFixed(3),
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                       ],
                    ),
                  ),
               ],
            ),
            const SizedBox(height: 20),
            TweenAnimationBuilder<double>(
               tween: Tween<double>(begin: 0, end: ((score + 1) / 2).clamp(0.0, 1.0)),
               duration: const Duration(milliseconds: 1400),
               curve: Curves.easeOutCubic,
               builder: (_, val, __) => ClipRRect(
                 borderRadius: BorderRadius.circular(6),
                 child: LinearProgressIndicator(
                   value: val,
                   minHeight: 8,
                   backgroundColor: accentColor.withValues(alpha: 0.15),
                   valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                 ),
               ),
            ),
            const SizedBox(height: 24),
            Row(children: [
              _ScorePill(label: t('positive'), value: positive, color: _DS.emerald),
              const SizedBox(width: 12),
              _ScorePill(label: t('negative'), value: negative, color: _DS.crimson),
            ]),
          ],
        ),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 6),
        TweenAnimationBuilder<double>(
           tween: Tween<double>(begin: 0, end: value * 100),
           duration: const Duration(milliseconds: 1200),
           curve: Curves.easeOutCubic,
           builder: (_, val, __) => Text(
             '$label  ${val.toStringAsFixed(1)}%',
             style: TextStyle(color: _DS.deepBlue, fontSize: 13, fontWeight: FontWeight.w700),
           ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  TECHNICAL SECTION
// ─────────────────────────────────────────────────────────────────
class _TechnicalSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final String lang;

  const _TechnicalSection({super.key, required this.data, required this.lang});

  String t(String key) => _l10n[lang]![key] ?? key;

  @override
  Widget build(BuildContext context) {
    final close = (data['Close'] as num?)?.toDouble();
    final rsi = (data['RSI_14'] as num?)?.toDouble() ?? 50.0;
    final macd = (data['MACD'] as num?)?.toDouble();

    final rsiColor = rsi > 70 ? _DS.crimson : (rsi < 30 ? _DS.emerald : _DS.deepBlue);
    final rsiSignal = rsi > 70 ? t('overbought') : (rsi < 30 ? t('oversold') : null);

    final macdBullish = macd != null && macd >= 0;
    final macdColor = macdBullish ? _DS.emerald : _DS.crimson;
    final macdSignal = macd != null ? (macdBullish ? '▲ Bullish' : '▼ Bearish') : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(t('technical').toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _DS.textMuted,
                  letterSpacing: 1.5)),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.15,
          children: [
            _TechCard(
              label: t('priceCard'),
              value: close,
              prefix: '\$',
              decimals: 2,
              icon: Icons.attach_money,
              color: _DS.deepBlue,
            ),
            _TechCard(
              label: t('rsiCard'),
              value: rsi,
              decimals: 1,
              sublabel: rsiSignal,
              icon: Icons.speed,
              color: rsiColor,
              progressValue: rsi / 100,
            ),
            _TechCard(
              label: t('macdCard'),
              value: macd,
              decimals: 4,
              sublabel: macdSignal,
              icon: Icons.show_chart,
              color: macdColor,
            ),
          ],
        ),
      ],
    );
  }
}

class _TechCard extends StatelessWidget {
  final String label;
  final double? value;
  final String prefix;
  final int decimals;
  final String? sublabel;
  final IconData icon;
  final Color color;
  final double? progressValue;

  const _TechCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.prefix = '',
    this.decimals = 2,
    this.sublabel,
    this.progressValue,
  });

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        color: _DS.textSecondary,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 12),
            if (value != null)
              TweenAnimationBuilder<double>(
                 tween: Tween<double>(begin: 0, end: value!),
                 duration: const Duration(milliseconds: 1200),
                 curve: Curves.easeOutCubic,
                 builder: (_, val, __) => Text(
                   '$prefix${val.toStringAsFixed(decimals)}',
                   style: TextStyle(
                       fontSize: 24,
                       fontWeight: FontWeight.w800,
                       color: color),
                 ),
              )
            else
              Text('--', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            
            if (sublabel != null || progressValue != null) ...[
               const SizedBox(height: 10),
               Row(children: [
                  if (sublabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(sublabel!,
                          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
                    ),
                  if (progressValue != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: TweenAnimationBuilder<double>(
                           tween: Tween<double>(begin: 0, end: progressValue!),
                           duration: const Duration(milliseconds: 1400),
                           curve: Curves.easeOutCubic,
                           builder: (_, val, __) => ClipRRect(
                             borderRadius: BorderRadius.circular(4),
                             child: LinearProgressIndicator(
                               value: val,
                               minHeight: 4,
                               backgroundColor: color.withValues(alpha: 0.15),
                               valueColor: AlwaysStoppedAnimation<Color>(color),
                             ),
                           ),
                        ),
                      ),
                    ),
               ]),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  RECENT NEWS SECTION
// ─────────────────────────────────────────────────────────────────
class _RecentNewsSection extends StatelessWidget {
  final List<String> news;
  final String lang;

  const _RecentNewsSection({super.key, required this.news, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            _l10n[lang]!['recentNews']!.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _DS.textMuted,
              letterSpacing: 1.5,
            ),
          ),
        ),
        if (news.isEmpty)
           _PremiumCard(
             child: Padding(
               padding: const EdgeInsets.all(24),
               child: Center(
                 child: Text(_l10n[lang]!['noNews']!, style: const TextStyle(color: _DS.textMuted)),
               ),
             ),
           )
        else
           ...news.map((headline) => Padding(
                 padding: const EdgeInsets.only(bottom: 12),
                 child: _PremiumCard(
                   child: Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                     child: Row(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Container(
                           padding: const EdgeInsets.all(10),
                           decoration: BoxDecoration(
                             color: _DS.surfaceAlt,
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(color: Colors.white, width: 1.5),
                             boxShadow: [
                               BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                             ],
                           ),
                           child: const Icon(Icons.article_rounded, color: _DS.deepBlue, size: 20),
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                           child: Text(
                             headline,
                             style: const TextStyle(
                               color: _DS.textPrimary,
                               fontSize: 14,
                               fontWeight: FontWeight.w600,
                               height: 1.4,
                             ),
                           ),
                         ),
                       ],
                     ),
                   ),
                 ),
               )).toList(),
      ],
    );
  }
}
