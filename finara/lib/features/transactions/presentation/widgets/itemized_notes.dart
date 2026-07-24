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
  String toString() => '$item Ã— $qty = \u20B9${price.toStringAsFixed(2)}';
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
    final total = widget.items.fold<double>(0, (sum, e) => sum + e.total);
    widget.onTotalChanged(total);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.fold<double>(0, (sum, e) => sum + e.total);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentViolet.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    'SL',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Item',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 45,
                  child: Text(
                    'Qty',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Price',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 28),
              ],
            ),
          ),

          // Item rows
          ...List.generate(widget.items.length, (index) {
            final entry = widget.items[index];
            return _ItemRow(
              key: ObjectKey(entry),
              index: index,
              entry: entry,
              onChanged: _notifyTotal,
              onDelete: () => _removeRow(index),
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
                  Icon(
                    Icons.add_circle_outline,
                    size: 18,
                    color: AppColors.accentViolet,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Add item',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.accentViolet,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Total row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accentViolet.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
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

class _ItemRow extends StatefulWidget {
  final int index;
  final ItemEntry entry;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _ItemRow({
    super.key,
    required this.index,
    required this.entry,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  late TextEditingController _itemCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _itemCtrl = TextEditingController(text: widget.entry.item);
    _qtyCtrl = TextEditingController(
      text: widget.entry.qty == 1 ? '1' : widget.entry.qty.toString(),
    );
    _priceCtrl = TextEditingController(
      text: widget.entry.price > 0 ? widget.entry.price.toString() : '',
    );
  }

  @override
  void dispose() {
    _itemCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // SL number
          SizedBox(
            width: 30,
            child: Text(
              '${widget.index + 1}',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          // Item name
          Expanded(
            flex: 3,
            child: TextField(
              controller: _itemCtrl,
              decoration: const InputDecoration(
                hintText: 'Item',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
              ),
              style: AppTypography.bodySmall,
              onChanged: (v) {
                widget.entry.item = v;
                widget.onChanged();
              },
            ),
          ),
          // Qty
          SizedBox(
            width: 45,
            child: TextField(
              controller: _qtyCtrl,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
              ),
              style: AppTypography.bodySmall,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              onChanged: (v) {
                widget.entry.qty = double.tryParse(v) ?? 1;
                widget.onChanged();
              },
            ),
          ),
          // Price
          Expanded(
            flex: 2,
            child: TextField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                hintText: '0',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
              ),
              style: AppTypography.bodySmall,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.right,
              onChanged: (v) {
                widget.entry.price = double.tryParse(v) ?? 0;
                widget.onChanged();
              },
            ),
          ),
          // Delete button
          SizedBox(
            width: 28,
            child: IconButton(
              icon: const Icon(Icons.close, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: widget.onDelete,
              color: AppColors.expense,
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
      buffer.writeln(
        '${i + 1}. ${e.item} - ${e.qty} = ₹${e.price.toStringAsFixed(2)}',
      );
    }
  }
  final total = items.fold<double>(0, (s, e) => s + e.total);
  buffer.writeln('\nTotal: ₹${total.toStringAsFixed(2)}');
  return buffer.toString().trim();
}
