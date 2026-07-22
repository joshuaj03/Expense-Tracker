import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/empty_state.dart';
import '../../../../core/providers/providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() =>
      _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog(String type) {
    final nameController = TextEditingController();
    String selectedIcon = type == 'expense' ? '📌' : '💰';
    int selectedColor = AppColors.categoryPalette[0].toARGB32();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Add ${type == 'income' ? 'Income' : 'Expense'} Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g. Groceries',
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                Text('Icon', style: AppTypography.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    '🍕', '🛒', '🚗', '🛍️', '🎬', '💡', '🏥', '📚',
                    '🏠', '💇', '👗', '✈️', '🛡️', '🎁', '📺', '💰',
                    '💻', '📊', '📈', '🔄', '🏦', '✨', '📌', '🎯',
                  ].map((emoji) {
                    final isSelected = emoji == selectedIcon;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedIcon = emoji),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentViolet.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: AppColors.accentViolet)
                              : null,
                        ),
                        child: Center(
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Color', style: AppTypography.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppColors.categoryPalette.take(12).map((color) {
                    final isSelected = color.toARGB32() == selectedColor;
                    return GestureDetector(
                      onTap: () => setDialogState(
                          () => selectedColor = color.toARGB32()),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final dao = ref.read(categoriesDaoProvider);
                await dao.insertCategory(CategoriesCompanion(
                  name: Value(name),
                  type: Value(type),
                  icon: Value(selectedIcon),
                  color: Value(selectedColor),
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentViolet,
          labelColor: AppColors.accentViolet,
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final type =
              _tabController.index == 0 ? 'expense' : 'income';
          _showAddCategoryDialog(type);
        },
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryList(type: 'expense', ref: ref),
          _CategoryList(type: 'income', ref: ref),
        ],
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final String type;
  final WidgetRef ref;

  const _CategoryList({required this.type, required this.ref});

  @override
  Widget build(BuildContext context) {
    final dao = ref.watch(categoriesDaoProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<Category>>(
      stream: dao.watchCategoriesByType(type),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const EmptyState(
            icon: '📁',
            title: 'No categories',
            subtitle: 'Tap + to add a category',
          );
        }

        final categories = snapshot.data!;
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: isDark
                    ? AppColors.darkCard
                    : AppColors.lightCard,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          Color(cat.color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(cat.icon,
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  title: Text(cat.name,
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  trailing: cat.isSystem
                      ? Text('System',
                          style: AppTypography.labelSmall)
                      : IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20),
                          onPressed: () async {
                            final confirm =
                                await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title:
                                    const Text('Delete Category?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('Delete',
                                        style: TextStyle(
                                            color:
                                                AppColors.expense)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              ref
                                  .read(categoriesDaoProvider)
                                  .deleteCategory(cat.id);
                            }
                          },
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
