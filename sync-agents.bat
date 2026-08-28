@echo off
cd /d "C:\Users\shicheng.chang\.config\opencode"
echo ============================================
echo   Sync AGENTS.md to all branches
echo ============================================
echo.

:: Remember current branch
for /f "tokens=*" %%i in ('git branch --show-current') do set CURRENT=%%i
echo Current branch: %CURRENT%
echo.

:: Check if AGENTS.md has changes
git diff --name-only | findstr /i "AGENTS.md" >nul
if %errorlevel% neq 0 (
    git diff --cached --name-only | findstr /i "AGENTS.md" >nul
    if %errorlevel% neq 0 (
        echo [SKIP] No changes in AGENTS.md
        goto :end
    )
)

echo [1/3] Committing AGENTS.md to %CURRENT% ...
git add AGENTS.md
git commit -m "update AGENTS.md"
echo.

:: Merge to other branches
for /f "tokens=*" %%i in ('git branch --format^("%%^(refname:short^)"^)') do (
    if "%%~i" neq "%CURRENT%" (
        echo [2/3] Merging to %%~i ...
        git checkout %%~i
        git merge %CURRENT% --no-edit
        echo.
    )
)

:: Switch back
echo [3/3] Switching back to %CURRENT% ...
git checkout %CURRENT%
echo.

echo ============================================
echo   Done! Use TortoiseGit to push all branches
echo ============================================
:end
pause
