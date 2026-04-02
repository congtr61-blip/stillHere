# 🔍 找不到 OAuth 字段？完整导航指南

## 问题诊断

如果你没有看到这两个字段：
- ❌ **Authorized JavaScript Origins**
- ❌ **Authorized Redirect URIs**

可能原因有 3 种，下面逐一解决。

---

## 🚨 问题 A: Google 提供者根本没有启用

### 症状
- 在 Authentication 页面看不到任何 Google 配置
- 或者 Google 选项显示为 "disabled"

### 解决步骤

**1. 打开 Firebase Console**
```
https://console.firebase.google.com/
```

**2. 选择你的项目**
```
选择: stillhere-ad395
```

**3. 进入 Authentication**
```
左侧菜单 → Build → Authentication
```

**4. 点击 "Sign-in method" 标签**
```
确保你在正确的标签页！
不是 "Users"，不是 "Settings"，而是 "Sign-in method"
```

**5. 查看 Google 提供者状态**
```
列表中找: "Google"
状态应该是: ✅ Enabled 或 🔵 Enabled (已启用)

如果是灰色或显示 "Disabled":
  → 点击 Google 那一行
  → 右上角打开开关 (toggle)
  → 选择一个项目 ID (通常是第一个选项)
  → 点击 "Save"
```

**6. Google 应该现在显示为启用状态** ✅

---

## 🔴 问题 B: 字段被隐藏在"高级选项"中

### 症状
- 能看到 Google 是启用的
- 但只看到 "Client ID" 和 "Client Secret"
- 看不到 Origins 字段

### 解决步骤

**1. 找到 Google 提供者卡片**
```
Authentication → Sign-in method → Google
```

**2. 点击 Google 提供者卡片**
```
不是编辑按钮（铅笔图标），而是整个 Google 区块
```

**3. 向下滚动**
```
⬇️ 向下滑动页面
应该能看到：
  - Authorized domains
  - Web SDK configuration (or similar heading)
```

**4. 在 Web SDK configuration 部分**
```
你应该看到两个文本框:
  □ Authorized JavaScript origins (空白或有内容)
  □ Authorized redirect URIs (空白或有内容)
```

**5. 如果仍然看不到，点击"Edit"按钮**
```
Google 卡片右上角有个铅笔 ✏️ 图标
点击它进入编辑模式
```

---

## 🟠 问题 C: 使用了新 UI，字段名称不同

### 症状
- Firebase 显示了新版本的 UI
- 字段可能被称为其他名称
- 看到的是表格形式而不是文本框

### 新 UI 字段映射

Firebase 新版本中，相同的字段可能被称为：

| Dart 代码需要的 | Firebase 新 UI 中显示为 |
|---|---|
| **Authorized JavaScript Origins** | • Authorized domains<br/>• Authorized web origins<br/>• Web client origins |
| **Authorized Redirect URIs** | • Redirect URIs<br/>• OAuth redirect URIs<br/>• Callback URLs |

### 新 UI 导航步骤

**1. 访问项目设置**
```
https://console.firebase.google.com/project/stillhere-ad395/settings/general
```

**2. 找到 Google Cloud Project**
```
在"Your Firebase Project"部分
找到: "Google Cloud Project"
点击那个蓝色链接
```

**3. 这会打开 Google Cloud Console**
```
会自动打开: https://console.cloud.google.com/
继续看下面的 "问题 D" 部分
```

---

## 🟡 问题 D: 直接在 Google Cloud Console 配置

### 症状
- 发现 Firebase UI 不完整
- 想直接在源头（Google Cloud）配置

### Google Cloud 中的正确位置

**1. 打开 Google Cloud Console**
```
https://console.cloud.google.com/apis/credentials
```

**2. 确保选择正确的项目**
```
顶部左侧: 下拉菜单 (Select a Project)
选择: stillhere-ad395 (可能显示为 "stillhere-ad395" 或项目 ID)
```

**3. 找到你的 OAuth 2.0 Client**
```
页面上应该看到: "OAuth 2.0 Client IDs"
找到行: "Web client" 或 "stillhere-web"
客户端 ID 应该是: 581299274158-qr77vni6a3mli0s34g9rif4lkocsqnum.apps.googleusercontent.com
```

**4. 点击那个 Client ID**
```
打开编辑对话框
```

**5. 现在你应该看到这些字段** ✅

```
编辑 OAuth 2.0 Client 对话框:

┌─────────────────────────────────────┐
│ Client ID                           │
│ 581299274158-q...                   │
│ (显示而非编辑)                        │
├─────────────────────────────────────┤
│ Authorized JavaScript origins       │ ← 【这里！】
│ ─────────────────────────────────── │
│ [输入框] https://stillhere-ad395... │
│ [+ Add URI]                         │
├─────────────────────────────────────┤
│ Authorized redirect URIs            │ ← 【这里！】
│ ─────────────────────────────────── │
│ [输入框] https://stillhere-ad395... │
│ [+ Add URI]                         │
├─────────────────────────────────────┤
│ [Cancel]  [Save]                    │
└─────────────────────────────────────┘
```

**6. 添加缺失的 URIs**

**Authorized JavaScript origins** 需要包含:
```
✓ https://stillhere-ad395.web.app
✓ https://stillhere-ad395.firebaseapp.com
```

