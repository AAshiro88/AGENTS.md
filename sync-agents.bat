@echo off
cd /d "C:\Users\shicheng.chang\.gemini\antigravity"
echo ============================================
echo   Sync AGENTS.md to all branches
echo ============================================
echo.

:: Check if AGENTS.md has changes
git diff --name-only | findstr /i "AGENTS.md" >nul
if %errorlevel% neq 0 (
    git diff --cached --name-only | findstr /i "AGENTS.md" >nul
    if %errorlevel% neq 0 (
        echo [SKIP] No changes in AGENTS.md
        goto :sync_opencode
    )
)

echo [1/4] Committing AGENTS.md to master ...
git add AGENTS.md
git commit -m "update AGENTS.md"
echo.

:sync_opencode
echo [2/4] Syncing to opencode ...
git checkout opencode
git show master:AGENTS.md > AGENTS.md
git add AGENTS.md
git diff --cached --quiet
if %errorlevel% neq 0 (
    git commit -m "sync AGENTS.md from master"
    echo [OK] AGENTS.md updated on opencode
) else (
    echo [SKIP] AGENTS.md already up to date on opencode
)
git checkout master
echo.

echo [3/4] Syncing to claude ...
git checkout claude
git show master:AGENTS.md > CLAUDE.md
git add CLAUDE.md
git diff --cached --quiet
if %errorlevel% neq 0 (
    git commit -m "sync CLAUDE.md from master"
    echo [OK] CLAUDE.md updated on claude
) else (
    echo [SKIP] CLAUDE.md already up to date on claude
)
git checkout master
echo.

echo ============================================
echo   Done! Use TortoiseGit to push:
echo     - master
echo     - opencode
echo     - claude
echo ============================================
:end
pause
