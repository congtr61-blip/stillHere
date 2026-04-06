@echo off
cd /d "c:\Users\Administrator\Desktop\Jason\stillHere\stillhere"
git add privacy-policy.html privacy-policy-en.html
git commit -m "Add privacy policy HTML files for web and Google Play publishing"
git push origin main
echo Done!
pause
