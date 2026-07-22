/// Itemized notes widget â€” structured list with SL, Item, Qty, Price columns.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';

class ItemEntry {
  String item;
  double qty;
  double price;

  ItemEntry({this.item = '', this.qty = 1, this.price = 0});

  double get total => qty * price;

  @override
  String toString() => '$item Ã— $qty = ₹${price.toStringAsFixed(2)}';
}

class ItemizedNotes extends StatefulWidget {
  final List<ItemEntry> items;
  final ValueChanged<double> onTotalChanged;

  const ItemizedNotes({
    super.key,
    required this.items,
    required this.onTotalChanged,
  });

  @override
  State<ItemizedNotes> createState() => _ItemizedNotesState();
}

class _ItemizedNotesState extends State<ItemizedNotes> {
  void _addRow() {
    setState(() {
      widget.items.add(ItemEntry());
    });
  }

  void _removeRow(int index) {
    setState(() {
      widget.items.removeAt(index);
      _notifyTotal();
    });
  }

  void _notifyTotal() {
    final total =
        widget.items.fold<double>(0, (sum, e) => sum + e.total);
    widget.onTotalChanged(total);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total =
        widget.items.fold<double>(0, (sum, e) => sum + e.total);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accentViolet.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                SizedBox(
                    width: 30,
                    child: Text('SL',
                        style: AppTypography.labelSmall
                            .copyWith(fontWeight: FontWeight.w700))),
                Expanded(
                    flex: 3,
                    child: Text('Item',
                        style: AppTypography.labelSmall
                            .copyWith(fontWeight: FontWeight.w700))),
                SizedBox(
                    width: 45,
                    child: Text('Qty',
                        style: AppTypography.labelSmall
                            .copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center)),
                Expanded(
                    flex: 2,
                    child: Text('Price',
                        style: AppTypography.labelSmall
                            .copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.right)),
                const SizedBox(width: 28),
              ],
            ),
          ),

          // Item rows
          ...List.generate(widget.items.length, (index) {
            final entry = widget.items[index];
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // SL number
                  SizedBox(
                    width: 30,
                    child: Text('${index + 1}',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center),
                  ),
                  // Item name
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Item',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                      ),
                      style: AppTypography.bodySmall,
                      onChanged: (v) {
                        entry.item = v;
                      },
                      controller:
                          TextEditingController(text: entry.item),
                    ),
                  ),
                  // Qty
                  SizedBox(
                    width: 45,
                    child: TextField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                      ),
                      style: AppTypography.bodySmall,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      textAlign: TextAlign.center,
                      onChanged: (v) {
                        entry.qty = double.tryParse(v) ?? 1;
                        setState(() {});
                        _notifyTotal();
                      },
                      controller: TextEditingController(
                          text: entry.qty == 1
                              ? '1'
                              : entry.qty.toString()),
                    ),
                  ),
                  // Price
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                      ),
                      style: AppTypography.bodySmall,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      textAlign: TextAlign.right,
                      onChanged: (v) {
                        entry.price = double.tryParse(v) ?? 0;
                        setState(() {});
                        _notifyTotal();
                      },
                      controller: TextEditingController(
                          text: entry.price > 0
                              ? entry.price.toString()
                              : ''),
                    ),
                  ),
                  // Delete button
                  SizedBox(
                    width: 28,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _removeRow(index),
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Add row button
          InkWell(
            onTap: _addRow,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 18, color: AppColors.accentViolet),
                  const SizedBox(width: 6),
                  Text('Add item',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.accentViolet)),
                ],
              ),
            ),
          ),

          // Total row
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accentViolet.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(
                  CurrencyFormatter.format(total),
                  style: AppTypography.currencySmall.copyWith(
                    color: AppColors.accentViolet,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Converts itemized list to text for notes storage.
String itemizedToText(List<ItemEntry> items) {
  final buffer = StringBuffer();
  for (int i = 0; i < items.length; i++) {
    final e = items[i];
    if (e.item.isNotEmpty) {
      buffer.writeln('${i + 1}. ${e.item} Ã— ${e.qty} = ₹${e.price.toStringAsFixed(2)}');
    }
  }
  final total = items.fold<double>(0, (s, e) => s + e.total);
  buffer.writeln('Total: ₹${total.toStringAsFixed(2)}');
  return buffer.toString().trim();
}
