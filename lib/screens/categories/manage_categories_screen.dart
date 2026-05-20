import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/app_category_model.dart';
import '../../providers/category_provider.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'કેટેગરી મેનેજ કરો',
          style: TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: '📈 આવક'),
            Tab(text: '📉 ખર્ચ'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'નવી કેટેગરી',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, catP, _) {
          if (catP.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final incomeCategories = catP.byType('income');
          final expenseCategories = catP.byType('expense');

          return TabBarView(
            controller: _tabController,
            children: [
              _CategoryList(
                categories: incomeCategories,
                onEdit: _showAddEditSheet,
                onDelete: _deleteCategory,
              ),
              _CategoryList(
                categories: expenseCategories,
                onEdit: _showAddEditSheet,
                onDelete: _deleteCategory,
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddEditSheet([AppCategoryModel? category]) {
    final isEdit = category != null;

    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final emojiCtrl = TextEditingController(text: category?.emoji ?? '📁');
    String selectedType =
        category?.type ?? (_tabController.index == 0 ? 'income' : 'expense');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEdit ? 'કેટેગરી એડિટ કરો' : 'નવી કેટેગરી ઉમેરો',
                    style: const TextStyle(
                      fontFamily: 'NotoSansGujarati',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: emojiCtrl,
                    decoration: InputDecoration(
                      labelText: 'ઈમોજી',
                      hintText: 'જેમ કે 💼 / 🍔 / 🚗',
                      labelStyle:
                          const TextStyle(fontFamily: 'NotoSansGujarati'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'NotoSansGujarati',
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'કેટેગરી નામ',
                      hintText: 'જેમ કે પગાર, પેટ્રોલ, દવા',
                      labelStyle:
                          const TextStyle(fontFamily: 'NotoSansGujarati'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'NotoSansGujarati',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedType = 'income'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedType == 'income'
                                  ? AppColors.income.withValues(alpha: 0.10)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selectedType == 'income'
                                    ? AppColors.income
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '📈 આવક',
                                style: TextStyle(
                                  fontFamily: 'NotoSansGujarati',
                                  fontWeight: FontWeight.w700,
                                  color: selectedType == 'income'
                                      ? AppColors.income
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedType = 'expense'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedType == 'expense'
                                  ? AppColors.expense.withValues(alpha: 0.10)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selectedType == 'expense'
                                    ? AppColors.expense
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '📉 ખર્ચ',
                                style: TextStyle(
                                  fontFamily: 'NotoSansGujarati',
                                  fontWeight: FontWeight.w700,
                                  color: selectedType == 'expense'
                                      ? AppColors.expense
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final emoji = emojiCtrl.text.trim().isEmpty
                            ? '📁'
                            : emojiCtrl.text.trim();

                        if (name.isEmpty) return;

                        try {
                          final provider = context.read<CategoryProvider>();

                          if (isEdit) {
                            await provider.updateCategory(
                              id: category.id,
                              name: name,
                              emoji: emoji,
                              type: selectedType,
                            );
                          } else {
                            await provider.addCategory(
                              name: name,
                              emoji: emoji,
                              type: selectedType,
                            );
                          }

                          if (!mounted) return;
                          Navigator.pop(sheetContext);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEdit
                                    ? 'કેટેગરી અપડેટ થઈ ગઈ'
                                    : 'નવી કેટેગરી ઉમેરાઈ ગઈ',
                                style: const TextStyle(
                                  fontFamily: 'NotoSansGujarati',
                                ),
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'ભૂલ: $e',
                                style: const TextStyle(
                                  fontFamily: 'NotoSansGujarati',
                                ),
                              ),
                              backgroundColor: AppColors.expense,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isEdit ? 'અપડેટ કરો' : 'ઉમેરો',
                        style: const TextStyle(
                          fontFamily: 'NotoSansGujarati',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCategory(AppCategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'કેટેગરી કાઢવી છે?',
          style: TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '"${category.name}" કાઢી નાખવી છે?',
          style: const TextStyle(
            fontFamily: 'NotoSansGujarati',
          ),
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

    if (confirm == true && mounted) {
      await context.read<CategoryProvider>().deleteCategory(category.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'કેટેગરી કાઢી નાખી',
            style: TextStyle(fontFamily: 'NotoSansGujarati'),
          ),
        ),
      );
    }
  }
}

class _CategoryList extends StatelessWidget {
  final List<AppCategoryModel> categories;
  final void Function(AppCategoryModel category) onEdit;
  final void Function(AppCategoryModel category) onDelete;

  const _CategoryList({
    required this.categories,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Text(
          'કોઈ કેટેગરી નથી',
          style: TextStyle(
            fontFamily: 'NotoSansGujarati',
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontFamily: 'NotoSansGujarati',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.isDefault ? 'ડિફોલ્ટ' : 'કસ્ટમ',
                      style: TextStyle(
                        fontFamily: 'NotoSansGujarati',
                        fontSize: 11,
                        color: category.isDefault
                            ? AppColors.primary
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => onEdit(category),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: () => onDelete(category),
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.expense.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
