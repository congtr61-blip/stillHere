@echo off
setlocal enabledelayedexpansion

cd C:\Users\Administrator\Desktop\Jason\stillHere\stillhere

echo Checking git status...
git status

echo.
echo Resetting merge state...
git reset --merge

echo.
echo Pushing to origin main...
git push origin main --force-with-lease

echo.
echo Verifying push...
git log --oneline -1

pause
