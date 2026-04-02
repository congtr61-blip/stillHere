import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart'; 
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

class CryptoService {
  // 使用更强的密钥派生方式：带盐的 PBKDF2-like 实现
  static encrypt.Key _getKey(String uid) {
    // 使用 UID 作为主要输入，添加固定盐值以提高安全性
    const String pepper = 'stillhere-crypto-pepper-v1';
    final input = utf8.encode('$uid:$pepper');
    
    // 进行多轮哈希以增加密钥派生的强度
    var hash = sha256.convert(input);
    for (int i = 0; i < 10000; i++) {
      hash = sha256.convert([...hash.bytes, ...input]);
    }
    
    return encrypt.Key(Uint8List.fromList(hash.bytes));
  }

  // 固定 IV，实际环境中建议为每条记录生成独立 IV
  static final _iv = encrypt.IV.fromUtf8('STILLHERE_SECURE'); 

  // 生成数据完整性校验码（HMAC）
  static String _generateHmac(String text, String uid) {
    final key = utf8.encode('$uid:stillhere-hmac-key');
    final bytes = utf8.encode(text);
    return Hmac(sha256, key).convert(bytes).toString();
  }

  // 验证数据完整性
  static bool _verifyHmac(String text, String hmac, String uid) {
    final expectedHmac = _generateHmac(text, uid);
    return expectedHmac == hmac;
  }

  static String encryptText(String text, String? uid) {
    if (text.isEmpty || uid == null) return "";
    
    // 如果已经是加密数据格式，直接返回（防止重复加密）
    if (text.length >= 24 && RegExp(r'^[a-zA-Z0-9+/|]+={0,2}$').hasMatch(text)) {
      return text;
    }
    
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_getKey(uid), mode: encrypt.AESMode.sic));
      final encrypted = encrypter.encrypt(text, iv: _iv).base64;
      
      // 计算 HMAC 用于完整性验证
      final hmac = _generateHmac(encrypted, uid);
      
      // 格式: encrypted_base64|hmac_hex
      return '$encrypted|${hmac.substring(0, 16)}';
    } catch (e) {
      debugPrint("加密错误 (UID: $uid): $e");
      return text;
    }
  }

  static String decryptText(String encryptedBase64, String? uid) {
    if (encryptedBase64.isEmpty || uid == null) return "...";
    
    try {
      final cleanInput = encryptedBase64.trim();
      
      // 1. 快速判定：如果长度太短或不符合加密格式，直接返回原值（兼容未加密数据）
      if (cleanInput.length < 20 || !RegExp(r'^[a-zA-Z0-9+/|=]+$').hasMatch(cleanInput)) {
        return cleanInput;
      }

      // 2. 分离加密数据和 HMAC
      final parts = cleanInput.split('|');
      if (parts.isEmpty) {
        return cleanInput;
      }

      final encryptedData = parts[0];
      final providedHmac = parts.length > 1 ? parts[1] : '';

      // 3. 验证完整性（如果存在 HMAC）
      if (providedHmac.isNotEmpty) {
        if (!_verifyHmac(encryptedData, providedHmac, uid)) {
          debugPrint("❌ 完整性校验失败 (UID: $uid) - 数据可能已损坏或被篡改");
          return " [⚠️ 数据验证失败：请重新获取] ";
        }
      }

      // 4. 执行解密
      final encrypter = encrypt.Encrypter(encrypt.AES(_getKey(uid), mode: encrypt.AESMode.sic));
      return encrypter.decrypt64(encryptedData, iv: _iv);
      
    } catch (e) {
      debugPrint("❌ 解密失败 (UID: $uid): $e");
      return " [⚠️ 密文锁定：身份校验中] ";
    }
  }

  // 用于验证数据来源的签名函数（可选，用于增强安全性）
  static String generateSignature(String data, String uid) {
    final key = utf8.encode('$uid:stillhere-signature-key');
    final bytes = utf8.encode(data);
    return Hmac(sha256, key).convert(bytes).toString().substring(0, 32);
  }

  // 验证数据签名
  static bool verifySignature(String data, String signature, String uid) {
    return generateSignature(data, uid) == signature;
  }
}