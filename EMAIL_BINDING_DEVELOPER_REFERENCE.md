# 邮箱绑定与账号链接 - 开发者技术参考

## 快速概览

### 实现的功能

```
├── 邮箱绑定
│   ├── 新邮箱绑定（简单）
│   ├── 已使用邮箱检测
│   └── 自动冲突解决
├── 账号链接（新）
│   ├── 密码验证链接
│   ├── 自动识别链接
│   └── 并发处理
└── 错误处理
    ├── email-already-in-use
    ├── wrong-password
    ├── requires-recent-login
    └── credential-already-in-use
```

---

## 文件修改清单

### `lib/services/auth_service.dart`（核心变更）

#### 新增方法

```dart
// 1. 检查邮箱状态（建议在绑定前调用）
Future<Map<String, dynamic>> checkEmailStatus(String email)
  ↳ 返回：{ available: bool, status: 'available'|'in_use', methods: List<String> }
  ↳ 用途：判断邮箱是否被使用及使用方式

// 2. 验证邮箱是否被使用
Future<bool> isEmailInUse(String email)
  ↳ 返回：true/false
  ↳ 用途：简单的邮箱可用性检查

// 3. 链接邮箱凭证（密码验证）
Future<Map<String, dynamic>> linkEmailCredential(String email, String password)
  ↳ 返回：{ success: bool, message: String, linkedEmails: List<String> }
  ↳ 错误：wrong-password, user-not-found, requires-recent-login
  ↳ 用途：将已有的邮箱账户链接到当前账户

// 4. 检查邮箱是否已验证
Future<bool> isEmailVerified()
  ↳ 返回：true/false
  ↳ 用途：判断当前邮箱是否需要验证

// 5. 重新发送验证邮件
Future<void> resendEmailVerification()
  ↳ 抛出异常：FirebaseAuthException
  ↳ 用途：验证邮件过期或未收到时
```

#### 修改方法

```dart
// bindEmail() - 完全重写
// 之前：直接绑定，邮箱冲突报错
// 现在：检测冲突 → 返回状态码 → 前端决定处理方式

Future<Map<String, dynamic>> bindEmail(String email) {
  // 1. 验证邮箱格式
  // 2. 检查邮箱是否自己已有
  // 3. 尝试绑定
  //    ├─ 成功 → { status: 'success', ... }
  //    ├─ 邮箱冲突 → { status: 'email_already_in_use', ... }
  //    └─ 其他错误 → { status: 'error', message: ... }
  // 4. 返回不是异常，而是状态
}
```

#### Firestore 更新

```dart
// 添加字段：linkedEmails
/users/{uid} {
  email: String,
  emailVerified: Boolean,
  phoneNumber: String,
  phoneNumberVerified: Boolean,
  linkedEmails: Array<String>,  // NEW
  createdAt: Timestamp,
  lastLoginAt: Timestamp,
  emailUpdatedAt: Timestamp      // NEW
}

// 链接时的更新逻辑
await _firestore.collection('users').doc(userId).update({
  'linkedEmails': FieldValue.arrayUnion([email]),
  'emailUpdatedAt': Timestamp.now(),
});
```

### `lib/screens/contact_binding_page.dart`（UI 变更）

#### 新增状态变量

```dart
bool _showPasswordInput = false;
TextEditingController _passwordController = TextEditingController();
String? _emailStatusMessage;
bool _isCheckingEmailStatus = false;
```

#### 新增方法

```dart
// 1. 显示账号合并对话框
Future<void> _showAccountMergingDialog(String email, String status)
  ├─ 解释：邮箱已被使用
  ├─ 选项：使用密码链接 / 取消
  └─ 返回：用户选择

// 2. 链接邮箱（使用密码）
Future<void> _handleLinkEmailWithPassword()
  ├─ 验证密码非空
  ├─ 调用 auth.linkEmailCredential()
  ├─ 处理成功/错误
  └─ 更新 UI
```

#### UI 变更

```dart
// 添加条件渲染的密码输入框
if (_showPasswordInput) ...[
  SizedBox(height: 16),
  TextField(
    controller: _passwordController,
    obscureText: true,
    decoration: InputDecoration(
      labelText: "邮箱密码",
      hintText: "请输入该邮箱的密码",
      prefixIcon: Icon(Icons.lock),
      helperText: "用于验证您确实拥有这个邮箱账户",
    ),
  ),
  SizedBox(height: 12),
  ElevatedButton.icon(
    onPressed: _handleLinkEmailWithPassword,
    icon: Icon(Icons.link),
    label: Text("链接账户"),
  ),
]
```

#### 流程变更

