import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 加个锁，防止重复点击触发 Future already completed
  bool _isSigningIn = false;

  // 手机号验证相关
  String? _verificationId;
  int? _forceResendingToken;
  
  // reCAPTCHA 相关
  bool _recaptchaInitialized = false;

  Stream<User?> get userChanges => _auth.userChanges();
  
  /// 初始化 reCAPTCHA（Web 平台必需）
  Future<void> initializeRecaptcha() async {
    if (!kIsWeb) {
      debugPrint("📱 非 Web 平台，无需初始化 reCAPTCHA");
      return;
    }
    
    if (_recaptchaInitialized) {
      debugPrint("✅ reCAPTCHA 已初始化");
      return;
    }
    
    try {
      debugPrint("🔐 正在初始化 reCAPTCHA...");
      
      // 设置 reCAPTCHA 验证器
      await _auth.setSettings(
        appVerificationDisabledForTesting: false,
      );
      
      // 针对 Web 平台，设置 persistence 为 LOCAL
      await _auth.setPersistence(Persistence.LOCAL);
      
      _recaptchaInitialized = true;
      debugPrint("✅ reCAPTCHA 初始化成功");
    } catch (e) {
      debugPrint("⚠️ reCAPTCHA 初始化警告: $e");
      debugPrint("💡 提示: 这在开发环境中可能是正常的");
      // 不抛出异常，继续执行
    }
  }
  
  /// 禁用 reCAPTCHA（用于开发/测试）
  void disableRecaptchaForTesting() {
    if (kIsWeb) {
      debugPrint("🔓 禁用 reCAPTCHA（仅用于测试）");
      _auth.setSettings(appVerificationDisabledForTesting: true);
    }
  }
  
  /// 启用 reCAPTCHA
  void enableRecaptcha() {
    if (kIsWeb) {
      debugPrint("🔐 启用 reCAPTCHA");
      _auth.setSettings(appVerificationDisabledForTesting: false);
    }
  }

  // ==================== Google 登录 ====================
  
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
      
      // 初始化用户文档
      await _initializeUserDocument(result.user!);
      
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

  // ==================== 手机号登录 ====================

  /// 发送验证码到指定手机号
  Future<void> sendPhoneVerificationCode(String phoneNumber) async {
    try {
      debugPrint("📱 正在向 $phoneNumber 发送验证码...");
      
      // Web 平台需要初始化 reCAPTCHA
      if (kIsWeb) {
        debugPrint("🌐 Web 平台检测到，确保 reCAPTCHA 正确配置");
        await initializeRecaptcha();
      }
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(minutes: 2),
        verificationCompleted: (PhoneAuthCredential credential) {
          // 自动验证（某些情况下）
          debugPrint("✅ 自动验证完成");
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint("❌ 验证失败: Code=${e.code}");
          debugPrint("   Message: ${e.message}");
          
          if (e.code == 'invalid-app-verifier') {
            debugPrint("🔴 reCAPTCHA 验证失败！");
            debugPrint("   原因：reCAPTCHA token 无效或已过期");
            debugPrint("   解决方案：");
            debugPrint("   1. 检查 Firebase Console 中的 reCAPTCHA 配置");
            debugPrint("   2. 确保域名在 reCAPTCHA 白名单中");
            debugPrint("   3. 对于本地开发，添加 localhost 和 127.0.0.1");
            debugPrint("   4. 在测试环境，可以禁用 reCAPTCHA 检查");
          }
          
          throw e;
        },
        codeSent: (String verificationId, int? forceResendingToken) {
          _verificationId = verificationId;
          _forceResendingToken = forceResendingToken;
          debugPrint("✅ 验证码已发送到 $phoneNumber");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          debugPrint("⏱️ 自动验证超时（2分钟）");
        },
      );
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ 发送验证码失败:");
      debugPrint("   Code: ${e.code}");
      debugPrint("   Message: ${e.message}");
      debugPrint("   详细信息: ${e.toString()}");
      
      _logRecaptchaError(e);
      
      rethrow;
    } catch (e) {
      debugPrint("❌ 未知错误: $e");
      rethrow;
    }
  }

  /// 使用验证码登录
  Future<UserCredential?> signInWithPhoneNumber(String smsCode) async {
    try {
      if (_verificationId == null) {
        throw Exception("验证ID不存在，请重新发送验证码");
      }

      debugPrint("🔐 正在用验证码登录...");
      
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      final result = await _auth.signInWithCredential(credential);
      
      debugPrint("✅ 手机号登录成功！");
      
      // 初始化用户文档
      await _initializeUserDocument(result.user!);
      
      // 清空验证ID
      _verificationId = null;
      _forceResendingToken = null;
      
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ 登录失败: Code=${e.code}, Message=${e.message}");
      rethrow;
    }
  }

  /// 重新发送验证码
  Future<void> resendPhoneVerificationCode(String phoneNumber) async {
    try {
      debugPrint("🔄 重新发送验证码...");
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: _forceResendingToken,
        timeout: const Duration(minutes: 2),
        verificationCompleted: (PhoneAuthCredential credential) {
          debugPrint("✅ 自动验证完成");
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint("❌ 验证失败: ${e.message}");
          throw e;
        },
        codeSent: (String verificationId, int? forceResendingToken) {
          _verificationId = verificationId;
          _forceResendingToken = forceResendingToken;
          debugPrint("✅ 验证码已重新发送");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ 重新发送失败: ${e.message}");
      rethrow;
    }
  }

  // ==================== 邮箱和手机号绑定管理 ====================

  /// 绑定邮箱 - 包含验证和账号链接逻辑
  Future<Map<String, dynamic>> bindEmail(String email) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("用户未登录");

      debugPrint("📧 正在绑定邮箱: $email");
      
      // 尝试更新邮箱
      try {
        await user.updateEmail(email);
        
        // 发送验证邮件
        await user.sendEmailVerification();
        
        // 保存到 Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'email': email,
          'emailVerified': false,
          'emailUpdatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint("✅ 邮箱绑定成功，验证邮件已发送");
        return {
          'success': true,
          'message': '邮箱绑定成功，验证邮件已发送',
          'status': 'email_sent',
        };
      } on FirebaseAuthException catch (e) {
        // 邮箱已被使用的情况
        if (e.code == 'email-already-in-use') {
          debugPrint("⚠️ 邮箱已被使用，需要进行账号链接");
          debugPrint("   建议：使用该邮箱登录后，系统会自动链接账户");
          
          return {
            'success': false,
            'message': '该邮箱已被使用',
            'status': 'email_already_in_use',
            'code': e.code,
            'email': email,
          };
        }
        
        // 需要验证新邮箱
        if (e.code == 'requires-recent-login') {
          debugPrint("🔐 需要最近的登录状态，请重新登录");
          
          return {
            'success': false,
            'message': '安全原因，请重新登录后重试',
            'status': 'requires_recent_login',
            'code': e.code,
          };
        }
        
        debugPrint("❌ 邮箱绑定失败: ${e.message}");
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ 绑定邮箱异常: ${e.message}");
      rethrow;
    }
  }

  /// 检查邮箱是否已被使用（在绑定前检查）
  Future<bool> isEmailInUse(String email) async {
    try {
      debugPrint("🔍 检查邮箱 $email 是否已被使用...");
      
      // 使用 fetchSignInMethodsForEmail 来检查邮箱是否存在
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      
      final isInUse = methods.isNotEmpty;
      if (isInUse) {
        debugPrint("✓ 邮箱已被注册，使用方式: $methods");
      } else {
        debugPrint("✓ 邮箱未被使用");
      }
      
      return isInUse;
    } catch (e) {
      debugPrint("⚠️ 检查邮箱使用状态失败: $e");
      return false;
    }
  }

  /// 获取邮箱验证状态
  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // 刷新用户信息以获取最新的验证状态
      await user.reload();
      return user.emailVerified;
    } catch (e) {
      debugPrint("⚠️ 获取邮箱验证状态失败: $e");
      return false;
    }
  }

  /// 重新发送邮箱验证链接
  Future<void> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("用户未登录");

      debugPrint("📧 正在发送邮箱验证链接...");
      await user.sendEmailVerification();
      debugPrint("✅ 验证邮件已发送到 ${user.email}");
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ 发送验证邮件失败: ${e.message}");
      rethrow;
    }
  }

  /// 使用邮箱凭证链接现有账户
  /// 用于实现账号合并（当邮箱已被使用时）
  Future<Map<String, dynamic>> linkEmailCredential(
    String email,
    String password,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("用户未登录");

      debugPrint("🔗 正在链接邮箱凭证到当前账户...");
      debugPrint("   当前UID: ${currentUser.uid}");
      debugPrint("   邮箱: $email");

      // 使用邮箱和密码创建凭证
      final emailCredential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      // 链接到当前账户
      await currentUser.linkWithCredential(emailCredential);

      // 更新 Firestore
      await _firestore.collection('users').doc(currentUser.uid).update({
        'email': email,
        'emailVerified': false,
        'linkedEmails': FieldValue.arrayUnion([email]),
        'emailUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ 邮箱已成功链接到当前账户");
      
      // 发送验证邮件
      await currentUser.sendEmailVerification();

      return {
        'success': true,
        'message': '邮箱已链接到当前账户，验证邮件已发送',
        'status': 'linked_success',
      };
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ 邮箱链接失败: ${e.message}");
      
      if (e.code == 'provider-already-linked') {
        return {
          'success': false,
          'message': '该邮箱凭证已链接',
          'status': 'provider_already_linked',
          'code': e.code,
        };
      }
      
      if (e.code == 'credential-already-in-use') {
        return {
          'success': false,
          'message': '该邮箱已与其他账户关联',
          'status': 'credential_in_use',
          'code': e.code,
        };
      }

      rethrow;
    }
  }

  /// 检查邮箱是否为当前用户的登录邮箱
  /// 用于确定是否可以进行账号合并
  Future<Map<String, dynamic>> checkEmailStatus(String email) async {
    try {
      debugPrint("🔍 检查邮箱状态: $email");
      
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      
      if (methods.isEmpty) {
        // 邮箱未被使用
        debugPrint("✓ 邮箱未被使用，可以直接绑定");
        return {
          'available': true,
          'status': 'available',
          'methods': [],
        };
      } else {
        // 邮箱已被使用，显示使用方式
        debugPrint("✓ 邮箱已被注册，登录方式: $methods");
        return {
          'available': false,
          'status': 'in_use',
          'methods': methods,
          'hint': '此邮箱已被使用。${methods.contains('password') ? '您可以使用邮箱和密码链接此账户。' : '请使用其他登录方式链接此账户。'}',
        };
      }
    } catch (e) {
      debugPrint("⚠️ 检查邮箱状态失败: $e");
      return {
        'available': false,
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// 绑定手机号
  Future<void> bindPhoneNumber(String phoneNumber) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("用户未登录");

      debugPrint("📱 正在绑定手机号: $phoneNumber");
      
      // 发送验证码
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(minutes: 2),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await user.linkWithCredential(credential);
          debugPrint("✅ 手机号自动验证并绑定成功");
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint("❌ 手机号验证失败: ${e.message}");
          throw e;
        },
        codeSent: (String verificationId, int? forceResendingToken) {
          _verificationId = verificationId;
          _forceResendingToken = forceResendingToken;
          debugPrint("✅ 验证码已发送");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ 手机号绑定失败: ${e.message}");
      rethrow;
    }
  }

  /// 完成手机号绑定（输入验证码后调用）
  Future<void> confirmPhoneNumberBinding(String smsCode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("用户未登录");
      if (_verificationId == null) throw Exception("验证ID不存在");

      debugPrint("🔐 正在验证手机号...");
      
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      // 从 credentials 中提取手机号
      String? phoneNumber = credential.signInMethod == 'phone' 
          ? credential.toString().split('phoneNumber=').last.split(',').first 
          : null;

      await user.linkWithCredential(credential);

      // 保存到 Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'phoneNumber': user.phoneNumber ?? phoneNumber,
        'phoneNumberVerified': true,
        'phoneNumberUpdatedAt': FieldValue.serverTimestamp(),
      });

      // 清空验证ID
      _verificationId = null;
      _forceResendingToken = null;

      debugPrint("✅ 手机号绑定成功");
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ 手机号验证失败: ${e.message}");
      rethrow;
    }
  }

  /// 获取用户的联系方式信息
  Future<Map<String, dynamic>> getUserContactInfo(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return {
          'email': null,
          'emailVerified': false,
          'phoneNumber': null,
          'phoneNumberVerified': false,
        };
      }

      return {
        'email': doc.data()?['email'],
        'emailVerified': doc.data()?['emailVerified'] ?? false,
        'phoneNumber': doc.data()?['phoneNumber'],
        'phoneNumberVerified': doc.data()?['phoneNumberVerified'] ?? false,
      };
    } catch (e) {
      debugPrint("❌ 获取联系方式信息失败: $e");
      return {
        'email': null,
        'emailVerified': false,
        'phoneNumber': null,
        'phoneNumberVerified': false,
      };
    }
  }

  /// 解绑邮箱
  Future<void> unbindEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("用户未登录");

      // 从 Firestore 中删除邮箱
      await _firestore.collection('users').doc(user.uid).update({
        'email': FieldValue.delete(),
        'emailVerified': FieldValue.delete(),
      });

      debugPrint("✅ 邮箱已解绑");
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ 邮箱解绑失败: ${e.message}");
      rethrow;
    }
  }

  /// 解绑手机号
  Future<void> unbindPhoneNumber() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("用户未登录");

      // 从 Firestore 中删除手机号
      await _firestore.collection('users').doc(user.uid).update({
        'phoneNumber': FieldValue.delete(),
        'phoneNumberVerified': FieldValue.delete(),
      });

      debugPrint("✅ 手机号已解绑");
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ 手机号解绑失败: ${e.message}");
      rethrow;
    }
  }

  // ==================== 工具方法 ====================

  /// 记录 reCAPTCHA 相关的错误
  void _logRecaptchaError(FirebaseAuthException e) {
    if (e.code.contains('app-verifier') || 
        e.message?.contains('reCAPTCHA') == true ||
        e.message?.contains('invalid application verifier') == true) {
      debugPrint("\n🔴 === reCAPTCHA 错误诊断 ===");
      debugPrint("错误代码: ${e.code}");
      debugPrint("错误信息: ${e.message}");
      debugPrint("\n可能的原因:");
      debugPrint("1. reCAPTCHA Enterprise 未在 Firebase 中启用");
      debugPrint("2. reCAPTCHA 密钥配置不正确");
      debugPrint("3. 当前域名未添加到 reCAPTCHA 白名单");
      debugPrint("4. reCAPTCHA token 已过期（有效期 2 分钟）");
      debugPrint("\n解决步骤:");
      debugPrint("✅ 方案 A（推荐开发环境）:");
      debugPrint("   在 firebase.json 中配置本地测试:");
      debugPrint("   按照 RECAPTCHA_SETUP.md 中的步骤");
      debugPrint("\n✅ 方案 B（生产环境）:");
      debugPrint("   1. Firebase Console → Authentication → App verification");
      debugPrint("   2. 启用 reCAPTCHA Enterprise");
      debugPrint("   3. Google Cloud Console 配置 reCAPTCHA 密钥");
      debugPrint("   4. 将域名添加到允许列表");
      debugPrint("========================\n");
    }
  }

  /// 初始化用户文档（首次登录时调用）
  Future<void> _initializeUserDocument(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // 新用户，创建文档
        await docRef.set({
          'uid': user.uid,
          'email': user.email,
          'emailVerified': user.emailVerified,
          'phoneNumber': user.phoneNumber,
          'phoneNumberVerified': false,
          'displayName': user.displayName,
          'photoUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        debugPrint("✅ 已创建新用户文档");
      } else {
        // 既有用户，更新最后登录时间
        await docRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("⚠️ 初始化用户文档失败: $e");
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}