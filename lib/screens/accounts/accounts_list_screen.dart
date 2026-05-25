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

          // ── Dynamic Group by AccountType (all types auto-included) ──
          final grouped = {
            for (final type in AccountType.values)
              type: accounts.where((a) => a.type == type).toList(),
          };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Total Balance Card ──
              _buildTotalCard(ctx, provider.totalBalance, cur),
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

  // ─────────────────────────────────────────────
  //  Total Balance Card
  // ─────────────────────────────────────────────
  Widget _buildTotalCard(BuildContext context, double total, String cur) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text('🏦', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'કુલ રકમ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'NotoSansGujarati',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$cur${_fmt(total)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Account Tile
  // ─────────────────────────────────────────────
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // ── Icon ──
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accColor.withValues(alpha: 0.12),
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

          // ── Name, Balance, Type ──
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
                  '$cur${_fmt(acc.balance)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  acc.type.label,
                  style: TextStyle(
                    color: accColor.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontFamily: 'NotoSansGujarati',
                  ),
                ),
              ],
            ),
          ),

          // ── Edit ──
          IconButton(
            onPressed: () => _showEditSheet(context, acc, provider),
            icon: Icon(
              Icons.edit_rounded,
              color: accColor.withValues(alpha: 0.8),
              size: 20,
            ),
            tooltip: 'Edit',
          ),

          // ── Delete ──
          IconButton(
            onPressed: () =>
                _confirmDelete(context, provider, acc.id, acc.name),
            icon: Icon(
              Icons.delete_rounded,
              color: AppColors.expense.withValues(alpha: 0.8),
              size: 20,
            ),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Empty State
  // ─────────────────────────────────────────────
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
                  borderRadius: BorderRadius.circular(12)),
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

  // ─────────────────────────────────────────────
  //  Edit Bottom Sheet
  // ─────────────────────────────────────────────
  void _showEditSheet(
    BuildContext context,
    AccountModel acc,
    AccountProvider provider,
  ) {
    final nameCtrl = TextEditingController(text: acc.name);
    final balanceCtrl =
        TextEditingController(text: acc.balance.toStringAsFixed(2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${acc.icon} ખાતું Edit',
              style: const TextStyle(
                fontFamily: 'NotoSansGujarati',
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),

            // Name
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'ખાતાનું નામ',
                labelStyle: TextStyle(fontFamily: 'NotoSansGujarati'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_rounded),
              ),
            ),
            const SizedBox(height: 12),

            // Balance
            TextField(
              controller: balanceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'બાકી રકમ',
                labelStyle: TextStyle(fontFamily: 'NotoSansGujarati'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Save
            ElevatedButton(
              onPressed: () {
                final newName = nameCtrl.text.trim();
                final newBalance =
                    double.tryParse(balanceCtrl.text) ?? acc.balance;
                if (newName.isEmpty) return;

                final updated = acc.copyWith(
                  name: newName,
                  balance: newBalance,
                );
                provider.updateAccount(updated);
                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'ખાતું update થઈ ગયું ✅',
                      style: TextStyle(fontFamily: 'NotoSansGujarati'),
                    ),
                    backgroundColor: AppColors.income,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'સાચવો',
                style: TextStyle(
                  fontFamily: 'NotoSansGujarati',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Delete Confirmation
  // ─────────────────────────────────────────────
  Future<void> _confirmDelete(
    BuildContext context,
    AccountProvider provider,
    String id,
    String name,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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

  // ─────────────────────────────────────────────
  //  Navigate to AddAccountScreen
  // ─────────────────────────────────────────────
  void _goToAddAccount(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAccountScreen()),
    ).then((_) {
      context.read<AccountProvider>().loadAccounts();
    });
  }

  // ─────────────────────────────────────────────
  //  Format Amount
  // ─────────────────────────────────────────────
  String _fmt(double amount) =>
      NumberFormat('#,##,##0.00', 'en_IN').format(amount.abs());
}

// ─────────────────────────────────────────────────────────────
//  Group Header Widget
// ─────────────────────────────────────────────────────────────
class _GroupHeader extends StatelessWidget {
  final String icon;
  final String title;
  const _GroupHeader({required this.icon, required this.title});

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
            color: AppColors.primary.withValues(alpha: 0.2),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