```
原始流程：
输入邮箱 → 绑定 → 成功或失败

新流程：
输入邮箱 → 检查状态
  ├─ 可用 → 绑定 → 成功
  ├─ 已使用 → 显示合并对话框
  │  ├─ 点"链接" → 输入密码 → 验证 → 链接
  │  └─ 点"取消" → 提示用原方式登录
  └─ 错误 → 显示错误信息
```

---

## API 调用顺序

### 场景 1：绑定新邮箱

```dart
// 前端
var status = await authService.bindEmail('new@gmail.com');

if (status['status'] == 'success') {
  // 显示验证邮件提示
  showDialog('邮件已发送，请在邮箱中验证');
}
```

### 场景 2：绑定已使用邮箱（不知道密码）

```dart
// 前端 - 先检查
var emailStatus = await authService.checkEmailStatus('used@gmail.com');

if (!emailStatus['available']) {
  // 显示合并对话框
  showAccountMergingDialog(
    email: 'used@gmail.com',
    methods: emailStatus['methods'],  // ['password', ...]
  );
  
  // 用户点"取消"
  // 提示：用 used@gmail.com 重新登录以合并账户
}
```

### 场景 3：绑定已使用邮箱（知道密码）

```dart
// 前端 - 用户输入密码后
var result = await authService.linkEmailCredential(
  'used@gmail.com',
  'password123'
);

if (result['success']) {
  // 账户已链接
  showSnackBar('账户链接成功！现在可以用两种方式登录');
} else if (result['message'].contains('wrong-password')) {
  showError('密码错误，请重试');
}
```

---

## 错误代码参考

### Firebase 原始错误 → 应用级处理

| Firebase 错误码 | 含义 | 应用处理 | 用户提示 |
|---|---|---|---|
| `email-already-in-use` | 邮箱已被使用 | 检测邮箱状态 → 提示链接 | "该邮箱已被使用，可链接账户" |
| `wrong-password` | 密码错误 | 重新提示输入 | "密码错误，请重试" |
| `user-not-found` | 邮箱不存在 | 提示注册 | "该邮箱未注册" |
| `requires-recent-login` | 安全验证 | 要求重新登录 | "需要重新登录以确保安全" |
| `credential-already-in-use` | 凭证已链接 | 检查当前凭证 | "该凭证已链接到此账户" |
| `invalid-email` | 邮箱格式错 | 验证输入 | "请输入有效的邮箱地址" |
| `weak-password` | 密码太弱 | 提示强度 | "密码强度不足" |

### 应用级状态码

```dart
// bindEmail() 返回值
{
  'status': 'success',  // 成功
  'status': 'email_already_in_use',  // 邮箱冲突
  'status': 'invalid_email',  // 格式错误
  'status': 'error',  // 其他错误
  'message': String,  // 详细信息
  'methods': List<String>  // 使用该邮箱的登录方式
}

// linkEmailCredential() 返回值
{
  'success': bool,
  'message': String,
  'linkedEmails': List<String>,  // 现有所有链接邮箱
  'needsRecentLogin': bool  // 是否需要重新登录
}
```

---

## 数据流图

### 绑定邮箱冲突检测与处理

```
┌─────────────────────────────────────────────────────┐
│ 用户输入邮箱 → 点击"绑定邮箱"                      │
└────────────────┬────────────────────────────────────┘
                 ↓
         ┌──────────────┐
         │ 验证邮箱格式 │
         └──────┬───────┘
                │
         ┌──────▼───────────────┐
         │ 调用 bindEmail()      │
         └──────┬───────────────┘
                │
        ┌───────┴────────┬─────────────┬──────────────┐
        │                │             │              │
        ▼                ▼             ▼              ▼
     成功          邮箱冲突      格式错误        网络错误
       │              │             │              │
       ▼              ▼             ▼              ▼
    发送验证    显示链接对话框  显示错误      重试/取消
    邮件已发送  选项1：链接    格式不对
               选项2：取消
                    │
    ┌───────────────┼──────────────┐
    ▼               ▼              ▼
  取消          选择链接         耐心等待
  提示用         输入密码         原方式登
  原方式登       验证成功        录关联账户
  录             账户链接
```

---

## 集成检查表

### 后端（Firebase）

- [x] Email Authentication provider 配置
- [x] Firestore /users 集合已准备
- [x] linkedEmails 字段已加入 schema
- [x] 安全规则允许邮箱数据读写
- [ ] (可选) 函数支持邮箱验证通知

### 前端（Flutter）

- [x] auth_service.dart 新增 5 个方法
- [x] contact_binding_page.dart UI 增强
- [x] 密码输入框条件渲染
- [x] 错误处理完善
- [x] 账号合并对话框
- [ ] (建议) 添加加载动画

### 文档

