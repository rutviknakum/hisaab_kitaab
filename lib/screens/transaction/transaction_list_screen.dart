import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  TransactionType? _filterType;
  TransactionCategory? _filterCat;
  DateTimeRange? _dateRange;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => setState(() {
          switch (_tabCtrl.index) {
            case 0:
              _filterType = null;
              break;
            case 1:
              _filterType = TransactionType.income;
              break;
            case 2:
              _filterType = TransactionType.expense;
              break;
          }
        }));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<TransactionModel> _filtered(List<TransactionModel> all) {
    var list = all;

    if (_filterType != null) {
      list = list.where((t) => t.type == _filterType).toList();
    }
    if (_filterCat != null) {
      list = list.where((t) => t.category == _filterCat).toList();
    }
    if (_dateRange != null) {
      list = list
          .where((t) =>
              t.date.isAfter(
                  _dateRange!.start.subtract(const Duration(days: 1))) &&
              t.date.isBefore(_dateRange!.end.add(const Duration(days: 1))))
          .toList();
    }
    if (_search.isNotEmpty) {
      list = list
          .where((t) =>
              t.title.toLowerCase().contains(_search.toLowerCase()) ||
              t.category.label.contains(_search) ||
              (t.note?.contains(_search) ?? false))
          .toList();
    }

    return list;
  }

  Map<String, List<TransactionModel>> _grouped(List<TransactionModel> list) {
    final map = <String, List<TransactionModel>>{};
    for (final t in list) {
      final key = DateFormat('dd MMMM yyyy').format(t.date);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ FAB સંપૂર્ણ હટાવ્યું — custom Positioned button વાપર્યું
      appBar: AppBar(
        title: const Text(
          'વ્યવહારો',
          style: TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _dateRange != null ? Icons.date_range : Icons.date_range_outlined,
              color: _dateRange != null ? AppColors.primary : null,
            ),
            onPressed: _pickDateRange,
            tooltip: 'તારીખ ફિલ્ટર',
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: _filterCat != null ? AppColors.primary : null,
            ),
            onPressed: _showCategoryFilter,
            tooltip: 'Category ફિલ્ટર',
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelStyle: const TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'બધા'),
            Tab(text: '📈 આવક'),
            Tab(text: '📉 ખર્ચ'),
          ],
        ),
      ),

      // ✅ Stack — body + custom FAB button
      body: Stack(
        children: [
          // ── Main Content ──────────────────────────
          Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'શોધો... (title, category)',
                    hintStyle: const TextStyle(
                      fontFamily: 'NotoSansGujarati',
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _search = ''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.borderLight),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),

              // Active filter chips
              if (_dateRange != null || _filterCat != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      if (_dateRange != null)
                        _FilterChip(
                          label:
                              '${DateFormat('dd MMM').format(_dateRange!.start)} - ${DateFormat('dd MMM').format(_dateRange!.end)}',
                          onRemove: () => setState(() => _dateRange = null),
                        ),
                      if (_filterCat != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                            label: '${_filterCat!.icon} ${_filterCat!.label}',
                            onRemove: () => setState(() => _filterCat = null),
                          ),
                        ),
                    ],
                  ),
                ),

              // Transaction list
              Expanded(
                child: Consumer<TransactionProvider>(
                  builder: (ctx, provider, _) {
                    final cur = ctx.read<SettingsProvider>().currency;
                    final filtered = _filtered(provider.thisMonthTransactions);
                    final grouped = _grouped(filtered);

                    if (filtered.isEmpty) {
                      return _buildEmpty(context);
                    }

                    final totalIncome = filtered
                        .where((t) => t.type == TransactionType.income)
                        .fold(0.0, (s, t) => s + t.amount);
                    final totalExpense = filtered
                        .where((t) => t.type == TransactionType.expense)
                        .fold(0.0, (s, t) => s + t.amount);

                    return Column(
                      children: [
                        // Summary bar
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _MiniStat(
                                label: 'આવક',
                                amount: '$cur${_fmtShort(totalIncome)}',
                                color: AppColors.income,
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: AppColors.borderLight,
                              ),
                              _MiniStat(
                                label: 'ખર્ચ',
                                amount: '$cur${_fmtShort(totalExpense)}',
                                color: AppColors.expense,
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: AppColors.borderLight,
                              ),
                              _MiniStat(
                                label: 'બચત',
                                amount:
                                    '$cur${_fmtShort(totalIncome - totalExpense)}',
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),

                        // Grouped list
                        Expanded(
                          child: ListView.builder(
                            // ✅ bottom padding — FAB ઢાંકે નહીં
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: grouped.length,
                            itemBuilder: (_, i) {
                              final dateKey = grouped.keys.elementAt(i);
                              final txns = grouped[dateKey]!;
                              final dayTotal = txns.fold(
                                0.0,
                                (s, t) => t.type == TransactionType.income
                                    ? s + t.amount
                                    : s - t.amount,
                              );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date header
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 12, bottom: 6),
                                    child: Row(
                                      children: [
                                        Text(
                                          dateKey,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${dayTotal >= 0 ? '+' : ''}$cur${_fmtShort(dayTotal)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: dayTotal >= 0
                                                ? AppColors.income
                                                : AppColors.expense,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Tiles
                                  ...txns.map((t) => TransactionTile(
                                        transaction: t,
                                        showDate: false,
                                      )),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // ✅ Custom FAB — Flutter FAB replace
          // BottomNav ઉપર right corner — circle problem નહીં
          Positioned(
            right: 16,
            bottom: 16,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddTransactionScreen(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'નવો',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'NotoSansGujarati',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'કોઈ વ્યવહાર મળ્યો નહીં',
            style: TextStyle(
              fontFamily: 'NotoSansGujarati',
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              Theme.of(ctx).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category ફિલ્ટર',
              style: TextStyle(
                fontFamily: 'NotoSansGujarati',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TransactionCategory.values.map((c) {
                  final sel = _filterCat == c;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _filterCat = sel ? null : c);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primarySurface
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? AppColors.primary : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        '${c.icon} ${c.label}',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'NotoSansGujarati',
                          color: sel ? AppColors.primary : null,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _fmtShort(double v) {
    if (v.abs() >= 100000) {
      return '${(v / 100000).toStringAsFixed(1)}L';
    } else if (v.abs() >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}K';
    }
    return NumberFormat('#,##0.00', 'en_IN').format(v);
  }
}

// ── Filter Chip ────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontFamily: 'NotoSansGujarati',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini Stat ──────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  const _MiniStat(
      {required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'NotoSansGujarati',
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
