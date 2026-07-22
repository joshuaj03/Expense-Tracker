import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/daos/transactions_dao.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/amount_text.dart';
import '../../../../core/design_system/widgets/empty_state.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_formatter.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dao = ref.watch(transactionsDaoProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search transactions...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          style: AppTypography.bodyLarge,
          onChanged: (value) {
            setState(() => _query = value.trim());
          },
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? const EmptyState(
              icon: '🔍',
              title: 'Search your records',
              subtitle:
                  'Search by notes, categories, or account names',
            )
          : StreamBuilder<List<TransactionWithDetails>>(
              stream: dao.searchTransactions(_query),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptyState(
                    icon: '🤷',
                    title: 'No results found',
                    subtitle: 'Try a different search term',
                  );
                }

                final results = snapshot.data!;
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final txn = results[index];
                    final t = txn.transaction;
                    final isIncome = t.type == 'income';
                    final isTransfer = t.type == 'transfer';
                    final icon = isTransfer
                        ? '🔄'
                        : (txn.categoryIcon ?? '📌');
                    final title = isTransfer
                        ? '${txn.accountName} → ${txn.toAccountName ?? '?'}'
                        : (txn.categoryName ?? 'Uncategorized');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Material(
                        color: isDark
                            ? AppColors.darkCard
                            : AppColors.lightCard,
                        borderRadius:
                            BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Color(txn.categoryColor ??
                                          0xFF6C63FF)
                                      .withValues(alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(icon,
                                      style: const TextStyle(
                                          fontSize: 20)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(title,
                                        style: AppTypography
                                            .bodyMedium
                                            .copyWith(
                                                fontWeight:
                                                    FontWeight
                                                        .w600)),
                                    if (t.note.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(t.note,
                                          style: AppTypography
                                              .bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow
                                              .ellipsis),
                                    ],
                                    const SizedBox(height: 2),
                                    Text(
                                      '${txn.accountName} • ${DateFormatter.relative(t.date)}',
                                      style:
                                          AppTypography.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                              AmountText(
                                amount: isIncome
                                    ? t.amount
                                    : -t.amount,
                                size: AmountSize.small,
                                colored: !isTransfer,
                                overrideColor: isTransfer
                                    ? AppColors.transfer
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
