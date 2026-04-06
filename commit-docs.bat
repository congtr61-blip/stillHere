@echo off
chcp 65001 >nul
cd /d "c:\Users\Administrator\Desktop\Jason\stillHere\stillhere"

REM 添加新的综合文档
git add INDEX.md FEATURES.md DEPLOYMENT.md TESTING.md TROUBLESHOOTING.md

REM 提交
git commit -m "docs: consolidate 28 documents into 5 comprehensive guides"

REM 推送
git push origin main

echo.
echo 提交完成！
pause
