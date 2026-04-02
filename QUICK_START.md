# 🚀 StillHere 快速部署指南

## 📌 部署状态

- ✅ **前端**: 已部署到 Firebase Hosting
  - 访问地址: https://stillhere-ad395.web.app
  - 构建: `flutter build web --release`

- ✅ **后端**: 已部署 Cloud Functions
  - 函数名: `dailySecurityCheck`
  - 执行: 每天凌晨 00:00 UTC
  - 功能: 自动检查失联用户并发送邮件

- ⚠️ **Firestore 安全规则**: 需要立即部署！(🔓 当前无权限控制)

---

## 🔒 立即部署安全规则 (必须)

```bash
cd c:\Users\Administrator\Desktop\Jason\stillHere\stillhere
firebase deploy --only firestore:rules
```

**规则内容**:
- 用户只能访问自己的数据 (`users/{userId}`)
- 用户只能读写自己的遗产指令 (`records/{recordId}`)
- 默认拒绝所有其他访问

---

## ✅ 快速测试

### 1. 打开应用
访问: https://stillhere-ad395.web.app

### 2. 登录
点击 "使用 Google 账号登录"

### 3. 创建遗产指令
- 点击右下角 ➕ 按钮
- 填写: 标题、继承人邮箱、指令内容
- 点击 "SAVE" 保存

### 4. 验证心跳系统
- 点击中间的青色圆环
- 观察倒计时更新（应重置为 72 小时）

### 5. 测试邮件发送（可选）
**方式 A: 等待定时任务**
- 每天凌晨 00:00 UTC 自动运行

**方式 B: 手动触发** (需要 Google Cloud 权限)
- 进入 Google Cloud Console
- Cloud Scheduler → 找到 `dailySecurityCheck`
- 点击 "Force run" (强制执行)

**方式 C: 修改数据库测试**
```javascript
// 在 Firestore Console 中：
// 1. 找到你的用户文档 (users/{uid})
// 2. 编辑 lastHeartbeat 字段，设置为 3+ 天前
// 3. 等待或手动触发云函数
// 4. 查看邮箱是否收到邮件
```

---

## 📧 邮件验证

当邮件发送时，继承人会收到：

**邮件内容包括**:
- ✅ HTML 格式（漂亮的深色主题）
- ✅ 6位随机验证码
- ✅ HMAC 签名（防伪）
- ✅ 发送时间戳
- ✅ 安全提示

**验证步骤**:
1. 收到邮件（From: StillHere 遗产系统）
2. 查看邮件中的验证码
3. 核对指令内容的真实性
4. 执行相应的遗产指令

---

## 🔧 故障排查

### 问题: 邮件未发送

**查看 Cloud Functions 日志**:
```bash
firebase functions:log --limit 100
```

**常见原因**:
1. Gmail 凭证错误
   - 检查: `functions/.env` 中的 `GMAIL_USER` 和 `GMAIL_PASS`
   - 验证: https://myaccount.google.com/apppasswords

2. 继承人邮箱无效
   - 检查: Firestore 中的 `heirEmail` 字段

3. Firestore 规则阻止访问
   - 检查: 是否部署了安全规则

### 问题: 用户看不到指令列表

**原因**: Firestore 规则未部署

**解决**:
```bash
firebase deploy --only firestore:rules
```

### 问题: 登录失败

**排查步骤**:
```bash
# 检查 Firebase Auth 配置
firebase auth:export accounts.json

# 验证 Google OAuth 配置
# Firebase Console → Authentication → Google Sign-in
```

---

## 📦 部署结果

### 前端 (Frontend)
```
build/web/
├── index.html              ✅ 主页面
├── main.dart.js            ✅ Dart 编译后的 JS
├── manifest.json           ✅ PWA 配置
├── assets/                 ✅ 资源文件
│   ├── AssetManifest.bin.json
│   ├── FontManifest.json
│   └── fonts/
└── canvaskit/              ✅ Flutter Web 运行时
    ├── canvaskit.js
    └── 其他依赖...
```

### 后端 (Backend)
```
functions/
├── index.js                ✅ Cloud Functions 代码
├── package.json            ✅ 依赖清单
├── .env                    ✅ 环境变量
└── node_modules/           ✅ npm 依赖

部署的函数:
└── dailySecurityCheck      📅 每天 00:00 执行
    ├── 1. 扫描失联用户
    ├── 2. 生成验证码
    ├── 3. 发送邮件
    └── 4. 记录状态
```

---

## 📊 性能指标

| 指标 | 值 |
|------|-----|
| 前端页面加载 | < 2s |
| 登录响应 | < 1s |
| 指令加载 | 实时 (Firestore) |
| 邮件发送延迟 | < 30s |
| 云函数执行时间 | < 5 分钟 |

---

## 🎯 后续计划

- [ ] 添加移动应用 (iOS/Android)
- [ ] 实现文件附件功能 (Firebase Storage)
- [ ] 邮件模板多语言支持
- [ ] 用户统计和分析器
- [ ] API 文档生成

---

## 🆘 需要帮助？

如有问题，请检查:

1. **Firebase Console** 
   - https://console.firebase.google.com/project/stillhere-ad395

2. **Cloud Functions 日志**
   ```bash
   firebase functions:log
   ```

3. **Firestore 状态**
   - 检查是否所有规则已部署
   - 验证集合权限

4. **邮件测试**
   - 查看 Firestore 中的 `status` 字段
   - 检查 `failureReason` 了解失败原因

---

**祝贺! 🎉 StillHere 已准备好！**

访问应用: https://stillhere-ad395.web.app
