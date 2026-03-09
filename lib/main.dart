import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';

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
//  MARKET MARQUEE COMPONENT
// ─────────────────────────────────────────────────────────────────
class _MarketMarquee extends StatefulWidget {
  final List<dynamic> items;
  const _MarketMarquee({required this.items});

  @override
  State<_MarketMarquee> createState() => _MarketMarqueeState();
}

class _MarketMarqueeState extends State<_MarketMarquee> with SingleTickerProviderStateMixin {
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
        border: Border(bottom: BorderSide(color: _DS.textMuted.withValues(alpha: 0.1), width: 1)),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(), // Auto-scroll only
        itemBuilder: (context, index) {
          // Infinite loop effect
          final item = widget.items[index % widget.items.length];
          final symbol = item['symbol'] as String;
          final price = (item['price'] as num).toDouble();
          final change = (item['change_pct'] as num).toDouble();
          
          final isPositive = change >= 0;
          final color = isPositive ? _DS.emerald : _DS.crimson;
          final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(symbol, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _DS.textSecondary)),
                const SizedBox(width: 8),
                Text(price.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _DS.deepBlue)),
                const SizedBox(width: 4),
                Icon(icon, size: 12, color: color),
                Text('${change.abs().toStringAsFixed(2)}%', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: color)),
              ],
            ),
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
      final uri = Uri.parse('$_baseUrl/api/market_summary');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
         final body = jsonDecode(response.body);
         if (mounted) {
           setState(() {
             _marketSummary = body['data'] as List<dynamic>;
           });
         }
      }
    } catch (_) {
      // Fail silently for the marquee so it doesn't break the main UI
    }
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
        _loading = true;
        _error = null;
        _data = null;
        _dataList = null;
        _forecast = null;
        _recentNews = null;
        _lastFetchTime = null;
      });
    }

    try {
      final uri = Uri.parse('$_baseUrl/api/analyze/$ticker?range=$_selectedRange');
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
            _recentNews = (body['recent_news'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList();
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
                            child: _ProChartSection(
                               key: ValueKey('chart_${_selectedRange}_${_lastFetchTime?.millisecondsSinceEpoch}'),
                               dataList: _dataList!,
                               forecast: _forecast,
                               lang: widget.lang,
                               selectedRange: _selectedRange,
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
//  PRO CHART SECTION (fl_chart)
// ─────────────────────────────────────────────────────────────────
class _ProChartSection extends StatelessWidget {
  final List<dynamic> dataList;
  final Map<String, dynamic>? forecast;
  final String lang;
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;

  const _ProChartSection({
    super.key,
    required this.dataList,
    this.forecast,
    required this.lang,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  String t(String key) => _l10n[lang]![key] ?? key;

  @override
  Widget build(BuildContext context) {
    if (dataList.isEmpty) return const SizedBox.shrink();

    // 1. Prepare Historical Points
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

    // 2. Prepare Prediction Point
    FlSpot? predSpot;
    Color predColor = _DS.neutral;
    
    if (forecast != null && forecast!['target_price'] != null && spots.isNotEmpty) {
       final targetPrice = (forecast!['target_price'] as num).toDouble();
       final lastX = spots.last.x;
       predSpot = FlSpot(lastX + 1, targetPrice);
       
       if (targetPrice < minY) minY = targetPrice;
       if (targetPrice > maxY) maxY = targetPrice;
       
       final label = forecast!['forecast_label'] as String? ?? '';
       final isBullish = label.toLowerCase().contains("up") || label.toLowerCase().contains("bull");
       predColor = isBullish ? _DS.emerald : _DS.crimson;
    }

    // Add padding to Y axis so the chart doesn't touch the edges completely
    final yPadding = (maxY - minY) * 0.1;
    if (yPadding == 0) {
      minY -= 1;
      maxY += 1;
    } else {
      minY -= yPadding;
      maxY += yPadding;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Text(t('technical').toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _DS.textMuted,
                      letterSpacing: 1.5)),
              const Spacer(),
              if (forecast != null)
                 Row(
                   children: [
                     Container(width: 8, height: 2, color: predColor),
                     const SizedBox(width: 4),
                     Text('AI TARGET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: predColor)),
                   ],
                 ),
            ],
          ),
        ),
        
        // Time Range Toggles
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
                        color: isActive ? _DS.deepBlue.withValues(alpha: 0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        r,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                          color: isActive ? _DS.deepBlue : _DS.textMuted,
                        ),
                      ),
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
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: _DS.textMuted.withValues(alpha: 0.15),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            '\$${value.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: _DS.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Historical Line
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.2,
                    color: _DS.deepBlue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _DS.deepBlue.withValues(alpha: 0.15),
                          _DS.deepBlue.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Prediction Line (Connecting last historical point to target)
                  if (predSpot != null && spots.isNotEmpty)
                    LineChartBarData(
                       spots: [spots.last, predSpot],
                       isCurved: false,
                       color: predColor,
                       barWidth: 3,
                       isStrokeCapRound: true,
                       dashArray: [5, 5],
                       dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                             if (index == 1) { // Only show dot on the final target prediction
                               return FlDotCirclePainter(
                                 radius: 5,
                                 color: Colors.white,
                                 strokeWidth: 3,
                                 strokeColor: predColor,
                               );
                             }
                             return FlDotCirclePainter(radius: 0, color: Colors.transparent);
                          },
                       ),
                    ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                           '\$${spot.y.toStringAsFixed(2)}',
                           const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
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
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   title,
                                   style: const TextStyle(
                                     color: _DS.textPrimary,
                                     fontSize: 14,
                                     fontWeight: FontWeight.w600,
                                     height: 1.4,
                                   ),
                                 ),
                                 if (publisher.isNotEmpty)
                                   Padding(
                                     padding: const EdgeInsets.only(top: 6),
                                     child: Text(
                                       publisher.toUpperCase(),
                                       style: TextStyle(
                                         color: _DS.textMuted,
                                         fontSize: 10,
                                         fontWeight: FontWeight.w800,
                                         letterSpacing: 1.0,
                                       ),
                                     ),
                                   ),
                               ],
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),
                 ),
               ),
             );
           }).toList(),
      ],
    );
  }
}
