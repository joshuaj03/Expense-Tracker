import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart';

import 'logger.dart';

/// Decrypts MyMoney .mbak backup files natively.
class MbakDecryptor {
  static const String _appPassword = "my_money_password";
  // The raw base64 salt from the python script: "my_money_salt"
  // It has 13 chars, so we pad it to a multiple of 4: "my_money_salt==="
  static const String _appSaltB64 = "my_money_salt===";

  static Future<String> decrypt(File file) async {
    final log = AppLogger.instance;
    log.backup('MbakDecryptor: Starting decryption of ${file.path}');

    final raw = (await file.readAsString()).trim();
    final parts = raw.split(':');
    if (parts.length != 3) {
      throw FormatException(
        'Expected iv:mac:ciphertext, got ${parts.length} parts',
      );
    }

    final ivBytes = base64.decode(parts[0]);
    final macBytes = base64.decode(parts[1]);
    final ciphertextBytes = base64.decode(parts[2]);

    final keys = _deriveKeys();
    final aesKey = keys.sublist(0, 16);
    final hmacKey = keys.sublist(16, 48);

    // Verify MAC
    final hmac = Hmac(sha256, hmacKey);
    final payloadToMac = Uint8List.fromList([...ivBytes, ...ciphertextBytes]);
    final computedMac = hmac.convert(payloadToMac).bytes;

    bool macMatches = true;
    if (computedMac.length != macBytes.length) {
      macMatches = false;
    } else {
      for (int i = 0; i < computedMac.length; i++) {
        if (computedMac[i] != macBytes[i]) {
          macMatches = false;
          break;
        }
      }
    }

    if (!macMatches) {
      log.error(
        'MbakDecryptor: MAC mismatch. File may be corrupted or not a valid .mbak file.',
      );
      throw FormatException('MAC mismatch - invalid backup file');
    }

    // Decrypt AES/CBC/PKCS7
    final key = enc.Key(Uint8List.fromList(aesKey));
    final iv = enc.IV(Uint8List.fromList(ivBytes));
    final encrypter = enc.Encrypter(
      enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7'),
    );

    try {
      final decrypted = encrypter.decrypt(
        enc.Encrypted(Uint8List.fromList(ciphertextBytes)),
        iv: iv,
      );
      log.backup(
        'MbakDecryptor: Successfully decrypted ${decrypted.length} characters',
      );
      return decrypted;
    } catch (e, st) {
      log.error('MbakDecryptor: Failed to decrypt ciphertext', e, st);
      throw Exception('Failed to decrypt data: $e');
    }
  }

  static Uint8List _deriveKeys() {
    final salt = base64.decode(_appSaltB64);
    final passwordBytes = Uint8List.fromList(utf8.encode(_appPassword));

    // PBKDF2WithHmacSHA1, 10000 iterations, 384-bit (48 byte) output
    final derivator = PBKDF2KeyDerivator(
      HMac(SHA1Digest(), 64),
    ); // block size of SHA-1 is 64
    derivator.init(Pbkdf2Parameters(salt, 10000, 48));
    return derivator.process(passwordBytes);
  }
}
