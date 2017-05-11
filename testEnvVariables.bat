@echo off
if "%HG_HOOKS_PATH%"=="" (
    echo HG_HOOKS_PATH isn't set
) else (
    echo HG_HOOKS_PATH is %HG_HOOKS_PATH%
)
if "%HG_STYLECOP_PATH%"=="" (
    echo HG_STYLECOP_PATH isn't set
) else (
    echo HG_STYLECOP_PATH is %HG_STYLECOP_PATH%
)
pause