**Authorized redirect URIs** 需要包含:
```
✓ https://stillhere-ad395.firebaseapp.com/__/auth/callback
✓ https://stillhere-ad395.web.app/__/auth/callback
```

**7. 点击 [Save]** ✅

---

## 📋 三个位置都需要配置

Google OAuth 配置分布在 3 个地方，都需要相同的 URIs：

### 位置 1️⃣: Firebase Console (最简单)
```
https://console.firebase.google.com/project/stillhere-ad395/authentication/providers

找: Google 提供者
编辑: Web SDK configuration 中的两个字段
添加相同的 URIs
```

### 位置 2️⃣: Google Cloud Console - Credentials
```
https://console.cloud.google.com/apis/credentials

找: OAuth 2.0 Client IDs → Web client
编辑: 相同的两个字段
添加相同的 URIs
```

### 位置 3️⃣: Google Cloud Console - OAuth Consent Screen
```
https://console.cloud.google.com/apis/consent

找: Authorized domains
添加: stillhere-ad395.web.app
```

---

## ✅ 验证清单

完成后，检查这些地方都已更新：

- [ ] **Firebase** - Google 提供者已配置 Origins + Redirect URIs
- [ ] **Google Cloud** - Credentials 中的 Client 已配置 Origins + Redirect URIs  
- [ ] **Google Cloud** - OAuth Consent Screen 已添加 authorized domains
- [ ] **已等待** 2-3 分钟使配置生效
- [ ] **已清除** 浏览器缓存和 Cookie
- [ ] **已测试** 访问 https://stillhere-ad395.web.app 点击登录

---

## 🧪 3 个快速诊断

### 诊断 1️⃣: Chrome 开发者工具
```
1. 访问 https://stillhere-ad395.web.app
2. 按 F12 打开开发者工具
3. 找到 "Console" 标签
4. 粘贴这个命令:

  fetch('https://accounts.google.com/.well-known/openid-configuration')
    .then(r => r.json())
    .then(d => console.log('Google OAuth ready:', !!d.token_endpoint))

5. 应该看到: ✅ Google OAuth ready: true
```

### 诊断 2️⃣: 检查 Firebase 项目配置
```
1. 访问 https://stillhere-ad395.web.app
2. 按 F12 → Console
3. 粘贴:

  console.log('Firebase config:', firebase.app().options)

4. 应该看到日志显示你的 projectId 等信息
```

### 诊断 3️⃣: 测试 OAuth 流程
```
1. 访问 https://stillhere-ad395.web.app
2. 点击 "使用 Google 账号登录"
3. 观察结果:
   ✅ 如果打开 Google 登录窗口 → 配置正确
   ❌ 如果显示 "redirect_uri_mismatch" → URIs 配置不完整
   ❌ 如果显示"无效的请求"错误 → 项目 ID 不匹配
```

---

## 🆘 仍然找不到字段？

如果按照以上步骤仍然找不到这些字段，可能是：

1. **你在的不是正确的 Google Cloud 项目**
   ```
   → 检查 Firebase Console 中的项目 ID 是否确实是 stillhere-ad395
   → 检查 Google Cloud Console 顶部选择的是否是同一个项目
   ```

2. **Google OAuth 客户端类型错误**
   ```
   → 在 Google Cloud Credentials 中，需要找的是 "Web application" 类型
   → 不是 "Desktop"、"Mobile" 或其他类型
   → 如果找不到 Web application，需要创建一个新的
   ```

3. **Firebase 和 Google Cloud 没有链接**
   ```
   → 访问: https://console.firebase.google.com/project/stillhere-ad395/settings/general
   → 确保 "Google Cloud Project" 字段显示了 stillhere-ad395
   → 如果是"Link a Google Cloud project"，点击它链接
   ```

### 如果需要创建新的 OAuth 客户端

```
1. 访问: https://console.cloud.google.com/apis/credentials
2. 点击 [+ Create Credentials] → OAuth 2.0 Client ID
3. 如果提示配置同意屏幕，先完成那个
4. 应用类型选: Web application
5. 名称: StillHere Web App
6. 添加 URIs:
   Origins: https://stillhere-ad395.web.app, https://stillhere-ad395.firebaseapp.com
   Redirect: https://stillhere-ad395.web.app/__/auth/callback, https://stillhere-ad395.firebaseapp.com/__/auth/callback
7. 点击 Create
8. 复制新的 Client ID
9. 更新 web/index.html 中的 google-signin-client_id
   <meta name="google-signin-client_id" content="[新的 Client ID]">
10. 运行: flutter build web --release
11. 运行: firebase deploy --only hosting
```

---

## 📞 最终检查

在这三个位置都添加了 URIs 之后：

```bash
# 1. 清除浏览器缓存
Ctrl + Shift + Delete

# 2. 等待 2-3 分钟

# 3. 打开无痕模式测试
Ctrl + Shift + N

# 4. 访问应用
https://stillhere-ad395.web.app

# 5. 点击 "使用 Google 账号登录"

# 预期结果:
✅ Google 登录窗口打开（无任何错误）
✅ 能输入邮箱和密码
✅ 完成登录并进入应用
✅ 看到心跳倒计时仪表板
```

---

**如果这还是不行，请告诉我：**
1. 你现在看到的是什么界面？
2. 在 Firebase 还是 Google Cloud？
3. 是否有任何错误信息？
4. 截图或详细描述你看到的内容？

我会根据你的具体情况继续帮你！
