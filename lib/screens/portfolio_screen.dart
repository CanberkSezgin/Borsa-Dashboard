import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../design_tokens.dart';

// ─────────────────────────────────────────────────────────────────
//  PAPER TRADING — PORTFOLIO SCREEN (v2 — Live P&L)
// ─────────────────────────────────────────────────────────────────
class PortfolioScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;
  final String lang;

  const PortfolioScreen({
    super.key,
    required this.token,
    required this.user,
    required this.lang,
  });

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  static const double _startingCash = 10000.0;

  List<Map<String, dynamic>> _holdings = [];
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  double _cashBalance = _startingCash;
  double _totalInvested = 0;
  double _totalCurrentValue = 0;

  String t(String key) {
    const tr = {
      'portfolio': 'Portföyüm',
      'paperTrading': 'Sanal İşlem',
      'balance': 'Toplam Değer',
      'cash': 'Nakit',
      'invested': 'Yatırılan',
      'currentVal': 'Güncel Değer',
      'holdings': 'Varlıklarım',
      'history': 'İşlem Geçmişi',
      'noHoldings': 'Henüz varlığınız yok.\nBir hisse analiz edip AL butonuna basın.',
      'noHistory': 'Henüz işlem yapılmadı.',
      'shares': 'adet',
      'avgCost': 'Ort. Maliyet',
      'livePrice': 'Canlı Fiyat',
      'profit': 'Kâr/Zarar',
      'sellNow': 'Şimdi Sat',
    };
    const en = {
      'portfolio': 'My Portfolio',
      'paperTrading': 'Paper Trading',
      'balance': 'Total Value',
      'cash': 'Cash',
      'invested': 'Invested',
      'currentVal': 'Current Value',
      'holdings': 'Holdings',
      'history': 'Trade History',
      'noHoldings': 'No holdings yet.\nAnalyze a stock and press BUY.',
      'noHistory': 'No trades yet.',
      'shares': 'shares',
      'avgCost': 'Avg Cost',
      'livePrice': 'Live Price',
      'profit': 'P&L',
      'sellNow': 'Sell Now',
    };
    return (widget.lang == 'tr' ? tr[key] : en[key]) ?? key;
  }

  @override
  void initState() {
    super.initState();
    _fetchPortfolio();
  }

  Future<void> _fetchPortfolio() async {
    setState(() => _loading = true);
    final userId = widget.user['id'];
    try {
      final holdingsRes = await http.get(
        Uri.parse('${DS.baseUrl}/api/portfolio/$userId'),
      ).timeout(const Duration(seconds: 15));

      final historyRes = await http.get(
        Uri.parse('${DS.baseUrl}/api/portfolio/$userId/history'),
      ).timeout(const Duration(seconds: 10));

      if (holdingsRes.statusCode == 200) {
        final body = jsonDecode(holdingsRes.body);
        _holdings = ((body['holdings'] as List<dynamic>?) ?? [])
            .map((e) => e as Map<String, dynamic>).toList();
      }

      if (historyRes.statusCode == 200) {
        final body = jsonDecode(historyRes.body);
        _history = ((body['history'] as List<dynamic>?) ?? [])
            .map((e) => e as Map<String, dynamic>).toList();
      }

      // Calculate cash balance
      double spent = 0;
      for (var trade in _history) {
        final action = trade['action'] as String? ?? '';
        final price = (trade['price'] as num?)?.toDouble() ?? 0;
        final shares = (trade['shares'] as num?)?.toDouble() ?? 0;
        if (action == 'BUY') spent += price * shares;
        else if (action == 'SELL') spent -= price * shares;
      }
      _cashBalance = _startingCash - spent;

      // Totals from holdings
      _totalInvested = 0;
      _totalCurrentValue = 0;
      for (var h in _holdings) {
        _totalInvested += (h['net_cost'] as num?)?.toDouble() ?? 0;
        _totalCurrentValue += (h['current_value'] as num?)?.toDouble() ?? 0;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _sellHolding(String ticker, double shares, double price) async {
    try {
      final uri = Uri.parse('${DS.baseUrl}/api/portfolio/trade');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': widget.token,
          'ticker': ticker,
          'action': 'SELL',
          'price': price,
          'shares': shares,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        final body = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message'] ?? 'Sold'),
            backgroundColor: DS.crimson,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _fetchPortfolio(); // Refresh
      } else if (response.statusCode == 400 && mounted) {
        final body = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['detail'] ?? 'Error'),
            backgroundColor: DS.amber,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {}
  }

  void _showSellDialog(String ticker, double maxShares, double currentPrice) {
    int sellQuantity = 1;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: DS.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: DS.surfaceBorder.withValues(alpha: 0.5))),
              title: Text('${widget.lang == 'tr' ? 'Satış' : 'Sell'} $ticker', style: const TextStyle(color: DS.textPrimary, fontWeight: FontWeight.w800)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.lang == 'tr'
                        ? 'Kaç adet satmak istiyorsunuz? (Maks: ${maxShares.toStringAsFixed(0)})'
                        : 'How many shares to sell? (Max: ${maxShares.toStringAsFixed(0)})',
                    style: const TextStyle(color: DS.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: DS.crimson),
                        onPressed: sellQuantity > 1 ? () => setDialogState(() => sellQuantity--) : null,
                      ),
                      const SizedBox(width: 16),
                      Text('$sellQuantity', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: DS.textPrimary)),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: DS.emerald),
                        onPressed: sellQuantity < maxShares ? () => setDialogState(() => sellQuantity++) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${widget.lang == 'tr' ? 'Toplam Getiri' : 'Total Return'}: \$${(sellQuantity * currentPrice).toStringAsFixed(2)}',
                    style: const TextStyle(color: DS.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(widget.lang == 'tr' ? 'İptal' : 'Cancel', style: const TextStyle(color: DS.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _sellHolding(ticker, sellQuantity.toDouble(), currentPrice);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DS.crimson,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(widget.lang == 'tr' ? 'SAT' : 'SELL', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  double get _portfolioValue => _cashBalance + _totalCurrentValue;

  @override
  Widget build(BuildContext context) {
    final pnl = _totalCurrentValue - _totalInvested;
    final pnlPct = _totalInvested > 0 ? (pnl / _totalInvested * 100) : 0.0;
    final isProfit = pnl >= 0;

    return Scaffold(
      backgroundColor: DS.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom AppBar ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: DS.surface,
                border: Border(bottom: BorderSide(color: DS.surfaceBorder.withValues(alpha: 0.3), width: 1)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DS.surfaceAlt.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: DS.textPrimary, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t('portfolio'),
                        style: const TextStyle(color: DS.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                      Text(t('paperTrading'),
                        style: const TextStyle(color: DS.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _fetchPortfolio,
                    icon: const Icon(Icons.refresh_rounded, color: DS.textSecondary),
                  ),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: _loading
                ? const Center(child: CircularProgressIndicator(color: DS.indigo))
                : RefreshIndicator(
                    onRefresh: _fetchPortfolio,
                    color: DS.indigo,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── Balance Card ──
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: DS.surfaceBorder.withValues(alpha: 0.3)),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                                ),
                                child: Column(
                                  children: [
                                    Text(t('balance').toUpperCase(),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DS.textMuted, letterSpacing: 1.5)),
                                    const SizedBox(height: 8),
                                    Text('\$${_portfolioValue.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: DS.textPrimary, letterSpacing: -1)),
                                    const SizedBox(height: 4),
                                    if (_totalInvested > 0)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                            color: isProfit ? DS.emerald : DS.crimson, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${isProfit ? "+" : ""}${pnl.toStringAsFixed(2)} (${pnlPct.toStringAsFixed(1)}%)',
                                            style: TextStyle(color: isProfit ? DS.emerald : DS.crimson, fontSize: 14, fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 16),
                                    // Summary row
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: DS.surfaceAlt.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _BalanceStat(label: t('cash'), value: '\$${_cashBalance.toStringAsFixed(0)}', color: DS.textPrimary),
                                          Container(width: 1, height: 28, color: DS.surfaceBorder.withValues(alpha: 0.3)),
                                          _BalanceStat(label: t('invested'), value: '\$${_totalInvested.toStringAsFixed(0)}', color: DS.indigo),
                                          Container(width: 1, height: 28, color: DS.surfaceBorder.withValues(alpha: 0.3)),
                                          _BalanceStat(label: t('currentVal'), value: '\$${_totalCurrentValue.toStringAsFixed(0)}', color: isProfit ? DS.emerald : DS.crimson),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Holdings ──
                              Text(t('holdings').toUpperCase(),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DS.textMuted, letterSpacing: 1.5)),
                              const SizedBox(height: 12),

                              if (_holdings.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: DS.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: DS.surfaceBorder.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.account_balance_wallet_outlined, color: DS.textMuted.withValues(alpha: 0.5), size: 48),
                                      const SizedBox(height: 12),
                                      Text(t('noHoldings'),
                                        style: const TextStyle(color: DS.textSecondary, fontSize: 13), textAlign: TextAlign.center),
                                    ],
                                  ),
                                )
                              else
                                ..._holdings.map((h) => _HoldingCard(
                                  holding: h,
                                  lang: widget.lang,
                                  onSell: () {
                                    final netShares = (h['net_shares'] as num?)?.toDouble() ?? 0;
                                    final livePrice = (h['live_price'] as num?)?.toDouble() ?? 0;
                                    final ticker = h['ticker'] as String? ?? '';
                                    if (livePrice > 0 && netShares > 0) {
                                      _showSellDialog(ticker, netShares, livePrice);
                                    }
                                  },
                                  t: t,
                                )),

                              const SizedBox(height: 24),

                              // ── Trade History ──
                              Text(t('history').toUpperCase(),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DS.textMuted, letterSpacing: 1.5)),
                              const SizedBox(height: 12),

                              if (_history.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: DS.surface, borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: DS.surfaceBorder.withValues(alpha: 0.3)),
                                  ),
                                  child: Center(child: Text(t('noHistory'),
                                    style: const TextStyle(color: DS.textSecondary, fontSize: 13))),
                                )
                              else
                                ..._history.map((trade) => _TradeRow(trade: trade)),

                              const SizedBox(height: 40),
                            ],
                          ),
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

// ─── Balance Stat Widget ───
class _BalanceStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _BalanceStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: DS.textMuted, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ],
    );
  }
}

