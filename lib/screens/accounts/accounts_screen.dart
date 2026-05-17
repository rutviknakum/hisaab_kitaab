import 'package:flutter/material.dart';
import 'package:hisaab_kitaab/widgets/transaction_tile.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/account_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import 'add_account_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ખાતાઓ',
            style: TextStyle(
                fontFamily: 'NotoSansGujarati', fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddAccountScreen()),
            ),
            tooltip: 'નવું ખાતું',
          ),
        ],
      ),
      body: Consumer2<AccountProvider, SettingsProvider>(
        builder: (ctx, accP, settP, _) {
          final accounts = accP.activeAccounts;
          final cur = settP.currency;

          if (accounts.isEmpty) {
            return _buildEmpty(context);
          }

          return Column(
            children: [
              // Total Balance Card
              _TotalBalanceCard(
                total: accP.totalBalance,
                currency: cur,
                count: accounts.length,
              ),

              // Account list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: accounts.length,
                  itemBuilder: (ctx, i) => _AccountDetailCard(
                    account: accounts[i],
                    currency: cur,
                    onTap: () => _showDetail(context, accounts[i], cur),
                    onEdit: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddAccountScreen(existing: accounts[i]),
                      ),
                    ),
                    onDelete: () => _confirmDelete(context, accounts[i]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddAccountScreen()),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('નવું ખાતું',
            style: TextStyle(
                fontFamily: 'NotoSansGujarati', fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Text('🏦', style: TextStyle(fontSize: 52)),
          ),
          const SizedBox(height: 20),
          const Text('કોઈ ખાતું નથી',
              style: TextStyle(
                fontFamily: 'NotoSansGujarati',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 8),
          Text(
            'Cash, Bank, UPI ખાતું ઉમેરો\nઅને balance ટ્રૅક કરો',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NotoSansGujarati',
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AccountModel account) async {
    final accP = context.read<AccountProvider>();
    final txnP = context.read<TransactionProvider>();

    final txnCount = txnP.getByAccount(account.id).length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${account.icon} ${account.name} કાઢો?',
            style: const TextStyle(fontFamily: 'NotoSansGujarati')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('આ ખાતું કાઢવાથી:',
                style: TextStyle(
                    fontFamily: 'NotoSansGujarati',
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('• $txnCount વ્યવહારો પણ ભૂંસાશે',
                style: const TextStyle(
                    fontFamily: 'NotoSansGujarati', color: AppColors.expense)),
            const Text('• આ ક્રિયા પાછી ન થઈ શકે',
                style: TextStyle(
                    fontFamily: 'NotoSansGujarati', color: AppColors.expense)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ના',
                style: TextStyle(fontFamily: 'NotoSansGujarati')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text('હા, કાઢો',
                style: TextStyle(fontFamily: 'NotoSansGujarati')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await txnP.deleteByAccount(account.id);
      await accP.deleteAccount(account.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${account.name} ખાતું કાઢ્યું',
                style: const TextStyle(fontFamily: 'NotoSansGujarati')),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  void _showDetail(BuildContext context, AccountModel acc, String cur) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AccountDetailSheet(account: acc, currency: cur),
    );
  }
}

// ── Total Balance Card ─────────────────────────
class _TotalBalanceCard extends StatelessWidget {
  final double total;
  final String currency;
  final int count;

  const _TotalBalanceCard({
    required this.total,
    required this.currency,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('કુલ Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontFamily: 'NotoSansGujarati',
                    )),
                const SizedBox(height: 6),
                Text(
                  '$currency${NumberFormat('#,##,##0.00', 'en_IN').format(total)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count ખાતા',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontFamily: 'NotoSansGujarati',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('🏦', style: TextStyle(fontSize: 32)),
          ),
        ],
      ),
    );
  }
}

// ── Account Detail Card ────────────────────────
class _AccountDetailCard extends StatelessWidget {
  final AccountModel account;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountDetailCard({
    required this.account,
    required this.currency,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(account.color.replaceFirst('#', '0xFF')));
    final txns = context.read<TransactionProvider>().getByAccount(account.id);
    final income = txns
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = txns
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(account.icon,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFamily: 'NotoSansGujarati',
                            fontSize: 15,
                          )),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${account.type.icon} ${account.type.label}',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'NotoSansGujarati',
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currency${NumberFormat('#,##,##0.00', 'en_IN').format(account.balance)}',
                      style: TextStyle(
                        color: account.balance >= 0
                            ? AppColors.income
                            : AppColors.expense,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onEdit,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit,
                                size: 14, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onDelete,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.expenseLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete,
                                size: 14, color: AppColors.expense),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Income/Expense mini bar
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatChip(
                  label: 'આવક',
                  amount: '$currency${_fmtShort(income)}',
                  color: AppColors.income,
                  icon: '📈',
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'ખર્ચ',
                  amount: '$currency${_fmtShort(expense)}',
                  color: AppColors.expense,
                  icon: '📉',
                ),
                const Spacer(),
                Text('${txns.length} વ્યવહારો',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'NotoSansGujarati',
                      color: Colors.grey.shade500,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtShort(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return NumberFormat('#,##0', 'en_IN').format(v);
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final String icon;

  const _StatChip({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade500,
                  fontFamily: 'NotoSansGujarati',
                )),
            Text(amount,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
          ],
        ),
      ],
    );
  }
}

// ── Account Detail Bottom Sheet ────────────────
class _AccountDetailSheet extends StatelessWidget {
  final AccountModel account;
  final String currency;

  const _AccountDetailSheet({
    required this.account,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(account.color.replaceFirst('#', '0xFF')));
    final txns = context.read<TransactionProvider>().getByAccount(account.id)
      ..sort((a, b) => b.date.compareTo(a.date));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Text(account.icon, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontFamily: 'NotoSansGujarati',
                            fontSize: 18,
                          )),
                      Text(account.type.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontFamily: 'NotoSansGujarati',
                          )),
                    ],
                  ),
                ),
                Text(
                  '$currency${NumberFormat('#,##,##0.00', 'en_IN').format(account.balance)}',
                  style: TextStyle(
                    color: account.balance >= 0
                        ? AppColors.income
                        : AppColors.expense,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),

          // Transactions
          Expanded(
            child: txns.isEmpty
                ? Center(
                    child: Text('કોઈ વ્યવહાર નથી',
                        style: TextStyle(
                          fontFamily: 'NotoSansGujarati',
                          color: Colors.grey.shade400,
                        )))
                : ListView.builder(
                    controller: ctrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: txns.length,
                    itemBuilder: (_, i) =>
                        TransactionTile(transaction: txns[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
