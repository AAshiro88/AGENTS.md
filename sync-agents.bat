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
        goto :crossrepo
    )
)

echo [1/4] Committing AGENTS.md to %CURRENT% ...
git add AGENTS.md
git commit -m "update AGENTS.md"
echo.

:: Sync AGENTS.md to other branches
for /f "tokens=*" %%i in ('git branch --format^("%%^(refname:short^)"^)') do (
    if "%%~i" neq "%CURRENT%" (
        echo [2/4] Syncing AGENTS.md to %%~i ...
        git checkout %%~i
        git checkout %CURRENT% -- AGENTS.md
        git commit -m "sync AGENTS.md from %CURRENT%"
        echo.
    )
)

:: Switch back
echo [3/4] Switching back to %CURRENT% ...
git checkout %CURRENT%
echo.

:crossrepo
:: Sync AGENTS.md to .claude/CLAUDE.md
echo [4/4] Syncing AGENTS.md to CLAUDE.md ...
copy /y "C:\Users\shicheng.chang\.config\opencode\AGENTS.md" "C:\Users\shicheng.chang\.claude\CLAUDE.md" >nul
cd /d "C:\Users\shicheng.chang\.claude"
git checkout claude
git add CLAUDE.md
git diff --cached --quiet
if %errorlevel% neq 0 (
    git commit -m "sync CLAUDE.md from opencode"
    echo [OK] CLAUDE.md updated
) else (
    echo [SKIP] CLAUDE.md already up to date
)
cd /d "C:\Users\shicheng.chang\.config\opencode"
echo.

echo ============================================
echo   Done! Use TortoiseGit to push:
echo     - opencode repo: push all branches
echo     - .claude repo: push claude branch
echo ============================================
:end
pause