// ─── Holding Card Widget (per-ticker) ───
class _HoldingCard extends StatelessWidget {
  final Map<String, dynamic> holding;
  final String lang;
  final VoidCallback onSell;
  final String Function(String) t;

  const _HoldingCard({required this.holding, required this.lang, required this.onSell, required this.t});

  @override
  Widget build(BuildContext context) {
    final ticker = holding['ticker'] as String? ?? '?';
    final netShares = (holding['net_shares'] as num?)?.toDouble() ?? 0;
    final avgCost = (holding['avg_cost'] as num?)?.toDouble() ?? 0;
    final livePrice = (holding['live_price'] as num?)?.toDouble() ?? 0;
    final pnl = (holding['pnl'] as num?)?.toDouble() ?? 0;
    final pnlPct = (holding['pnl_pct'] as num?)?.toDouble() ?? 0;
    final currentValue = (holding['current_value'] as num?)?.toDouble() ?? 0;
    final isProfit = pnl >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DS.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isProfit
            ? DS.emerald.withValues(alpha: 0.2)
            : DS.crimson.withValues(alpha: 0.2),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          // Top row: ticker + value
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [DS.indigoSoft, DS.surface],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(ticker.length >= 2 ? ticker.substring(0, 2) : ticker,
                  style: const TextStyle(color: DS.indigo, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticker, style: const TextStyle(color: DS.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('${netShares.toStringAsFixed(2)} ${t('shares')}',
                      style: const TextStyle(color: DS.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${currentValue.toStringAsFixed(2)}',
                    style: const TextStyle(color: DS.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isProfit ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                      color: isProfit ? DS.emerald : DS.crimson, size: 18),
                    Text(
                      '${isProfit ? "+" : ""}${pnl.toStringAsFixed(2)} (${pnlPct.toStringAsFixed(1)}%)',
                      style: TextStyle(color: isProfit ? DS.emerald : DS.crimson, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ]),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Detail row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: DS.bg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniStat(label: t('avgCost'), value: '\$${avgCost.toStringAsFixed(2)}'),
                _MiniStat(label: t('livePrice'), value: '\$${livePrice.toStringAsFixed(2)}'),
                _MiniStat(label: t('profit'), value: '${isProfit ? "+" : ""}\$${pnl.toStringAsFixed(2)}',
                  color: isProfit ? DS.emerald : DS.crimson),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Sell button
          SizedBox(
            width: double.infinity, height: 36,
            child: ElevatedButton.icon(
              onPressed: onSell,
              icon: const Icon(Icons.sell_rounded, size: 14),
              label: Text('${t('sellNow')} (${netShares.toStringAsFixed(0)} ${t('shares')})',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: DS.crimson.withValues(alpha: 0.15),
                foregroundColor: DS.crimson,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _MiniStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color ?? DS.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: DS.textMuted, fontSize: 9, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Trade History Row ───
class _TradeRow extends StatelessWidget {
  final Map<String, dynamic> trade;
  const _TradeRow({required this.trade});

  @override
  Widget build(BuildContext context) {
    final action = trade['action'] as String? ?? '';
    final ticker = trade['ticker'] as String? ?? '';
    final price = (trade['price'] as num?)?.toDouble() ?? 0;
    final shares = (trade['shares'] as num?)?.toDouble() ?? 0;
    final timestamp = trade['timestamp'] as String? ?? '';
    final isBuy = action == 'BUY';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DS.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DS.surfaceBorder.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: isBuy ? DS.emerald.withValues(alpha: 0.15) : DS.crimson.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              isBuy ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isBuy ? DS.emerald : DS.crimson, size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$action $ticker',
                  style: TextStyle(color: isBuy ? DS.emerald : DS.crimson, fontWeight: FontWeight.w800, fontSize: 13)),
                Text('${shares.toStringAsFixed(2)} @ \$${price.toStringAsFixed(2)}',
                  style: const TextStyle(color: DS.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${(price * shares).toStringAsFixed(2)}',
                style: const TextStyle(color: DS.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
              Text(timestamp.length >= 16 ? timestamp.substring(0, 16) : timestamp,
                style: const TextStyle(color: DS.textMuted, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}
