import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/shared_prefs_provider.dart';

part 'theme_provider.g.dart';

@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt('theme_mode') ?? 0;
  }

  void setMode(int mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setInt('theme_mode', mode);
  }
}
