@echo off
cd /d "C:\Users\shicheng.chang\.claude"
echo ============================================
echo   Sync CLAUDE.md to all AGENTS.md
echo ============================================
echo.

:: Remember current branch
for /f "tokens=*" %%i in ('git branch --show-current') do set CURRENT=%%i
echo Current branch: %CURRENT%
echo.

:: Check if CLAUDE.md has changes
git diff --name-only | findstr /i "CLAUDE.md" >nul
if %errorlevel% neq 0 (
    git diff --cached --name-only | findstr /i "CLAUDE.md" >nul
    if %errorlevel% neq 0 (
        echo [SKIP] No changes in CLAUDE.md
        goto :crossrepo
    )
)

echo [1/4] Committing CLAUDE.md to %CURRENT% ...
git add CLAUDE.md
git commit -m "update CLAUDE.md"
echo.

:: Sync CLAUDE.md to master branch (as AGENTS.md)
if "%CURRENT%" neq "master" (
    echo [2/4] Syncing CLAUDE.md to master as AGENTS.md ...
    git checkout master
    git checkout %CURRENT% -- CLAUDE.md
    git mv CLAUDE.md AGENTS.md
    git commit -m "sync AGENTS.md from %CURRENT%"
    echo.
)

:: Switch back
echo [3/4] Switching back to %CURRENT% ...
git checkout %CURRENT%
echo.

:crossrepo
:: Sync CLAUDE.md to .config/opencode/AGENTS.md
echo [4/4] Syncing CLAUDE.md to opencode repo ...
copy /y "C:\Users\shicheng.chang\.claude\CLAUDE.md" "C:\Users\shicheng.chang\.config\opencode\AGENTS.md" >nul
cd /d "C:\Users\shicheng.chang\.config\opencode"
for /f "tokens=*" %%i in ('git branch --show-current') do set OPENCODE_CURRENT=%%i
git checkout opencode
git add AGENTS.md
git diff --cached --quiet
if %errorlevel% neq 0 (
    git commit -m "sync AGENTS.md from CLAUDE.md"
    echo [OK] AGENTS.md updated on opencode
) else (
    echo [SKIP] AGENTS.md already up to date
)
:: Sync to master
git checkout master
git checkout opencode -- AGENTS.md
git add AGENTS.md
git diff --cached --quiet
if %errorlevel% neq 0 (
    git commit -m "sync AGENTS.md from opencode"
    echo [OK] AGENTS.md updated on master
) else (
    echo [SKIP] AGENTS.md already up to date on master
)
git checkout opencode
cd /d "C:\Users\shicheng.chang\.claude"
echo.

echo ============================================
echo   Done! Use TortoiseGit to push:
echo     - .claude repo: push claude branch
echo     - opencode repo: push all branches
echo ============================================
:end
pause
