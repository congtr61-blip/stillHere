import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'package:stillhere/screens/login_page.dart';
import 'package:stillhere/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
       home: const DashboardScreen(),
       //StreamBuilder<User?>(
      //   stream: FirebaseAuth.instance.authStateChanges(),
      //   builder: (context, snapshot) {
      //     // 如果正在连接，显示加载圈
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return const Scaffold(
      //         body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      //       );
      //     }
          
      //     // 如果有用户数据，进主面板，否则进登录页
      //     // 注意：这里去掉了 const，防止因为类中含有非 const 成员导致的报错
      //     if (snapshot.hasData) {
      //       return DashboardScreen(); 
      //     }
      //     return LoginPage();
      //   },
      // ),
      // 路由表
      routes: {
        '/login': (context) => LoginPage(),
        '/dashboard': (context) => DashboardScreen(),
      },
    );
  }
}