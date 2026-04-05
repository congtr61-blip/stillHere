import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'phone_login_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  bool _isLoggingIn = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoggingIn = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null && mounted) {
        // StreamBuilder 在 main.dart 中会自动监听到登录状态的改变
        // 并自动切换到 DashboardScreen，无需手动导航
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("登录失败: $e")),
      );
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  Future<void> _handlePhoneLogin() async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PhoneLoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "STILL HERE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "数据永存，爱不留憾",
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
                const SizedBox(height: 60),
                _isLoggingIn
                    ? const CircularProgressIndicator(color: Colors.cyanAccent)
                    : Column(
                        children: [
                          // Google 登录按钮
                          ElevatedButton.icon(
                            onPressed: _handleGoogleSignIn,
                            icon: const Icon(Icons.login, color: Colors.black),
                            label: const Text("使用 Google 账号登录"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(300, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // 分隔线
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: Colors.white24),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  "或",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: Colors.white24),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // 手机号登录按钮
                          ElevatedButton.icon(
                            onPressed: _handlePhoneLogin,
                            icon: const Icon(Icons.phone, color: Colors.black),
                            label: const Text("使用手机号登录"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(300, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}