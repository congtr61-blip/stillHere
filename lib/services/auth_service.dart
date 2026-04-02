import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // 加个锁，防止重复点击触发 Future already completed
  bool _isSigningIn = false;

  Stream<User?> get userChanges => _auth.userChanges();

  Future<UserCredential?> signInWithGoogle() async {
    if (_isSigningIn) return null; // 如果正在登录，直接拦截
    _isSigningIn = true;

    try {
      // Web 端有时需要先登出一下以确保清除之前的状态残留
      if (await _googleSignIn.isSignedIn()) {
        try {
          await _googleSignIn.signOut();
        } catch (e) {
          debugPrint("SignOut warning: $e");
        }
      }

      debugPrint("🔐 开始 Google Sign-In 流程...");
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint("⚠️ Google Sign-In 被用户取消或失败");
        _isSigningIn = false;
        return null;
      }

      debugPrint("✅ Google Sign-In 成功，正在获取认证信息...");
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint("🔄 正在使用 Firebase 认证...");
      
      final result = await _auth.signInWithCredential(credential);
      
      debugPrint("✅ Firebase 认证成功！用户: ${result.user?.email}");
      _isSigningIn = false;
      
      return result;
    } on FirebaseAuthException catch (e) {
      _isSigningIn = false;
      
      debugPrint("❌ Firebase Auth Error:");
      debugPrint("   Code: ${e.code}");
      debugPrint("   Message: ${e.message}");
      
      // 特殊处理 OAuth 配置错误
      if (e.code == 'invalid-credential') {
        debugPrint("💡 提示: 检查 Firebase & Google Cloud OAuth 配置");
        debugPrint("   1. Firebase Console: https://console.firebase.google.com/project/stillhere-ad395/authentication/providers");
        debugPrint("   2. 确保已添加这些 URIs:");
        debugPrint("      - https://stillhere-ad395.web.app");
        debugPrint("      - https://stillhere-ad395.web.app/__/auth/callback");
      }
      
      rethrow;
    } catch (e) {
      _isSigningIn = false;
      
      debugPrint("❌ Google Auth Error: $e");
      
      // 检查是否为常见的 redirect_uri_mismatch 错误
      if (e.toString().contains('redirect_uri_mismatch') || 
          e.toString().contains('CONFIGURATION_NOT_FOUND')) {
        debugPrint("🔴 发现 OAuth 配置错误！");
        debugPrint("   请按照以下步骤修复:");
        debugPrint("   1. 访问: FIX_OAUTH_ERROR.md");
        debugPrint("   2. 配置 Firebase Google 提供者");
        debugPrint("   3. 配置 Google Cloud OAuth 同意屏幕");
        debugPrint("   4. 更新 OAuth Credentials");
      }
      
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}