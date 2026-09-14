import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finara/core/providers/providers.dart';
import 'package:finara/core/services/shared_prefs_provider.dart';

class AiConfig {
  final bool isAiEnabled;
  final String groqApiKey;

  const AiConfig({
    required this.isAiEnabled,
    required this.groqApiKey,
  });

  AiConfig copyWith({
    bool? isAiEnabled,
    String? groqApiKey,
  }) {
    return AiConfig(
      isAiEnabled: isAiEnabled ?? this.isAiEnabled,
      groqApiKey: groqApiKey ?? this.groqApiKey,
    );
  }
}

class AiConfigNotifier extends StateNotifier<AiConfig> {
  final SharedPreferences prefs;

  AiConfigNotifier(this.prefs)
      : super(AiConfig(
          isAiEnabled: prefs.getBool('isAiEnabled') ?? false,
          groqApiKey: prefs.getString('groqApiKey') ?? '',
        ));

  void setAiEnabled(bool value) {
    prefs.setBool('isAiEnabled', value);
    state = state.copyWith(isAiEnabled: value);
  }

  void setGroqApiKey(String key) {
    prefs.setString('groqApiKey', key);
    state = state.copyWith(groqApiKey: key);
  }
}

final aiConfigProvider = StateNotifierProvider<AiConfigNotifier, AiConfig>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AiConfigNotifier(prefs);
});
