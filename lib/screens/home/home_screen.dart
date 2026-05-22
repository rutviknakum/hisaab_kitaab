import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hisaab_kitaab/screens/ledger/person_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../models/ledger_person_model.dart';
import '../../models/loan_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/transaction_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().loadAccounts();
      context.read<TransactionProvider>().loadTransactions();
      context.read<LoanProvider>().loadAll();
    });
  }

  Future<bool> _showExitDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'એપ બંધ કરવી છે?',
          style: TextStyle(fontFamily: 'NotoSansGujarati'),
        ),
        content: const Text(
          'શું તમે ખરેખર એપમાંથી બહાર નીકળવા માંગો છો?',
          style: TextStyle(fontFamily: 'NotoSansGujarati'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ના',
                style: TextStyle(fontFamily: 'NotoSansGujarati')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('હા',
                style: TextStyle(fontFamily: 'NotoSansGujarati')),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  void _openPersonDetails(LedgerPersonModel person) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PersonDetailScreen(person: person)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog();
        if (shouldExit) SystemNavigator.pop();
      },
      child: Scaffold(
        body: Column(
          children: [
            // ── Fixed: AppBar ──────────────────────────
            _buildAppBarWidget(context),

            // ── Fixed: Balance Card (scroll સાથે નહીં જાય) ──
            _buildBalanceCardFixed(context),

            // ── Scrollable content ─────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await Future.wait([
                    context.read<AccountProvider>().loadAccounts(),
                    context.read<TransactionProvider>().loadTransactions(),
                    context.read<LoanProvider>().loadAll(),
                  ]);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _buildLedgerSummary(context),
                    _buildOverdueAlert(context),
                    _buildRecentTransactions(context),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar Widget (Fixed) ────────────────────────────────────────────────

  Widget _buildAppBarWidget(BuildContext context) {
    final now = DateTime.now();
    const weekdays = ['રવિ', 'સોમ', 'મંગળ', 'બુધ', 'ગુરુ', 'શુક્ર', 'શનિ'];
    const months = [
      'જાન્યુ',
      'ફેબ્રુ',
      'માર્ચ',
      'એપ્રિ',
      'મે',
      'જૂન',
      'જુલાઈ',
      'ઓગ',
      'સપ્ટે',
      'ઓક્ટો',
      'નવે',
      'ડિસે',
    ];
    final dayName = weekdays[now.weekday % 7];
    final monthName = months[now.month - 1];
    final fullDate = '$dayName, ${now.day} $monthName ${now.year}';

    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 12,
        bottom: 12,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'NotoSansGujarati',
                ),
              ),
              const Text(
                'હિસાબ કિતાબ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'NotoSansGujarati',
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Colors.white, size: 12),
                const SizedBox(width: 5),
                Text(
                  fullDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NotoSansGujarati',
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Balance Card (Fixed, scroll સાથે ન જાય) ─────────────────────────────

  Widget _buildBalanceCardFixed(BuildContext context) {
    return Consumer2<TransactionProvider, AccountProvider>(
      builder: (ctx, txnP, accP, _) {
        final cur = ctx.read<SettingsProvider>().currency;
        final now = DateTime.now();
        final income = txnP.monthlyIncome(now.year, now.month);
        final expense = txnP.monthlyExpense(now.year, now.month);
        final balance = accP.totalBalance;
        final isPositive = balance >= 0;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -30,
                top: -20,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  children: [
                    // ── કુલ બાકી રકમ label ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'કુલ રકમ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontFamily: 'NotoSansGujarati',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ── Amount ──
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: cur,
                            style: TextStyle(
                              color: isPositive
                                  ? Colors.white70
                                  : Colors.red.shade200,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              height: 1.6,
                            ),
                          ),
                          TextSpan(
                            text: _fmt(balance.abs()),
                            style: TextStyle(
                              color: isPositive
                                  ? Colors.white
                                  : Colors.red.shade200,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── ઋણ badge ──
                    if (!isPositive)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '⚠️ ઋણ બાકી',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontFamily: 'NotoSansGujarati',
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.15),
                      thickness: 1,
                    ),
                    const SizedBox(height: 16),

                    // ── આવક / ખર્ચ pills ──
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryPill(
                            label: 'કુલ આવક',
                            amount: '$cur${_fmt(income)}',
                            icon: Icons.arrow_upward_rounded,
                            color: Colors.green.shade300,
                            bgColor: Colors.green.withValues(alpha: 0.15),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryPill(
                            label: 'કુલ ખર્ચ',
                            amount: '$cur${_fmt(expense)}',
                            icon: Icons.arrow_downward_rounded,
                            color: Colors.red.shade300,
                            bgColor: Colors.red.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Text(
                      '${_currentMonthName(now.month)} ${now.year} નો સારાંશ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10,
                        fontFamily: 'NotoSansGujarati',
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Ledger Summary ───────────────────────────────────────────────────────

  SliverToBoxAdapter _buildLedgerSummary(BuildContext context) {
    return SliverToBoxAdapter(
      child: Consumer<LoanProvider>(
        builder: (ctx, provider, _) {
          final cur = ctx.read<SettingsProvider>().currency;

          final receiveMap = <String, double>{};
          final payMap = <String, double>{};

          for (final loan in provider.loans) {
            if (loan.status != LoanStatus.active) continue;
            final out = provider.outstandingAmount(loan.id);
            if (out <= 0) continue;

            if (loan.type == LoanType.gave) {
              receiveMap[loan.personId] =
                  (receiveMap[loan.personId] ?? 0) + out;
            } else {
              payMap[loan.personId] = (payMap[loan.personId] ?? 0) + out;
            }
          }

          if (receiveMap.isEmpty && payMap.isEmpty) {
            return const SizedBox.shrink();
          }

          final receiveEntries = receiveMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final payEntries = payMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get('ledger_title'),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (receiveEntries.isNotEmpty) ...[
                  const Text(
                    'ઉઘરાણી',
                    style: TextStyle(
                      fontFamily: 'NotoSansGujarati',
                      fontWeight: FontWeight.w700,
                      color: AppColors.income,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...receiveEntries.map((e) {
                    final person = provider.getPersonById(e.key);
                    if (person == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _openPersonDetails(person),
                        child: _PersonLoanSummaryCard(
                          name: person.name,
                          amount: '$cur${_fmt(e.value)}',
                          subtitle: 'મળવાનું',
                          color: AppColors.income,
                          bgColor: AppColors.incomeLight,
                          icon: '💸',
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                ],
                if (payEntries.isNotEmpty) ...[
                  const Text(
                    'ઉધાર',
                    style: TextStyle(
                      fontFamily: 'NotoSansGujarati',
                      fontWeight: FontWeight.w700,
                      color: AppColors.expense,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...payEntries.map((e) {
                    final person = provider.getPersonById(e.key);
                    if (person == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _openPersonDetails(person),
                        child: _PersonLoanSummaryCard(
                          name: person.name,
                          amount: '$cur${_fmt(e.value)}',
                          subtitle: 'આપવાનું',
                          color: AppColors.expense,
                          bgColor: AppColors.expenseLight,
                          icon: '🤲',
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Overdue Alert ────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildOverdueAlert(BuildContext context) {
    return SliverToBoxAdapter(
      child: Consumer<LoanProvider>(
        builder: (ctx, provider, _) {
          final overdue = provider.overdueEmis;
          if (overdue.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${overdue.length} EMI ની ચૂકવણી બાકી છે!',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'NotoSansGujarati',
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.warning),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Recent Transactions ──────────────────────────────────────────────────

  SliverToBoxAdapter _buildRecentTransactions(BuildContext context) {
    return SliverToBoxAdapter(
      child: Consumer<TransactionProvider>(
        builder: (ctx, provider, _) {
          final txns = provider.thisMonthTransactions.take(10).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.get('recent_txns'),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (txns.isNotEmpty)
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'બધા જુઓ →',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontFamily: 'NotoSansGujarati',
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              if (txns.isEmpty)
                _buildEmptyState(context)
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: txns
                        .map((t) => TransactionTile(transaction: t))
                        .toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(
                child: Text('📊', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'કોઈ વ્યવહાર નથી',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'NotoSansGujarati',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'નીચે + બટન દબાવી\nપ્રથમ વ્યવહાર ઉમેરો',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.45),
                fontFamily: 'NotoSansGujarati',
                height: 1.6,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'સુ-પ્રભાત 🌅';
    if (h < 17) return 'નમસ્કાર 🙏';
    return 'શુભ સાંજ 🌙';
  }

  String _currentMonthName(int month) {
    const months = [
      'જાન્યુઆરી',
      'ફેબ્રુઆરી',
      'માર્ચ',
      'એપ્રિલ',
      'મે',
      'જૂન',
      'જુલાઈ',
      'ઓગસ્ટ',
      'સપ્ટેમ્બર',
      'ઓક્ટોબર',
      'નવેમ્બર',
      'ડિસેમ્બર',
    ];
    return months[month - 1];
  }

  String _fmt(double amount) =>
      NumberFormat('#,##,##0.00', 'en_IN').format(amount);
}

// ── Reusable Widgets ─────────────────────────────────────────────────────────

class _PersonLoanSummaryCard extends StatelessWidget {
  final String name;
  final String amount;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final String icon;

  const _PersonLoanSummaryCard({
    required this.name,
    required this.amount,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'NotoSansGujarati',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'NotoSansGujarati',
                    fontSize: 11,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, color: color),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _SummaryPill({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontFamily: 'NotoSansGujarati',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
