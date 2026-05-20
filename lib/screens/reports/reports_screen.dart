import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/loan_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/loan_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';

String _fmt(double v) => NumberFormat('#,##,##0.00', 'en_IN').format(v);

String _fmtShort(double v) {
  final abs = v.abs();
  if (abs >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
  if (abs >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
  if (abs >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return NumberFormat('#,##0', 'en_IN').format(v);
}

TextStyle _guj({
  double fontSize = 13,
  FontWeight fontWeight = FontWeight.normal,
  Color? color,
  double? height,
}) =>
    TextStyle(
      fontFamily: 'NotoSansGujarati',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _onMonthChanged(int y, int m) => setState(() {
        _year = y;
        _month = m;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'રિપોર્ટ 📊',
          style: _guj(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tab,
          labelStyle: _guj(fontWeight: FontWeight.w700),
          unselectedLabelStyle: _guj(color: Colors.grey),
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '📅 માસિક'),
            Tab(text: '📆 વાર્ષિક'),
            Tab(text: '🗂️ Category'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _MonthlyTab(
            year: _year,
            month: _month,
            onMonthChanged: _onMonthChanged,
          ),
          _YearlyTab(year: _year),
          _CategoryTab(year: _year, month: _month),
        ],
      ),
    );
  }
}

class _MonthlyTab extends StatelessWidget {
  final int year;
  final int month;
  final void Function(int year, int month) onMonthChanged;

  const _MonthlyTab({
    required this.year,
    required this.month,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<TransactionProvider, SettingsProvider, LoanProvider>(
      builder: (ctx, txnP, settP, loanP, _) {
        final cur = settP.currency;
        final txns = txnP.getByMonth(year, month);

        final income = txns
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (s, t) => s + t.amount);

        final expense = txns
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (s, t) => s + t.amount);

        final saved = income - expense;

        final expenseTxns = txns
            .where((t) => t.type == TransactionType.expense)
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

        double toReceive = 0;
        double toPay = 0;
        for (final loan in loanP.loans) {
          final out = loanP.outstandingAmount(loan.id);
          if (out <= 0) continue;
          if (loan.type == LoanType.gave) {
            toReceive += out;
          } else {
            toPay += out;
          }
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _MonthPicker(
              year: year,
              month: month,
              onMonthChanged: onMonthChanged,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    label: 'આવક',
                    amount: '$cur ${_fmt(income)}',
                    color: AppColors.income,
                    icon: '📈',
                    bg: AppColors.incomeLight,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiCard(
                    label: 'ખર્ચ',
                    amount: '$cur ${_fmt(expense)}',
                    color: AppColors.expense,
                    icon: '📉',
                    bg: AppColors.expenseLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _KpiCard(
              label: 'બચત',
              amount: '${saved >= 0 ? '+' : ''}$cur ${_fmt(saved)}',
              color: saved >= 0 ? AppColors.income : AppColors.expense,
              icon: saved >= 0 ? '💰' : '⚠️',
              bg: saved >= 0 ? AppColors.incomeLight : AppColors.expenseLight,
              wide: true,
            ),
            const SizedBox(height: 24),
            if (txns.isNotEmpty) ...[
              const _SectionTitle('Week-wise ખર્ચ'),
              const SizedBox(height: 12),
              _WeekBarChart(txns: txns),
              const SizedBox(height: 24),
            ],
            if (income > 0 || expense > 0) ...[
              const _SectionTitle('આવક vs ખર્ચ'),
              const SizedBox(height: 12),
              _IncomeExpenseDonut(
                income: income,
                expense: expense,
                cur: cur,
              ),
              const SizedBox(height: 24),
            ],
            if (expenseTxns.isNotEmpty) ...[
              const _SectionTitle('Top 5 ખર્ચ'),
              const SizedBox(height: 8),
              _TopTransactions(
                txns: expenseTxns,
                currency: cur,
                limit: 5,
              ),
            ],
            if (toReceive > 0 || toPay > 0) ...[
              const SizedBox(height: 24),
              const _SectionTitle('💰 ઉઘરાણી / ઉધાર'),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (toReceive > 0)
                    Expanded(
                      child: _KpiCard(
                        label: 'ઉઘરાણી (મળવાનું)',
                        amount: '$cur ${_fmt(toReceive)}',
                        color: AppColors.income,
                        icon: '💸',
                        bg: AppColors.incomeLight,
                      ),
                    ),
                  if (toReceive > 0 && toPay > 0) const SizedBox(width: 10),
                  if (toPay > 0)
                    Expanded(
                      child: _KpiCard(
                        label: 'ઉધાર (આપવાનું)',
                        amount: '$cur ${_fmt(toPay)}',
                        color: AppColors.expense,
                        icon: '🤲',
                        bg: AppColors.expenseLight,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _LoanPersonList(loanP: loanP, currency: cur),
            ],
            if (txns.isEmpty && toReceive == 0 && toPay == 0)
              _EmptyState(
                message: 'આ મહિને કોઈ નોંધ નથી.\nઉપર + button વડે ઉમેરો.',
              ),
          ],
        );
      },
    );
  }
}

class _YearlyTab extends StatelessWidget {
  final int year;
  const _YearlyTab({required this.year});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, SettingsProvider>(
      builder: (ctx, txnP, settP, _) {
        final cur = settP.currency;

        final monthData = List.generate(12, (i) {
          final m = i + 1;
          final txns = txnP.getByMonth(year, m);
          final inc = txns
              .where((t) => t.type == TransactionType.income)
              .fold(0.0, (s, t) => s + t.amount);
          final exp = txns
              .where((t) => t.type == TransactionType.expense)
              .fold(0.0, (s, t) => s + t.amount);
          return <String, dynamic>{
            'month': m,
            'income': inc,
            'expense': exp,
          };
        });

        final totalInc =
            monthData.fold(0.0, (s, d) => s + (d['income'] as double));
        final totalExp =
            monthData.fold(0.0, (s, d) => s + (d['expense'] as double));
        final totalSav = totalInc - totalExp;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$year',
                  style: _guj(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _KpiCard(
              label: '$year ની કુલ બચત',
              amount: '${totalSav >= 0 ? '+' : ''}$cur ${_fmt(totalSav)}',
              color: totalSav >= 0 ? AppColors.income : AppColors.expense,
              icon: '🏆',
              bg: totalSav >= 0
                  ? AppColors.incomeLight
                  : AppColors.expenseLight,
              wide: true,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    label: 'કુલ આવક',
                    amount: '$cur ${_fmtShort(totalInc)}',
                    color: AppColors.income,
                    icon: '📈',
                    bg: AppColors.incomeLight,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiCard(
                    label: 'કુલ ખર્ચ',
                    amount: '$cur ${_fmtShort(totalExp)}',
                    color: AppColors.expense,
                    icon: '📉',
                    bg: AppColors.expenseLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle('12 મહિના — Income vs Expense'),
            const SizedBox(height: 4),
            Row(
              children: [
                _ChartLegendDot(color: AppColors.income, label: 'આવક'),
                const SizedBox(width: 16),
                _ChartLegendDot(color: AppColors.expense, label: 'ખર્ચ'),
              ],
            ),
            const SizedBox(height: 12),
            _YearLineChart(monthData: monthData),
            const SizedBox(height: 24),
            const _SectionTitle('Month-wise Summary'),
            const SizedBox(height: 8),
            _MonthTable(monthData: monthData, currency: cur),
          ],
        );
      },
    );
  }
}

class _CategoryTab extends StatefulWidget {
  final int year;
  final int month;
  const _CategoryTab({required this.year, required this.month});

  @override
  State<_CategoryTab> createState() => _CategoryTabState();
}

class _CategoryTabState extends State<_CategoryTab> {
  TransactionType _viewType = TransactionType.expense;
  int _touchedIndex = -1;

  static const _catColors = [
    Color(0xFF01696F),
    Color(0xFFE53935),
    Color(0xFF8E24AA),
    Color(0xFF1E88E5),
    Color(0xFFF4511E),
    Color(0xFF00897B),
    Color(0xFFFFB300),
    Color(0xFF6D4C41),
    Color(0xFF546E7A),
    Color(0xFF43A047),
    Color(0xFF00ACC1),
    Color(0xFFAB47BC),
  ];

  String _safeCategoryName(TransactionModel t) {
    final raw = t.categoryName.trim();
    if (raw.isEmpty || raw == 'કેટેગરી') {
      final title = t.title.trim();
      return title.isNotEmpty ? title : 'અન્ય';
    }
    return raw;
  }

  String _safeCategoryEmoji(TransactionModel t) {
    final raw = t.categoryEmoji.trim();
    return raw.isEmpty ? '📁' : raw;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, SettingsProvider>(
      builder: (ctx, txnP, settP, _) {
        final cur = settP.currency;
        final txns = txnP
            .getByMonth(widget.year, widget.month)
            .where((t) => t.type == _viewType)
            .toList();

        final Map<String, double> catMap = {};
        for (final t in txns) {
          final key = '${_safeCategoryEmoji(t)} ${_safeCategoryName(t)}';
          catMap[key] = (catMap[key] ?? 0) + t.amount;
        }

        final sorted = catMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final total = sorted.fold(0.0, (s, e) => s + e.value);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            SegmentedButton<TransactionType>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.primary,
                selectedForegroundColor: Colors.white,
              ),
              segments: [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('ખર્ચ', style: _guj(fontSize: 13)),
                  icon: const Icon(Icons.arrow_downward, size: 16),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('આવક', style: _guj(fontSize: 13)),
                  icon: const Icon(Icons.arrow_upward, size: 16),
                ),
              ],
              selected: {_viewType},
              onSelectionChanged: (s) => setState(() {
                _viewType = s.first;
                _touchedIndex = -1;
              }),
            ),
            const SizedBox(height: 20),
            if (total > 0)
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: (_viewType == TransactionType.expense
                        ? AppColors.expenseLight
                        : AppColors.incomeLight),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'કુલ: ${settP.currency} ${_fmt(total)}',
                    style: _guj(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _viewType == TransactionType.expense
                          ? AppColors.expense
                          : AppColors.income,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (sorted.isEmpty)
              _EmptyState(
                message:
                    'આ મહિને ${_viewType == TransactionType.expense ? "ખર્ચ" : "આવક"} ની નોંધ નથી.',
              )
            else ...[
              _SectionTitle(
                '${_viewType == TransactionType.expense ? "ખર્ચ" : "આવક"} Breakdown',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 260,
                child: _CategoryPieChart(
                  data: sorted,
                  colors: _catColors,
                  total: total,
                  currency: cur,
                  touchedIndex: _touchedIndex,
                  onTouch: (i) => setState(() => _touchedIndex = i),
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Category-wise detail'),
              const SizedBox(height: 8),
              ...sorted.asMap().entries.map(
                    (e) => _CategoryRow(
                      label: e.value.key,
                      amount: e.value.value,
                      total: total,
                      color: _catColors[e.key % _catColors.length],
                      currency: cur,
                    ),
                  ),
            ],
          ],
        );
      },
    );
  }
}

class _LoanPersonList extends StatelessWidget {
  final LoanProvider loanP;
  final String currency;

  const _LoanPersonList({
    required this.loanP,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final receiveMap = <String, double>{};
    final payMap = <String, double>{};

    for (final loan in loanP.loans) {
      if (loan.status != LoanStatus.active) continue;
      final out = loanP.outstandingAmount(loan.id);
      if (out <= 0) continue;

      if (loan.type == LoanType.gave) {
        receiveMap[loan.personId] = (receiveMap[loan.personId] ?? 0) + out;
      } else {
        payMap[loan.personId] = (payMap[loan.personId] ?? 0) + out;
      }
    }

    if (receiveMap.isEmpty && payMap.isEmpty) return const SizedBox.shrink();

    final allEntries = [
      ...receiveMap.entries.map((e) => (
            person: loanP.getPersonById(e.key),
            amount: e.value,
            isReceive: true,
          )),
      ...payMap.entries.map((e) => (
            person: loanP.getPersonById(e.key),
            amount: e.value,
            isReceive: false,
          )),
    ]..sort((a, b) => b.amount.compareTo(a.amount));

    return Column(
      children: allEntries.map((entry) {
        if (entry.person == null) return const SizedBox.shrink();
        final color = entry.isReceive ? AppColors.income : AppColors.expense;
        final bg =
            entry.isReceive ? AppColors.incomeLight : AppColors.expenseLight;
        final icon = entry.isReceive ? '💸' : '🤲';
        final label = entry.isReceive ? 'ઉઘરાણી' : 'ઉધાર';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.person!.name,
                      style: _guj(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      label,
                      style: _guj(
                        fontSize: 10,
                        color: color.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$currency ${_fmt(entry.amount)}',
                style: _guj(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _WeekBarChart extends StatelessWidget {
  final List<TransactionModel> txns;
  const _WeekBarChart({required this.txns});

  @override
  Widget build(BuildContext context) {
    final weeks = List.filled(5, 0.0);
    for (final t in txns.where((x) => x.type == TransactionType.expense)) {
      final w = ((t.date.day - 1) ~/ 7).clamp(0, 4);
      weeks[w] += t.amount;
    }
    final maxVal = weeks.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? (maxVal * 1.25).ceilToDouble() : 1000.0;

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: List.generate(
            5,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: weeks[i],
                  color: AppColors.expense,
                  width: 24,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: AppColors.expenseLight,
                  ),
                ),
              ],
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'W${v.toInt() + 1}',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (v, _) => Text(
                  _fmtShort(v),
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF28251D),
              getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
                '₹${NumberFormat('#,##0', 'en_IN').format(rod.toY)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IncomeExpenseDonut extends StatelessWidget {
  final double income;
  final double expense;
  final String cur;

  const _IncomeExpenseDonut({
    required this.income,
    required this.expense,
    required this.cur,
  });

  @override
  Widget build(BuildContext context) {
    final total = income + expense;
    if (total == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 52,
                sections: [
                  PieChartSectionData(
                    color: AppColors.income,
                    value: income,
                    title: '${(income / total * 100).toStringAsFixed(0)}%',
                    radius: 45,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  PieChartSectionData(
                    color: AppColors.expense,
                    value: expense,
                    title: '${(expense / total * 100).toStringAsFixed(0)}%',
                    radius: 45,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Legend(
                  color: AppColors.income,
                  label: 'આવક',
                  amount: '$cur ${_fmtShort(income)}',
                ),
                const SizedBox(height: 16),
                _Legend(
                  color: AppColors.expense,
                  label: 'ખર્ચ',
                  amount: '$cur ${_fmtShort(expense)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _YearLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthData;
  const _YearLineChart({required this.monthData});

  @override
  Widget build(BuildContext context) {
    double maxVal = 0;
    for (final d in monthData) {
      final inc = d['income'] as double;
      final exp = d['expense'] as double;
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }
    final maxY = maxVal > 0 ? (maxVal * 1.25).ceilToDouble() : 1000.0;

    LineChartBarData line(List<FlSpot> spots, Color color) => LineChartBarData(
          spots: spots,
          color: color,
          barWidth: 2.5,
          isCurved: true,
          curveSmoothness: 0.3,
          belowBarData: BarAreaData(
            show: true,
            color: color.withValues(alpha: 0.08),
          ),
          dotData: FlDotData(
            getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
              radius: 3.5,
              color: color,
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            ),
          ),
        );

    const monthLabels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return SizedBox(
      height: 230,
      child: LineChart(
        LineChartData(
          maxY: maxY,
          minY: 0,
          lineBarsData: [
            line(
              List.generate(
                12,
                (i) => FlSpot(
                  i.toDouble(),
                  monthData[i]['income'] as double,
                ),
              ),
              AppColors.income,
            ),
            line(
              List.generate(
                12,
                (i) => FlSpot(
                  i.toDouble(),
                  monthData[i]['expense'] as double,
                ),
              ),
              AppColors.expense,
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    monthLabels[v.toInt()],
                    style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (v, _) => Text(
                  _fmtShort(v),
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF28251D),
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      '₹${NumberFormat('#,##0', 'en_IN').format(s.y)}',
                      TextStyle(
                        color: s.bar.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final List<MapEntry<String, double>> data;
  final List<Color> colors;
  final double total;
  final String currency;
  final int touchedIndex;
  final void Function(int) onTouch;

  const _CategoryPieChart({
    required this.data,
    required this.colors,
    required this.total,
    required this.currency,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 55,
        pieTouchData: PieTouchData(
          touchCallback: (e, r) {
            if (r?.touchedSection != null) {
              onTouch(r!.touchedSection!.touchedSectionIndex);
            } else {
              onTouch(-1);
            }
          },
        ),
        sections: data.asMap().entries.map((e) {
          final isTouched = e.key == touchedIndex;
          final color = colors[e.key % colors.length];
          final pct = total > 0 ? (e.value.value / total * 100) : 0.0;

          return PieChartSectionData(
            color: color,
            value: e.value.value,
            title: isTouched
                ? '${pct.toStringAsFixed(1)}%\n${e.value.key}'
                : '${pct.toStringAsFixed(0)}%',
            radius: isTouched ? 72 : 56,
            titleStyle: TextStyle(
              fontFamily: 'NotoSansGujarati',
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: isTouched ? 11 : 9,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  final int year;
  final int month;
  final void Function(int, int) onMonthChanged;

  const _MonthPicker({
    required this.year,
    required this.month,
    required this.onMonthChanged,
  });

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = year == now.year && month == now.month;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous month',
          onPressed: () => month == 1
              ? onMonthChanged(year - 1, 12)
              : onMonthChanged(year, month - 1),
        ),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(year, month),
              firstDate: DateTime(2020),
              lastDate: now,
            );
            if (picked != null) {
              onMonthChanged(picked.year, picked.month);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_months[month - 1]} $year',
                  style: _guj(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.calendar_today,
                    size: 14, color: AppColors.primary),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next month',
          onPressed: isCurrentMonth
              ? null
              : () => month == 12
                  ? onMonthChanged(year + 1, 1)
                  : onMonthChanged(year, month + 1),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final String icon;
  final Color bg;
  final bool wide;

  const _KpiCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.bg,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: wide ? 14 : 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: wide
          ? Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: _guj(
                          fontSize: 11,
                          color: color.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        amount,
                        style: _guj(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: _guj(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: _guj(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String label;
  final double amount;
  final double total;
  final Color color;
  final String currency;

  const _CategoryRow({
    required this.label,
    required this.amount,
    required this.total,
    required this.color,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: _guj(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$currency ${_fmt(amount)}',
                style: _guj(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(pct * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopTransactions extends StatelessWidget {
  final List<TransactionModel> txns;
  final String currency;
  final int limit;

  const _TopTransactions({
    required this.txns,
    required this.currency,
    required this.limit,
  });

  String _safeCategoryName(TransactionModel t) {
    final raw = t.categoryName.trim();
    if (raw.isEmpty || raw == 'કેટેગરી') {
      final title = t.title.trim();
      return title.isNotEmpty ? title : 'અન્ય';
    }
    return raw;
  }

  String _safeCategoryEmoji(TransactionModel t) {
    final raw = t.categoryEmoji.trim();
    return raw.isEmpty ? '📁' : raw;
  }

  @override
  Widget build(BuildContext context) {
    final items = txns.take(limit).toList();
    return Column(
      children: List.generate(items.length, (idx) {
        final t = items[idx];
        final rank = idx + 1;
        final safeName = _safeCategoryName(t);
        final safeEmoji = _safeCategoryEmoji(t);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.expenseLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: rank == 1
                      ? const Color(0xFFFFB300)
                      : rank == 2
                          ? const Color(0xFF90A4AE)
                          : rank == 3
                              ? const Color(0xFFBF8970)
                              : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: rank <= 3 ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(safeEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: _guj(fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$safeEmoji $safeName',
                      style: _guj(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Text(
                '$currency ${_fmt(t.amount)}',
                style: _guj(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MonthTable extends StatelessWidget {
  final List<Map<String, dynamic>> monthData;
  final String currency;

  const _MonthTable({
    required this.monthData,
    required this.currency,
  });

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _cols = [
    {'label': 'Income', 'colorVal': 0xFF43A047},
    {'label': 'Expense', 'colorVal': 0xFFE53935},
    {'label': 'Saved', 'colorVal': 0xFF9E9E9E},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Month',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                ..._cols.map(
                  (c) => SizedBox(
                    width: 72,
                    child: Text(
                      c['label']! as String,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: Color(c['colorVal']! as int),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...monthData.asMap().entries.map((e) {
            final i = e.key;
            final d = e.value;
            final inc = d['income'] as double;
            final exp = d['expense'] as double;
            final sav = inc - exp;
            final hasData = inc > 0 || exp > 0;

            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _monthNames[i],
                          style: TextStyle(
                            fontFamily: 'NotoSansGujarati',
                            fontSize: 12,
                            color: hasData ? null : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 72,
                        child: Text(
                          hasData ? _fmtShort(inc) : '-',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: hasData
                                ? AppColors.income
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 72,
                        child: Text(
                          hasData ? _fmtShort(exp) : '-',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: hasData
                                ? AppColors.expense
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 72,
                        child: Text(
                          hasData ? _fmtShort(sav) : '-',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: hasData
                                ? (sav >= 0
                                    ? AppColors.income
                                    : AppColors.expense)
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < 11)
                  Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: _guj(fontSize: 15, fontWeight: FontWeight.w800),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final String amount;

  const _Legend({
    required this.color,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: _guj(fontSize: 11, color: Colors.grey.shade500)),
            Text(amount,
                style: _guj(fontSize: 13, fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }
}

class _ChartLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: _guj(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Text('📭', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: _guj(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
