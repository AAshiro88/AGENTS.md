@echo off
cd /d "C:\Users\shicheng.chang\.config\opencode"
echo ============================================
echo   Sync AGENTS.md to all branches
echo ============================================
echo.

:: Pull latest from remote
echo Pulling latest from remote ...
git pull origin opencode
if %errorlevel% neq 0 (
    echo [ERROR] Failed to pull opencode. Fix conflicts then re-run.
    goto :end
)
echo.

:: Check if AGENTS.md has changes
git diff --name-only | findstr /i "AGENTS.md" >nul
if %errorlevel% neq 0 (
    git diff --cached --name-only | findstr /i "AGENTS.md" >nul
    if %errorlevel% neq 0 (
        echo [SKIP] No changes in AGENTS.md
        goto :sync_master
    )
)

echo [1/4] Committing AGENTS.md to opencode ...
git add AGENTS.md
git commit -m "update AGENTS.md"
echo.

:sync_master
echo [2/4] Syncing to master ...
git checkout master
git pull origin master
if %errorlevel% neq 0 (
    echo [ERROR] Failed to pull master. Fix conflicts then re-run.
    goto :end
)
git show opencode:AGENTS.md > AGENTS.md
git add AGENTS.md
git diff --cached --quiet
if %errorlevel% neq 0 (
    git commit -m "sync AGENTS.md from opencode"
    echo [OK] AGENTS.md updated on master
) else (
    echo [SKIP] AGENTS.md already up to date on master
)
git checkout opencode
echo.

echo [3/4] Syncing to .gemini/antigravity ...
cd /d "C:\Users\shicheng.chang\.gemini\antigravity"
git pull origin master
if %errorlevel% neq 0 (
    echo [ERROR] Failed to pull gemini. Fix conflicts then re-run.
    cd /d "C:\Users\shicheng.chang\.config\opencode"
    goto :end
)
git show opencode:AGENTS.md > AGENTS.md
git add AGENTS.md
git diff --cached --quiet
if %errorlevel% neq 0 (
    git commit -m "sync AGENTS.md from opencode"
    echo [OK] AGENTS.md updated on gemini
) else (
    echo [SKIP] AGENTS.md already up to date on gemini
)
cd /d "C:\Users\shicheng.chang\.config\opencode"
echo.

echo [4/4] Syncing to .claude ...
cd /d "C:\Users\shicheng.chang\.claude"
git pull origin claude
if %errorlevel% neq 0 (
    echo [ERROR] Failed to pull claude. Fix conflicts then re-run.
    cd /d "C:\Users\shicheng.chang\.config\opencode"
    goto :end
)
git show opencode:AGENTS.md > CLAUDE.md
git add CLAUDE.md
git diff --cached --quiet
if %errorlevel% neq 0 (
    git commit -m "sync CLAUDE.md from opencode"
    echo [OK] CLAUDE.md updated
) else (
    echo [SKIP] CLAUDE.md already up to date
)
git checkout master
cd /d "C:\Users\shicheng.chang\.config\opencode"
echo.

echo ============================================
echo   Done! Use TortoiseGit to push:
echo     - master
echo     - opencode
echo     - claude
echo ============================================
:end
pause
