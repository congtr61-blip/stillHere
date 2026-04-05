# reCAPTCHA 配置完整指南

## 问题描述

当尝试在 Web 平台使用手机号认证时，出现以下错误：

```
❌ Failed to initialize reCAPTCHA Enterprise config. Triggering the reCAPTCHA v2 verification.
❌ The phone verification request contains an invalid application verifier. 
   The reCAPTCHA token response is either invalid or expired.
```

这是因为 Firebase Phone Authentication 在 Web 平台需要 reCAPTCHA 保护。

---

## 解决方案

### 方案 A：本地开发环境（快速，推荐用于测试）

#### 步骤 1：禁用 reCAPTCHA 检查（仅开发使用）

在 `main.dart` 中修改初始化代码：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 仅在开发环境禁用 reCAPTCHA
  if (kDebugMode) {
    FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
    debugPrint("🔓 已禁用 reCAPTCHA（开发模式）");
  }
  
  runApp(const StillHereApp());
}
```

**警告**：这种方法仅用于本地开发和测试。生产环境必须启用 reCAPTCHA。

#### 步骤 2：在手机登录页面禁用

或者在 `lib/screens/phone_login_page.dart` 中：

```dart
@override
void initState() {
  super.initState();
  // 开发环境禁用 reCAPTCHA
  if (kDebugMode) {
    _authService.disableRecaptchaForTesting();
  }
}
```

#### 步骤 3：使用测试手机号登录

使用以下虚拟号码进行测试：

| 国家 | 号码 | 验证码 |
|------|------|--------|
| 中国 | +8611111111111 | 123456 |
| 南非 | +27737798227 | 123456（待确认） |
| 美国 | +13334445555 | 123456 |
| 英国 | +441632960001 | 123456 |

---

### 方案 B：生产环境设置（完整配置）

#### 步骤 1：在 Firebase Console 启用认证

1. 打开 [Firebase Console](https://console.firebase.google.com)
2. 选择项目 → **Authentication**
3. 点击 **Sign-in method** 标签
4. 找到 **Phone** → 点击启用 ✅

#### 步骤 2：启用 reCAPTCHA Enterprise

1. Firebase Console → **Authentication**
2. 点击 **App verification** 标签
3. 查看 **reCAPTCHA Enterprise** 部分
4. 点击 **Enable reCAPTCHA Enterprise** 按钮

如果按钮不可用，需要先创建 reCAPTCHA Enterprise 密钥：

#### 步骤 3：在 Google Cloud Console 配置 reCAPTCHA

1. 访问 [Google Cloud Console](https://console.cloud.google.com)
2. 选择与 Firebase 项目相同的 GCP 项目
3. 左侧菜单 → **Security** → **reCAPTCHA Enterprise**
4. 点击 **Create Key** 创建新密钥

**配置新密钥：**

| 选项 | 值 |
|------|-----|
| **Display name** | StillHere Phone Auth |
| **reCAPTCHA type** | reCAPTCHA v3 |
| **Platforms** | Web |
| **Domains** | 见下面的域名配置 |

#### 步骤 4：添加域名到白名单

在 Google Cloud 的 reCAPTCHA 密钥配置中，添加允许的域名：

**生产环境：**
```
stillhere-ad395.web.app
www.stillhere-ad395.web.app
```

**本地开发：**
```
localhost
127.0.0.1
localhost:5000
127.0.0.1:5000
```

**自定义域名：**
```
your-domain.com
www.your-domain.com
```

#### 步骤 5：在 Firebase 中关联 reCAPTCHA 密钥

1. Firebase Console → **Authentication** → **App verification**
2. reCAPTCHA Enterprise 部分
3. 点击配置，选择刚创建的 reCAPTCHA 密钥

#### 步骤 6：配置 CORS（如果使用自定义域名）

如果不是使用 firebase hosting，需要配置 CORS。在 `web/index.html` 中确保包含：

```html
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<script src="https://www.gstatic.com/recaptcha/releases/XXX/recaptcha.js"></script>
```

---

## 快速诊断清单

### ✅ 检查项目配置

- [ ] Firebase Phone Authentication 已启用
- [ ] reCAPTCHA Enterprise 已启用（生产环境）
- [ ] 当前域名已添加到 reCAPTCHA 白名单
- [ ] Firebase Web App 已创建
- [ ] Firebase 配置文件 `google-services.json` 正确

### ✅ 检查代码配置

- [ ] `main.dart` 中正确初始化 Firebase
- [ ] `auth_service.dart` 中的 `initializeRecaptcha()` 被正确调用
- [ ] 在开发环境，已正确禁用 reCAPTCHA（如果需要）

### ✅ 检查网络环境

- [ ] 网络连接正常
- [ ] 可以访问 Google Cloud 服务
- [ ] 没有被防火墙阻止

---

## 错误日志说明

### 错误：`invalid-app-verifier`

```
The phone verification request contains an invalid application verifier. 
The reCAPTCHA token response is either invalid or expired.
```

**原因：**
1. reCAPTCHA 未正确初始化
2. reCAPTCHA token 已过期（有效期仅 2 分钟）
3. 域名不在白名单中

**解决：**
- 刷新页面重新尝试
- 检查 reCAPTCHA 配置
- 确保域名在白名单中

### 错误：`Failed to initialize reCAPTCHA Enterprise`

```
Failed to initialize reCAPTCHA Enterprise config. 
Triggering the reCAPTCHA v2 verification.
```

**原因：**
1. reCAPTCHA Enterprise 密钥配置不正确
2. GCP 项目和 Firebase 项目不匹配
3. 没有权限访问 reCAPTCHA

**解决：**
- 确认使用同一个 GCP 项目
- 检查 IAM 权限
- 重新配置 reCAPTCHA 密钥

---

## 开发 vs 生产配置

### 本地开发

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 仅在调试模式下禁用
  if (kDebugMode) {
    FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }
  
  runApp(const StillHereApp());
}
```

