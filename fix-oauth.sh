#!/bin/bash

# StillHere OAuth 配置修复脚本
# 用途: 验证和修复 Google OAuth redirect_uri_mismatch 错误

echo "🔍 StillHere Google OAuth 配置检查"
echo "===================================="
echo ""

PROJECT_ID="stillhere-ad395"
WEB_APP_URL="https://stillhere-ad395.web.app/__/auth/callback"
FIREBASE_APP_URL="https://stillhere-ad395.firebaseapp.com/__/auth/callback"

echo "📋 需要配置的重定向 URI:"
echo "1️⃣  $WEB_APP_URL"
echo "2️⃣  $FIREBASE_APP_URL"
echo ""

echo "🔗 访问以下链接进行手动配置:"
echo ""
echo "✅ Firebase Console - Authentication:"
echo "   https://console.firebase.google.com/project/$PROJECT_ID/authentication/providers"
echo ""
echo "✅ Google Cloud Console - OAuth Consent Screen:"
echo "   https://console.cloud.google.com/apis/consent"
echo ""
echo "✅ Google Cloud Console - Credentials:"
echo "   https://console.cloud.google.com/apis/credentials"
echo ""

echo "✅ 配置步骤:"
echo "1. 打开 Firebase Console → Authentication"
echo "2. 点击 'Google' 提供者"
echo "3. 在 'Web SDK configuration' 中找到 'Authorized JavaScript origins'"
echo "4. 添加以下 URI:"
echo "   - https://stillhere-ad395.web.app"
echo "   - https://stillhere-ad395.firebaseapp.com"
echo ""
echo "5. 在 'Authorized redirect URIs' 中添加:"
echo "   - $WEB_APP_URL"
echo "   - $FIREBASE_APP_URL"
echo ""
echo "6. 保存并等待 2-3 分钟使配置生效"
echo ""

echo "🧪 配置完成后进行测试:"
echo "1. 清除浏览器缓存及 Cookie"
echo "2. 重新访问: $WEB_APP_URL"
echo "3. 点击 'Google 登录'"
echo "4. 应该能成功登录"
echo ""

echo "❓ 如果问题仍未解决:"
echo "1. 检查时间同步 (服务器时间必须准确)"
echo "2. 检查 Google Cloud 项目是否与 Firebase 项目关联"
echo "3. 检查 OAuth 2.0 Client ID 是否正确"
echo "4. 确保 Google 账户是项目所有者或编辑者"
echo ""
