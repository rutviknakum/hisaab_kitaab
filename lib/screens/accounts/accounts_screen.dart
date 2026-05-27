import 'dart:math' as math;
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

  Future<void> _openAddAccount(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAccountScreen()),
    );
    if (!context.mounted) return;
    await context.read<AccountProvider>().loadAccounts();
  }

  Future<void> _openEditAccount(
    BuildContext context,
    AccountModel account,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAccountScreen(existing: account),
      ),
    );
    if (!context.mounted) return;
    await context.read<AccountProvider>().loadAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ખાતાઓ',
          style: TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _openAddAccount(context),
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

          final normalAccounts = accP.normalAccounts;
          final creditCards = accP.creditCardAccounts;

          return Column(
            children: [
              _AccountsSummaryCard(
                currency: cur,
                totalNormalBalance: accP.totalNormalBalance,
                totalCcOutstanding: accP.totalCcOutstanding,
                totalCcAvailable: accP.totalCcAvailable,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    if (normalAccounts.isNotEmpty) ...[
                      const _SectionTitle(
                        icon: '🏦',
                        title: 'બૅન્ક / રોકડ / UPI',
                      ),
                      const SizedBox(height: 10),
                      ...normalAccounts.map(
                        (account) => _NormalAccountCard(
                          account: account,
                          currency: cur,
                          onTap: () => _showDetail(context, account, cur),
                          onEdit: () => _openEditAccount(context, account),
                          onDelete: () => _confirmDelete(context, account),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (creditCards.isNotEmpty) ...[
                      const _SectionTitle(
                        icon: '💳',
                        title: 'ક્રેડિટ કાર્ડ',
                      ),
                      const SizedBox(height: 10),
                      ...creditCards.map(
                        (account) => _CreditCardAccountCard(
                          account: account,
                          currency: cur,
                          onTap: () => _showDetail(context, account, cur),
                          onEdit: () => _openEditAccount(context, account),
                          onDelete: () => _confirmDelete(context, account),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _openAddAccount(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'નવું ખાતું',
          style: TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w700,
          ),
        ),
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
          const Text(
            'કોઈ ખાતું નથી',
            style: TextStyle(
              fontFamily: 'NotoSansGujarati',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cash, Bank, UPI અને Credit Card ખાતાં ઉમેરો',
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
    BuildContext context,
    AccountModel account,
  ) async {
    final accP = context.read<AccountProvider>();
    final txnP = context.read<TransactionProvider>();

    final txnCount = txnP.getByAccount(account.id).length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '${account.icon} ${account.name} કાઢો?',
          style: const TextStyle(fontFamily: 'NotoSansGujarati'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'આ ખાતું કાઢવાથી:',
              style: TextStyle(
                fontFamily: 'NotoSansGujarati',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• $txnCount વ્યવહારો પણ ભૂંસાશે',
              style: const TextStyle(
                fontFamily: 'NotoSansGujarati',
                color: AppColors.expense,
              ),
            ),
            const Text(
              '• આ ક્રિયા પાછી ન થઈ શકે',
              style: TextStyle(
                fontFamily: 'NotoSansGujarati',
                color: AppColors.expense,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'ના',
              style: TextStyle(fontFamily: 'NotoSansGujarati'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'હા, કાઢો',
              style: TextStyle(fontFamily: 'NotoSansGujarati'),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await txnP.deleteByAccount(account.id);
      await accP.deleteAccount(account.id);
      await txnP.loadTransactions();
      await accP.loadAccounts();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${account.name} ખાતું કાઢ્યું',
            style: const TextStyle(fontFamily: 'NotoSansGujarati'),
          ),
          backgroundColor: AppColors.expense,
        ),
      );
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

class _AccountsSummaryCard extends StatelessWidget {
  final String currency;
  final double totalNormalBalance;
  final double totalCcOutstanding;
  final double totalCcAvailable;

  const _AccountsSummaryCard({
    required this.currency,
    required this.totalNormalBalance,
    required this.totalCcOutstanding,
    required this.totalCcAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('🏦', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'કુલ બૅન્ક બેલેન્સ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'NotoSansGujarati',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$currency${fmt.format(totalNormalBalance)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'બૅન્ક, રોકડ, UPI અને અન્ય સામાન્ય ખાતાં',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontFamily: 'NotoSansGujarati',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryMiniCard(
                  icon: '💳',
                  title: 'કુલ કાર્ડ બાકી',
                  value: '$currency${fmt.format(totalCcOutstanding)}',
                  tint: AppColors.expense,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryMiniCard(
                  icon: '🏷️',
                  title: 'ઉપલબ્ધ limit',
                  value:
                      '$currency${fmt.format(math.max(totalCcAvailable, 0.0))}',
                  tint: AppColors.income,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMiniCard extends StatelessWidget {
  final String icon;
  final String title;
  final String value;
  final Color tint;

  const _SummaryMiniCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'NotoSansGujarati',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: tint,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: AppColors.primary.withOpacity(0.18),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

class _NormalAccountCard extends StatelessWidget {
  final AccountModel account;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NormalAccountCard({
    required this.account,
    required this.currency,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  String _fmtShort(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return NumberFormat('#,##0', 'en_IN').format(v);
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(account.color.replaceFirst('#', '0xFF')));

    return Consumer<TransactionProvider>(
      builder: (context, txnP, _) {
        final txns = txnP.getByAccount(account.id);
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
              border: Border.all(color: color.withOpacity(0.20), width: 1),
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
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          account.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: 'NotoSansGujarati',
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.10),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'બેલેન્સ: $currency${NumberFormat('#,##,##0.00', 'en_IN').format(account.balance)}',
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
                                child: const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
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
                                child: const Icon(
                                  Icons.delete,
                                  size: 14,
                                  color: AppColors.expense,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
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
                    Text(
                      '${txns.length} વ્યવહારો',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'NotoSansGujarati',
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CreditCardAccountCard extends StatelessWidget {
  final AccountModel account;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CreditCardAccountCard({
    required this.account,
    required this.currency,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(account.color.replaceFirst('#', '0xFF')));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.20), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  account.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'NotoSansGujarati',
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'બાકી: $currency${NumberFormat('#,##,##0.00', 'en_IN').format(account.outstandingAmount)}',
                    style: const TextStyle(
                      color: AppColors.expense,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Limit $currency${NumberFormat('#,##,##0.00', 'en_IN').format(account.creditLimit)}  •  ઉપલબ્ધ $currency${NumberFormat('#,##,##0.00', 'en_IN').format(math.max(account.availableLimit, 0.0))}',
                    style: TextStyle(
                      fontFamily: 'NotoSansGujarati',
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
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
                    child: const Icon(
                      Icons.edit,
                      size: 14,
                      color: AppColors.primary,
                    ),
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
                    child: const Icon(
                      Icons.delete,
                      size: 14,
                      color: AppColors.expense,
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
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade500,
                fontFamily: 'NotoSansGujarati',
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

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

    return Consumer<TransactionProvider>(
      builder: (context, txnP, _) {
        final txns = txnP.getByAccount(account.id)
          ..sort((a, b) => b.date.compareTo(a.date));

        final isCreditCard = account.isCreditCard;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          builder: (_, ctrl) => Column(
            children: [
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
                      child: Text(
                        account.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontFamily: 'NotoSansGujarati',
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            account.type.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontFamily: 'NotoSansGujarati',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      isCreditCard
                          ? 'બાકી: $currency${NumberFormat('#,##,##0.00', 'en_IN').format(account.outstandingAmount)}'
                          : 'બેલેન્સ: $currency${NumberFormat('#,##,##0.00', 'en_IN').format(account.balance)}',
                      style: TextStyle(
                        color: isCreditCard
                            ? AppColors.expense
                            : (account.balance >= 0
                                ? AppColors.income
                                : AppColors.expense),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCreditCard) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InfoPill(
                          label: 'Limit',
                          value:
                              '$currency${NumberFormat('#,##,##0.00', 'en_IN').format(account.creditLimit)}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoPill(
                          label: 'ઉપલબ્ધ',
                          value:
                              '$currency${NumberFormat('#,##,##0.00', 'en_IN').format(math.max(account.availableLimit, 0.0))}',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(height: 20),
              Expanded(
                child: txns.isEmpty
                    ? Center(
                        child: Text(
                          'કોઈ વ્યવહાર નથી',
                          style: TextStyle(
                            fontFamily: 'NotoSansGujarati',
                            color: Colors.grey.shade400,
                          ),
                        ),
                      )
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
      },
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'NotoSansGujarati',
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
