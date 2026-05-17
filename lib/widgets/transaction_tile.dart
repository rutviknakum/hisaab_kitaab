import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../models/transaction_model.dart';
import '../providers/account_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../screens/transaction/add_transaction_screen.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final bool showDate;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.showDate = true,
  });

  String _fmt(double v) => NumberFormat('#,##,##0.00', 'en_IN').format(v);

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final cur = context.read<SettingsProvider>().currency;
    final account =
        context.read<AccountProvider>().getById(transaction.accountId);
    final colorScheme = Theme.of(context).colorScheme;

    return Slidable(
      key: ValueKey(transaction.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.42,
        children: [
          SlidableAction(
            onPressed: (_) => _edit(context),
            icon: Icons.edit_rounded,
            label: 'સુધારો',
            foregroundColor: Colors.white,
            backgroundColor: AppColors.income,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          SlidableAction(
            onPressed: (_) => _confirmDelete(context),
            icon: Icons.delete_rounded,
            label: 'કાઢો',
            foregroundColor: Colors.white,
            backgroundColor: AppColors.expense,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.08),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),

          // ── Leading: Category Icon ────────────
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isIncome ? AppColors.incomeLight : AppColors.expenseLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                transaction.category.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),

          // ── Title ─────────────────────────────
          title: Text(
            transaction.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'NotoSansGujarati',
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),

          // ── Subtitle ──────────────────────────
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category + Account
                Row(
                  children: [
                    Text(
                      transaction.category.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'NotoSansGujarati',
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    if (account != null) ...[
                      Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '${account.icon} ${account.name}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),

                // Date
                if (showDate) ...[
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(transaction.date),
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],

                // Note
                if (transaction.note != null &&
                    transaction.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '📝 ${transaction.note}',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'NotoSansGujarati',
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 2),
              ],
            ),
          ),

          // ── Trailing: Amount + Badge ──────────
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isIncome ? '+' : '-'}$cur ${_fmt(transaction.amount)}',
                style: TextStyle(
                  color: isIncome ? AppColors.income : AppColors.expense,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color:
                      isIncome ? AppColors.incomeLight : AppColors.expenseLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isIncome ? 'આવક' : 'ખર્ચ',
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'NotoSansGujarati',
                    fontWeight: FontWeight.w700,
                    color: isIncome ? AppColors.income : AppColors.expense,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Edit Transaction
  // ─────────────────────────────────────────────
  void _edit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          existing: transaction,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Delete with confirmation
  // ─────────────────────────────────────────────
  Future<void> _confirmDelete(BuildContext context) async {
    final txnP = context.read<TransactionProvider>();
    final accP = context.read<AccountProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '🗑️ નોંધ કાઢો?',
          style: TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'NotoSansGujarati',
              fontSize: 14,
              color: Colors.black87,
            ),
            children: [
              const TextSpan(text: '"'),
              TextSpan(
                text: transaction.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(
                text: '" ની નોંધ કાઢી નાખવી?\nઆ ક્રિયા undo ન થઈ શકે.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'ના',
              style: TextStyle(
                fontFamily: 'NotoSansGujarati',
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'હા, કાઢો',
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
      // Balance reverse:
      // expense delete → balance add back (isReverse = true)
      // income delete  → balance subtract (isReverse = false)
      await accP.adjustBalance(
        transaction.accountId,
        transaction.amount,
        transaction.type == TransactionType.expense,
      );
      await txnP.deleteTransaction(transaction.id);
    }
  }
}
