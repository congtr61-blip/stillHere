#!/bin/bash

# 邮箱绑定与账号链接 - 快速检查脚本
# Quick verification script for email binding and account linking implementation
#
# 使用: ./check_email_binding.sh
# Usage: ./check_email_binding.sh

echo "======================================"
echo "邮箱绑定实现检查 / Email Binding Check"
echo "======================================"
echo ""

# 颜色定义 / Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查计数器 / Check counters
PASS=0
FAIL=0
WARN=0

# 检查函数 / Check function
check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}✗${NC} $description - 文件不存在 (File not found: $file)"
        FAIL=$((FAIL + 1))
    fi
}

check_content() {
    local file=$1
    local content=$2
    local description=$3
    
    if grep -q "$content" "$file" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $description"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}✗${NC} $description - 内容未找到 (Content not found)"
        FAIL=$((FAIL + 1))
    fi
}

echo "1️⃣  检查核心文件 / Checking Core Files"
echo "---"

check_file "lib/services/auth_service.dart" "auth_service.dart 存在"
check_file "lib/screens/contact_binding_page.dart" "contact_binding_page.dart 存在"
check_file "lib/main.dart" "main.dart 存在"

echo ""
echo "2️⃣  检查新增方法 / Checking New Methods"
echo "---"

check_content "lib/services/auth_service.dart" "Future<Map<String, dynamic>> checkEmailStatus" "checkEmailStatus() 方法"
check_content "lib/services/auth_service.dart" "Future<bool> isEmailInUse" "isEmailInUse() 方法"
check_content "lib/services/auth_service.dart" "Future<bool> isEmailVerified" "isEmailVerified() 方法"
check_content "lib/services/auth_service.dart" "Future<void> resendEmailVerification" "resendEmailVerification() 方法"
check_content "lib/services/auth_service.dart" "Future<Map<String, dynamic>> linkEmailCredential" "linkEmailCredential() 方法"

echo ""
echo "3️⃣  检查 UI 更新 / Checking UI Updates"
echo "---"

check_content "lib/screens/contact_binding_page.dart" "_showPasswordInput" "_showPasswordInput 状态变量"
check_content "lib/screens/contact_binding_page.dart" "_passwordController" "_passwordController 控制器"
check_content "lib/screens/contact_binding_page.dart" "_showAccountMergingDialog" "_showAccountMergingDialog() 方法"
check_content "lib/screens/contact_binding_page.dart" "_handleLinkEmailWithPassword" "_handleLinkEmailWithPassword() 方法"
check_content "lib/screens/contact_binding_page.dart" "链接账户" "链接账户按钮文本"

echo ""
echo "4️⃣  检查 Firebase 配置 / Checking Firebase Configuration"
echo "---"

check_content "lib/main.dart" "kIsWeb" "Web 平台检查"
check_content "lib/main.dart" "reCAPTCHA\|RecaptchaV3Provider" "reCAPTCHA 配置"

echo ""
echo "5️⃣  检查文档 / Checking Documentation"
echo "---"

check_file "ACCOUNT_LINKING_GUIDE.md" "ACCOUNT_LINKING_GUIDE.md 文档"
check_file "EMAIL_BINDING_QUICK_REFERENCE.md" "EMAIL_BINDING_QUICK_REFERENCE.md 文档"
check_file "EMAIL_BINDING_DEVELOPER_REFERENCE.md" "EMAIL_BINDING_DEVELOPER_REFERENCE.md 文档"
check_file "EMAIL_BINDING_DEPLOYMENT_CHECKLIST.md" "EMAIL_BINDING_DEPLOYMENT_CHECKLIST.md 文档"
check_file "EMAIL_BINDING_IMPLEMENTATION_SUMMARY.md" "EMAIL_BINDING_IMPLEMENTATION_SUMMARY.md 文档"

echo ""
echo "6️⃣  检查 Firestore 字段 / Checking Firestore Fields"
echo "---"

check_content "lib/services/auth_service.dart" "linkedEmails" "linkedEmails 字段更新"
check_content "lib/services/auth_service.dart" "emailUpdatedAt" "emailUpdatedAt 字段更新"
check_content "lib/services/auth_service.dart" "FieldValue.arrayUnion" "使用 arrayUnion 操作"

echo ""
echo "7️⃣  检查错误处理 / Checking Error Handling"
echo "---"

check_content "lib/services/auth_service.dart" "email-already-in-use" "处理 email-already-in-use 错误"
check_content "lib/services/auth_service.dart" "wrong-password" "处理 wrong-password 错误"
check_content "lib/services/auth_service.dart" "user-not-found" "处理 user-not-found 错误"
check_content "lib/services/auth_service.dart" "requires-recent-login" "处理 requires-recent-login 错误"
check_content "lib/services/auth_service.dart" "credential-already-in-use" "处理 credential-already-in-use 错误"

echo ""
echo "======================================"
echo "检查结果 / Check Results"
echo "======================================"
echo -e "✓ 通过 / Passed: ${GREEN}${PASS}${NC}"
echo -e "✗ 失败 / Failed: ${RED}${FAIL}${NC}"
if [ $WARN -gt 0 ]; then
    echo -e "⚠ 警告 / Warnings: ${YELLOW}${WARN}${NC}"
fi
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ 所有检查通过！可以部署。${NC}"
    echo "✓ All checks passed! Ready to deploy."
    exit 0
else
    echo -e "${RED}✗ 发现 $FAIL 个问题，请检查。${NC}"
    echo -e "✗ Found $FAIL issues. Please review."
    exit 1
fi
