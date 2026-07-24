import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../../core/database/app_database.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import 'package:finara/features/categories/data/categories_provider.dart';

class AddCategoryDialog extends ConsumerStatefulWidget {
  final String type;

  const AddCategoryDialog({super.key, required this.type});

  @override
  ConsumerState<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends ConsumerState<AddCategoryDialog> {
  late TextEditingController _nameController;
  late String _selectedIcon;
  late int _selectedColor;

  List<String> _iconSuggestions = [];
  bool _isSearching = false;

  final List<String> _defaultEmojis = [
    '🏠', '🛒', '🚗', '🛍️', '🎬', '💡', '🏥', '📚', 
    '🏢', '💇', '👗', '✈️', '🛡️', '🎁', '📺', '💰', 
    '💻', '📊', '📈', '🔄', '🐶', '✨', '📌', '🎯'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedIcon = widget.type == 'expense' ? '📌' : '💰';
    _selectedColor = AppColors.categoryPalette[0].toARGB32();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchIconSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _iconSuggestions = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final res = await http.get(
        Uri.parse('https://api.iconify.design/search?query=$query&limit=15'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> iconsList = data['icons'] ?? [];
        
        final urls = iconsList.map((iconStr) {
          final parts = (iconStr as String).split(':');
          if (parts.length == 2) {
            return 'https://api.iconify.design/${parts[0]}/${parts[1]}.svg';
          }
          return null;
        }).whereType<String>().toList();

        if (mounted) {
          setState(() {
            _iconSuggestions = urls;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch icons: $e');
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Add ${widget.type == 'income' ? 'Income' : 'Expense'} Category',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g. Groceries',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search Icons Online',
                hintText: 'e.g. home, car, food',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) {
                _fetchIconSuggestions(val);
              },
            ),
            const SizedBox(height: 8),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Searching...', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            if (_iconSuggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _iconSuggestions.length,
                  itemBuilder: (context, index) {
                    final iconUrl = _iconSuggestions[index];
                    final isSelected = iconUrl == _selectedIcon;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIcon = iconUrl;
                        });
                        FocusScope.of(context).unfocus();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentViolet.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: AppColors.accentViolet)
                              : Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Center(
                          child: SvgPicture.network(
                            iconUrl,
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).iconTheme.color ?? Colors.black, 
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('Default Icons', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _defaultEmojis.map((emoji) {
                final isSelected = emoji == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = emoji),
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
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
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
                final isSelected = color.toARGB32() == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color.toARGB32()),
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;

            final dao = ref.read(categoriesDaoProvider);
            await dao.insertCategory(
              CategoriesCompanion(
                name: Value(name),
                type: Value(widget.type),
                icon: Value(_selectedIcon),
                color: Value(_selectedColor),
              ),
            );

            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
