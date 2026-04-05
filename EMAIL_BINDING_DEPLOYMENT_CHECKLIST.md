# 邮箱绑定与账号链接 - 部署集成检查表

## 概览

此检查表确保邮箱绑定和账号链接功能已完全集成并准备好用于生产。

**功能版本：** 1.1.2 (账户链接功能)  
**最后更新：** 2024-01-15  
**预期完成时间：** 2-3 小时  

---

## 📋 代码集成检查

### ✅ 后端服务（`lib/services/auth_service.dart`）

- [x] 导入所需包
  - [x] `package:firebase_auth/firebase_auth.dart`
  - [x] `package:cloud_firestore/cloud_firestore.dart`
  - [x] `EmailAuthProvider` 导入

- [x] 新增方法实现
  - [x] `checkEmailStatus(String email)` - 完全实现
  - [x] `isEmailInUse(String email)` - 完全实现
  - [x] `isEmailVerified()` - 完全实现
  - [x] `resendEmailVerification()` - 完全实现
  - [x] `linkEmailCredential(String email, String password)` - 完全实现
  
- [x] 方法修改
  - [x] `bindEmail()` - 重写为返回 Map<String, dynamic>
  - [x] 错误处理包含：
    - [x] `email-already-in-use`
    - [x] `wrong-password`
    - [x] `user-not-found`
    - [x] `requires-recent-login`
    - [x] `credential-already-in-use`

- [x] 编译验证
  - [x] 无编译错误
  - [x] 无警告
  - [x] 导入完整

**检查方法：**
```bash
cd stillhere
flutter analyze
flutter build web --release
```

### ✅ UI 层（`lib/screens/contact_binding_page.dart`）

- [x] 状态变量添加
  - [x] `_showPasswordInput: bool`
  - [x] `_passwordController: TextEditingController`
  - [x] `_emailStatusMessage: String?`
  - [x] `_isCheckingEmailStatus: bool`

- [x] 新增方法
  - [x] `_showAccountMergingDialog()` - 显示合并选项对话框
  - [x] `_handleLinkEmailWithPassword()` - 处理密码链接

- [x] UI 元素
  - [x] 邮箱检查 loading 状态
  - [x] 密码输入框（条件渲染）
  - [x] "链接账户"按钮（条件渲染）
  - [x] 合并对话框说明文本
  - [x] 错误消息显示

- [x] 流程集成
  - [x] 邮箱输入 → 自动检查状态
  - [x] 状态可用 → 直接绑定
  - [x] 状态已用 → 显示合并对话框
  - [x] 用户选择链接 → 显示密码输入
  - [x] 密码验证 → 账户链接或错误处理

- [x] 编译验证
  - [x] 无编译错误
  - [x] 无未使用的变量
  - [x] 导入完整

**检查方法：**
```bash
cd stillhere
flutter analyze lib/screens/contact_binding_page.dart
flutter pub get
```

### ✅ 应用入口（`lib/main.dart`）

- [x] reCAPTCHA 配置
  - [x] Web 平台检查
  - [x] Debug 模式禁用 reCAPTCHA
  - [x] Release 模式启用 reCAPTCHA

- [x] 初始化逻辑
  - [x] Firebase 初始化
  - [x] reCAPTCHA 初始化
  - [x] 错误处理

**验证：**
```bash
# 查看 main.dart 中的平台检查
grep -n "kIsWeb\|reCAPTCHA" lib/main.dart
```

---

## 🔧 Firebase 配置检查

### ✅ Authentication 提供商

- [x] Email/Password 启用
  ```bash
  Firebase Console → Authentication → Sign-in method
  检查：Email/Password ✓
  ```

- [x] Phone 认证启用
  ```bash
  Firebase Console → Authentication → Sign-in method
  检查：Phone ✓
  reCAPTCHA Enterprise 配置 ✓
  ```

- [x] Google Sign-In 启用
  ```bash
  Firebase Console → Authentication → Sign-in method
  检查：Google ✓
  ```

### ✅ Cloud Firestore 配置

- [x] 集合创建
  ```
  /users 集合已存在
  /users/{uid} 文档结构：
    ├── email: String
    ├── emailVerified: Boolean
    ├── phoneNumber: String
    ├── phoneNumberVerified: Boolean
    ├── linkedEmails: Array<String>  ← NEW
    ├── createdAt: Timestamp
    ├── lastLoginAt: Timestamp
    └── emailUpdatedAt: Timestamp     ← NEW
  ```