### 生产环境

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 生产环境启用 reCAPTCHA
  FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  
  runApp(const StillHereApp());
}
```

---

## 常见问题

### Q: 为什么本地 localhost 也需要 reCAPTCHA？

A: Firebase Phone Authentication 出于安全考虑，所有 Web 环境都需要 reCAPTCHA 保护。对于开发，可以在 `firebase.json` 中配置绕过。

### Q: reCAPTCHA token 过期怎么办？

A: Token 有效期为 2 分钟。如果在这个时间内没有完成验证，会收到 "token expired" 错误。用户需要重新发送验证码。

### Q: 如何在 Firebase Emulator 中测试？

A: 在 Emulator 中，自动禁用 reCAPTCHA：

```bash
firebase emulators:start
```

### Q: 支持 reCAPTCHA v2（验证码框）吗？

A: Firebase Phone Auth 默认使用 v3（无感知）。如果需要 v2，需要在 Google Cloud 中配置为 v2。

### Q: 多个项目共享一个 reCAPTCHA 密钥可以吗？

A: 不行。每个项目需要独立的 reCAPTCHA 密钥。

---

## 测试步骤

### 1. 本地测试（推荐先用这个）

```bash
# 启用调试模式并禁用 reCAPTCHA
flutter run -d web --debug
```

然后使用虚拟号码 `+8611111111111`，验证码 `123456`

### 2. reCAPTCHA 配置完成后测试

```bash
# 启用生产 reCAPTCHA
flutter run -d web --release
```

使用真实手机号进行测试

### 3. 查看日志

在 Chrome DevTools 中：
1. F12 → Console 标签页
2. 搜索 "reCAPTCHA" 或 "firebase" 关键词
3. 查看初始化状态

---

## 安全建议

### 开发环境
- ✅ 可以禁用 reCAPTCHA（方便测试）
- ✅ 使用虚拟号码
- ✅ 在代码中标记（`kDebugMode`）

### 生产环境
- ❌ 不能禁用 reCAPTCHA
- ❌ 必须正确配置密钥
- ✅ 必须添加所有域名到白名单
- ✅ 定期审查 reCAPTCHA 分析报告

---

## 相关文档

- [Firebase Phone Authentication](https://firebase.google.com/docs/auth/flutter/phone-auth)
- [reCAPTCHA Enterprise](https://cloud.google.com/recaptcha-enterprise/docs)
- [Google Cloud reCAPTCHA 配置](https://cloud.google.com/recaptcha-enterprise/docs/configure-sites)

---

## 获取帮助

如果上述步骤不能解决问题：

1. **检查 Firebase 日志**
   - Firebase Console → Analytics → DebugView
   - 查看认证相关事件

2. **查看浏览器日志**
   - Chrome DevTools → Console
   - 搜索 "reCAPTCHA" 错误

3. **验证 GCP 权限**
   - Google Cloud Console
   - IAM & Admin → Service Accounts
   - 确认 Firebase service account 有权限

4. **重置配置**
   - 删除 reCAPTCHA 密钥并重新创建
   - 清除浏览器缓存和 cookies
   - 重新部署应用
