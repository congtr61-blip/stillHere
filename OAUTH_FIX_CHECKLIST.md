# 🎯 OAuth redirect_uri_mismatch 修复优先级清单

## 🚨 错误症状

```
错误 400: redirect_uri_mismatch
此应用的请求无效
```

---

## 🔴 优先级 1 - 立即修复 (5 分钟)

### 步骤 1: Firebase Google 提供者配置

**访问地址**:
```
https://console.firebase.google.com/project/stillhere-ad395/authentication/providers
```

**检查项**:
- [ ] Google 提供者**已启用** ✓
- [ ] 找到 "Web SDK configuration" 部分
- [ ] 检查这两个字段:

**字段 1 - Authorized JavaScript Origins**:
```
需要包含:
✓ https://stillhere-ad395.web.app
✓ https://stillhere-ad395.firebaseapp.com
```

**字段 2 - Authorized Redirect URIs**:
```
需要包含:
✓ https://stillhere-ad395.firebaseapp.com/__/auth/callback
✓ https://stillhere-ad395.web.app/__/auth/callback
```

**完成**:
- [ ] 点击 "Save" 按钮
- [ ] **等待 2-3 分钟使配置生效**

---

## 🟠 优先级 2 - 配置同意屏幕 (3 分钟)

### 步骤 2: Google Cloud OAuth 同意屏幕

**访问地址**:
```
https://console.cloud.google.com/apis/consent
```

**必填项**:
- [ ] **User Type**: 选择 "External"
- [ ] **App name**: 填入 "StillHere"
- [ ] **User support email**: 填入 "congtr61@gmail.com"
- [ ] **Authorized domains**: 添加 "stillhere-ad395.web.app"
- [ ] **Developer contact**: 填入 "congtr61@gmail.com"

**完成**:
- [ ] 点击 "Save and Continue"
- [ ] 选择 Scopes (保留默认)
- [ ] 点击 "Save and Continue"
- [ ] 在 "Test users" 中添加 "congtr61@gmail.com"
- [ ] 点击 "Save and Finish" / "Publish"

---

## 🟡 优先级 3 - 更新 OAuth Credentials (2 分钟)

### 步骤 3: Google Cloud OAuth 凭证

**访问地址**:
```
https://console.cloud.google.com/apis/credentials
```

**查找你的 Web 客户端**:
- [ ] 找到类型为 "Web application" 的 OAuth 2.0 客户端
- [ ] 客户端 ID 应该是: `581299274158-qr77vni6a3mli0s34g9rif4lkocsqnum.apps.googleusercontent.com`

**编辑配置**:

**Authorized JavaScript Origins** - 应包含:
```
✓ https://stillhere-ad395.web.app
✓ https://stillhere-ad395.firebaseapp.com
  (可选) http://localhost:5000
```

**Authorized redirect URIs** - 应包含:
```
✓ https://stillhere-ad395.web.app/__/auth/callback
✓ https://stillhere-ad395.firebaseapp.com/__/auth/callback
  (可选) http://localhost:5000/__/auth/callback
```

**完成**:
- [ ] 点击 "Save"

---

## 🟢 优先级 4 - 清除浏览器缓存和测试 (2 分钟)

### 步骤 4: 清除缓存并测试

**清除浏览器缓存**:
```
Windows Chrome: Ctrl + Shift + Delete
Windows Firefox: Ctrl + Shift + Delete
Mac Chrome: Cmd + Shift + Delete
Mac Firefox: Cmd + Shift + Delete
```

**详细步骤**:
1. 选择 "All time" 或 "The entire time"
2. 勾选:
   - [ ] Cookies and other site data
   - [ ] Cached images and files
3. 点击 "Clear data"

**测试登录**:
1. [ ] 访问: https://stillhere-ad395.web.app
2. [ ] 点击 "使用 Google 账号登录"
3. [ ] 应该看到 Google 登录页面（无错误）
4. [ ] 使用 congtr61@gmail.com 登录
5. [ ] 成功进入应用仪表板

**成功标志**:
```
✅ 无 "redirect_uri_mismatch" 错误
✅ Google 登录窗口正常打开
✅ 能使用 Google 账户登录
✅ 进入应用后显示心跳倒计时
```

---

## ⏱️ 时间表

