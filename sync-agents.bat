@echo off
cd /d "C:\Users\shicheng.chang\.gemini\antigravity"
echo ============================================
echo   Sync AGENTS.md to all repos
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
:: Sync to .config/opencode repo
echo [2/4] Syncing AGENTS.md to opencode repo ...
copy /y "C:\Users\shicheng.chang\.gemini\antigravity\AGENTS.md" "C:\Users\shicheng.chang\.config\opencode\AGENTS.md" >nul
cd /d "C:\Users\shicheng.chang\.config\opencode"
git checkout opencode
git add AGENTS.md
git diff --cached --quiet
if %errorlevel% neq 0 (
    git commit -m "sync AGENTS.md from gemini"
    echo [OK] AGENTS.md updated on opencode
) else (
    echo [SKIP] AGENTS.md already up to date on opencode
)
git checkout master
cd /d "C:\Users\shicheng.chang\.gemini\antigravity"
echo.

:: Sync to .claude repo
echo [3/4] Syncing AGENTS.md to .claude as CLAUDE.md ...
copy /y "C:\Users\shicheng.chang\.gemini\antigravity\AGENTS.md" "C:\Users\shicheng.chang\.claude\CLAUDE.md" >nul
cd /d "C:\Users\shicheng.chang\.claude"
git checkout claude
git add CLAUDE.md
git diff --cached --quiet
if %errorlevel% neq 0 (
    git commit -m "sync CLAUDE.md from gemini"
    echo [OK] CLAUDE.md updated
) else (
    echo [SKIP] CLAUDE.md already up to date
)
git checkout master
cd /d "C:\Users\shicheng.chang\.gemini\antigravity"
echo.

echo ============================================
echo   Done! Use TortoiseGit to push:
echo     - .gemini/antigravity: master
echo     - .config/opencode: all branches
echo     - .claude: claude branch
echo ============================================
:end
pause
