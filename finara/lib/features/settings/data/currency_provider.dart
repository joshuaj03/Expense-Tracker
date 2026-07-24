import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/shared_prefs_provider.dart';

import '../../../../core/utils/currency_formatter.dart';

final currencyNotifierProvider =
    StateNotifierProvider<CurrencyNotifier, String>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return CurrencyNotifier(prefs);
    });

class CurrencyNotifier extends StateNotifier<String> {
  final _prefs;
  static const _key = 'app_currency';

  CurrencyNotifier(this._prefs) : super(_prefs.getString(_key) ?? '₹') {
    CurrencyFormatter.symbol = state;
  }

  Future<void> setCurrency(String currency) async {
    state = currency;
    CurrencyFormatter.symbol = currency;
    await _prefs.setString(_key, currency);
  }
}
