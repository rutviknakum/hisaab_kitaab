import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/loan_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/loan_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
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

  String? _filterCatName;
  String? _filterCatEmoji;
  DateTimeRange? _dateRange;
  String _search = '';

  bool get _isLoanTab => _tabCtrl.index == 3 || _tabCtrl.index == 4;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<TransactionModel> _filteredTransactions(
    List<TransactionModel> all,
    TransactionType? type,
  ) {
    var list = all;

    if (type != null) {
      list = list.where((t) => t.type == type).toList();
    }

    if (_filterCatName != null && !_isLoanTab) {
      list = list.where((t) => t.categoryName == _filterCatName).toList();
    }

    if (_dateRange != null) {
      list = list
          .where(
            (t) =>
                t.date.isAfter(
                  _dateRange!.start.subtract(const Duration(days: 1)),
                ) &&
                t.date.isBefore(
                  _dateRange!.end.add(const Duration(days: 1)),
                ),
          )
          .toList();
    }

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.categoryName.toLowerCase().contains(q) ||
                (t.note?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    return list;
  }

  List<LoanModel> _filteredLoans(
    List<LoanModel> all,
    LoanProvider loanP,
    LoanType? type,
  ) {
    var list = all.where((l) => l.status == LoanStatus.active).toList();

    if (type != null) {
      list = list.where((l) => l.type == type).toList();
    }

    if (_dateRange != null) {
      list = list
          .where(
            (l) =>
                l.startDate.isAfter(
                  _dateRange!.start.subtract(const Duration(days: 1)),
                ) &&
                l.startDate.isBefore(
                  _dateRange!.end.add(const Duration(days: 1)),
                ),
          )
          .toList();
    }

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((l) {
        final person = loanP.getPersonById(l.personId);
        final personName = person?.name.toLowerCase() ?? '';
        final note = l.note?.toLowerCase() ?? '';
        return personName.contains(q) || note.contains(q);
      }).toList();
    }

    return list;
  }

  List<Map<String, dynamic>> _mergedItems({
    required List<TransactionModel> txns,
    required List<LoanModel> loans,
    required LoanProvider loanP,
  }) {
    final items = <Map<String, dynamic>>[];

    for (final t in txns) {
      items.add({
        'kind': 'txn',
        'date': t.date,
        'txn': t,
      });
    }

    for (final l in loans) {
      items.add({
        'kind': 'loan',
        'date': l.startDate,
        'loan': l,
        'personName': loanP.getPersonById(l.personId)?.name ?? 'અજ્ઞાત',
      });
    }

    items.sort((a, b) {
      final ad = a['date'] as DateTime;
      final bd = b['date'] as DateTime;
      return bd.compareTo(ad);
    });

    return items;
  }

  Map<String, List<Map<String, dynamic>>> _groupedMerged(
    List<Map<String, dynamic>> items,
  ) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final d = item['date'] as DateTime;
      final key = DateFormat('dd MMMM yyyy').format(d);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  Map<String, List<TransactionModel>> _groupedTransactions(
    List<TransactionModel> list,
  ) {
    final map = <String, List<TransactionModel>>{};
    for (final t in list) {
      final key = DateFormat('dd MMMM yyyy').format(t.date);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  Map<String, List<Map<String, dynamic>>> _groupedLoans(
    List<LoanModel> loans,
    LoanProvider loanP,
  ) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final loan in loans) {
      final key = DateFormat('dd MMMM yyyy').format(loan.startDate);
      map.putIfAbsent(key, () => []).add({
        'loan': loan,
        'personName': loanP.getPersonById(loan.personId)?.name ?? 'અજ્ઞાત',
      });
    }
    return map;
  }

  List<Map<String, String>> _extractCategories(List<TransactionModel> all) {
    final seen = <String>{};
    final categories = <Map<String, String>>[];

    for (final t in all) {
      final name = t.categoryName.trim();
      if (name.isEmpty) continue;

      final key = '${t.categoryEmoji}|$name';
      if (seen.add(key)) {
        categories.add({
          'name': name,
          'emoji': t.categoryEmoji,
        });
      }
    }

    categories.sort(
      (a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''),
    );

    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          if (!_isLoanTab)
            IconButton(
              icon: Icon(
                Icons.filter_list_rounded,
                color: _filterCatName != null ? AppColors.primary : null,
              ),
              onPressed: _showCategoryFilter,
              tooltip: 'Category ફિલ્ટર',
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabAlignment: TabAlignment.fill,
          labelStyle: const TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          labelPadding: EdgeInsets.zero,
          tabs: const [
            Tab(text: 'બધા'),
            Tab(text: 'આવક'),
            Tab(text: 'ખર્ચ'),
            Tab(text: 'ઉઘરાણી'),
            Tab(text: 'ઉધાર'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: _isLoanTab
                        ? 'શોધો... (person, note)'
                        : 'શોધો... (title, category, person)',
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
              if (_dateRange != null || (_filterCatName != null && !_isLoanTab))
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_dateRange != null)
                          _FilterChip(
                            label:
                                '${DateFormat('dd MMM').format(_dateRange!.start)} - ${DateFormat('dd MMM').format(_dateRange!.end)}',
                            onRemove: () => setState(() => _dateRange = null),
                          ),
                        if (_filterCatName != null && !_isLoanTab)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _FilterChip(
                              label:
                                  '${_filterCatEmoji ?? '📁'} $_filterCatName',
                              onRemove: () => setState(() {
                                _filterCatName = null;
                                _filterCatEmoji = null;
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Consumer2<TransactionProvider, LoanProvider>(
                  builder: (ctx, txnP, loanP, _) {
                    final cur = ctx.read<SettingsProvider>().currency;
                    final selectedIndex = _tabCtrl.index;

                    final txnFilterType = switch (selectedIndex) {
                      1 => TransactionType.income,
                      2 => TransactionType.expense,
                      _ => null,
                    };

                    final loanFilterType = switch (selectedIndex) {
                      3 => LoanType.gave,
                      4 => LoanType.took,
                      _ => null,
                    };

                    final filteredTxns = _filteredTransactions(
                      txnP.thisMonthTransactions,
                      txnFilterType,
                    );

                    final filteredLoans = _filteredLoans(
                      loanP.loans,
                      loanP,
                      loanFilterType,
                    );

                    final allTxnsForAllTab = _filteredTransactions(
                      txnP.thisMonthTransactions,
                      null,
                    );

                    final allLoansForAllTab = _filteredLoans(
                      loanP.loans,
                      loanP,
                      null,
                    );

                    final totalIncome = filteredTxns
                        .where((t) => t.type == TransactionType.income)
                        .fold(0.0, (s, t) => s + t.amount);

                    final totalExpense = filteredTxns
                        .where((t) => t.type == TransactionType.expense)
                        .fold(0.0, (s, t) => s + t.amount);

                    final totalReceive = filteredLoans
                        .where((l) => l.type == LoanType.gave)
                        .fold(0.0, (s, l) => s + loanP.outstandingAmount(l.id));

                    final totalPay = filteredLoans
                        .where((l) => l.type == LoanType.took)
                        .fold(0.0, (s, l) => s + loanP.outstandingAmount(l.id));

                    final totalReceiveAll = allLoansForAllTab
                        .where((l) => l.type == LoanType.gave)
                        .fold(0.0, (s, l) => s + loanP.outstandingAmount(l.id));

                    final totalPayAll = allLoansForAllTab
                        .where((l) => l.type == LoanType.took)
                        .fold(0.0, (s, l) => s + loanP.outstandingAmount(l.id));

                    if (selectedIndex == 0) {
                      final merged = _mergedItems(
                        txns: allTxnsForAllTab,
                        loans: allLoansForAllTab,
                        loanP: loanP,
                      );

                      if (merged.isEmpty) {
                        return _buildEmpty(context);
                      }

                      final grouped = _groupedMerged(merged);

                      return Column(
                        children: [
                          _buildStatsCardAll(
                            context: context,
                            cur: cur,
                            totalIncome: allTxnsForAllTab
                                .where((t) => t.type == TransactionType.income)
                                .fold(0.0, (s, t) => s + t.amount),
                            totalExpense: allTxnsForAllTab
                                .where((t) => t.type == TransactionType.expense)
                                .fold(0.0, (s, t) => s + t.amount),
                            totalReceive: totalReceiveAll,
                            totalPay: totalPayAll,
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              itemCount: grouped.length,
                              itemBuilder: (_, i) {
                                final dateKey = grouped.keys.elementAt(i);
                                final items = grouped[dateKey]!;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 12,
                                        bottom: 6,
                                      ),
                                      child: Text(
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
                                    ),
                                    ...items.map((item) {
                                      if (item['kind'] == 'txn') {
                                        return TransactionTile(
                                          transaction:
                                              item['txn'] as TransactionModel,
                                          showDate: false,
                                        );
                                      }

                                      final loan = item['loan'] as LoanModel;
                                      final personName =
                                          item['personName'] as String;

                                      return _LoanTile(
                                        loan: loan,
                                        personName: personName,
                                        amount:
                                            loanP.outstandingAmount(loan.id),
                                        currency: cur,
                                      );
                                    }),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }

                    if (selectedIndex == 1 || selectedIndex == 2) {
                      if (filteredTxns.isEmpty) {
                        return _buildEmpty(context);
                      }

                      final grouped = _groupedTransactions(filteredTxns);

                      return Column(
                        children: [
                          _buildStatsCardTxn(
                            context: context,
                            cur: cur,
                            totalIncome: totalIncome,
                            totalExpense: totalExpense,
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 12,
                                        bottom: 6,
                                      ),
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
                                    ...txns.map(
                                      (t) => TransactionTile(
                                        transaction: t,
                                        showDate: false,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }

                    if (selectedIndex == 3 || selectedIndex == 4) {
                      if (filteredLoans.isEmpty) {
                        return _buildEmpty(context);
                      }

                      final grouped = _groupedLoans(filteredLoans, loanP);

                      return Column(
                        children: [
                          _buildStatsCardLoan(
                            context: context,
                            cur: cur,
                            totalReceive: totalReceive,
                            totalPay: totalPay,
                            isReceiveTab: selectedIndex == 3,
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              itemCount: grouped.length,
                              itemBuilder: (_, i) {
                                final dateKey = grouped.keys.elementAt(i);
                                final loans = grouped[dateKey]!;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 12,
                                        bottom: 6,
                                      ),
                                      child: Text(
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
                                    ),
                                    ...loans.map((item) {
                                      final loan = item['loan'] as LoanModel;
                                      final personName =
                                          item['personName'] as String;

                                      return _LoanTile(
                                        loan: loan,
                                        personName: personName,
                                        amount:
                                            loanP.outstandingAmount(loan.id),
                                        currency: cur,
                                      );
                                    }),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }

                    return _buildEmpty(context);
                  },
                ),
              ),
            ],
          ),
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

  Widget _buildStatsCardAll({
    required BuildContext context,
    required String cur,
    required double totalIncome,
    required double totalExpense,
    required double totalReceive,
    required double totalPay,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'આવક',
                  amount: '$cur${_fmtShort(totalIncome)}',
                  color: AppColors.income,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'ખર્ચ',
                  amount: '$cur${_fmtShort(totalExpense)}',
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'ઉઘરાણી',
                  amount: '$cur${_fmtShort(totalReceive)}',
                  color: AppColors.income,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'ઉધાર',
                  amount: '$cur${_fmtShort(totalPay)}',
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCardTxn({
    required BuildContext context,
    required String cur,
    required double totalIncome,
    required double totalExpense,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            amount: '$cur${_fmtShort(totalIncome - totalExpense)}',
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCardLoan({
    required BuildContext context,
    required String cur,
    required double totalReceive,
    required double totalPay,
    required bool isReceiveTab,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            label: isReceiveTab ? 'ઉઘરાણી' : 'ઉધાર',
            amount: '$cur${_fmtShort(isReceiveTab ? totalReceive : totalPay)}',
            color: isReceiveTab ? AppColors.income : AppColors.expense,
          ),
          Container(
            width: 1,
            height: 28,
            color: AppColors.borderLight,
          ),
          _MiniStat(
            label: 'એકાઉન્ટ',
            amount: isReceiveTab ? 'મેળવવાનું' : 'ચૂકવવાનું',
            color: AppColors.primary,
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
            _isLoanTab ? 'કોઈ ઉધાર-ઉઘરાણી મળી નહીં' : 'કોઈ વ્યવહાર મળ્યો નહીં',
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
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _showCategoryFilter() {
    final provider = context.read<TransactionProvider>();
    final categories = _extractCategories(provider.thisMonthTransactions);

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
            if (categories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'કોઈ category મળી નથી',
                  style: TextStyle(
                    fontFamily: 'NotoSansGujarati',
                    fontSize: 13,
                  ),
                ),
              )
            else
              Flexible(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((c) {
                    final name = c['name'] ?? '';
                    final emoji = c['emoji'] ?? '📁';
                    final sel = _filterCatName == name;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (sel) {
                            _filterCatName = null;
                            _filterCatEmoji = null;
                          } else {
                            _filterCatName = name;
                            _filterCatEmoji = emoji;
                          }
                        });
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
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
                          '$emoji $name',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'NotoSansGujarati',
                            color: sel ? AppColors.primary : null,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.normal,
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

class _LoanTile extends StatelessWidget {
  final LoanModel loan;
  final String personName;
  final double amount;
  final String currency;

  const _LoanTile({
    required this.loan,
    required this.personName,
    required this.amount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isReceive = loan.type == LoanType.gave;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isReceive ? AppColors.incomeLight : AppColors.expenseLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              isReceive ? '💸' : '🤲',
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          personName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'NotoSansGujarati',
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isReceive ? 'ઉઘરાણી' : 'ઉધાર',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'NotoSansGujarati',
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('dd MMM yyyy').format(loan.startDate),
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
              ),
              if (loan.note != null && loan.note!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '📝 ${loan.note}',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'NotoSansGujarati',
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isReceive ? '+' : '-'}$currency ${NumberFormat('#,##,##0.00', 'en_IN').format(amount)}',
              style: TextStyle(
                color: isReceive ? AppColors.income : AppColors.expense,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isReceive ? AppColors.incomeLight : AppColors.expenseLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isReceive ? 'ઉઘરાણી' : 'ઉધાર',
                style: TextStyle(
                  fontSize: 9,
                  fontFamily: 'NotoSansGujarati',
                  fontWeight: FontWeight.w700,
                  color: isReceive ? AppColors.income : AppColors.expense,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({
    required this.label,
    required this.onRemove,
  });

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

class _MiniStat extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.amount,
    required this.color,
  });

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