- [x] 安全规则
  ```bash
  Firestore → Rules 标签页
  检查是否允许：
  ✓ 认证用户读写自己的文档
  ✓ 只能修改 email, phoneNumber, linkedEmails 字段
  ✓ 禁止删除 uid 或关键字段
  ```

  **推荐规则示例：**
  ```
  match /users/{uid} {
    allow read, write: if request.auth.uid == uid;
    allow create: if request.auth.uid == request.resource.data.uid;
  }
  ```

- [x] 索引配置
  ```bash
  Firestore → Indexes 标签页
  不需要新增索引（linkedEmails 不需要复合索引）
  ```

### ✅ CORS 配置（Web）

- [x] Firebase SDK JavaScript 配置
  ```javascript
  // web/index.html 中
  <script>
    const firebaseConfig = {
      apiKey: "YOUR_API_KEY",
      authDomain: "YOUR_APP.firebaseapp.com",
      projectId: "YOUR_PROJECT",
      storageBucket: "YOUR_APP.appspot.com",
      messagingSenderId: "YOUR_MSG_SENDER_ID",
      appId: "YOUR_APP_ID"
    };
  </script>
  ```

- [x] reCAPTCHA Enterprise 密钥
  ```
  Firebase Console → Customers → Manage
  检查：Web reCAPTCHA key 已配置
  ```

---

## 📱 平台特定检查

### ✅ Web 平台

- [x] 邮箱验证链接打开
  ```
  用户收到邮件 → 点击链接 → 在浏览器中打开
  检查：能正确识别当前用户
  ```

- [x] 密码输入安全
  ```
  检查：密码字段类型为 password
  检查：使用了 obscureText: true
  検査：输入完成后立即清空
  ```

- [x] 错误处理
  ```
  测试场景：
  ✓ 网络断开时的行为
  ✓ 密码多次错误时的冷却
  ✓ 邮箱验证链接过期的处理
  ```

### ✅ 移动平台（iOS/Android）

- [x] 邮箱验证链接打开
  ```
  用户收到邮件 → 点击链接 → 跳转到应用
  检查：Deep linking 配置正确
  
  iOS: 需要 Associated Domains
  Android: 需要 Intent Filters
  ```

- [x] 密码输入法
  ```
  检查：屏幕键盘正确显示
  检查：密码字段使用正确的输入类型
  ```

---

## 🧪 测试检查表

### ✅ 单元测试

- [x] 邮箱验证函数
  ```dart
  test('checkEmailStatus returns available for new email', () async {
    final result = await authService.checkEmailStatus('new@example.com');
    expect(result['available'], true);
    expect(result['status'], 'available');
  });
  ```

- [x] 邮箱检查函数
  ```dart
  test('isEmailInUse detects used email', () async {
    // 使用已注册的邮箱
    final result = await authService.isEmailInUse('used@example.com');
    expect(result, true);
  });
  ```

- [x] 错误处理
  ```dart
  test('bindEmail returns email_already_in_use status', () async {
    final result = await authService.bindEmail('used@example.com');
    expect(result['status'], 'email_already_in_use');
  });
  ```

**运行测试：**
```bash
cd stillhere
flutter test test/
```

### ✅ 集成测试

**场景 A：新邮箱绑定**
```
前提：已登录（手机号或 Google）
操作：
1. 打开联系方式管理
2. 输入新邮箱：newemail@gmail.com
3. 点击"绑定邮箱"
4. 系统提示"邮件已发送"
5. 检查邮箱收到验证邮件
6. 点击验证链接
7. 返回应用，邮箱显示"已验证"

预期结果：✓ 邮箱绑定成功、已验证
```

**场景 B：已使用邮箱检测和链接**
```
前提：
- 账户 A：Google 登录
- 账户 B：用 used@qq.com + 密码 登录

操作：
1. 用 Google 登录账户 A
2. 打开联系方式管理
3. 输入 used@qq.com
4. 点击"绑定邮箱"
5. 系统提示"邮箱已被使用"显示链接对话框
6. 点击"使用密码链接"（或"链接账户" 按钮）
7. 输入该邮箱的密码
8. 点击"链接账户"
9. 系统需要重新登录
10. 重新 Google 登录
11. 系统自动链接成功

预期结果：✓ 账户链接成功，邮箱已绑定

验证：
- 可以用 Google 登录
- 可以用 used@qq.com + 密码 登录
- 两种方式进入同一账户
```

**场景 C：错误处理**
```
A. 密码错误
   1. 输入错误密码
   2. 点击"链接账户"
   预期：显示"密码错误，请重试"，允许重新输入

B. 邮箱未注册
   1. 输入从未使用过的邮箱 error@example.com
   2. 系统提示"该邮箱未注册"或直接绑定
   预期：正常处理，不报错

C. 网络错误
   1. 断开网络
   2. 点击"绑定邮箱"或"链接账户"
   预期：显示网络错误，允许重试

D. 安全验证
   1. 修改密码后立即尝试链接
   预期：提示"需要重新登录"，用户重新认证
```

