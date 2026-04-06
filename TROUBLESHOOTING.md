# 🔧 StillHere 故障排除指南

**常见问题 | 错误解决 | 调试方法 | 快速参考**

---

## 📋 目录

1. [快速诊断](#快速诊断)
2. [OAuth 认证问题](#oauth-认证问题)
3. [reCAPTCHA 问题](#recaptcha-问题)
4. [Firebase 问题](#firebase-问题)
5. [网络问题](#网络问题)
6. [本地开发问题](#本地开发问题)
7. [部署问题](#部署问题)
8. [性能问题](#性能问题)

---

## 快速诊断

### 🎯 问题诊断矩阵

| 症状 | 可能原因 | 解决方案 | 优先级 |
|------|--------|--------|--------|
| 无法登录 | OAuth 配置错误, Firebase 离线 | 检查 API 密钥, 检查 Firebase 状态 | 🔴 高 |
| reCAPTCHA 失败 | 验证失败, 密钥错误 | 清除缓存, 检查 reCAPTCHA 密钥 | 🔴 高 |
| 页面加载缓慢 | 网络问题, CDN 问题 | 检查网络, 清除缓存 | 🟡 中 |
| 邮箱不能发送 | Firebase 配置, SMTP 问题 | 检查 Cloud Functions, 检查日志 | 🟡 中 |
| 手机号验证失败 | 地区限制, 服务商问题 | 检查地区设置, 联系服务商 | 🟡 中 |

### 📊 诊断检查清单

```bash
# 1. 检查网络连接
ping google.com

# 2. 检查 Firebase 状态
curl -I https://firestore.googleapis.com

# 3. 检查 OAuth 端点
curl -I https://accounts.google.com

# 4. 查看应用日志
# 浏览器 → F12 → Console 标签

# 5. 检查 Firebase 控制台
# https://console.firebase.google.com
```

---

## OAuth 认证问题

### ❌ 问题：Google 登录按钮无法点击

**症状：**
```
用户看到 Google 登录按钮，但点击无响应
```

**原因：**
- OAuth 客户端 ID 配置不正确
- JavaScript SDK 未加载
- 跨域资源共享 (CORS) 问题

**解决步骤：**

```
1️⃣ 验证 OAuth 客户端 ID
   - 进入 GCP 控制台 → APIs & Services
   - 检查 OAuth 2.0 凭据
   - 确认已创建 Web 应用类型的凭据
   - 验证授权的 JavaScript 来源

2️⃣ 检查 Firebase 配置
   - firebase_options.dart 中的 webClientId 是否正确
   - 与 GCP 凭据中的客户端 ID 是否一致

3️⃣ 清除浏览器缓存
   - 按 Ctrl+Shift+Delete (Windows) 或 Cmd+Shift+Delete (Mac)
   - 清除所有缓存

4️⃣ 检查控制台错误
   - 按 F12 打开开发者工具
   - 查看 Console 标签中的错误消息

5️⃣ 检查 CORS 设置
   - 在 cors.json 中验证来源 URL
   - 运行: firebase deploy --only storage
```

**诊断代码：**

```dart
// lib/main.dart 中添加调试用例

void main() async {
  // 检查 Firebase 配置
  print('Firebase Project ID: ${Firebase.app().options.projectId}');
  
  // 检查 Google Sign-In 配置
  print('Web Client ID: ${FirebaseOptions.currentPlatform?.webClientId}');
  
  runApp(const MyApp());
}
```

---

### ❌ 问题：Google 登录后页面卡住

**症状：**
```
用户点击 Google 登录
弹出 Google 账户选择窗口
用户选择账户后页面不响应
```

**原因：**
- Firebase 初始化失败
- 网络超时
- Redirect URL 不匹配

**解决步骤：**

```
1️⃣ 检查 Redirect URL
   GCP 控制台 → OAuth 凭据 → 编辑
   
   允许的重定向 URI 应包括：
   - http://localhost:5000/
   - https://stillhere-ad395.web.app/
   
2️⃣ 检查 Firebase 配置
   pubspec.yaml 中的 firebase_core 版本是否最新
   
3️⃣ 查看网络请求
   F12 → Network 标签
   - 检查 Google API 请求是否成功
   - 检查 Firebase 请求是否有 403/401 错误

4️⃣ 检查服务器日志
   Firebase 控制台 → Logs
   查看认证相关的错误日志
```

**常见错误代码：**

| 错误代码 | 含义 | 解决方案 |
|---------|------|--------|
| `popup_closed_by_user` | 用户关闭了弹窗 | 正常行为，无需处理 |
| `network_error` | 网络连接问题 | 检查网络连接 |
| `invalid_client` | OAuth 客户端 ID 错误 | 检查 Firebase 配置 |
| `redirect_mismatch` | Redirect URL 不匹配 | 检查 GCP 凭据配置 |

---

### ❌ 问题：Google 登录成功但无法访问用户信息

**症状：**
```
Google 登录完成
页面跳转到仪表板
但用户名/邮箱显示为空或未定义
```

**原因：**
- Firestore 数据库规则限制读取
- 用户对象未正确初始化
- scope 权限不足

**解决步骤：**

```
1️⃣ 检查 Firestore 规则
   Firebase 控制台 → Firestore Database → Rules
   
   规则应允许：
   match /users/{uid} {
     allow read, write: if request.auth.uid == uid;
   }

2️⃣ 检查 Google OAuth Scope
   lib/services/auth_service.dart 中：
   
   static const List<String> scopes = [
     'email',
     'profile',
   ];

3️⃣ 验证用户创建逻辑
   // ✅ 正确
   UserCredential cred = await GoogleSignIn().signIn();
   User user = FirebaseAuth.instance.currentUser!;
   
   // ❌ 错误
   // 未等待用户创建完成

4️⃣ 查看数据库
   Firebase 控制台 → Firestore
   验证用户文档是否已创建
```

---

## reCAPTCHA 问题

### ❌ 问题：reCAPTCHA 验证失败（错误 401）

**症状：**
```
登录或注册时出现：
"reCAPTCHA 验证失败"
Error Code: 401
```

**原因：**
- reCAPTCHA 密钥不匹配
- 请求头信息缺失
- 浏览器阻止第三方脚本

**解决步骤：**

```
1️⃣ 验证 reCAPTCHA 密钥
   Firebase 控制台 → Project Settings → reCAPTCHA 密钥
   
   Web 密钥应配置在：
   - web/index.html 中的 <script> 标签
   - 环境变量或 firebase.json

2️⃣ 检查脚本加载
   F12 → Network 标签
   搜索 "recaptcha"
   
   应该看到：
   - https://www.google.com/recaptcha/api.js
   - 状态码：200 ✅

3️⃣ 清除浏览器数据
   - 清除 cookies
   - 清除本地存储
   - 清除缓存
   
   快捷键：
   - Windows: Ctrl+Shift+Delete
   - Mac: Cmd+Shift+Delete

4️⃣ 测试 reCAPTCHA
   在浏览器控制台输入：
   
   grecaptcha.getResponse()  // 获取 token
   grecaptcha.reset()        // 重置验证

5️⃣ 检查防火墙/代理
   - 公司防火墙可能阻止 Google 脚本
   - 代理可能修改请求头
   - 尝试使用代理绕过（VPN）
```

**诊断脚本：**

```javascript
// 在浏览器控制台运行
console.log('reCAPTCHA 诊断:');
console.log('1. reCAPTCHA 脚本加载:', typeof grecaptcha !== 'undefined');
console.log('2. 当前 Response:', grecaptcha?.getResponse());
console.log('3. reCAPTCHA 容器:', document.querySelector('.g-recaptcha'));
```

---

### ❌ 问题：reCAPTCHA 验证 Token 过期

**症状：**
```
收到错误：
"Verification token has expired"
```

**原因：**
- Token 有效期（通常 2 分钟）已过
- 多次重复提交同一 token
- 用户网络延迟

**解决步骤：**

```
1️⃣ 重新生成 Token
   点击 Chrome 标志图标（I'm not a robot）
   完成验证
   立即提交表单

2️⃣ 检查时间同步
   确保客户端和服务器系统时间一致
   
   // 客户端检查
   new Date().toISOString()

3️⃣ 增加超时时间
   如果用户需要更多时间，可以：
   - 在验证成功后立即提交
   - 显示实时倒计时
   - 提供"刷新验证"按钮

4️⃣ 查看 Cloud Functions 日志
   Firebase 控制台 → Functions → Logs
   
   搜索：invalid_token_code
```

---

### ❌ 问题：reCAPTCHA 对某些用户无法正常显示

**症状：**
```
某些地区的用户报告：
- 看不到 reCAPTCHA 窗口
- 窗口显示为空白
```

**原因：**
- 地区被 Google reCAPTCHA 限制
- 浏览器扩展冲突
- JavaScript 执行错误

**解决步骤：**

```
1️⃣ 检查地区限制
   某些国家和地区可能对 Google 脚本有限制
   
   解决办法：
   - 提供备用验证方式（邮箱验证）
   - 使用 VPN 测试

2️⃣ 检查浏览器扩展
   - 禁用所有扩展
   - 在隐私/无痕模式测试
   
   常见冲突扩展：
   - 广告拦截器
   - VPN 扩展
   - 代理管理器

3️⃣ 查看 JavaScript 错误
   F12 → Console → 搜索 "recaptcha"
   
   常见错误：
   - "grecaptcha is not defined"
   → 脚本未加载
   
   - "Failed to load reCAPTCHA"
   → 网络问题或地区限制

4️⃣ 测试备用验证
   提供邮箱验证作为 reCAPTCHA 的备选项
```

---

## Firebase 问题

### ❌ 问题：Firebase 初始化失败

**症状：**
```
应用启动时崩溃
错误消息：
"Firebase app not initialized"
```

**原因：**
- firebase_options.dart 配置不正确
- 网络连接时 Firebase 无法初始化
- API 密钥无效

**解决步骤：**

```
1️⃣ 重新生成 Firebase 配置
   flutter pub global activate flutterfire_cli
   flutterfire configure
   
   选择项目和平台

2️⃣ 验证 firebase_options.dart
   lib/firebase_options.dart
   
   检查项目 ID、API 密钥等

3️⃣ 检查 firebase.json
   确保 projectId 一致

4️⃣ 清除缓存
   flutter clean
   rm -rf pubspec.lock
   flutter pub get

5️⃣ 查看详细错误
   删除 lib/main.dart 中的 try-catch
   获取完整错误堆栈
```

---

### ❌ 问题：Firestore 查询返回空结果

**症状：**
```
应用成功启动
但仪表板不显示任何数据
用户列表为空
```

**原因：**
- 数据库规则拒绝读取
- 集合不存在
- 用户权限不足

**解决步骤：**

```
1️⃣ 检查 Firestore 规则
   Firebase 控制台 → Firestore → Rules
   
   允许测试访问（仅开发）：
   match /{document=**} {
     allow read, write: if true;
   }

2️⃣ 验证集合存在
   Firebase 控制台 → Firestore
   检查是否有 users 集合
   检查文档结构

3️⃣ 检查查询日志
   Firebase 控制台 → Logs
   搜索 Firestore 相关错误

4️⃣ 测试查询
   // Dart 代码调试
   var users = await FirebaseFirestore.instance
     .collection('users')
     .get();
   print('Users: ${users.docs.length}');

5️⃣ 启用详细日志
   // firebase.json
   {
     "firestore": {
       "rules": "firestore.rules"
     },
     "logging": {
       "level": "DEBUG"
     }
   }
```

---

### ❌ 问题：Firestore 权限被拒绝（403 错误）

**症状：**
```
数据库写入失败
错误：Permission denied for default document
```

**原因：**
- Firestore 安全规则过于严格
- 用户未认证
- 用户 UID 不匹配

**解决步骤：**

```
1️⃣ 验证用户认证
   // 检查用户是否已登录
   User? user = FirebaseAuth.instance.currentUser;
   print('User UID: ${user?.uid}');

2️⃣ 检查 Firestore 规则
   正确的规则应该：
   
   match /users/{uid} {
     allow create: if request.auth.uid != null;
     allow read, update, delete: if request.auth.uid == uid;
   }

3️⃣ 检查数据写入路径
   // ✅ 正确
   FirebaseFirestore.instance
     .collection('users')
     .doc(user.uid)
     .set(data);
   
   // ❌ 错误
   FirebaseFirestore.instance
     .collection('users')
     .add(data);  // 生成自动 ID

4️⃣ 测试规则
   Firebase 控制台 → Firestore → Rules
   点击"模拟"测试规则

5️⃣ 启用调试模式
   // pubspec.yaml
   dependencies:
     firebase_core: latest
   
   // main.dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
```

---

## 网络问题

### ❌ 问题：CORS 错误（跨域资源共享）

**症状：**
```
浏览器控制台错误：
Access to XMLHttpRequest at 'https://...' from origin 'http://localhost:5000'
has been blocked by CORS policy
```

**原因：**
- Firebase 或 API 服务器的 CORS 配置不允许跨域请求
- 开发环境和生产环境的域名不同

**解决步骤：**

```
1️⃣ 检查 CORS 配置
   cors.json:
   
   [
     {
       "origin": ["http://localhost:5000", "https://stillhere-ad395.web.app"],
       "method": ["GET", "HEAD", "DELETE"],
       "responseHeader": ["Content-Type"],
       "maxAgeSeconds": 3600
     }
   ]

2️⃣ 部署 CORS 配置
   gsutil cors set cors.json gs://YOUR_BUCKET_NAME
   
   或使用 Firebase CLI：
   firebase deploy

3️⃣ 清除缓存
   Ctrl+Shift+Delete → 强制刷新

4️⃣ 检查 API 端点
   确保 APIendpoint 在白名单中：
   
   允许的来源：
   - http://localhost:*
   - https://*.web.app
   - https://*.firebaseapp.com
```

---

### ❌ 问题：请求超时（504 Gateway Timeout）

**症状：**
```
发送数据到服务器时：
504 Gateway Timeout
或
Request timeout after 30000ms
```

**原因：**
- 服务器响应缓慢
- 网络连接不稳定
- Cloud Functions 超时

**解决步骤：**

```
1️⃣ 检查网络速度
   ping google.com
   curl -w '%{time_total}' -o /dev/null -s https://firebase.google.com

2️⃣ 增加超时时间
   // Dart 代码
   final httpClient = http.Client();
   final future = httpClient.get(url)
     .timeout(Duration(seconds: 60));

3️⃣ 检查 Cloud Functions 日志
   Firebase 控制台 → Functions → Logs
   
   查看函数执行时间

4️⃣ 优化函数性能
   - 删除不必要的操作
   - 使用缓存
   - 异步处理长时间任务

5️⃣ 测试本地环境
   firebase emulators:start
   测试是否是远程问题还是本地问题
```

---

## 本地开发问题

### ❌ 问题：Flutter Web 应用无法启动

**症状：**
```
运行 flutter run -d chrome 时出错
```

**原因：**
- Flutter SDK 未正确安装
- WebGL 不支持

**解决步骤：**

```bash
# 1. 检查 Flutter 安装
flutter --version

# 2. 检查环境
flutter doctor -v

# 3. 清除缓存
flutter clean
rm -rf build/
rm -rf pubspec.lock

# 4. 获取依赖
flutter pub get

# 5. 运行应用
flutter run -d chrome

# 如果还是失败：
# 6. 使用其他浏览器
flutter run -d firefox
flutter run -d edge

# 7. 查看详细日志
flutter run -d chrome -v
```

---

### ❌ 问题：Firebase 模拟器连接失败

**症状：**
```
本地测试时无法连接 Firebase 模拟器
错误：Connection refused
```

**解决步骤：**

```bash
# 1. 检查 Node.js 和 Firebase CLI
node --version
firebase --version

# 2. 安装 Firebase 模拟器
firebase setup:emulators

# 3. 启动模拟器
firebase emulators:start

# 4. 检查输出信息
# 确保看到：
# ✔ All emulators started successfully and authenticated.

# 5. 在应用中启用模拟器连接
// lib/firebase_options.dart
if (kDebugMode) {
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
}

# 6. 重新运行应用
flutter clean
flutter run -d chrome
```

---

## 部署问题

### ❌ 问题：Firebase Hosting 部署失败

**症状：**
```
运行 firebase deploy 时出错
```

**原因：**
- Firebase CLI 未设置
- 项目 ID 不匹配
- 构建产物缺失

**解决步骤：**

```bash
# 1. 检查 Firebase CLI
firebase --version

# 2. 登录 Firebase
firebase login

# 3. 列出项目
firebase projects:list

# 4. 设置项目
firebase use --add
# 选择项目：stillhere-ad395

# 5. 构建应用
flutter build web

# 6. 检查构建输出
ls -la build/web/

# 7. 部署
firebase deploy

# 如果失败，查看详细日志
firebase deploy -v
```

---

### ❌ 问题：部署后应用崩溃或加载失败

**症状：**
```
网站显示：Error 500 或白屏
```

**原因：**
- 缺失 index.html
- JavaScript 文件未正确加载
- 环境变量不匹配

**解决步骤：**

```bash
# 1. 检查构建输出
cat build/web/index.html | head -20

# 2. 验证文件大小
ls -lh build/web/*.js | head

# 3. 查看 Firebase Hosting 日志
firebase hosting:open-site

# 进入 F12 检查：
# - Network 标签：是否所有文件都加载成功？
# - Console 标签：是否有错误消息？

# 4. 清除缓存重新部署
rm -rf build/
flutter build web
firebase deploy --only hosting

# 5. 强制清除浏览器缓存
# F12 → Settings → Disable cache (while DevTools is open)
```

---

## 性能问题

### 🐢 问题：应用加载速度慢

**症状：**
```
首屏加载时间 > 2 秒
```

**优化步骤：**

```
1️⃣ 分析性能
   - 打开应用
   - F12 → Performance → 点击记录
   - 等待页面加载完成
   - 停止记录，分析结果

2️⃣ 启用 CanvasKit（性能推荐）
   flutter run -d chrome --web-renderer canvaskit
   
   或添加到 index.html：
   <script src="canvaskit/canvaskit.js"></script>

3️⃣ 压缩资源
   flutter build web --release

4️⃣ 启用 GZIP 压缩
   // firebase.json
   {
     "hosting": {
       "cleanUrls": true,
       "trailingSlashBehavior": "REMOVE",
       "redirects": [],
       "rewrites": [{
         "source": "**",
         "destination": "/index.html"
       }]
     }
   }

5️⃣ 使用 CDN
   Firebase Hosting 自动提供 CDN
   确认部署成功后，访问应该开启缓存

6️⃣ 监控性能
   Firebase Console → Performance
   查看应用加载速度统计
```

---

### 💾 问题：应用内存占用过高

**症状：**
```
应用运行时内存占用 > 100MB
浏览器变卡、崩溃
```

**优化步骤：**

```
1️⃣ 检查内存使用
   F12 → Memory → Take heap snapshot
   分析哪些对象占用内存

2️⃣ 清理缓存
   // Dart 代码
   // 定期清除不需要的缓存
   Future<void> clearCache() async {
     // 清除图片缓存
     imageCache.clear();
     imageCache.clearLiveImages();
   }

3️⃣ 使用图片懒加载
   // ✅ 推荐
   Image.network(
     url,
     cacheHeight: 100,
     cacheWidth: 100,
   )
   
   // ❌ 避免
   Image.network(url)  // 不压缩

4️⃣ 及时释放资源
   @override
   void dispose() {
     controller.dispose();
     subscription.cancel();
     super.dispose();
   }

5️⃣ 分析依赖
   flutter pub deps
   
   检查是否有没用的大型包
```

---

## 常见错误代码速查

| 错误代码 | 含义 | 解决方案 |
|---------|------|--------|
| 400 | Bad Request | 检查请求参数 |
| 401 | Unauthorized | 重新验证身份 |
| 403 | Forbidden | 检查权限 |
| 404 | Not Found | 检查 URL 地址 |
| 500 | Server Error | 联系技术支持 |
| 503 | Service Unavailable | 等待服务恢复 |
| NETWORK_ERROR | 网络错误 | 检查网络连接 |
| TIMEOUT | 请求超时 | 增加超时时间 |

---

## 获取帮助

### 📞 支持渠道

1. **查看文档**
   - [功能文档](FEATURES.md)
   - [部署指南](DEPLOYMENT.md)
   - [测试指南](TESTING.md)

2. **Firebase 官方资源**
   - Firebase 控制台：https://console.firebase.google.com
   - Stack Overflow：标签 `firebase` + `flutter`
   - GitHub Issues：flutter/flutter/issues

3. **社区支持**
   - Flutter Medium：medium.com/flutter
   - Stack Overflow
   - Reddit：r/flutterdev

### 🐛 提交 Bug 报告

```
标题：[BUG] 清晰的问题描述

内容：
- 环境：操作系统、浏览器、Flutter 版本
- 步骤：如何复现问题
- 预期：应该发生什么
- 实际：实际发生了什么
- 日志：相关的日志或错误信息
```

---

**最后更新：** 2026 年 4 月 6 日 | **版本：** 1.0