- [x] ACCOUNT_LINKING_GUIDE.md - 详细指南
- [x] EMAIL_BINDING_QUICK_REFERENCE.md - 快速参考
- [x] 本文件 - 开发者参考
- [ ] (建议) API 文档自动生成

### 测试

- [ ] 单元测试：checkEmailStatus()
- [ ] 单元测试：linkEmailCredential()
- [ ] 集成测试：完整绑定流程
- [ ] 集成测试：密码验证失败
- [ ] UI 测试：密码输入框显示/隐藏
- [ ] UI 测试：错误消息显示

---

## 性能考虑

### 邮箱状态检查

```dart
// ⚠️ 避免
for (var email in emailList) {
  await checkEmailStatus(email);  // N 个请求！
}

// ✅ 推荐  
var statuses = await Future.wait(
  emailList.map(checkEmailStatus)
);  // 并发请求
```

### 缓存策略

```dart
// 建议：缓存邮箱检查结果（5 分钟）
class CachedEmailService {
  final Map<String, CacheEntry> _cache = {};
  
  Future<Map<String, dynamic>> checkEmailStatus(String email) async {
    // 检查缓存是否过期
    if (_cache.containsKey(email)) {
      final entry = _cache[email];
      if (!entry.isExpired) {
        return entry.data;
      }
    }
    
    // 获取新数据
    final status = await _auth.fetchSignInMethodsForEmail(email);
    _cache[email] = CacheEntry(status, DateTime.now());
    return status;
  }
}
```

### 网络优化

```dart
// Debounce 邮箱检查（避免输入时每次都检查）
Future<void> _onEmailChanged(String email) async {
  _emailCheckDebounce?.cancel();
  _emailCheckDebounce = Timer(Duration(milliseconds: 500), () async {
    var status = await authService.checkEmailStatus(email);
    setState(() => _emailStatus = status);
  });
}
```

---

## 安全考虑

### ✅ 实现的安全措施

1. **密码一次性使用**
   ```
   密码 → 验证 → 销毁（内存）
   不存储、不记录、不传输
   ```

2. **链接凭证管理**
   ```
   - Firebase 凭证库管理
   - 只存储凭证引用，不存储密码
   - 完全由 Firebase 处理加密
   ```

3. **验证邮件安全**
   ```
   - 唯一链接
   - 24 小时过期
   - 一次性订阅
   - IP 验证
   ```

4. **速率限制**
   ```
   Firebase 内置:
   - 密码验证：最多 5 次失败后冷却
   - 邮件发送：限制频率
   - 短信验证：防止滥用
   ```

### ⚠️ 需要注意

```dart
// ❌ 不要
authService.linkEmailCredential(email, password);
// 然后保存 password 到本地存储

// ✅ 要做
// 密码立即销毁，只保留链接状态
_passwordController.clear();
Future.delayed(Duration(seconds: 1), () {
  _passwordController.dispose();
  setState(() => _showPasswordInput = false);
});
```

### 建议的附加安全

```dart
// 1. 添加速率限制（应用层）
class RateLimiter {
  final Duration _window = Duration(hours: 1);
  final int _maxAttempts = 5;
  final Map<String, List<DateTime>> _attempts = {};
  
  bool canAttempt(String key) {
    final now = DateTime.now();
    final attempts = _attempts[key] ?? [];
    
    // 清除过期记录
    attempts.removeWhere((t) => now.difference(t) > _window);
    
    if (attempts.length >= _maxAttempts) return false;
    
    attempts.add(now);
    _attempts[key] = attempts;
    return true;
  }
}

// 2. 添加审计日志
Future<void> _logSecurityEvent(String event, String userId) {
  return _firestore.collection('audit_logs').add({
    'event': event,
    'userId': userId,
    'timestamp': Timestamp.now(),
    'ipAddress': userIpAddress,  // 获取方式见下
    'userAgent': userAgent,
  });
}

// 3. 获取客户端信息（仅 Web）
String get _userAgent => html.window.navigator.userAgent;
```

---

## 调试技巧

### 启用详细日志

```dart
// 在 auth_service.dart 中
import 'package:flutter/foundation.dart';

const bool _DEBUG_EMAIL_BINDING = kDebugMode;

Future<Map<String, dynamic>> checkEmailStatus(String email) async {
  if (_DEBUG_EMAIL_BINDING) {
    print('[EmailBinding] Checking status for: $email');
  }
  
  try {
    final methods = await _auth.fetchSignInMethodsForEmail(email);
    if (_DEBUG_EMAIL_BINDING) {
      print('[EmailBinding] Methods found: $methods');
    }
    return {'available': methods.isEmpty, 'methods': methods};
  } catch (e) {
    if (_DEBUG_EMAIL_BINDING) {
      print('[EmailBinding] Error checking email: $e');
    }
    rethrow;
  }
}
```