**手动测试命令：**
```bash
cd stillhere

# 清除缓存并重新构建
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# 运行 Web 版本
flutter run -d chrome --web-port=5000

# 或使用调试器
flutter run -d chrome --debug
```

### ✅ UI/UX 测试

- [x] 密码输入框显示/隐藏
  ```
  新邮箱：输入框不出现 ✓
  已用邮箱：输入框出现 ✓
  提交后：输入框隐藏 ✓
  ```

- [x] 加载状态
  ```
  邮箱检查时：显示 loading ✓
  密码验证时：显示 loading ✓
  ```

- [x] 错误消息清晰
  ```
  ✓ "该邮箱已被使用，可以链接账户"
  ✓ "密码错误，请重试"
  ✓ "该邮箱未注册"
  ✓ "需要重新登录以确保安全"
  ```

- [x] 响应式设计
  ```
  ✓ 手机屏幕（< 600px）
  ✓ 平板屏幕（600px - 900px）
  ✓ 桌面屏幕（> 900px）
  ```

---

## 📊 Firestore 数据验证

### ✅ 文档结构验证

```javascript
// Firebase Console 中运行：
db.collection("users").doc("YOUR_UID").get().then(doc => {
  console.log(JSON.stringify(doc.data(), null, 2));
});

// 期望输出：
{
  "email": "user@example.com",
  "emailVerified": true,
  "phoneNumber": "+86 1234567890",
  "phoneNumberVerified": true,
  "linkedEmails": ["linked@example.com", "another@example.com"],
  "createdAt": Timestamp(2024, 1, 15),
  "lastLoginAt": Timestamp(2024, 1, 15),
  "emailUpdatedAt": Timestamp(2024, 1, 15)
}
```

### ✅ 数据完整性检查

```javascript
// 检查所有用户都有必要字段
db.collection("users")
  .where("linkedEmails", "==", null)
  .get()
  .then(snapshot => {
    if (snapshot.empty) {
      console.log("✓ 所有用户都有 linkedEmails 字段");
    }
  });
```

---

## 📚 文档验证

- [x] [ACCOUNT_LINKING_GUIDE.md](ACCOUNT_LINKING_GUIDE.md)
  - [x] 内容完整
  - [x] 步骤清晰
  - [x] 场景覆盖全面

- [x] [EMAIL_BINDING_QUICK_REFERENCE.md](EMAIL_BINDING_QUICK_REFERENCE.md)
  - [x] 快速参考有用
  - [x] 命令清晰
  - [x] 常见错误覆盖

- [x] [EMAIL_BINDING_DEVELOPER_REFERENCE.md](EMAIL_BINDING_DEVELOPER_REFERENCE.md)
  - [x] API 说明完整
  - [x] 代码示例可用
  - [x] 集成步骤清晰

- [ ] 用户手册（如需要）
  - [ ] 截图和预览
  - [ ] 视频教程（可选）

---

## 🚀 生产前检查

### ✅ 代码质量

- [x] 没有 `print()` 语句（使用 logging）
  ```bash
  grep -r "print(" lib/ functions/
  # 应该没有结果
  ```

- [x] 没有 TODO 注释（除非有 issue 链接）
  ```bash
  grep -r "TODO\|FIXME\|HACK" lib/
  # 应该最少
  ```

- [x] 异常处理完整
  ```bash
  grep -r "try {" lib/services/auth_service.dart
  # 所有 try 都有对应 catch
  ```

- [x] 没有未使用的导入
  ```bash
  flutter analyze --no-fatal-infos
  # 应该没有"unused import"
  ```

### ✅ 性能检查

- [x] 不在主线程阻塞 UI
  ```
  邮箱检查：异步操作 ✓
  密码验证：异步操作 ✓
  Firestore 更新：异步操作 ✓
  ```

- [x] 没有内存泄漏
  ```
  TextEditingController 释放 ✓
  Dialog 正确关闭 ✓
  Stream 订阅取消 ✓
  ```

- [x] 合理的超时设置
  ```dart
  // 所有网络操作都应该有超时
  await Future.wait([...]).timeout(Duration(seconds: 30));
  ```

### ✅ 安全检查

- [x] 敏感数据不记录
  ```
  ✓ 密码从不打印到日志
  ✓ token 不暴露
  ✓ 用户 ID 可以只标记（不完整）
  ```

- [x] 输入验证
  ```dart
  // Email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }
  ```

