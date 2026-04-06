# 🪦 StillHere - 数字遗产与指令系统

[![Firebase Hosting](https://img.shields.io/badge/Hosted%20on-Firebase-orange?style=flat-square)](https://stillhere-ad395.web.app/)
[![Flutter Web](https://img.shields.io/badge/Built%20with-Flutter%20Web-blue?style=flat-square)](https://flutter.dev/web)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

> **自动化数字遗产与指令传递系统** — 确保您的重要指令和数字遗产即使在您无法手动操作的情况下也能被传递。

---

## 🎯 项目概述

**StillHere** 是一个基于 Flutter 和 Firebase 的 Web 应用程序，实现了"死人开关"(Dead Man's Switch) 功能，通过定期心跳检测确保您的数字安全。

### 🫀 核心概念

用户通过与应用交互来维持一个"心跳"。如果心跳在预定义的时间段（通常为 72 小时）内停止，系统会自动触发：

1. **📨 自动分发** - 预设的指令和记录自动发送给指定的继承人
2. **🔐 加密传输** - 所有通信均通过加密邮件完成
3. **📱 简约界面** - 高对比度、生物识别主题的最小化仪表板

---

## 🚀 快速开始

**👉 [查看完整文档 → INDEX.md](INDEX.md)**

### 🔗 快速链接

| 文档 | 说明 |
|------|------|
| [📑 INDEX.md](INDEX.md) | **👈 从这里开始** - 完整项目导航 |
| [✨ FEATURES.md](FEATURES.md) | 功能与认证系统详解 |
| [🚀 DEPLOYMENT.md](DEPLOYMENT.md) | 部署与基础设施指南 |
| [🧪 TESTING.md](TESTING.md) | 测试与代码质量 |
| [🔧 TROUBLESHOOTING.md](TROUBLESHOOTING.md) | 常见问题与解决方案 |

---

## 📊 项目状态

```
开发进度：100% ✅
部署状态：100% ✅
Google Play 准备度：95% 🟡
文档整合：100% ✅
```

**🌐 实时应用：** https://stillhere-ad395.web.app/

---

## 💻 技术栈

### 前端
- **Flutter** - 跨平台 UI 框架（Web/Android/iOS）
- **Dart** - 编程语言
- **responsive 设计** - 移动端和桌面端兼容

### 后端
- **Firebase Firestore** - 实时数据库
- **Firebase Authentication** - 多方式认证（Google、Email、Phone）
- **Cloud Functions** - 自动支持的后端逻辑（Node.js）
- **Cloud Storage** - 文件存储和管理

### 第三方服务
- **Google OAuth** - 单点登录
- **Firebase Hosting** - Web 应用部署
- **reCAPTCHA Enterprise** - 机器人防护
- **Twilio/SMS** - 手机验证（可选）

---

## 🔐 安全特性

✅ **认证与授权**
- 多种登录方式（Google OAuth、Email、Phone）
- Firebase 内置身份验证
- 自动账户绑定和冲突检测

✅ **数据保护**
- Firestore 安全规则
- 端到端加密
- HTTPS/TLS 通信
- reCAPTCHA 保护

✅ **隐私合规**
- GDPR 合规
- 隐私政策：[PRIVACY_POLICY.md](PRIVACY_POLICY.md) (中文) / [PRIVACY_POLICY_EN.md](PRIVACY_POLICY_EN.md) (英文)
- 用户数据最小化

---

## 🛠️ 配置与部署

### 本地开发

```bash
# 1. 克隆项目
git clone <repo-url>
cd stillhere

# 2. 安装依赖
flutter pub get

# 3. 配置 Firebase
flutterfire configure

# 4. 启动应用（Web）
flutter run -d chrome

# 5. 启动应用（移动）
flutter run -d emulator-5554
```

### 生产部署

```bash
# 构建 Web 应用
flutter build web --release

# 部署到 Firebase Hosting
firebase deploy
```

**详见：[DEPLOYMENT.md](DEPLOYMENT.md)**

---

## 📚 文档结构

```
项目文件夹
├── INDEX.md                    # 👈 项目导航中心
├── FEATURES.md                 # 功能详解和 API 文档
├── DEPLOYMENT.md               # 部署指南
├── TESTING.md                  # 测试指引
├── TROUBLESHOOTING.md          # 常见问题解决
├── PRIVACY_POLICY.md           # 隐私政策（中文）
├── PRIVACY_POLICY_EN.md        # 隐私政策（英文）
└── GOOGLE_PLAY_RESOURCE_GUIDE.md
```

---

## 🧪 测试与质量

```bash
# 单元测试
flutter test

# 覆盖率报告
flutter test --coverage

# 代码分析
flutter analyze

# 格式检查
dart format --set-exit-if-changed .
```

**详见：[TESTING.md](TESTING.md)**

---

## 🐛 常见问题

遇到问题？查看 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

**快速解决：**

| 问题 | 解决方案 |
|------|--------|
| 无法登录 | 检查 Firebase 配置、API 密钥 |
| reCAPTCHA 失败 | 清除浏览器缓存、检查密钥 |
| 加载缓慢 | 检查网络连接、清除缓存 |
| 权限错误 | 检查 Firestore 安全规则 |

---

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支：`git checkout -b feature/AmazingFeature`
3. 提交更改：`git commit -m 'Add some AmazingFeature'`
4. 推送分支：`git push origin feature/AmazingFeature`
5. 提交 Pull Request

---

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE)

---

## 📞 联系方式

- 📧 Email: contact@stillhere.app
- 🐙 GitHub: [Project Repository](https://github.com/)
- 🌐 Website: https://stillhere-ad395.web.app/

---

**最后更新：** 2026 年 4 月 6 日 | **版本：** 1.0
