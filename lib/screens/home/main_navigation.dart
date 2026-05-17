import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../home/home_screen.dart';
import '../transaction/transaction_list_screen.dart';
import '../transaction/add_transaction_screen.dart';
import '../ledger/ledger_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    TransactionListScreen(),
    LedgerScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'App બંધ કરો?',
              style: TextStyle(fontFamily: 'NotoSansGujarati'),
            ),
            content: const Text(
              'હિસાબ કિતાબ બંધ કરવી છે?',
              style: TextStyle(fontFamily: 'NotoSansGujarati'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'ના',
                  style: TextStyle(fontFamily: 'NotoSansGujarati'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx, true);
                  SystemNavigator.pop();
                },
                child: const Text(
                  'હા, બંધ કરો',
                  style: TextStyle(
                    color: AppColors.expense,
                    fontFamily: 'NotoSansGujarati',
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    iconOutline: Icons.home_outlined,
                    label: AppStrings.get('home'),
                    index: 0,
                    current: _currentIndex,
                    onTap: () => setState(() => _currentIndex = 0),
                  ),
                  _NavItem(
                    icon: Icons.receipt_rounded,
                    iconOutline: Icons.receipt_outlined,
                    label: AppStrings.get('transactions'),
                    index: 1,
                    current: _currentIndex,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  _AddButton(
                    onTap: () => _showAddBottomSheet(context),
                  ),
                  _NavItem(
                    icon: Icons.bar_chart_rounded,
                    iconOutline: Icons.bar_chart_outlined,
                    label: AppStrings.get('reports'),
                    index: 3,
                    current: _currentIndex,
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                  _NavItem(
                    icon: Icons.settings_rounded,
                    iconOutline: Icons.settings_outlined,
                    label: AppStrings.get('settings'),
                    index: 4,
                    current: _currentIndex,
                    onTap: () => setState(() => _currentIndex = 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Single handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'શું ઉમેરવું છે?',
              style: TextStyle(
                fontFamily: 'NotoSansGujarati',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // ── આવક ──
                Expanded(
                  child: _AddOptionCard(
                    iconWidget: Icon(
                      Icons.trending_up_rounded,
                      color: AppColors.income,
                      size: 32,
                    ),
                    label: 'આવક',
                    color: AppColors.income,
                    bgColor: AppColors.incomeLight,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddTransactionScreen(
                            // ✅ FIX 1: String → TransactionType enum
                            initialType: TransactionType.income,
                          ),
                        ),
                      ).then((_) {
                        if (mounted) {
                          context
                              .read<TransactionProvider>()
                              .loadTransactions();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // ── ખર્ચ ──
                Expanded(
                  child: _AddOptionCard(
                    iconWidget: Icon(
                      Icons.trending_down_rounded,
                      color: AppColors.expense,
                      size: 32,
                    ),
                    label: 'ખર્ચ',
                    color: AppColors.expense,
                    bgColor: AppColors.expenseLight,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddTransactionScreen(
                            // ✅ FIX 1: String → TransactionType enum
                            initialType: TransactionType.expense,
                          ),
                        ),
                      ).then((_) {
                        if (mounted) {
                          context
                              .read<TransactionProvider>()
                              .loadTransactions();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // ── ઉધાર ──
                Expanded(
                  child: _AddOptionCard(
                    iconWidget: Text(
                      '🤝',
                      style: TextStyle(fontSize: 30),
                    ),
                    label: 'ઉધાર',
                    color: AppColors.accent,
                    bgColor: AppColors.accentLight,
                    onTap: () {
                      Navigator.pop(ctx);
                      // ✅ FIX 2: AddLoanScreen(personId) error → tab switch
                      setState(() => _currentIndex = 2);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Nav Item ───────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData iconOutline;
  final String label;
  final int index;
  final int current;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.iconOutline,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == current;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? icon : iconOutline,
              color: isSelected
                  ? AppColors.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'NotoSansGujarati',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Center Add Button ──────────────────────────
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

// ── Add Option Card ────────────────────────────
class _AddOptionCard extends StatelessWidget {
  final Widget iconWidget;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _AddOptionCard({
    required this.iconWidget,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontFamily: 'NotoSansGujarati',
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
