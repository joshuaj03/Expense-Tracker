/// Bottom sheet for selecting a category.
library;

import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';

class CategoryPickerSheet extends StatefulWidget {
  final List<Category> categories;
  final int? selectedId;
  final String transactionType; // 'income' or 'expense'

  const CategoryPickerSheet({
    super.key,
    required this.categories,
    this.selectedId,
    required this.transactionType,
  });

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  String _search = '';

  List<Category> get _filtered {
    final base = widget.categories
        .where((c) => c.type == widget.transactionType)
        .toList();
    if (_search.isEmpty) return base;
    return base
        .where(
            (c) => c.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title + search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
                Text('Select Category',
                    style: AppTypography.headlineSmall),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkCard
                        : AppColors.lightCard,
                  ),
                ),
              ],
            ),
          ),
          // Category grid
          Flexible(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final cat = _filtered[index];
                final isSelected = cat.id == widget.selectedId;

                return GestureDetector(
                  onTap: () => Navigator.pop(context, cat),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(cat.color).withValues(alpha: 0.15)
                          : isDark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected
                          ? Border.all(
                              color: Color(cat.color), width: 1.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(cat.icon,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 6),
                        Text(
                          cat.name,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? Color(cat.color)
                                : null,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : null,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
