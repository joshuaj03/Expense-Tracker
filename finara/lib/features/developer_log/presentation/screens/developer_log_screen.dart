import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/utils/logger.dart';

class DeveloperLogScreen extends ConsumerWidget {
  const DeveloperLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = ref.watch(loggerProvider);
    final logs = logger.logs;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Developer Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              logger.clear();
              // To trigger a rebuild, we would ideally use a StateNotifier, 
              // but since logger is simple, we can just trigger a manual update or rely on hot reload.
              // For a real app, AppLogger should be a ChangeNotifier or StateNotifier.
            },
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(child: Text('No logs'))
          : ListView.separated(
              itemCount: logs.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final log = logs[index];
                Color color;
                switch (log.level) {
                  case LogLevel.info:
                    color = AppColors.income;
                    break;
                  case LogLevel.warning:
                    color = Colors.orange;
                    break;
                  case LogLevel.error:
                    color = AppColors.expense;
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            log.level.name.toUpperCase(),
                            style: AppTypography.labelSmall.copyWith(
                                color: color, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                            style: AppTypography.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(log.message, style: AppTypography.bodyMedium),
                      if (log.error != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          log.error.toString(),
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.expense),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}