### 测试虚拟邮箱

```dart
// Firebase 提供的测试邮箱
const testEmails = [
  'success+uid-000000000000@example.com',
  'success+uid-111111111111@example.com',
];

// 这些邮箱可以：
// 1. 创建账户
// 2. 不需要真实验证
// 3. 用于自动化测试
```

### 查看 Firestore linkedEmails 字段

```dart
// 在控制台检查链接情况
db.collection('users').doc(uid).get().then(doc => {
  console.log(doc.data().linkedEmails);  // ['user@example.com', ...]
});

// 或在 Flutter 中
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();
    
print('Linked emails: ${userDoc['linkedEmails']}');
```

---

## 常见问题（开发者）

### Q: 为什么不自动合并数据？  
A: 出于三个原因：
1. **用户选择** - 用户应该知道发生了什么
2. **数据完整性** - 避免意外覆盖重要数据
3. **Firebase限制** - 无法将文档数据合并，只能新增字段

**替代方案：** 使用 Cloud Functions 自动迁移数据

```javascript
// functions/index.js
exports.mergeAccountsOnLink = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    if (before.linkedEmails.length < after.linkedEmails.length) {
      // 检测到新链接
      // 迁移该邮箱之前账户的数据
      const newEmail = after.linkedEmails[after.linkedEmails.length - 1];
      const oldUser = await admin.auth().getUserByEmail(newEmail);
      
      // 迁移数据逻辑...
    }
  });
```

### Q: 为什么要检查邮箱状态而不是直接绑定？
A: 三个好处：
1. **更好的 UX** - 提前告知结果，避免意外
2. **并发安全** - 减少竞态条件
3. **错误恢复** - 用户可以选择处理方式

### Q: linkedEmails 数组有上限吗？
A: 
- Firestore 数组最大 20,000 项
- 实际上，一个用户不太会链接 1000 个邮箱
- 建议限制：在应用代码中最多 10 个

```dart
if ((user['linkedEmails'] as List).length >= 10) {
  throw Exception('最多只能链接 10 个邮箱');
}
```

### Q: 如何实现"取消链接 (unlink)"？
A: Firebase 支持，但需谨慎

```dart
Future<void> unlinkEmailProvider() async {
  final currentUser = FirebaseAuth.instance.currentUser!;
  
  // 确保用户还有其他登录方式
  if (currentUser.providerData.length <= 1) {
    throw Exception('无法删除最后一个登录方式');
  }
  
  await currentUser.unlink('password');
}
```

---

## 扩展功能建议

### 1. 邮箱验证状态提醒

```dart
// 在 dashboard 显示未验证邮箱
class UnverifiedEmailBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: authService.isEmailVerified(),
      builder: (context, snapshot) {
        if (snapshot.data == false) {
          return Card(
            color: Colors.orange[100],
            child: ListTile(
              title: Text('邮箱未验证'),
              subtitle: Text('点击验证以完全激活账户'),
              trailing: ElevatedButton(
                onPressed: () => authService.resendEmailVerification(),
                child: Text('重新发送'),
              ),
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}
```

### 2. 账户安全检查

```dart
Future<Map<String, dynamic>> getAccountSecurityStatus() async {
  final user = _auth.currentUser!;
  
  return {
    'hasPassword': user.providerData.any((p) => p.providerId == 'password'),
    'hasGoogle': user.providerData.any((p) => p.providerId == 'google.com'),
    'hasPhone': user.phoneNumber != null,
    'emailVerified': user.emailVerified,
    'is2FAEnabled': user.multiFactor.enrolledFactors.isNotEmpty,
    'lastLoginAt': user.metadata.lastSignInTime,
  };
}
```

### 3. 邮箱变更历史

```dart
// Firestore 中添加
/users/{uid}/email_changes/{timestamp}
{
  'oldEmail': 'old@example.com',
  'newEmail': 'new@example.com',
  'timestamp': Timestamp,
  'verified': boolean,
}

// 用于审计和恢复
```

---

## 部署清单

- [ ] 所有测试通过
- [ ] 文档已更新
- [ ] reCAPTCHA 在生产环境启用
- [ ] Firestore 安全规则已检查
- [ ] 错误跟踪配置完成（如 Sentry）
- [ ] 用户文档已准备
- [ ] 降级计划已制定

---

## 相关文档

- [ACCOUNT_LINKING_GUIDE.md](ACCOUNT_LINKING_GUIDE.md) - 用户指南
- [EMAIL_BINDING_QUICK_REFERENCE.md](EMAIL_BINDING_QUICK_REFERENCE.md) - 快速参考
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - 部署指南

---

最后更新：2024-01-15
版本：1.1.2
作者：开发团队
