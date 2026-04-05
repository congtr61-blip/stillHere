import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

import 'package:stillhere/screens/login_page.dart';
import 'package:stillhere/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 配置 reCAPTCHA（Web 平台）
  if (kIsWeb) {
    debugPrint("🌐 Web 平台检测到，配置 reCAPTCHA...");
    
    if (kDebugMode) {
      // 开发环境：禁用 reCAPTCHA 检查，方便测试
      FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true,
      );
      debugPrint("🔓 开发模式：已禁用 reCAPTCHA 检查");
      debugPrint("💡 可以使用虚拟号码进行测试");
    } else {
      // 生产环境：启用 reCAPTCHA
      FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      debugPrint("🔐 生产模式：已启用 reCAPTCHA");
      debugPrint("⚠️ 确保已在 Firebase Console 配置 reCAPTCHA");
    }
  }
  
  runApp(const StillHereApp());
}

class StillHereApp extends StatelessWidget {
  const StillHereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StillHere',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
      ),
      // 使用 StreamBuilder 监听登录状态
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 如果正在连接，显示加载圈
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
            );
          }
          
          // 如果有用户数据，进主面板，否则进登录页
          if (snapshot.hasData && snapshot.data != null) {
            return DashboardScreen(uid: snapshot.data!.uid);
          }
          return const LoginPage();
        },
      ),
    );
  }
}