@echo off
if "%HG_HOOKS_PATH%"=="" (
    echo HG_HOOKS_PATH isn't set
) else (
    echo HG_HOOKS_PATH is %HG_HOOKS_PATH%
)
pause