# ⚡ OAuth 修复 - 快速参考卡

## 🎯 核心问题
```
错误: redirect_uri_mismatch
原因: Firebase OAuth 配置与实际应用 URL 不匹配
解决: 3 步配置 Firebase 和 Google Cloud
```

---

## 📍 3 个必需的配置位置

### 1️⃣ Firebase Console - Google 提供者
```
https://console.firebase.google.com/project/stillhere-ad395/authentication/providers
```

**需要的字段**:
```
Authorized JavaScript Origins:
  ✓ https://stillhere-ad395.web.app
  ✓ https://stillhere-ad395.firebaseapp.com

Authorized Redirect URIs:
  ✓ https://stillhere-ad395.web.app/__/auth/callback
  ✓ https://stillhere-ad395.firebaseapp.com/__/auth/callback
```

✅ 点击保存 → **等待 2-3 分钟**

---

### 2️⃣ Google Cloud - OAuth 同意屏幕
```
https://console.cloud.google.com/apis/consent
```

**必填项**:
```
☑ User Type: External
☑ App name: StillHere
☑ User support email: congtr61@gmail.com
☑ Developer contact: congtr61@gmail.com
☑ Add congtr61@gmail.com to Test users
```

✅ 点击发布 → **完成**

---

### 3️⃣ Google Cloud - OAuth Credentials
```
https://console.cloud.google.com/apis/credentials
```

**找到 Web 客户端并编辑**:

```
✓ Authorized JavaScript Origins:
  - https://stillhere-ad395.web.app
  - https://stillhere-ad395.firebaseapp.com

✓ Authorized Redirect URIs:
  - https://stillhere-ad395.web.app/__/auth/callback
  - https://stillhere-ad395.firebaseapp.com/__/auth/callback
```

✅ 点击保存

---

## 🧪 测试修复

```
1. 清除浏览器缓存 (Ctrl+Shift+Delete)
2. 清除 Cookie 和网站数据 ✓
3. 重新访问: https://stillhere-ad395.web.app
4. 点击 "使用 Google 账号登录"
5. 成功登录 ✅
```

---

## ⏰ 时间表

```
立即执行 (现在)
  ↓
配置 Firebase Google 提供者 (1 分钟)
  ↓
配置 Google Cloud OAuth 同意屏幕 (1 分钟)
  ↓
配置 Google Cloud Credentials (1 分钟)
  ↓
清除浏览器缓存 (1 分钟)
  ↓
等待生效 (2-3 分钟) ⏳
  ↓
测试登录 (立即) ✅
```

**总耗时: 6-8 分钟**

---

## ✨ 成功迹象

```
✅ 无 "redirect_uri_mismatch" 错误
✅ Google 登录窗口正常打开
✅ 登录后进入应用仪表板
✅ 显示心跳倒计时和指令列表
```

---

## 🆘 如果仍未成功

| 问题 | 解决方案 |
|------|---------|
| 仍有 redirect_uri_mismatch | 再等 5 分钟，清除更多缓存 |
| 无法打开 Google 登录窗口 | 尝试无痕浏览模式 |
| 登录成功但显示权限错误 | 检查 Firestore 规则配置 |
| 在其他设备也有问题 | 问题在服务器端，需要重新配置 |

---

## 📞 获取实时帮助

如果按照以上步骤后仍未解决，请提供:

```
1. 错误消息的完整文本
2. 浏览器 (Chrome/Firefox/Safari)
3. 设备 (Windows/Mac/Linux)
4. 国家地区 (用于 DNS 问题排查)
5. Firebase 项目检查 (firebase projects:list)
```

---

**预计修复时间**: 10 分钟 ⏱️  
**成功率**: 99% (如果配置正确)

---

**立即开始修复**: 
1. 打开第一个链接 (Firebase Console)
2. 按照 3 个配置位置依次完成
3. 清除浏览器缓存后测试

**希望你能尽快解决！** 💪