```
现在 (0 min)
  ↓ 
配置 Firebase (1-2 min) → [优先级 1]
  ↓
配置 Google Cloud 同意屏幕 (1-2 min) → [优先级 2]
  ↓
更新 OAuth Credentials (1 min) → [优先级 3]
  ↓
清除浏览器缓存 (1 min)
  ↓
等待配置生效 (2-3 min) ⏳
  ↓
测试登录 (立即) → [优先级 4] ✅
  ↓
完成 (总耗时: 8-10 min)
```

---

## 🆘 如果仍未成功

### 检查项 A: 配置确实已保存
- [ ] 重新访问 Firebase Console，检查配置是否还在
- [ ] 重新访问 Google Cloud Console，检查配置是否还在
- [ ] 如果丢失，重新添加

### 检查项 B: 等待时间足够
- [ ] 已等待至少 3-5 分钟
- [ ] 尝试完全关闭浏览器 (不只是标签页)
- [ ] 重新打开浏览器

### 检查项 C: 尝试无痕模式
```
Chrome: Ctrl + Shift + N
Firefox: Ctrl + Shift + P
Safari: Cmd + Shift + N
```

### 检查项 D: 尝试不同浏览器
```
✓ Chrome 最新版本
✓ Firefox 最新版本
✓ Safari (如果在 Mac)
✓ Edge (如果在 Windows)
```

### 检查项 E: 检查 Firebase 项目链接
1. [ ] 访问: https://console.firebase.google.com/project/stillhere-ad395/settings/general
2. [ ] 确认 "Google Cloud Project" 已正确链接
3. [ ] 确认 Project ID 是 "stillhere-ad395"

### 检查项 F: 检查网络和时间
```bash
# Windows Powershell - 同步系统时间
w32tm /resync /force

# 或手动: 设置 → 时间和语言 → 日期和时间 → 同步现在
```

---

## 📖 相关文档

- **快速参考**: [OAUTH_QUICK_FIX.md](OAUTH_QUICK_FIX.md)
- **完整指南**: [FIX_OAUTH_ERROR.md](FIX_OAUTH_ERROR.md)
- **诊断工具**: [OAUTH_DIAGNOSTIC.md](OAUTH_DIAGNOSTIC.md)

---

## 🧪 验证配置的诊断命令

在浏览器开发者控制台 (F12) 运行:

```javascript
// 检查当前 URL
console.log('Current URL:', window.location.href);
// 应该输出: https://stillhere-ad395.web.app

// 检查 Firebase 是否已初始化
console.log('Firebase App:', firebase.app());

// 测试 Google Sign-In (仅在配置正确时会工作)
async function testOAuth() {
  try {
    const provider = new firebase.auth.GoogleAuthProvider();
    const result = await firebase.auth().signInWithPopup(provider);
    console.log('✅ OAuth 配置正确！用户:', result.user.email);
  } catch (error) {
    console.error('❌ OAuth 配置错误:');
    console.error('Error code:', error.code);
    console.error('Error message:', error.message);
  }
}

// 执行测试
testOAuth();
```

---

## ✨ 预期结果

修复成功后:

```
✅ 访问 https://stillhere-ad395.web.app
✅ 点击 "使用 Google 账号登录"
✅ Google 登录窗口打开（无任何错误）
✅ 输入凭证 (congtr61@gmail.com)
✅ 登录成功
✅ 看到应用仪表板和心跳倒计时
```

---

## 📋 检查清单

完整修复检查清单:

- [ ] **优先级 1**: Firebase Google 提供者已配置
  - [ ] Origins 已添加
  - [ ] Redirect URIs 已添加
  - [ ] 已保存并等待生效

- [ ] **优先级 2**: Google Cloud 同意屏幕已配置
  - [ ] 用户类型设为 External
  - [ ] 应用名称已填入
  - [ ] 邮箱已填入
  - [ ] 已添加到测试用户

- [ ] **优先级 3**: OAuth Credentials 已更新
  - [ ] JavaScript Origins 已添加
  - [ ] Redirect URIs 已添加
  - [ ] 已保存

- [ ] **优先级 4**: 浏览器缓存已清除
  - [ ] 所有缓存已清除
  - [ ] 所有 Cookie 已清除
  - [ ] 浏览器已重启

- [ ] **测试**: 登录功能正常
  - [ ] 无 redirect_uri_mismatch 错误
  - [ ] Google 登录窗口打开
  - [ ] 成功登录
  - [ ] 进入应用

---

**状态**: 等待你的反馈 👀  
**预计成功率**: 99% (如果按照步骤执行)

从**优先级 1** 开始，然后按顺序进行！
