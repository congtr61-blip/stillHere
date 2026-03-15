import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart'; 
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

class CryptoService {
  static encrypt.Key _getKey(String uid) {
    final bytes = utf8.encode(uid);
    final digest = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  static final _iv = encrypt.IV.fromUtf8('STILLHERE_SECURE'); 

  static String encryptText(String text, String? uid) {
    if (text.isEmpty || uid == null) return "";
    if (text.length >= 24 && RegExp(r'^[a-zA-Z0-9+/]+={0,2}$').hasMatch(text)) return text; 
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_getKey(uid), mode: encrypt.AESMode.sic));
      return encrypter.encrypt(text, iv: _iv).base64;
    } catch (e) { return text; }
  }

  static String decryptText(String encryptedBase64, String? uid) {
    if (encryptedBase64.isEmpty || uid == null) return "...";
    
    try {
      final cleanInput = encryptedBase64.trim();
      
      // 1. 快速判定：如果长度太短或明显不是加密格式，直接返回原值（兼容旧的未加密数据）
      if (cleanInput.length < 20 || !RegExp(r'^[a-zA-Z0-9+/]+={0,2}$').hasMatch(cleanInput)) {
        return cleanInput;
      }

      final encrypter = encrypt.Encrypter(encrypt.AES(_getKey(uid), mode: encrypt.AESMode.sic));
      
      // 2. 解密执行
      return encrypter.decrypt64(cleanInput, iv: _iv);
      
    } catch (e) {
      // 3. 增强反馈：如果是账号归并期间 UID 还没对齐，提示用户
      debugPrint("解密失败 (UID: $uid): $e");
      return " [密文锁定: 身份校验中] "; 
    }
}
}