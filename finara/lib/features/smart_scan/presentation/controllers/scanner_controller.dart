import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finara/features/smart_scan/domain/upi_parser.dart';
import 'package:finara/features/smart_scan/domain/ai_receipt_parser.dart';
import 'package:finara/features/transactions/data/transactions_provider.dart';
import 'package:finara/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:finara/features/settings/data/ai_provider.dart';
import 'package:finara/features/categories/data/categories_provider.dart';
import 'package:finara/features/accounts/data/accounts_provider.dart';
import 'package:finara/core/utils/logger.dart';

class ScannerController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ScannerController(this.ref) : super(const AsyncValue.data(null));

  Future<int?> processUpiQr(String qrData) async {
    final log = AppLogger.instance;
    log.info('processUpiQr called with QR data');
    
    final upiData = UpiParser.parseUri(qrData);
    if (upiData == null) {
      log.warning('Failed to parse UPI data from QR');
      return null;
    }

    log.info('Extracted UPI data: $upiData');

    // Launch UPI Intent
    try {
      final uri = Uri.parse(qrData);
      log.info('Attempting to launch UPI intent');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback for Android 11+ if canLaunchUrl fails due to package visibility
        log.info('canLaunchUrl returned false, attempting fallback launch');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      log.error('Failed to launch UPI intent', e);
    }

    final amountStr = upiData['am'] ?? '';
    final amount = double.tryParse(amountStr) ?? 0.0;
    final payee = upiData['pn'] ?? upiData['pa'] ?? 'UPI Transfer';

    log.info('Creating draft for UPI scan');
    // Create a draft transaction
    return await _createDraftTransaction(
      amount: amount,
      merchant: payee,
      note: 'UPI: $payee (${upiData['pa']})',
    );
  }

  Future<int?> processReceiptImage(String imagePath) async {
    final log = AppLogger.instance;
    log.info('processReceiptImage called for path: $imagePath');

    // 1. Extract text offline using ML Kit
    final text = await AIReceiptParser.extractTextFromImage(imagePath);
    if (text.isEmpty) {
      log.warning('No text could be extracted from image by ML Kit');
      return null;
    }

    log.info('Extracted text length: \${text.length}');

    // Check AI config
    final aiConfig = ref.read(aiConfigProvider);
    Map<String, dynamic> parsedData;

    if (aiConfig.isAiEnabled && aiConfig.groqApiKey.isNotEmpty) {
      log.info('Sending text to Groq for parsing');
      parsedData = await AIReceiptParser.parseWithGroq(text, aiConfig.groqApiKey);
    } else {
      log.info('Groq is disabled or API key missing, falling back to heuristics');
      parsedData = AIReceiptParser.parseWithHeuristics(text);
    }

    log.info('Parsed data result: $parsedData');

    final parsedAmount = (parsedData['amount'] as num?)?.toDouble() ?? 0.0;
    final parsedMerchant = parsedData['merchant']?.toString() ?? 'Receipt Scan';
    
    // Parse new fields
    final parsedCategory = parsedData['category']?.toString();
    final mealType = parsedData['meal_type']?.toString();
    final parsedNotes = parsedData['notes']?.toString();
    final itemsList = parsedData['items'] as List<dynamic>?;
    
    String finalNote = parsedMerchant != 'Receipt Scan' ? 'Receipt: $parsedMerchant' : 'Extracted from receipt';
    
    if (mealType != null && mealType.isNotEmpty) {
      finalNote += ' [$mealType]';
    }
    if (parsedNotes != null && parsedNotes.isNotEmpty) {
      finalNote += '\nNote: $parsedNotes';
    }
    
    if (itemsList != null && itemsList.isNotEmpty) {
      finalNote += '\n\nItems:';
      for (final item in itemsList) {
        if (item is Map) {
          final name = item['name'] ?? 'Item';
          final qty = item['qty'] ?? 1;
          final price = item['price'] ?? 0;
          finalNote += '\n- $name (x$qty) : $price';
        } else {
          finalNote += '\n- ${item.toString()}';
        }
      }
    }

    log.info('Creating draft for Receipt Image');
    return await _createDraftTransaction(
      amount: parsedAmount,
      merchant: parsedMerchant,
      note: finalNote,
      suggestedCategory: parsedCategory,
    );
  }

  Future<int> _createDraftTransaction({
    required double amount,
    required String merchant,
    required String note,
    String? suggestedCategory,
  }) async {
    final dao = ref.read(transactionsDaoProvider);
    final catDao = ref.read(categoriesDaoProvider);
    final accountDao = ref.read(accountsDaoProvider);
    final log = AppLogger.instance;

    log.info('Creating draft transaction for merchant: $merchant, amount: $amount');

    int? matchedCategoryId;
    final categories = await catDao.getAllCategories();
    
    // 1. Try matching suggested category from AI
    if (suggestedCategory != null && suggestedCategory.isNotEmpty) {
      final catLower = suggestedCategory.toLowerCase();
      for (final cat in categories) {
        if (cat.name.toLowerCase() == catLower || cat.name.toLowerCase().contains(catLower)) {
          matchedCategoryId = cat.id;
          log.info('Matched suggested category "$suggestedCategory" to ID: $matchedCategoryId');
          break;
        }
      }
    }
    
    // 2. Fallback to matching merchant name
    if (matchedCategoryId == null && merchant.isNotEmpty && merchant != 'Receipt Scan' && merchant != 'UPI Transfer') {
      final merchantLower = merchant.toLowerCase();
      for (final cat in categories) {
        if (merchantLower.contains(cat.name.toLowerCase()) || 
            cat.name.toLowerCase().contains(merchantLower)) {
          matchedCategoryId = cat.id;
          log.info('Matched merchant "$merchant" to category ID: $matchedCategoryId');
          break;
        }
      }
    }
    
    // Find the first available account to assign this draft to
    final accountsList = await accountDao.getAllAccounts();
    final targetAccountId = accountsList.isNotEmpty ? accountsList.first.id : 1;
    log.info('Using account ID: $targetAccountId for draft');

    // Create draft transaction using TransactionsCompanion
    final companion = TransactionsCompanion.insert(
      accountId: targetAccountId, 
      amount: amount,
      type: 'expense',
      date: DateTime.now(),
      categoryId: matchedCategoryId != null ? Value(matchedCategoryId) : const Value.absent(), 
      note: Value(note),
      isDraft: const Value(true), // Explicitly mark as draft
    );

    // Call raw insert because insertTransactionWithBalance handles balances
    // which we DO NOT want for drafts.
    final id = await dao.into(dao.transactions).insert(companion);
    log.info('Draft transaction created successfully with ID: $id');
    return id;
  }
}

final scannerControllerProvider = StateNotifierProvider<ScannerController, AsyncValue<void>>((ref) {
  return ScannerController(ref);
});
