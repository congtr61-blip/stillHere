# 邮箱绑定与账号链接 - 快速检查脚本 (Windows PowerShell)
# Email Binding and Account Linking - Quick Check Script
#
# 使用: .\check_email_binding.ps1
# Usage: .\check_email_binding.ps1
#
# 如果遇到执行策略错误，运行:
# If you get execution policy error, run:
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

param(
    [switch]$Verbose = $false
)

# 颜色定义
$Green = 'Green'
$Red = 'Red'
$Yellow = 'Yellow'

# 检查计数器
$Pass = 0
$Fail = 0
$Warn = 0

# 日志函数
function Write-Check {
    param(
        [string]$Status,
        [string]$Message
    )
    
    switch ($Status) {
        "pass" {
            Write-Host "✓ " -ForegroundColor $Green -NoNewline
            Write-Host $Message
            $script:Pass++
        }
        "fail" {
            Write-Host "✗ " -ForegroundColor $Red -NoNewline
            Write-Host $Message -ForegroundColor $Red
            $script:Fail++
        }
        "warn" {
            Write-Host "⚠ " -ForegroundColor $Yellow -NoNewline
            Write-Host $Message -ForegroundColor $Yellow
            $script:Warn++
        }
    }
}

# 检查文件存在性
function Check-FileExists {
    param(
        [string]$FilePath,
        [string]$Description
    )
    
    if (Test-Path $FilePath) {
        Write-Check "pass" "$Description"
    } else {
        Write-Check "fail" "$Description - 文件不存在 (File not found: $FilePath)"
    }
}

# 检查文件内容
function Check-FileContent {
    param(
        [string]$FilePath,
        [string]$Pattern,
        [string]$Description
    )
    
    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath -Raw
        if ($content -match $Pattern) {
            Write-Check "pass" $Description
        } else {
            Write-Check "fail" "$Description - 内容未找到 (Content not found)"
        }
    } else {
        Write-Check "fail" "$Description - 文件不存在 (File not found: $FilePath)"
    }
}

Write-Host "======================================"
Write-Host "邮箱绑定实现检查 / Email Binding Check"
Write-Host "======================================"
Write-Host ""

# 1. 检查核心文件
Write-Host "1️⃣  检查核心文件 / Checking Core Files"
Write-Host "---"

Check-FileExists "lib\services\auth_service.dart" "auth_service.dart 存在"
Check-FileExists "lib\screens\contact_binding_page.dart" "contact_binding_page.dart 存在"
Check-FileExists "lib\main.dart" "main.dart 存在"

Write-Host ""
Write-Host "2️⃣  检查新增方法 / Checking New Methods"
Write-Host "---"

Check-FileContent "lib\services\auth_service.dart" "checkEmailStatus" "checkEmailStatus() 方法"
Check-FileContent "lib\services\auth_service.dart" "isEmailInUse" "isEmailInUse() 方法"
Check-FileContent "lib\services\auth_service.dart" "isEmailVerified" "isEmailVerified() 方法"
Check-FileContent "lib\services\auth_service.dart" "resendEmailVerification" "resendEmailVerification() 方法"
Check-FileContent "lib\services\auth_service.dart" "linkEmailCredential" "linkEmailCredential() 方法"

Write-Host ""
Write-Host "3️⃣  检查 UI 更新 / Checking UI Updates"
Write-Host "---"

Check-FileContent "lib\screens\contact_binding_page.dart" "_showPasswordInput" "_showPasswordInput 状态变量"
Check-FileContent "lib\screens\contact_binding_page.dart" "_passwordController" "_passwordController 控制器"
Check-FileContent "lib\screens\contact_binding_page.dart" "_showAccountMergingDialog" "_showAccountMergingDialog() 方法"
Check-FileContent "lib\screens\contact_binding_page.dart" "_handleLinkEmailWithPassword" "_handleLinkEmailWithPassword() 方法"
Check-FileContent "lib\screens\contact_binding_page.dart" "链接账户" "链接账户按钮文本"

Write-Host ""
Write-Host "4️⃣  检查 Firebase 配置 / Checking Firebase Configuration"
Write-Host "---"

Check-FileContent "lib\main.dart" "kIsWeb" "Web 平台检查"
Check-FileContent "lib\main.dart" "(reCAPTCHA|RecaptchaV3Provider)" "reCAPTCHA 配置"

Write-Host ""
Write-Host "5️⃣  检查文档 / Checking Documentation"
Write-Host "---"

Check-FileExists "ACCOUNT_LINKING_GUIDE.md" "ACCOUNT_LINKING_GUIDE.md 文档"
Check-FileExists "EMAIL_BINDING_QUICK_REFERENCE.md" "EMAIL_BINDING_QUICK_REFERENCE.md 文档"
Check-FileExists "EMAIL_BINDING_DEVELOPER_REFERENCE.md" "EMAIL_BINDING_DEVELOPER_REFERENCE.md 文档"
Check-FileExists "EMAIL_BINDING_DEPLOYMENT_CHECKLIST.md" "EMAIL_BINDING_DEPLOYMENT_CHECKLIST.md 文档"
Check-FileExists "EMAIL_BINDING_IMPLEMENTATION_SUMMARY.md" "EMAIL_BINDING_IMPLEMENTATION_SUMMARY.md 文档"

Write-Host ""
Write-Host "6️⃣  检查 Firestore 字段 / Checking Firestore Fields"
Write-Host "---"

Check-FileContent "lib\services\auth_service.dart" "linkedEmails" "linkedEmails 字段更新"
Check-FileContent "lib\services\auth_service.dart" "emailUpdatedAt" "emailUpdatedAt 字段更新"
Check-FileContent "lib\services\auth_service.dart" "FieldValue\.arrayUnion" "使用 arrayUnion 操作"

Write-Host ""
Write-Host "7️⃣  检查错误处理 / Checking Error Handling"
Write-Host "---"

Check-FileContent "lib\services\auth_service.dart" "email-already-in-use" "处理 email-already-in-use 错误"
Check-FileContent "lib\services\auth_service.dart" "wrong-password" "处理 wrong-password 错误"
Check-FileContent "lib\services\auth_service.dart" "user-not-found" "处理 user-not-found 错误"
Check-FileContent "lib\services\auth_service.dart" "requires-recent-login" "处理 requires-recent-login 错误"
Check-FileContent "lib\services\auth_service.dart" "credential-already-in-use" "处理 credential-already-in-use 错误"

Write-Host ""
Write-Host "======================================"
Write-Host "检查结果 / Check Results"
Write-Host "======================================"

Write-Host "✓ 通过 / Passed: " -NoNewline
Write-Host $Pass -ForegroundColor $Green
Write-Host "✗ 失败 / Failed: " -NoNewline
Write-Host $Fail -ForegroundColor $Red
if ($Warn -gt 0) {
    Write-Host "⚠ 警告 / Warnings: " -NoNewline
    Write-Host $Warn -ForegroundColor $Yellow
}

Write-Host ""

if ($Fail -eq 0) {
    Write-Host "✓ 所有检查通过！可以部署。" -ForegroundColor $Green
    Write-Host "✓ All checks passed! Ready to deploy." -ForegroundColor $Green
    exit 0
} else {
    Write-Host "✗ 发现 $Fail 个问题，请检查。" -ForegroundColor $Red
    Write-Host "✗ Found $Fail issues. Please review." -ForegroundColor $Red
    exit 1
}
