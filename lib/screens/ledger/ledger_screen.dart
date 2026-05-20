import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/ledger_person_model.dart';
import '../../models/loan_model.dart';
import '../../providers/loan_provider.dart';
import '../../providers/settings_provider.dart';
import 'add_person_screen.dart';
import 'person_detail_screen.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomNavHeight = 56.0 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ઉધાર-ઉઘરાણી',
          style: TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelStyle: const TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: '👥 બધા'),
            Tab(text: '💸 ઉઘરાણી'),
            Tab(text: '🤲 ઉધાર'),
          ],
        ),
      ),
      body: Consumer2<LoanProvider, SettingsProvider>(
        builder: (ctx, loanP, settP, _) {
          final cur = settP.currency;
          return Column(
            children: [
              _buildSummaryRow(loanP, cur),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'વ્યક્તિ શોધો...',
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
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _PersonList(
                      search: _search,
                      filterType: null,
                      extraBottomPadding: bottomNavHeight,
                    ),
                    _PersonList(
                      search: _search,
                      filterType: LoanType.gave,
                      extraBottomPadding: bottomNavHeight,
                    ),
                    _PersonList(
                      search: _search,
                      filterType: LoanType.took,
                      extraBottomPadding: bottomNavHeight,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bottomNavHeight + 8),
        child: ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddPersonScreen(),
              ),
            );
            if (mounted) {
              context.read<LoanProvider>().loadAll();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 6,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
          ),
          icon: const Icon(Icons.person_add_rounded, size: 22),
          label: const Text(
            'વ્યક્તિ ઉમેરો',
            style: TextStyle(
              fontFamily: 'NotoSansGujarati',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(LoanProvider loanP, String cur) {
    final toReceive = loanP.totalToReceive;
    final toPay = loanP.totalToPay;
    final net = toReceive - toPay;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _SumItem(
            label: 'ઉઘરાણી\n(મળવાનું)',
            amount: '$cur${_fmtShort(toReceive)}',
            color: Colors.green.shade300,
            icon: '💸',
          ),
          _Divider(),
          _SumItem(
            label: 'ઉધાર\n(આપવાનું)',
            amount: '$cur${_fmtShort(toPay)}',
            color: Colors.red.shade300,
            icon: '🤲',
          ),
          _Divider(),
          _SumItem(
            label: 'Net\nBalance',
            amount: '${net >= 0 ? '+' : ''}$cur${_fmtShort(net)}',
            color: net >= 0 ? Colors.green.shade300 : Colors.red.shade300,
            icon: net >= 0 ? '📈' : '📉',
          ),
        ],
      ),
    );
  }

  String _fmtShort(double v) {
    if (v.abs() >= 100000) {
      return '${(v / 100000).toStringAsFixed(1)}L';
    }
    if (v.abs() >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}K';
    }
    return NumberFormat('#,##0', 'en_IN').format(v);
  }
}

class _SumItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final String icon;

  const _SumItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontFamily: 'NotoSansGujarati',
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 44,
        color: Colors.white.withValues(alpha: 0.2),
      );
}

class _PersonList extends StatelessWidget {
  final String search;
  final LoanType? filterType;
  final double extraBottomPadding;

