# StillHere OAuth 诊断脚本

## 🔍 诊断步骤

### 1. 验证 Firebase 配置

```bash
cd c:\Users\Administrator\Desktop\Jason\stillHere\stillhere

# 检查当前项目
firebase projects:list

# 应该显示:
# ✅ stillhere-ad395 (current)

# 检查 Firebase 凭证
firebase auth:export accounts.json
```

### 2. 验证环境配置

访问: https://stillhere-ad395.web.app

**在浏览器开发者工具中检查** (F12):

```javascript
// 在浏览器控制台运行:

// 检查 Firebase 配置
firebase.initializeApp({
  projectId: 'stillhere-ad395',
  appId: '1:581299274158:web:841b9fc86071e640f5083f',
  apiKey: 'AIzaSyB3NeaMZI47JJI8cdhTKVKMwPDpwkeIr14'
});

console.log(firebase.app());

// 检查当前 URL
console.log(window.location.href);
// 应该输出: https://stillhere-ad395.web.app

// 检查 Auth 状态
firebase.auth().onAuthStateChanged(user => {
  console.log('Current user:', user);
});
```

---

## 📋 必需的配置检查

### Firebase 项目信息
```
项目 ID: stillhere-ad395
项目号: 581299274158
Web App ID: 1:581299274158:web:841b9fc86071e640f5083f
API Key: AIzaSyB3NeaMZI47JJI8cdhTKVKMwPDpwkeIr14
```

### Google Cloud 信息
```
Google Cloud Project: stillhere-ad395
OAuth 2.0 Client Type: Web application
Allowed origins:
  ✅ https://stillhere-ad395.web.app
  ✅ https://stillhere-ad395.firebaseapp.com
  
Authorized redirect URIs:
  ✅ https://stillhere-ad395.web.app/__/auth/callback
  ✅ https://stillhere-ad395.firebaseapp.com/__/auth/callback
```

---

## 🎯 必需的 URLs

| Service | URL |
|---------|-----|
| Web App | https://stillhere-ad395.web.app |
| Firebase App | https://stillhere-ad395.firebaseapp.com |
| Firebase Console | https://console.firebase.google.com/project/stillhere-ad395 |
| Google Cloud Console | https://console.cloud.google.com/apis/credentials |
| OAuth Consent Screen | https://console.cloud.google.com/apis/consent |

---

## 🧪 测试客户端配置

在浏览器控制台输入并运行:

```javascript
// 1. 检查完整的 Firebase 初始化配置
const firebaseConfig = {
  apiKey: "AIzaSyB3NeaMZI47JJI8cdhTKVKMwPDpwkeIr14",
  authDomain: "stillhere-ad395.firebaseapp.com",
  projectId: "stillhere-ad395",
  storageBucket: "stillhere-ad395.firebasestorage.app",
  messagingSenderId: "581299274158",
  appId: "1:581299274158:web:841b9fc86071e640f5083f"
};

console.log('Firebase Config:', firebaseConfig);

// 2. 测试 Google Sign-In
async function testGoogleSignIn() {
  try {
    const provider = new firebase.auth.GoogleAuthProvider();
    const result = await firebase.auth().signInWithPopup(provider);
    console.log('Sign-in successful:', result.user);
    return true;
  } catch (error) {
    console.error('Sign-in error:', error);
    console.error('Error code:', error.code);
    console.error('Error message:', error.message);
    return false;
  }
}

// 执行测试
testGoogleSignIn();
```

---

## ⚡ 快速修复清单

### 在 Firebase Console 中 (2 分钟)

```
1. 打开: https://console.firebase.google.com/project/stillhere-ad395/authentication/providers

2. 找到 "Google" 提供者

3. 确保已启用 ✓

4. 点击编辑，检查这些字段:
   
   Web SDK Configuration:
   ✓ Authorized JavaScript origins:
     - https://stillhere-ad395.web.app
     - https://stillhere-ad395.firebaseapp.com
   
   ✓ Authorized redirect URIs:
     - https://stillhere-ad395.web.app/__/auth/callback
     - https://stillhere-ad395.firebaseapp.com/__/auth/callback

5. 点击 "保存"

6. 等待 2-3 分钟
```

### 在 Google Cloud Console 中 (2 分钟)

```
1. 打开: https://console.cloud.google.com/apis/consent

2. User Type: External ✓

3. 应用信息:
   应用名称: StillHere
   用户支持邮箱: congtr61@gmail.com
   开发者联系: congtr61@gmail.com

4. 点击 "保存并继续"

5. 在 Scopes 中保留默认值，继续

6. 在 Test users 中添加:
   congtr61@gmail.com

7. 点击 "保存并发布"
```

---

## 🔗 完整配置链接

**一键打开所需的配置页面**:

1. Firebase Authentication:
   https://console.firebase.google.com/project/stillhere-ad395/authentication/providers

2. Google Cloud OAuth Consent:
   https://console.cloud.google.com/apis/consent

3. Google Cloud Credentials:
   https://console.cloud.google.com/apis/credentials

4. Firebase Project Settings:
   https://console.firebase.google.com/project/stillhere-ad395/settings/general

---

## 💡 故障排查

### 症状: 仍然显示 redirect_uri_mismatch

**检查**:
```bash
# 1. 检查项目关键信息
firebase projects:list

# 2. 验证部署
firebase hosting:disable
firebase deploy --only hosting

# 3. 重新部署认证模块
firebase deploy --only firestore:rules

# 4. 等待 DNS 更新
# 通常需要 2-5 分钟
```

### 症状: 登录窗口打开后立即关闭

**原因**: 通常是时间同步问题

**解决**:
```bash
# Windows 同步时间
w32tm /resync /force

# 或在系统设置中:
Settings → Time & Language → Date & time → Sync now
```

### 症状: 显示 "access_denied"

**原因**: OAuth 同意屏幕未配置或用户未在测试用户列表中

**解决**:
1. 访问: https://console.cloud.google.com/apis/consent
2. 确保已配置应用名称和用户邮箱
3. 将 congtr61@gmail.com 添加为测试用户

---

## ✅ 验证修复成功

修复完成后应该看到:

```
1. ✅ 点击登录无错误
2. ✅ Google 登录页面正常打开
3. ✅ 输入凭证后可以登录
4. ✅ 应用显示 "STILL HERE" 仪表板
5. ✅ 能看到心跳倒计时
```

错误应该消失，不再显示:
```
❌ 错误 400: redirect_uri_mismatch
❌ 此应用的请求无效
```

---

## 📞 技术支持

如果按照上述步骤操作后仍未解决:

1. **收集诊断信息**:
   ```bash
   # 导出 Firebase 配置
   firebase projects:list > firebase-projects.txt
   
   # 导出错误信息
   # 在浏览器中右键 → 检查 → 控制台，复制完整错误
   ```

2. **检查浏览器开发者工具** (F12):
   - Console 选项卡: 查看完整错误消息
   - Network 选项卡: 检查 OAuth 请求的状态
   - Application 选项卡: 检查 localStorage 中的配置

3. **尝试其他浏览器**:
   如果只在某个浏览器中出现问题，可能是缓存或扩展程序的影响

4. **联系 Google 支持**:
   如果是 Google 端的问题，访问: https://support.google.com/cloudidentity

---

**最后修改**: 2026-04-02  
**状态**: 等待用户反馈配置后的结果
