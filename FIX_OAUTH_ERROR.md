# 🔧 修复 Google OAuth redirect_uri_mismatch 错误

## ❌ 当前问题

```
错误 400: redirect_uri_mismatch
应用发送的请求无效
```

**原因**: Firebase 中的 Google OAuth 重定向 URI 配置与实际应用 URL 不匹配。

---

## ✅ 解决方案（3 个步骤）

### 步骤 1️⃣: Firebase Console 配置

**访问**:
```
https://console.firebase.google.com/project/stillhere-ad395/authentication/providers
```

**操作**:
1. 点击 **Google** 提供者
2. 在弹窗中找到 **Web SDK configuration** 部分
3. 复制 **Authorized JavaScript origins** 和 **Authorized redirect URIs**

**需要添加这些 Origins**:
```
https://stillhere-ad395.web.app
https://stillhere-ad395.firebaseapp.com
```

**需要添加这些 Redirect URIs**:
```
https://stillhere-ad395.firebaseapp.com/__/auth/callback
https://stillhere-ad395.web.app/__/auth/callback
```

**保存并等待 2-3 分钟**

---

### 步骤 2️⃣: Google Cloud OAuth 同意屏幕

**访问**:
```
https://console.cloud.google.com/apis/consent
```

**必须配置项**:
```
项目: stillhere-ad395
User Type: External (如果尚未发布)
应用名称: StillHere
User support email: congtr61@gmail.com
Developer contact: congtr61@gmail.com
```

**点击 "Save and Continue"**

---

### 步骤 3️⃣: OAuth 客户端凭证

**访问**:
```
https://console.cloud.google.com/apis/credentials
```

**找到你的 Web 客户端**，编辑后添加：

**授权的 JavaScript Origins**:
```
https://stillhere-ad395.web.app
https://stillhere-ad395.firebaseapp.com
localhost:5000
```

**授权的重定向 URIs**:
```
https://stillhere-ad395.firebaseapp.com/__/auth/callback
https://stillhere-ad395.web.app/__/auth/callback
http://localhost:5000/__/auth/callback
```

**点击 "Save"**

---

## 🧪 验证修复

1. **清除浏览器数据**:
   - 打开: 浏览器设置 → 隐私与安全 → 清除浏览数据
   - 选择: 全时间、Cookie 和其他网站数据
   - 点击: 清除数据

2. **重新访问应用**:
   ```
   https://stillhere-ad395.web.app
   ```

3. **点击 "使用 Google 账号登录"**

4. **应该能成功登录** ✅

---

## 🆘 如果问题仍未解决

### 原因 A: 配置尚未生效
**解决**: 再等 2-3 分钟，然后重试

### 原因 B: 缓存问题
**解决**:
```
1. 清除浏览器 Cache 和 Cookie
2. 尝试无痕/隐私浏览模式
3. 尝试不同浏览器
```

### 原因 C: Firebase 项目配置错误
**排查**:
```bash
# 验证 Firebase 配置
firebase emulators:start --only auth
```

### 原因 D: Google Cloud 项目链接问题
**检查**:
1. Firebase Console → Project Settings
2. 确保 Google Cloud Project 正确关联
3. 确保使用的是同一个 Project ID

### 原因 E: OAuth 同意屏幕未配置
**修复**:
1. 访问: https://console.cloud.google.com/apis/consent
2. 确保应用已配置为 "External"
3. 填写所有必需字段

---

## 📋 完整检查清单

- [ ] Firebase Console 中的 Google 提供者已启用
- [ ] 已添加 Origins:
  - [ ] https://stillhere-ad395.web.app
  - [ ] https://stillhere-ad395.firebaseapp.com
- [ ] 已添加 Redirect URIs:
  - [ ] https://stillhere-ad395.firebaseapp.com/__/auth/callback
  - [ ] https://stillhere-ad395.web.app/__/auth/callback
- [ ] Google Cloud OAuth 同意屏幕已配置
- [ ] OAuth 客户端凭证已更新
- [ ] 已等待 2-3 分钟
- [ ] 已清除浏览器缓存
- [ ] 已测试登录

---

## 🔐 安全检查

✅ **你的 Google 账户** (congtr61@gmail.com):
- 应该是 Firebase 项目的所有者
- 应该是 Google Cloud 项目的所有者
- OAuth 同意屏幕应该是 "External" 类型

✅ **您的应用**:
- 使用 HTTPS (不是 HTTP)
- 部署 URL 与配置匹配
- 没有拼写错误

---

## 🎯 常见错误

| 错误 | 原因 | 解决方案 |
|------|------|---------|
| redirect_uri_mismatch | URI 配置有误 | 检查精确的 URI 拼写 |
| invalid_client | Client ID 错误 | 重新获取正确的 Client ID |
| access_denied | 同意屏幕未配置 | 配置 OAuth 同意屏幕 |
| server_error | Google 服务内部错误 | 等待片刻后重试 |

---

## 📞 获取帮助

如果上述步骤未解决问题，请检查:

1. **Firebase CLI 信息**:
```bash
firebase projects:list
# 确保 stillhere-ad395 是当前项目
```

2. **验证配置**:
```bash
firebase auth:import accounts.json --hash-algo=scrypt
# 检查认证配置是否正确
```

3. **查看 Google Cloud 日志**:
在 Google Cloud Console 中检查 Cloud Logging 中是否有错误日志。

---

## ✨ 成功标志

当修复完成后，你应该看到：

1. ✅ 页面显示 "STILL HERE" 标语
2. ✅ 点击 "使用 Google 账号登录" 无错误
3. ✅ Google 登录窗口打开
4. ✅ 成功进入应用仪表板
5. ✅ 看到心跳倒计时和指令列表

---

**如果问题仍未解决，请复制完整错误消息给开发者** 📝

最后更新: 2026-04-02
