import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/logger.dart';
import '../../../../core/database/enums.dart';
import '../data/accounts_provider.dart';

part 'credit_card_service.g.dart';

@Riverpod(keepAlive: true)
CreditCardService creditCardService(CreditCardServiceRef ref) {
  return CreditCardService(ref);
}

class CreditCardService {
  final Ref _ref;
  final _log = AppLogger.instance;
  bool _initialized = false;

  CreditCardService(this._ref);

  Future<void> generateMissingBills() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final dao = _ref.read(accountsDaoProvider);
      final accounts = await dao.getAllAccounts();
      final creditCards = accounts
          .where(
            (a) =>
                a.type == AccountType.creditCard.name &&
                a.billGenerationDay != null,
          )
          .toList();

      if (creditCards.isEmpty) return;

      final now = DateTime.now();

      for (final card in creditCards) {
        final billDay = card.billGenerationDay!;

        // Check current month
        final currentGenDate = DateTime(now.year, now.month, billDay);
        if (now.isAfter(currentGenDate) ||
            now.isAtSameMomentAs(currentGenDate)) {
          await dao.generateBillIfNotExists(card.id, now.month, now.year);
        }

        // Check previous month
        final prevMonth = now.month == 1 ? 12 : now.month - 1;
        final prevYear = now.month == 1 ? now.year - 1 : now.year;

        await dao.generateBillIfNotExists(card.id, prevMonth, prevYear);
      }
    } catch (e, st) {
      _log.error('Failed to generate credit card bills', e, st);
    }
  }
}
