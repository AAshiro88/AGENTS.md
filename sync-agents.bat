@echo off
cd /d "C:\Users\shicheng.chang\.config\opencode"

:: 記住目前分支
for /f "tokens=*" %%i in ('git branch --show-current') do set CURRENT=%%i

:: 檢查 AGENTS.md 是否有變更
git diff --name-only | findstr /i "AGENTS.md" >nul
if %errorlevel% neq 0 (
    git diff --cached --name-only | findstr /i "AGENTS.md" >nul
    if %errorlevel% neq 0 (
        echo AGENTS.md 沒有變更
        goto :end
    )
)

:: 提交到目前分支
git add AGENTS.md
git commit -m "update AGENTS.md"

:: 合併到其他分支
for /f "tokens=*" %%i in ('git branch --format^("%%^(refname:short^)"^)') do (
    if "%%~i" neq "%CURRENT%" (
        echo 合併到 %%~i ...
        git checkout %%~i
        git merge %CURRENT% --no-edit
    )
)

:: 切回原分支
git checkout %CURRENT%

echo 完成
:end
pause