- [ ] HTTPS 检查
  ```
  所有 Firebase 通信都使用 HTTPS ✓
  没有 HTTP 端点 ✓
  ```

- [ ] 权限最小化
  ```
  Firestore 规则：用户只能访问自己的数据 ✓
  没有泄露他人数据的风险 ✓
  ```

### ✅ 错误追踪

- [ ] 配置 Sentry（可选但推荐）
  ```bash
  flutter pub add sentry_flutter
  
  # 在 main.dart 中初始化：
  await SentryFlutter.init(
    (options) {
      options.dsn = 'your-sentry-dsn';
    },
  );
  ```

- [ ] 配置 Firebase Crashlytics（推荐）
  ```bash
  flutter pub add firebase_crashlytics
  
  # 在 main.dart 中：
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  ```

- [ ] 配置应用监控
  ```
  Firebase Console → Analytics
  检查：事件跟踪已启用
  检查：Email binding 事件已添加
  ```

---

## 📋 部署步骤

### 阶段 1：预发布验证（2-3小时）

```bash
# 1. 清理项目
flutter clean
flutter pub get

# 2. 运行所有检查
flutter analyze
flutter test

# 3. 获取依赖审计
flutter pub outdated --no-dev-dependencies

# 4. 构建 Web 版本
flutter build web --release

# 5. 构建 APK（如有 Android）
flutter build apk --release

# 6. 构建 iOS（如有 iOS）
flutter build ios --release
```

### 阶段 2：Firebase 验证

```javascript
// Firebase Console → Functions
检查：所有 function 已部署
检查：没有错误日志

// Firebase Console → Authentication
检查：reCAPTCHA Enterprise 已配置
检查：Email/Password provider 已启用
检查：Phone provider 已启用（如有）

// Firebase Console → Firestore
检查：安全规则已设置
检查：没有违反规则的访问
```

### 阶段 3：登台测试（1-2小时）

```
在实际环境模拟测试：
1. 新账户注册（邮箱 + 密码）
2. 邮箱验证流程
3. 手机号绑定（如有）
4. 已使用邮箱链接
5. 账户登出和登入
6. 数据同步验证
```

### 阶段 4：生产部署

```bash
# 设置版本号
# pubspec.yaml
version: 1.1.2+5

# 构建生产版本
flutter build web --release --dart-define=FLAVOR=production

# （如有）上传到 App Store / Google Play
cd build/ios && fastlane release
cd build/android && fastlane release

# 或使用 Firebase Hosting
firebase deploy
```

### 阶段 5：上线后监控（24-48小时）

```
监控指标：
✓ 登录成功率 > 99%
✓ 邮箱绑定成功率 > 95%
✓ 错误率 < 0.5%
✓ 平均响应时间 < 2s
✓ 用户反馈：0 关键问题
```

---

## 🔄 回滚计划

如果遇到严重问题：

```bash
# 1. 立即停止新登录
Firebase Auth → 禁用能有问题的提供商

# 2. 恢复上一个版本
git revert <commit-hash>
flutter build web --release
firebase deploy

# 3. 联系用户
"我们发现了邮箱绑定的问题，已修复。
如果您遇到任何问题，请尝试：
1. 清除浏览器缓存
2. 刷新应用
3. 如果仍有问题，请重新登录"

# 4. 分析根因
检查错误日志和用户反馈
```

---

## ✨ 完成清单

### 部署前确认

- [ ] 所有代码检查通过
- [ ] 所有测试通过
- [ ] Firebase 配置正确
- [ ] 文档已更新
- [ ] 团队已审查
- [ ] 备份已制作
- [ ] 监控已设置

### 部署后 24 小时检查

- [ ] 没有严重错误
- [ ] 用户反馈积极
- [ ] 性能指标正常
- [ ] 没有安全问题

### 部署后 1 周检查

- [ ] 用户留存率良好
- [ ] 没有隐藏问题
- [ ] 文档精确性确认
- [ ] 考虑进一步改进

---

## 📞 支持联系

如有问题，请参考：

1. **代码问题**：查看 [EMAIL_BINDING_DEVELOPER_REFERENCE.md](EMAIL_BINDING_DEVELOPER_REFERENCE.md)
2. **用户问题**：查看 [EMAIL_BINDING_QUICK_REFERENCE.md](EMAIL_BINDING_QUICK_REFERENCE.md)
3. **详细指南**：查看 [ACCOUNT_LINKING_GUIDE.md](ACCOUNT_LINKING_GUIDE.md)
4. **错误追踪**：Firebase Console → Logs

---

**检查表完成日期：** ___________  
**检查者：** ___________  
**备注：** ___________

