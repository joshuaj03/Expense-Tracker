import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/shared_prefs_provider.dart';

part 'ui_preferences_provider.g.dart';

@Riverpod(keepAlive: true)
class SideBySideTransactionUINotifier
    extends _$SideBySideTransactionUINotifier {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('side_by_side_txn_ui') ?? false;
  }

  void setSideBySide(bool isSideBySide) {
    state = isSideBySide;
    ref
        .read(sharedPreferencesProvider)
        .setBool('side_by_side_txn_ui', isSideBySide);
  }
}

@Riverpod(keepAlive: true)
class EnableSplitAndSettleNotifier extends _$EnableSplitAndSettleNotifier {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    // Enabled by default
    return prefs.getBool('enable_split_and_settle') ?? true;
  }

  void setEnabled(bool isEnabled) {
    state = isEnabled;
    ref
        .read(sharedPreferencesProvider)
        .setBool('enable_split_and_settle', isEnabled);
  }
}
