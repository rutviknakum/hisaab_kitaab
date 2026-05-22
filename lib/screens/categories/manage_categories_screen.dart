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

  String get _currentType => _tabController.index == 0 ? 'income' : 'expense';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
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
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: '📈 આવક'),
            Tab(text: '📉 ખર્ચ'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        extendedPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'નવી કેટેગરી',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w700,
            fontSize: 14,
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
                emptyText: 'આવક માટે કોઈ કેટેગરી નથી',
                onEdit: _showAddEditSheet,
                onDelete: _deleteCategory,
              ),
              _CategoryList(
                categories: expenseCategories,
                emptyText: 'ખર્ચ માટે કોઈ કેટેગરી નથી',
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

    String selectedType = category?.type ?? _currentType;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> submit() async {
              final name = nameCtrl.text.trim();
              final emoji =
                  emojiCtrl.text.trim().isEmpty ? '📁' : emojiCtrl.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'કેટેગરી નામ લખો',
                      style: TextStyle(fontFamily: 'NotoSansGujarati'),
                    ),
                    backgroundColor: AppColors.expense,
                  ),
                );
                return;
              }

              setSheetState(() => isSaving = true);

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
                      isEdit ? 'કેટેગરી અપડેટ થઈ ગઈ' : 'નવી કેટેગરી ઉમેરાઈ ગઈ',
                      style: const TextStyle(fontFamily: 'NotoSansGujarati'),
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                setSheetState(() => isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'ભૂલ: $e',
                      style: const TextStyle(fontFamily: 'NotoSansGujarati'),
                    ),
                    backgroundColor: AppColors.expense,
                  ),
                );
              }
            }

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  emojiCtrl.text.isEmpty
                                      ? '📁'
                                      : emojiCtrl.text,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isEdit
                                    ? 'કેટેગરી એડિટ કરો'
                                    : 'નવી કેટેગરી ઉમેરો',
                                style: const TextStyle(
                                  fontFamily: 'NotoSansGujarati',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: emojiCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'ઈમોજી',
                            hintText: 'જેમ કે 💼 / 🍔 / 🚗',
                            labelStyle:
                                const TextStyle(fontFamily: 'NotoSansGujarati'),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.35),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'NotoSansGujarati',
                            fontSize: 22,
                          ),
                          onChanged: (_) => setSheetState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: nameCtrl,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'કેટેગરી નામ',
                            hintText: 'જેમ કે પગાર, પેટ્રોલ, દવા',
                            labelStyle:
                                const TextStyle(fontFamily: 'NotoSansGujarati'),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.35),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'NotoSansGujarati',
                            fontSize: 14,
                          ),
                          onSubmitted: (_) => submit(),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _TypeOption(
                                  text: '📈 આવક',
                                  selected: selectedType == 'income',
                                  activeColor: AppColors.income,
                                  onTap: () => setSheetState(
                                    () => selectedType = 'income',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _TypeOption(
                                  text: '📉 ખર્ચ',
                                  selected: selectedType == 'expense',
                                  activeColor: AppColors.expense,
                                  onTap: () => setSheetState(
                                    () => selectedType = 'expense',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isEdit ? 'અપડેટ કરો' : 'ઉમેરો',
                                    style: const TextStyle(
                                      fontFamily: 'NotoSansGujarati',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
  final String emptyText;
  final void Function(AppCategoryModel category) onEdit;
  final void Function(AppCategoryModel category) onDelete;

  const _CategoryList({
    required this.categories,
    required this.emptyText,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Text(
          emptyText,
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
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
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: category.isDefault
                            ? AppColors.primary.withValues(alpha: 0.10)
                            : Colors.grey.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category.isDefault ? 'ડિફોલ્ટ' : 'કસ્ટમ',
                        style: TextStyle(
                          fontFamily: 'NotoSansGujarati',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: category.isDefault
                              ? AppColors.primary
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => onEdit(category),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                ),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => onDelete(category),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.expense.withValues(alpha: 0.08),
                ),
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.expense.withValues(alpha: 0.90),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String text;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeOption({
    required this.text,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? activeColor : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'NotoSansGujarati',
              fontWeight: FontWeight.w700,
              color: selected ? activeColor : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
