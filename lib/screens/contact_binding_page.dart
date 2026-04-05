import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ContactBindingPage extends StatefulWidget {
  const ContactBindingPage({super.key});

  @override
  State<ContactBindingPage> createState() => _ContactBindingPageState();
}

class _ContactBindingPageState extends State<ContactBindingPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;
  bool _showPasswordInput = false;
  int _secondsRemaining = 0;

  Map<String, dynamic> _contactInfo = {
    'email': null,
    'emailVerified': false,
    'phoneNumber': null,
    'phoneNumberVerified': false,
  };

  @override
  void initState() {
    super.initState();
    _loadContactInfo();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadContactInfo() async {
    final userUid = _authService.userChanges.first.then((user) => user?.uid);
    userUid.then((uid) async {
      if (uid != null) {
        final info = await _authService.getUserContactInfo(uid);
        if (mounted) {
          setState(() {
            _contactInfo = info;
            _emailController.text = info['email'] ?? '';
            _phoneController.text = info['phoneNumber'] ?? '';
          });
        }
      }
    });
  }

  Future<void> _handleBindEmail() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      _showSnackBar("请输入邮箱");
      return;
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackBar("请输入有效的邮箱地址");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final emailStatus = await _authService.checkEmailStatus(email);
      
      if (emailStatus['available'] == true) {
        final result = await _authService.bindEmail(email);
        if (result['status'] == 'success') {
          _showSnackBar("✅ 邮箱绑定成功！请查收验证邮件");
          setState(() => _showPasswordInput = false);
          _loadContactInfo();
        }
      } else {
        _showAccountMergingDialog(email, emailStatus);
      }
    } catch (e) {
      _showSnackBar("检查邮箱失败: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAccountMergingDialog(String email, Map<String, dynamic> emailStatus) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("邮箱已被使用"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("该邮箱 ($email) 已与另一个账户关联。"),
            const SizedBox(height: 12),
            const Text("您有两个选项来解决这个问题："),
            const SizedBox(height: 12),
            const Text("选项 1：直接绑定（推荐）"),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 8),
              child: Text(
                "使用该邮箱关联的登录方式登录，系统会自动识别并链接账户。",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            const Text("选项 2：通过密码链接（如果邮箱有密码）"),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 8),
              child: Text(
                "输入该邮箱的密码，直接链接此账户。",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _showPasswordInput = true);
            },
            child: const Text("使用密码链接"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLinkEmailWithPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (password.isEmpty) {
      _showSnackBar("请输入密码");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _authService.linkEmailCredential(email, password);

      if (result['success'] == true) {
        _showSnackBar(result['message'] ?? "邮箱链接成功");
        setState(() {
          _showPasswordInput = false;
          _passwordController.clear();
        });
        _loadContactInfo();
      } else {
        String errorMsg = result['message'] ?? "链接失败";
        if (result['code'] == 'wrong-password') {
          errorMsg = "密码错误，请重试";
        } else if (result['code'] == 'user-not-found') {
          errorMsg = "该邮箱未注册";
        }
        _showSnackBar("❌ $errorMsg");
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('wrong-password')) {
        errorMsg = "密码错误，请重试";
      } else if (errorMsg.contains('user-not-found')) {
        errorMsg = "该邮箱未注册";
      } else if (errorMsg.contains('too-many-requests')) {
        errorMsg = "尝试次数过多，请稍后再试";
      }
      _showSnackBar("❌ $errorMsg");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSendVerificationCode() async {
    if (_phoneController.text.isEmpty) {
      _showSnackBar("请输入手机号");
      return;
    }

    setState(() => _isLoading = true);
    try {
      String phoneNumber = _phoneController.text.trim();
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+86$phoneNumber';
      }

      await _authService.bindPhoneNumber(phoneNumber);
      
      if (mounted) {
        setState(() {
          _codeSent = true;
          _secondsRemaining = 60;
        });
        _startCountdown();
        _showSnackBar("验证码已发送");
      }
    } catch (e) {
      _showSnackBar("发送失败: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleConfirmPhoneBinding() async {
    if (_codeController.text.isEmpty) {
      _showSnackBar("请输入验证码");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.confirmPhoneNumberBinding(_codeController.text);
      
      if (mounted) {
        setState(() => _codeSent = false);
        _codeController.clear();
        _showSnackBar("手机号绑定成功");
        _loadContactInfo();
      }
    } catch (e) {
      _showSnackBar("验证失败: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUnbindEmail() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("解绑邮箱"),
        content: const Text("确定要解绑邮箱吗？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("确定", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _authService.unbindEmail();
      
      if (mounted) {
        _emailController.clear();
        _showSnackBar("邮箱已解绑");
        _loadContactInfo();
      }
    } catch (e) {
      _showSnackBar("解绑失败: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUnbindPhone() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("解绑手机号"),
        content: const Text("确定要解绑手机号吗？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("确定", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _authService.unbindPhoneNumber();
      
      if (mounted) {
        _phoneController.clear();
        _showSnackBar("手机号已解绑");
        _loadContactInfo();
      }
    } catch (e) {
      _showSnackBar("解绑失败: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _secondsRemaining--);
      }
      return _secondsRemaining > 0 && mounted;
    });
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("联系方式管理"),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 邮箱绑定卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.email, color: Colors.blue),
                              const SizedBox(width: 10),
                              const Text(
                                "邮箱",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (_contactInfo['email'] != null)
                                Chip(
                                  label: Text(
                                    _contactInfo['emailVerified'] ? "已验证" : "未验证",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: _contactInfo['emailVerified']
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.orange.withOpacity(0.3),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_contactInfo['email'] == null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  enabled: !_showPasswordInput,
                                  decoration: InputDecoration(
                                    hintText: "请输入邮箱地址",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.email),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (_showPasswordInput)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          border: Border.all(
                                            color: Colors.orange.withOpacity(0.3),
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          "该邮箱已被使用。请输入该邮箱关联账户的密码来链接此账户。",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _passwordController,
                                        obscureText: true,
                                        decoration: InputDecoration(
                                          hintText: "请输入密码",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          prefixIcon: const Icon(Icons.lock),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _isLoading ? null : _handleLinkEmailWithPassword,
                                          icon: const Icon(Icons.link),
                                          label: const Text("链接账户"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton(
                                          onPressed: () => setState(() {
                                            _showPasswordInput = false;
                                            _passwordController.clear();
                                          }),
                                          child: const Text("取消"),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _isLoading ? null : _handleBindEmail,
                                      icon: const Icon(Icons.link),
                                      label: const Text("绑定邮箱"),
                                    ),
                                  ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _contactInfo['email'] ?? '',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _handleUnbindEmail,
                                    icon: const Icon(Icons.link_off),
                                    label: const Text("解绑"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 手机号绑定卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.phone, color: Colors.green),
                              const SizedBox(width: 10),
                              const Text(
                                "手机号",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (_contactInfo['phoneNumber'] != null)
                                Chip(
                                  label: Text(
                                    _contactInfo['phoneNumberVerified'] ? "已验证" : "未验证",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: _contactInfo['phoneNumberVerified']
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.orange.withOpacity(0.3),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 优先级 1：验证码已发送，显示验证码输入框
                          if (_codeSent)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "验证码已发送至 ${_phoneController.text}",
                                  style: const TextStyle(fontSize: 14, color: Colors.green),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _codeController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: "请输入验证码（6位数字）",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.pin),
                                    suffixText: _secondsRemaining > 0 ? "$_secondsRemaining s" : "",
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading ? null : _handleConfirmPhoneBinding,
                                    icon: const Icon(Icons.check),
                                    label: const Text("确认绑定"),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: _secondsRemaining > 0 ? null : _handleSendVerificationCode,
                                    child: Text(_secondsRemaining > 0
                                        ? "重新发送 ($_secondsRemaining s)"
                                        : "重新发送"),
                                  ),
                                ),
                              ],
                            )
                          // 优先级 2：手机号已验证并绑定，显示已绑定状态
                          else if (_contactInfo['phoneNumber'] != null && _contactInfo['phoneNumberVerified'] == true)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green, width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _contactInfo['phoneNumber'] ?? '',
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                            ),
                                            const Text(
                                              "已验证",
                                              style: TextStyle(fontSize: 12, color: Colors.green),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _handleUnbindPhone,
                                    icon: const Icon(Icons.link_off),
                                    label: const Text("解绑"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          // 优先级 3：手机号已绑定但未验证，或其他情况，显示输入框
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: "请输入手机号（如：13800138000）",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.phone),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading ? null : _handleSendVerificationCode,
                                    icon: const Icon(Icons.sms),
                                    label: const Text("发送验证码"),
                                  ),
                                )
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
