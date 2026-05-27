import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/account_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/settings_provider.dart';
import 'add_account_screen.dart';

class AccountsListScreen extends StatelessWidget {
  const AccountsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'બધા ખાતા',
          style: TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _goToAddAccount(context),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'ખાતું ઉમેરો',
          ),
        ],
      ),
      body: Consumer<AccountProvider>(
        builder: (ctx, provider, _) {
          final accounts = provider.activeAccounts;
          final cur = ctx.read<SettingsProvider>().currency;

          if (accounts.isEmpty) {
            return _buildEmptyState(ctx);
          }

          final grouped = {
            for (final type in AccountType.values)
              type: accounts.where((a) => a.type == type).toList(),
          };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCards(ctx, provider, cur),
              const SizedBox(height: 20),
              for (final type in AccountType.values)
                if (grouped[type]!.isNotEmpty) ...[
                  _GroupHeader(
                    icon: type.icon,
                    title: type.label,
                  ),
                  const SizedBox(height: 8),
                  ...grouped[type]!.map(
                    (acc) => _buildAccountTile(ctx, acc, cur, provider),
                  ),
                  const SizedBox(height: 16),
                ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    AccountProvider provider,
    String cur,
  ) {
    return Column(
      children: [
        _buildMainSummaryCard(
          context,
          title: 'કુલ બૅન્ક બેલેન્સ',
          value: '$cur${_fmt(provider.totalNormalBalance)}',
          subtitle: 'બૅન્ક, રોકડ, UPI અને અન્ય સામાન્ય ખાતાં',
          icon: '🏦',
          colors: const [AppColors.primary, AppColors.primaryDark],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMiniSummaryCard(
                context,
                title: 'કુલ કાર્ડ બાકી',
                value: '$cur${_fmt(provider.totalCcOutstanding)}',
                icon: '💳',
                color: AppColors.expense,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniSummaryCard(
                context,
                title: 'ઉપલબ્ધ limit',
                value: '$cur${_fmt(provider.totalCcAvailable)}',
                icon: '🏷️',
                color: AppColors.income,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required String icon,
    required List<Color> colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'NotoSansGujarati',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'NotoSansGujarati',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required String icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontFamily: 'NotoSansGujarati',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context,
    AccountModel acc,
    String cur,
    AccountProvider provider,
  ) {
    Color accColor;
    try {
      accColor = Color(int.parse(acc.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      accColor = AppColors.primary;
    }

    final isCc = acc.isCreditCard;
    final mainAmount = isCc ? acc.outstandingAmount : acc.balance;
    final mainLabel = isCc ? 'બાકી' : 'બેલેન્સ';

    final secondaryText = isCc
        ? 'Limit $cur${_fmt(acc.creditLimit)}  •  ઉપલબ્ધ $cur${_fmt(acc.availableLimit < 0 ? 0 : acc.availableLimit)}'
        : acc.type.label;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accColor.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                acc.icon,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  acc.name,
                  style: TextStyle(
                    color: accColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'NotoSansGujarati',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$mainLabel: $cur${_fmt(mainAmount)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  secondaryText,
                  style: TextStyle(
                    color: accColor.withOpacity(0.70),
                    fontSize: 10.5,
                    fontFamily: 'NotoSansGujarati',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _goToEditAccount(context, acc),
            icon: Icon(
              Icons.edit_rounded,
              color: accColor.withOpacity(0.80),
              size: 20,
            ),
            tooltip: 'ફેરફાર કરો',
          ),
          IconButton(
            onPressed: () =>
                _confirmDelete(context, provider, acc.id, acc.name),
            icon: Icon(
              Icons.delete_rounded,
              color: AppColors.expense.withOpacity(0.80),
              size: 20,
            ),
            tooltip: 'ભૂંસો',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Text(
              '🏦',
              style: TextStyle(fontSize: 48),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'કોઈ ખાતું નથી',
            style: TextStyle(
              fontFamily: 'NotoSansGujarati',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ઉપર + બટન દબાવી ખાતું ઉમેરો',
            style: TextStyle(
              fontFamily: 'NotoSansGujarati',
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _goToAddAccount(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'ખાતું ઉમેરો',
              style: TextStyle(fontFamily: 'NotoSansGujarati'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AccountProvider provider,
    String id,
    String name,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '🗑️ ખાતું ભૂંસો?',
          style: TextStyle(fontFamily: 'NotoSansGujarati'),
        ),
        content: Text(
          '"$name" ખાતું ભૂંસાઈ જશે.\nઆ ક્રિયા undo ન થઈ શકે!',
          style: const TextStyle(
            fontFamily: 'NotoSansGujarati',
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'રદ કરો',
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
              'ભૂંસો',
              style: TextStyle(fontFamily: 'NotoSansGujarati'),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await provider.deleteAccount(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"$name" ભૂંસાઈ ગયું ✅',
              style: const TextStyle(fontFamily: 'NotoSansGujarati'),
            ),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  void _goToAddAccount(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAccountScreen()),
    ).then((_) {
      context.read<AccountProvider>().loadAccounts();
    });
  }

  void _goToEditAccount(BuildContext context, AccountModel acc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAccountScreen(existing: acc),
      ),
    ).then((_) {
      context.read<AccountProvider>().loadAccounts();
    });
  }

  String _fmt(double amount) =>
      NumberFormat('#,##,##0.00', 'en_IN').format(amount.abs());
}

class _GroupHeader extends StatelessWidget {
  final String icon;
  final String title;

  const _GroupHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: AppColors.primary.withOpacity(0.2),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