  const _PersonList({
    required this.search,
    required this.filterType,
    required this.extraBottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<LoanProvider, SettingsProvider>(
      builder: (ctx, loanP, settP, _) {
        var persons = loanP.persons;
        final cur = settP.currency;

        if (search.isNotEmpty) {
          persons = persons
              .where((p) => p.name.toLowerCase().contains(search.toLowerCase()))
              .toList();
        }

        if (filterType != null) {
          persons = persons
              .where((p) =>
                  loanP.loansOfPerson(p.id).any((l) => l.type == filterType))
              .toList();
        }

        if (persons.isEmpty) {
          return _buildEmpty(filterType);
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 8, 16, extraBottomPadding + 80),
          itemCount: persons.length,
          itemBuilder: (_, i) {
            final person = persons[i];
            final net = loanP.personNetBalance(person.id);
            final loans = loanP.activeLoansOfPerson(person.id);

            return _PersonCard(
              person: person,
              net: net,
              currency: cur,
              loanCount: loans.length,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PersonDetailScreen(person: person),
                ),
              ),
              onDelete: () => _confirmDelete(context, loanP, person),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    LoanProvider loanP,
    LedgerPersonModel person,
  ) async {
    final loans = loanP.loansOfPerson(person.id);
    final activeLoans = loanP.activeLoansOfPerson(person.id);
    final hasActive = activeLoans.isNotEmpty;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '🗑️ ${person.name} ને ડિલીટ કરો?',
          style: const TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          hasActive
              ? 'આ વ્યક્તિ પાસે હજુ active loan છે.\n\nડિલીટ કરવાનો પ્રયાસ કરશો તો એપ તમને કારણ બતાવશે.'
              : loans.isNotEmpty
                  ? 'આ વ્યક્તિ ની closed loan history પણ ભૂંસાઈ જશે.\n\nઆ ક્રિયા undo ન થઈ શકે.'
                  : 'આ વ્યક્તિ ની સંપૂર્ણ history ભૂંસાઈ જશે.\n\nઆ ક્રિયા undo ન થઈ શકે.',
          style: const TextStyle(
            fontFamily: 'NotoSansGujarati',
            height: 1.5,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'NotoSansGujarati'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'હા, ડિલીટ કરો',
              style: TextStyle(
                fontFamily: 'NotoSansGujarati',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await loanP.deletePerson(person.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${person.name} ડિલીટ થઈ ગઈ ✅',
                style: const TextStyle(fontFamily: 'NotoSansGujarati'),
              ),
              backgroundColor: AppColors.expense,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            ),
          );
        }
      } catch (e) {
        if (!context.mounted) return;

        final message = e.toString().replaceFirst('Exception: ', '');

        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'ડિલીટ થઈ શક્યું નહીં',
              style: TextStyle(
                fontFamily: 'NotoSansGujarati',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              message,
              style: const TextStyle(
                fontFamily: 'NotoSansGujarati',
                height: 1.5,
                fontSize: 13,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'બરાબર',
                  style: TextStyle(
                    fontFamily: 'NotoSansGujarati',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildEmpty(LoanType? type) {
    final msg = type == LoanType.gave
        ? 'કોઈ ઉઘરાણી નથી'
        : type == LoanType.took
            ? 'કોઈ ઉધાર નથી'
            : 'કોઈ વ્યક્તિ નથી';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🤝', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(
            msg,
            style: TextStyle(
              fontFamily: 'NotoSansGujarati',
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '+ નીચે બટન વડે ઉમેરો',
            style: TextStyle(
              fontFamily: 'NotoSansGujarati',
              fontSize: 12,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final LedgerPersonModel person;
  final double net;
  final String currency;
  final int loanCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PersonCard({
    required this.person,
    required this.net,
    required this.currency,
    required this.loanCount,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = net >= 0;
    final color = isPositive ? AppColors.income : AppColors.expense;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFamily: 'NotoSansGujarati',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'NotoSansGujarati',
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (person.phone != null) ...[
                        Icon(Icons.phone,
                            size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(
                          person.phone!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$loanCount loan',
                          style: TextStyle(
                            fontSize: 9,
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'detail',
                      child: Row(
                        children: const [
                          Icon(Icons.visibility_rounded,
                              size: 16, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'વિગત જુઓ',
                            style: TextStyle(
                              fontFamily: 'NotoSansGujarati',
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: const [
                          Icon(Icons.delete_outline_rounded,
                              size: 16, color: AppColors.expense),
                          SizedBox(width: 8),
                          Text(
                            'ડિલીટ કરો',
                            style: TextStyle(
                              fontFamily: 'NotoSansGujarati',
                              fontSize: 13,
                              color: AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (val) {
                    if (val == 'detail') onTap();
                    if (val == 'delete') onDelete();
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  net == 0
                      ? 'Clear ✅'
                      : '${isPositive ? '+' : ''}$currency${NumberFormat('#,##,##0', 'en_IN').format(net)}',
                  style: TextStyle(
                    color: net == 0 ? AppColors.income : color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  net == 0
                      ? 'લેણ-દેણ Clear'
                      : isPositive
                          ? 'મળવાનું છે'
                          : 'આપવાનું છે',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'NotoSansGujarati',
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
