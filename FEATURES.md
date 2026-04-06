# 🔐 StillHere 功能与技术设计文档

**完整功能说明 | 架构和实现细节**

---

## 📋 目录

1. [核心功能](#核心功能)
2. [认证系统](#认证系统)
3. [账户管理](#账户管理)
4. [技术实现](#技术实现)
5. [API 参考](#api-参考)
6. [常见场景](#常见场景)

---

## 核心功能

### 🔑 三种登录方式

#### 1. Google OAuth 登录
- **优点**：最安全、最快速、无需记住密码
- **流程**：一键登录 → 自动账户链接
- **实现**：使用 Google Sign-In SDK
- **支持平台**：Web、Android、iOS

```dart
// 实现示例
final credential = await GoogleSignIn().signIn();
final idToken = credential?.idToken;
// 使用 Firebase 进行认证
await FirebaseAuth.instance.signInWithCredential(
  GoogleAuthProvider.credential(idToken: idToken)
);
```

#### 2. 邮箱 + 密码登录
- **优点**：灵活、易于绑定多个邮箱
- **流程**：邮箱 → 密码 → 邮箱验证 → 登录
- **实现**：Firebase Email/Password Authentication
- **安全性**：密码加密存储，支持密码重置

```dart
// 实现示例
try {
  final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );
  await credential.user?.sendEmailVerification();
} catch (e) {
  // 处理错误：邮箱已存在、密码过弱等
}
```

#### 3. 手机号 + SMS 验证登录
- **优点**：方便、快速、国际支持
- **流程**：手机号 → 发送验证码 → 输入验证码 → 登录
- **实现**：Firebase Phone Authentication
- **验证**：6位数字验证码，有效期：60秒

```dart
// 实现示例
// 步骤 1：发送验证码
await FirebaseAuth.instance.verifyPhoneNumber(
  phoneNumber: '+86 138 1234 5678',
  verificationCompleted: (PhoneAuthCredential credential) {
    // 自动验证
  },
  verificationFailed: (FirebaseAuthException e) {
    // 处理错误
  },
  codeSent: (String verificationId, int? resendToken) {
    // 保存 verificationId，等待用户输入验证码
  },
);

// 步骤 2：用户输入验证码后
final credential = PhoneAuthProvider.credential(
  verificationId: verificationId,
  smsCode: userInputCode,
);
await FirebaseAuth.instance.signInWithCredential(credential);
```

---

## 认证系统

### 🔐 核心概念

#### 用户身份
- 每个用户有唯一的 UID（User ID）
- 可绑定多个认证方式（邮箱、手机、Google）
- 所有认证方式共享同一个账户

#### 认证状态
```
未认证 → 邮箱待验证 → 已认证（邮箱）
                  ↓
            手机待验证 → 已认证（手机）
                  ↓
              Google 认证 → 已认证（Google）
```

#### 验证码管理
- **邮箱验证**：发送验证链接，点击验证
- **手机验证**：发送 SMS 验证码（6位数字）
- **重试策略**：可重新发送，间隔 30 秒

---

### 🔄 认证流程详解

#### 首次注册流程

```
用户选择登录方式
         ↓
   ┌─────┴─────┬──────────┬─────────┐
   ↓           ↓          ↓         ↓
  Google      邮箱        手机      密码
   ↓           ↓          ↓         ↓
一键登录    邮箱验证    验证码     密码验证
   ↓           ↓          ↓         ↓
创建账户   创建账户    创建账户   创建账户
   ↓           ↓          ↓         ↓
登录成功   检查冲突    检查冲突   检查冲突
   ↓           ↓          ↓         ↓
进入仪表板  进入仪表板  进入仪表板  进入仪表板
```

#### 后续登录流程

```
已登录用户
    ↓
输入凭证
    ↓
┌───┴───┬─────────┬──────────┐
↓       ↓         ↓          ↓
验证   发送       验证      验证
Google 验证码     邮箱      手机
  ↓       ↓         ↓        ↓
  ✓      ✓         ✓        ✓
登录成功
    ↓
进入仪表板
```

---

## 账户管理

### 👤 账户绑定

#### 绑定新邮箱
1. 用户输入邮箱地址
2. 应用发送验证链接
3. 用户点击验证链接
4. 邮箱绑定完成
5. 显示绑定状态：✅ 已验证

```dart
// 绑定邮箱实现
Future<void> bindEmail(String email) async {
  try {
    // 1. 检查邮箱是否已存在
    final signInMethods = await FirebaseAuth.instance
        .fetchSignInMethodsForEmail(email);
    if (signInMethods.isNotEmpty) {
      throw Exception('邮箱已被使用');
    }
    
    // 2. 添加邮箱提供者
    await FirebaseAuth.instance.currentUser
        ?.linkWithEmailAndPassword(email: email, password: tempPassword);
    
    // 3. 发送验证邮件
    await FirebaseAuth.instance.currentUser
        ?.sendEmailVerification();
  } catch (e) {
    print('绑定失败: $e');
  }
}
```

#### 绑定新手机号
1. 用户输入手机号
2. 应用发送 SMS 验证码
3. 用户输入验证码
4. 手机号绑定完成
5. 显示绑定状态：✅ 已验证

```dart
// 绑定手机号实现
Future<void> bindPhoneNumber(String phoneNumber) async {
  try {
    // 1. 检查手机号是否已存在
    final signInMethods = await FirebaseAuth.instance
        .fetchSignInMethodsForEmail(phoneNumber);
    if (signInMethods.isNotEmpty) {
      throw Exception('手机号已被使用');
    }
    
    // 2. 验证手机号
    await FirebaseAuth.instance.currentUser
        ?.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) {
        // 自动验证
      },
    );
    
    // 3. 等待验证码
    // ... 用户输入验证码 ...
    
    // 4. 链接凭证
    await FirebaseAuth.instance.currentUser
        ?.linkWithCredential(credential);
  } catch (e) {
    print('绑定失败: $e');
  }
}
```

#### 绑定 Google 账户
1. 用户点击"关联 Google"
2. 打开 Google 登录对话框
3. 用户选择 Google 账户
4. Google 账户绑定完成
5. 显示绑定状态：✅ 已链接

---

### 🔗 账户链接原理

#### 自动冲突检测
当用户使用新邮箱或手机号登录时：

```
1. 检查该邮箱/手机是否已存在
   ↓
   是 → 提示"邮箱已被使用"
   ↓
   否 → 继续
   ↓
2. 检查该邮箱是否与现有账户关联
   ↓
   是 → 询问用户是否关联
   ↓
   否 → 创建新账户
   ↓
3. 用户确认关联
   ↓
   自动合并账户
   ↓
4. 登录成功
```

#### 多账户链接
同一用户可关联：
- 🔓 Google 账户（最多 1 个）
- 📧 邮箱地址（最多 5 个）
- 📱 手机号（最多 3 个）
- 🔑 本地密码（自动生成）

```dart
// 链接示例
class LinkedAccount {
  final String uid;
  final List<String> emails;        // 多个邮箱
  final List<String> phoneNumbers;  // 多个手机号
  final bool hasGoogle;             // Google 关联
  final DateTime createdAt;
  final DateTime lastLogin;
}

// 实例
LinkedAccount(
  uid: 'user123',
  emails: ['user@gmail.com', 'user@outlook.com'],
  phoneNumbers: ['+86 138 1234 5678', '+86 139 8765 4321'],
  hasGoogle: true,
)
```

---

## 技术实现

### 🛠️ 后端服务

#### Firebase Authentication
- **提供商**：Google、邮箱/密码、手机号
- **安全性**：端对端加密、密码加盐
- **会话管理**：自动会话持久化

#### Cloud Firestore
- **用户数据**存储
- **绑定记录**存储
- **验证状态**跟踪

```
Firestore 结构：
users/
  ├── user_id/
  │   ├── email: "user@example.com"
  │   ├── phoneNumber: "+86 138 1234 5678"
  │   ├── googleId: "google_id"
  │   ├── linkedAccounts: ["email", "phone", "google"]
  │   ├── emailVerified: true
  │   ├── phoneVerified: true
  │   ├── createdAt: timestamp
  │   └── lastLogin: timestamp
  └── ...
```

#### Cloud Functions
- **验证码管理**：生成、存储、过期控制
- **邮件服务**：发送验证邮件
- **数据同步**：Firebase ↔ Firestore
- **账户冲突检测**：实时检查重复账户

### 📱 前端实现

#### Flutter 应用
- **auth_service.dart**：认证业务逻辑
- **screens/login_page.dart**：登录界面
- **screens/contact_binding_page.dart**：邮箱/手机绑定
- **widgets/daily_verification_dialog.dart**：验证对话框

#### Web 应用
- **index.html**：HTML 入口
- **main.dart.js**：编译的 Flutter Web
- **reCAPTCHA**：防止自动化攻击

---

### 🔐 安全考虑

#### 密码安全
- 密码最少 8 个字符
- 需包含大小写字母和数字
- Firebase 自动加盐存储
- 支持密码重置

#### 验证码安全
- 6 位随机数字
- 60 秒有效期
- 防止暴力破解（限制重试次数）
- 服务端验证

#### 隐私保护
- 用户数据加密存储
- GDPR 完全符合
- 支持数据导出
- 支持账户删除

---

## API 参考

### 认证 Service APIs

#### 手机号登录
```dart
// 发送验证码
Future<void> sendPhoneVerificationCode(String phoneNumber)

// 验证手机号
Future<UserCredential> verifyPhoneCode(
  String phoneNumber,
  String verificationCode
)

// 绑定手机号
Future<void> bindPhoneNumber(
  String phoneNumber,
  String verificationCode
)
```

#### 邮箱登录
```dart
// 创建邮箱账户
Future<UserCredential> createEmailAccount(
  String email,
  String password
)

// 邮箱登录
Future<UserCredential> signInWithEmail(
  String email,
  String password
)

// 绑定邮箱
Future<void> bindEmail(String email, String password)

// 发送邮箱验证
Future<void> sendEmailVerification()

// 检查邮箱验证状态
Future<bool> isEmailVerified()
```

#### Google 登录
```dart
// Google 登录
Future<UserCredential> signInWithGoogle()

// 链接 Google 账户
Future<void> linkGoogleAccount()
```

#### 账户管理
```dart
// 获取链接账户列表
Future<List<LinkedAccount>> getLinkedAccounts()

// 获取用户信息
Future<UserProfile> getUserProfile()

// 更新用户信息
Future<void> updateUserProfile(UserProfile profile)

// 删除账户
Future<void> deleteAccount()
```

---

## 常见场景

### 📍 场景 1：新用户使用邮箱注册

```
1. 用户点击"邮箱注册"
   ↓
2. 输入邮箱和密码
   ↓
3. 创建账户
   ↓
4. 发送验证邮件
   ↓
5. 用户点击邮件中的链接
   ↓
6. 邮箱验证完成
   ↓
7. 显示"邮箱已验证 ✓"
   ↓
8. 进入仪表板
```

### 📍 场景 2：已有 Google 账户的用户绑定邮箱

```
1. 用户已通过 Google 登录
   ↓
2. 进入"联系方式"页面
   ↓
3. 点击"+ 添加邮箱"
   ↓
4. 输入新邮箱地址
   ↓
5. 系统检查该邮箱是否已使用
   ↓
   是 → 提示"邮箱已被使用"
   否 → 继续
   ↓
6. 发送验证邮件
   ↓
7. 用户验证邮箱
   ↓
8. 显示邮箱绑定成功
   ↓
9. 现在可同时使用 Google 和邮箱登录
```

### 📍 场景 3：用户未登录，使用绑定的邮箱登录

```
1. 用户已注册但未登录
   ↓
2. 在登录界面输入邮箱和密码
   ↓
3. 点击"邮箱登录"
   ↓
4. 系统验证凭证
   ↓
5. 登录成功
   ↓
6. 进入仪表板
   ↓
7. 显示所有关联方式 (Google + 邮箱)
```

### 📍 场景 4：用户手机号绑定流程

```
1. 用户在"联系方式"看到手机号区域
   ↓
2. 点击"+ 添加手机号"
   ↓
3. 输入手机号（包括国家代码，如 +86）
   ↓
4. 点击"发送验证码"
   ↓
5. 系统发送 SMS 验证码
   ↓
6. 用户收到验证码
   ↓
7. 输入 6 位验证码
   ↓
8. 点击"验证"
   ↓
9. 验证成功，显示"✓ 已验证"
   ↓
10. 手机号绑定完成
```

---

## 🔍 故障排除

### ❌ 常见问题

**Q: 邮箱绑定失败，提示"邮箱已被使用"**
- A: 该邮箱已被其他账户使用，请使用不同邮箱或使用原邮箱的账户登录

**Q: 验证码一直没收到**
- A: 检查手机号格式、网络连接，或尝试重新发送（间隔 30 秒）

**Q: 忘记密码怎么办**
- A: 在登录界面点击"忘记密码"，使用邮箱重置

**Q: 如何取消绑定邮箱**
- A: 在"联系方式"页面点击邮箱右侧的"删除"按钮

---

## 📚 相关文档

- 完整的部署指南：[DEPLOYMENT.md](DEPLOYMENT.md)
- 测试和验证：[TESTING.md](TESTING.md)
- 故障排除：[TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- 隐私政策：[PRIVACY_POLICY.md](PRIVACY_POLICY.md)

---

**最后更新：** 2026 年 4 月 6 日 | **版本：** 1.0
