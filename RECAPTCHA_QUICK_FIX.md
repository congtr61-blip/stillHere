# reCAPTCHA 错误快速修复指南

## 🚨 您遇到的问题

```
❌ Failed to initialize reCAPTCHA Enterprise config. 
   Triggering the reCAPTCHA v2 verification.
❌ The phone verification request contains an invalid application verifier. 
   The reCAPTCHA token response is either invalid or expired.
```

## ✅ 快速修复（3种方案）

### 方案 1：最快修复（开发模式 - 推荐先用这个）

**时间：5分钟**

只需修改一个地方 - `lib/main.dart`

当前代码已经自动处理了！如果还是有问题，确保：

1. **重启应用**
   ```bash
   flutter clean
   flutter pub get
   flutter run -d web
   ```

2. **清除浏览器缓存**
   - Chrome: `Ctrl+Shift+Delete` (Win) 或 `Cmd+Shift+Delete` (Mac)
   - 选择 "所有时间" → 清空

3. **刷新页面**
   - 按 `Ctrl+F5` (Win) 或 `Cmd+Shift+R` (Mac)

4. **使用测试号码登录**
   ```
   手机号: +8611111111111
   验证码: 123456
   ```

**如果还是不行，继续方案 2...**

---

### 方案 2：显式禁用 reCAPTCHA（仅开发使用）

**时间：2分钟**

在 `lib/services/auth_service.dart` 的 `sendPhoneVerificationCode` 方法中，在发送验证码前添加：

```dart
// 开发环境临时禁用（确保在代码中标记）
// TODO: 移除此行用于生产环境
FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
```

完整示例：

```dart
Future<void> sendPhoneVerificationCode(String phoneNumber) async {
  try {
    debugPrint("📱 正在向 $phoneNumber 发送验证码...");
    
    // 开发临时方案
    if (kDebugMode) {
      _auth.setSettings(appVerificationDisabledForTesting: true);
    }
    
    // ... 其余代码
  }
}
```

---

### 方案 3：完整的 Firebase + Google Cloud 配置（生产环境）

**时间：20-30分钟** | **针对生产部署**

详见 [RECAPTCHA_SETUP.md](RECAPTCHA_SETUP.md) 中的 "方案 B：生产环境设置"

---

## 🔧 测试步骤

### Step 1：确认开发模式生效

在 Android Studio / VS Code 控制台，应该看到：

```
🌐 Web 平台检测到，配置 reCAPTCHA...
🔓 开发模式：已禁用 reCAPTCHA 检查
💡 可以使用虚拟号码进行测试
```

### Step 2：使用虚拟号码测试

| 号码 | 验证码 | 国家 |
|------|--------|------|
| +8611111111111 | 123456 | 中国 |
| +27737798227 | 123456 | 南非（您添加的） |
| +13334445555 | 123456 | 美国 |

**操作步骤：**
1. 打开应用 → 点击 "使用手机号登录"
2. 输入 `+8611111111111`
3. 点击 "发送验证码"
4. 输入 `123456`
5. 点击 "登录"

应该会成功登录！ ✅

### Step 3：检查浏览器控制台

打开浏览器的 DevTools：
- Chrome: F12
- Firefox: F12
- Safari: Cmd+Option+I

在 Console 标签页查看日志，确认没有 reCAPTCHA 错误。

---

## 📋 诊断清单

依次检查以下项目：

- [ ] `main.dart` 已更新为最新版本
- [ ] Flutter 应用完整重建（`flutter clean && flutter pub get`）
- [ ] 浏览器缓存已清除
- [ ] 页面已刷新（F5 或 Ctrl+Shift+R）
- [ ] 使用了正确的虚拟号码格式
- [ ] 验证码确实是 `123456`
- [ ] 网络连接正常
- [ ] 防火墙没有阻止 Firebase

---

## 🐛 其他常见错误

### 错误：手机号拒绝

```
❌ The given phone number is invalid
```

**解决：** 确保号码格式正确
```
❌ +27737798227          (可能格式不支持)
✅ +27737798227         (标准格式)
✅ +8611111111111       (虚拟号码，推荐)
```

### 错误：发送太频繁

```
❌ Too many requests from this IP address
```

**解决：** 等待 1 小时后重试，或更换网络

### 错误：国家不支持

```
❌ The given phone number is not supported
```

**解决：** 该号码的国家代码可能不被支持，尝试其他国家的虚拟号码

---

## 📞 调试技巧

### 查看详细日志

在 `PhoneLoginPage` 中添加日志：

```dart
Future<void> _handleSendCode() async {
  debugPrint("📱 当前平台: ${defaultTargetPlatform}");
  debugPrint("🌐 是否 Web: ${kIsWeb}");
  debugPrint("🔧 是否调试: ${kDebugMode}");
  debugPrint("📱 手机号: ${_phoneController.text}");
  
  // ... 继续原有代码
}
```

### Firebase 命令行工具

检查 Firebase 项目信息：

```bash
# 列出所有项目
firebase projects:list

# 获取当前项目信息
firebase projects:info
```

### 网络监控

在 Chrome DevTools 中：
1. F12 → Network 标签页
2. 发送验证码
3. 查看 API 调用
4. 检查是否有 reCAPTCHA 相关的请求

---

## ✅ 验证成功标志

如果您看到以下信息，说明配置成功：

```
✅ 验证码已发送到 +8611111111111
```

浏览器中正常显示短信验证码输入框

可以输入 `123456` 并成功登录

---

## 🚀 下一步

### 对于测试/演示
- ✅ 继续使用虚拟号码
- ✅ 方案 1 已完全满足需求
- ✅ 无需额外配置

### 对于生产部署
- 📋 按照 [RECAPTCHA_SETUP.md](RECAPTCHA_SETUP.md) 中的"方案 B"完整配置
- 📋 在 Firebase Console 启用 reCAPTCHA Enterprise
- 📋 在 Google Cloud 配置 reCAPTCHA 密钥
- 📋 添加您的域名到白名单

---

## 📊 配置对比

| 场景 | reCAPTCHA | 使用的号码 | 耗时 | 代码改动 |
|------|-----------|-----------|------|----------|
| **本地开发** | 禁用 ✅ | 虚拟 | 5分钟 | 无需改动 |
| **演示/测试** | 禁用 ✅ | 虚拟 | 5分钟 | 无需改动 |
| **生产部署** | 启用 🔐 | 真实 | 30分钟 | Firebase + GCP 配置 |

---

## 💾 备注

您添加的测试账号： **+27737798227**

- 如果这是真实号码，请不要在公共环境中测试
- 推荐使用虚拟号码 `+8611111111111` 进行测试
- 虚拟号码不会收到真实的短信

---

## 需要帮助？

1. **重新读一遍本指南** - 大多数问题都能自己解决
2. **查看 [RECAPTCHA_SETUP.md](RECAPTCHA_SETUP.md)** - 详细的完整指南
3. **检查浏览器控制台** - 通常能看到具体错误信息
4. **查看 Firebase 日志** - Firebase Console → Logs
