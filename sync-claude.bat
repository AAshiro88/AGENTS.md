@echo off
cd /d "C:\Users\shicheng.chang\.claude"
echo ============================================
echo   Sync CLAUDE.md to all branches
echo ============================================
echo.

:: Check if CLAUDE.md has changes
git diff --name-only | findstr /i "CLAUDE.md" >nul
if %errorlevel% neq 0 (
    git diff --cached --name-only | findstr /i "CLAUDE.md" >nul
    if %errorlevel% neq 0 (
        echo [SKIP] No changes in CLAUDE.md
        goto :sync_master
    )
)

echo [1/4] Committing CLAUDE.md to claude ...
git add CLAUDE.md
git commit -m "update CLAUDE.md"
echo.

:sync_master
echo [2/4] Syncing to master as AGENTS.md ...
git checkout master
git show claude:CLAUDE.md > AGENTS.md
git add AGENTS.md
git diff --cached --quiet
if %errorlevel% neq 0 (
    git commit -m "sync AGENTS.md from claude"
    echo [OK] AGENTS.md updated on master
) else (
    echo [SKIP] AGENTS.md already up to date on master
)
git checkout claude
echo.

echo [3/4] Syncing to opencode repo ...
copy /y "C:\Users\shicheng.chang\.claude\CLAUDE.md" "C:\Users\shicheng.chang\.config\opencode\AGENTS.md" >nul
cd /d "C:\Users\shicheng.chang\.config\opencode"
git checkout opencode
git show claude:CLAUDE.md > AGENTS.md
git add AGENTS.md
git diff --cached --quiet
if %errorlevel% neq 0 (
    git commit -m "sync AGENTS.md from claude"
    echo [OK] AGENTS.md updated on opencode
) else (
    echo [SKIP] AGENTS.md already up to date on opencode
)
:: Sync to master
git checkout master
git show claude:CLAUDE.md > AGENTS.md
git add AGENTS.md
git diff --cached --quiet
if %errorlevel% neq 0 (
    git commit -m "sync AGENTS.md from claude"
    echo [OK] AGENTS.md updated on master
) else (
    echo [SKIP] AGENTS.md already up to date on master
)
git checkout opencode
cd /d "C:\Users\shicheng.chang\.claude"
echo.

echo ============================================
echo   Done! Use TortoiseGit to push:
echo     - master
echo     - opencode
echo     - claude
echo ============================================
:end
pause
