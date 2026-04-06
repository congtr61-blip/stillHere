@echo off
setlocal enabledelayedexpansion
cd /d "c:\Users\Administrator\Desktop\Jason\stillHere\stillhere"

echo.
echo =========================================
echo 📚 文档整合完成 - 执行收尾工作
echo =========================================
echo.

REM 任务 1：提交新的综合文档到GitHub
echo ✅ 任务 1: 提交新的综合文档到GitHub...
git add INDEX.md FEATURES.md DEPLOYMENT.md TESTING.md TROUBLESHOOTING.md commit-docs.bat
git commit -m "docs: consolidate 28 documents into 5 comprehensive guides"
git push origin main
echo.

REM 任务 2：替换README.md为新版本
echo ✅ 任务 2: 替换README.md为新版本...
if exist "README.md" (
  ren "README.md" "README_old.md"
)
if exist "README_NEW.md" (
  ren "README_NEW.md" "README.md"
)
git add README.md
git commit -m "docs: update README with consolidated documentation structure"
git push origin main
echo.

REM 任务 3：删除过期的散乱MD文件
echo ✅ 任务 3: 删除过期的散乱MD文件...
del /f /q "PHONE_LOGIN_QUICK_START.md" 2>nul
del /f /q "EMAIL_BINDING_QUICK_REFERENCE.md" 2>nul
del /f /q "EMAIL_BINDING_DEVELOPER_REFERENCE.md" 2>nul
del /f /q "ACCOUNT_LINKING_GUIDE.md" 2>nul
del /f /q "IMPLEMENTATION_SUMMARY.md" 2>nul
del /f /q "DEPLOYMENT_GUIDE.md" 2>nul
del /f /q "FIREBASE_HOSTING_DEPLOYMENT.md" 2>nul
del /f /q "PHONE_AUTH_SETUP.md" 2>nul
del /f /q "LOCAL_TESTING_GUIDE.md" 2>nul
del /f /q "OAUTH_QUICK_FIX.md" 2>nul
del /f /q "OAUTH_FIX_CHECKLIST.md" 2>nul
del /f /q "OAUTH_FIND_FIELDS_GUIDE.md" 2>nul
del /f /q "OAUTH_DIAGNOSTIC.md" 2>nul
del /f /q "RECAPTCHA_QUICK_FIX.md" 2>nul
del /f /q "RECAPTCHA_FIX_SUMMARY.md" 2>nul
del /f /q "RECAPTCHA_SETUP.md" 2>nul
del /f /q "FIX_OAUTH_ERROR.md" 2>nul
del /f /q "QUICK_START.md" 2>nul
del /f /q "QUICK_REFERENCE.md" 2>nul

git add -A
git commit -m "docs: remove redundant documentation files (consolidated into main guides)"
git push origin main
echo.

REM 任务 4：验证GitHub更新
echo ✅ 任务 4: 验证GitHub更新...
echo.
echo 📊 最近的提交：
git log --oneline -5
echo.
echo 🌐 GitHub仓库状态：
git status
echo.

echo =========================================
echo ✨ 所有任务完成！
echo =========================================
echo.
echo 📚 新的文档结构：
echo   • INDEX.md - 项目导航中心
echo   • FEATURES.md - 功能与认证详解
echo   • DEPLOYMENT.md - 部署与基础设施
echo   • TESTING.md - 测试与代码质量
echo   • TROUBLESHOOTING.md - 问题排除
echo   • README.md - 已更新为新版本
echo.
echo 文档整合完成：28 个文件 → 10 个有组织的文档 ✅
echo.

pause
