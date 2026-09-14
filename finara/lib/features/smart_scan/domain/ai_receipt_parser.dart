import 'dart:convert';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

class AIReceiptParser {
  /// Extracts text from an image using ML Kit (Offline)
  static Future<String> extractTextFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } finally {
      textRecognizer.close();
    }
  }

  /// Redacts potential PII (like 16 digit card numbers)
  static String redactPII(String text) {
    // Redact 16-digit card numbers with optional spaces or dashes
    final cardRegex = RegExp(r'\b(?:\d[ -]*?){13,16}\b');
    return text.replaceAll(cardRegex, '[REDACTED_CARD_NUMBER]');
  }

  /// Parses text using basic heuristic fallback
  static Map<String, dynamic> parseWithHeuristics(String text) {
    double? amount;
    String? merchant;

    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.length > 2).toList();
    
    // Filter out common receipt garbage to find the real merchant name
    final garbageRegex = RegExp(r'(cashier|tel:|phone|tax|invoice|bill|date|time|gst|number|#)', caseSensitive: false);
    for (final line in lines) {
      if (!garbageRegex.hasMatch(line) && !RegExp(r'^\d+$').hasMatch(line)) {
        merchant = line;
        break;
      }
    }

    // Try to find the largest currency-looking number
    final amountRegex = RegExp(r'(?:(?:Rs\.?|INR|₹)\s*)?(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)');
    final matches = amountRegex.allMatches(text);
    
    double maxAmt = 0;
    for (final match in matches) {
      final numStr = match.group(1)?.replaceAll(',', '') ?? '0';
      final val = double.tryParse(numStr) ?? 0;
      if (val > maxAmt) {
        maxAmt = val;
      }
    }
    
    if (maxAmt > 0) amount = maxAmt;

    return {
      'merchant': merchant,
      'amount': amount,
    };
  }

  /// Parses text using Groq API LLM (Opt-in)
  static Future<Map<String, dynamic>> parseWithGroq(String text, String apiKey) async {
    print('--- MLKIT RAW EXTRACTED TEXT ---');
    print(text);
    print('--------------------------------');

    final redactedText = redactPII(text);
    
    final prompt = '''
Extract the following information from this OCR receipt text and return ONLY a valid JSON object.
If the text appears to be random alphanumeric characters or unreadable, do your best to extract a merchant name or default to "Receipt Scan". 
Keys must be:
- "merchant" (string, the name of the store or shop. Ignore tax numbers like GSTIN, single letters, phone numbers, or "CASHIER")
- "amount" (number, the total final amount paid. Ignore sub-totals or tax amounts)
- "date" (string, YYYY-MM-DD format, optional)
- "category" (string, guess the general expense category like "Food", "Groceries", "Transport", "Shopping", "Medical", etc.)
- "items" (array of objects, where each object has "name" (string), "qty" (number), and "price" (number). Extract this if the receipt is itemized)
- "meal_type" (string, optional. If it's a food or restaurant expense and time is visible, guess if it is "BREAKFAST", "LUNCH", "DINNER", or "SNACKS")
- "notes" (string, optional. Any other relevant info like payment method, order number, or table number)

Text:
$redactedText
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {'role': 'system', 'content': 'You are a helpful assistant that extracts receipt data into strict JSON.'},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.1,
          'response_format': {'type': 'json_object'}
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final content = body['choices'][0]['message']['content'];
        print('--- GROQ PARSED JSON ---');
        print(content);
        print('------------------------');
        return jsonDecode(content);
      } else {
        print('Groq API returned error: \${response.statusCode} - \${response.body}');
      }
    } catch (e) {
      print('Groq API error: $e');
    }
    return parseWithHeuristics(redactedText);
  }
}
