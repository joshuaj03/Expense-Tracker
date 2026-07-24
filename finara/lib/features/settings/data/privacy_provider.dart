import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/shared_prefs_provider.dart';

part 'privacy_provider.g.dart';

@Riverpod(keepAlive: true)
class HideOnlyTotalBalanceNotifier extends _$HideOnlyTotalBalanceNotifier {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('hide_only_total') ?? false;
  }

  void setHideOnlyTotal(bool hideOnlyTotal) {
    state = hideOnlyTotal;
    ref
        .read(sharedPreferencesProvider)
        .setBool('hide_only_total', hideOnlyTotal);
  }
}
