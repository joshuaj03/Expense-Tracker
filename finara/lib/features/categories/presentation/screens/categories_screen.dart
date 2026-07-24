import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/empty_state.dart';
import 'package:finara/features/categories/data/categories_provider.dart';
import '../widgets/add_category_dialog.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
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
    showDialog(
      context: context,
      builder: (ctx) => AddCategoryDialog(type: type),
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
          final type = _tabController.index == 0 ? 'expense' : 'income';
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
            icon: '📂',
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
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(cat.color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: cat.icon.startsWith('http')
                          ? (cat.icon.endsWith('.svg')
                              ? SvgPicture.network(
                                  cat.icon,
                                  width: 24,
                                  height: 24,
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(context).iconTheme.color ?? Colors.black,
                                    BlendMode.srcIn,
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: cat.icon,
                                    width: 24,
                                    height: 24,
                                    errorWidget: (c, u, e) => const Text(
                                      '📌',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ))
                          : Text(
                              cat.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                    ),
                  ),
                  title: Text(
                    cat.name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: cat.isSystem
                      ? Text('System', style: AppTypography.labelSmall)
                      : IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Category?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: AppColors.expense,
                                      ),
                                    ),
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
