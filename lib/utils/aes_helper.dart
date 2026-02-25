import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

class AESHelper {
  // 32 bytes key (AES-256)
  static const String _secretKey = "12345678901234567890123456789012";

  static IV _generateIV() {
    final random = Random.secure();

    // Convert to Uint8List (IMPORTANT)
    final ivBytes = Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );

    return IV(ivBytes);
  }

  static String encryptText(String plainText) {
    final key = Key.fromUtf8(_secretKey);
    final iv = _generateIV();

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // ivBase64:cipherBase64
    return "${iv.base64}:${encrypted.base64}";
  }

  static String decryptText(String encryptedText) {
    final key = Key.fromUtf8(_secretKey);

    final parts = encryptedText.split(":");
    if (parts.length != 2) {
      throw Exception("Invalid encrypted text format");
    }

    final iv = IV.fromBase64(parts[0]);
    final cipherText = Encrypted.fromBase64(parts[1]);

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    return encrypter.decrypt(cipherText, iv: iv);
  }
}
