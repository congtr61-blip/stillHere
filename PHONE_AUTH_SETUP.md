# 手机号登录功能配置指南

## 概述
此应用现已支持以下认证方式：
- ✅ Google 登录（已实现）
- ✅ **手机号登录（新增）**
- ✅ 每个账号可绑定邮箱（用于邮件通知）
- ✅ 每个账号可绑定手机号（用于短信通知或 2FA）

## 必需的 Firebase 配置

### 1. 启用 Phone Authentication
1. 访问 [Firebase Console](https://console.firebase.google.com)
2. 选择您的项目 → Authentication
3. 点击 "Sign-in method" 标签
4. 找到 "Phone" 选项，点击启用
5. 可选：配置速率限制和允许的国家/地区

### 2. 配置 Firestore 规则
为了安全地存储用户的联系方式，更新 Firestore 规则：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用户文档
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
      
      // 用户的记录集合
      match /records/{recordId} {
        allow read, write: if request.auth.uid == uid;
      }
    }
  }
}
```

### 3. 配置 Firebase 存储规则（可选）
如果使用存储媒体文件：

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{uid}/{allPaths=**} {
      allow read, write: if request.auth.uid == uid;
    }
  }
}
```

## 用户文档结构

用户在 Firestore 中的文档结构如下：

```json
{
  "users/{uid}": {
    "uid": "firebase_uid",
    "email": "user@example.com",
    "emailVerified": false,
    "phoneNumber": "+8613800138000",
    "phoneNumberVerified": true,
    "displayName": "User Name",
    "photoUrl": "https://...",
    "createdAt": "2024-01-01T12:00:00Z",
    "lastLoginAt": "2024-01-15T08:30:00Z",
    "lastHeartbeat": "2024-01-15T08:30:00Z",
    "status": "active"
  }
}
```

## 功能说明

### 手机号登录流程
1. **输入手机号** → 应用通过 Firebase Phone Auth 发送验证码到手机
2. **输入验证码** → 用户输入收到的 6 位验证码
3. **完成登录** → Firebase 验证无误后，用户即可登录

### 联系方式管理
用户登录后，可以通过以下步骤管理联系方式：

1. **访问菜单** → 在 Dashboard 右上角点击 ⋮ 按钮
2. **选择"联系方式管理"** → 打开管理页面
3. **绑定邮箱**
   - 输入邮箱地址
   - 点击"绑定邮箱"
   - 查收验证邮件并点击验证链接
4. **绑定手机号**
   - 输入手机号（支持 +86 格式或直接输入数字）
   - 点击"发送验证码"
   - 输入收到的验证码
   - 点击"验证并绑定"

### 支持的手机号格式
- `13800138000` （自动添加 +86 前缀）
- `+8613800138000` （完整国际格式）

## Android 配置（重要！）

由于使用了 Firebase Phone Authentication，需要进行额外配置：

### 1. 添加 SHA-1 证书指纹
1. 运行命令获取应用的 SHA-1：
   ```bash
   ./gradlew signingReport
   ```
2. 复制 Release SHA-1
3. 在 Firebase Console 中：
   - 项目设置 → 您的应用 → Android 应用
   - 添加 SHA-1 指纹

### 2. 启用 Play Integrity API
1. 在 Firebase Console 中启用 Play Integrity API
2. 这是 Android 上进行 reCAPTCHA 验证所必需的

## 测试手机号

Firebase 提供了以下用于测试的虚拟手机号：

| 国家 | 号码 | 验证码 |
|------|------|--------|
| 中国（+86） | +8611111111111 | 123456 |
| 美国（+1） | +13334445555 | 123456 |
| 英国（+44） | +441632960001 | 123456 |

**注意：** 这些测试号码仅在开发环境中有效，生产环境会收到真实的短信。

## 常见问题

### Q: 为什么我发送验证码时收不到短信？
A: 
- 检查手机号格式是否正确
- 确保 Firebase console 中已启用 Phone Authentication
- 如果使用虚拟号码，请确认是否在开发模式
- 检查运营商是否支持国际短信

### Q: 手机号解绑后还能重新绑定吗？
A: 可以。用户可以随时解绑和重新绑定新的邮箱/手机号。

### Q: 一个账户可以绑定多个邮箱/手机号吗？
A: 当前设计每个账户只支持一个邮箱和一个手机号。如需支持多个，需要修改 Firestore 结构。

### Q: 邮箱和手机号是否必填？
A: 不是必填的。用户可以只绑定其中之一，或都不绑定。

## 调试

### 查看 Firebase 认证日志
1. Firebase Console → Authentication → Logs
2. 查看最近的登录尝试和错误日志

### 本地调试
应用使用 `debugPrint()` 输出详细日志，可在开发工具中查看

## 相关文件

- [AuthService](lib/services/auth_service.dart) - 认证逻辑
- [PhoneLoginPage](lib/screens/phone_login_page.dart) - 手机号登录 UI
- [ContactBindingPage](lib/screens/contact_binding_page.dart) - 联系方式管理 UI
- [LoginPage](lib/screens/login_page.dart) - 登录页面
