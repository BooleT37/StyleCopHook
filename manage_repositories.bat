@echo off

if "%1"=="/?" (
    echo syntax:
    echo    manage_repositories.bat repo_name [status]
    echo    status: 0^|1    0 - disable StyleCop for repo, 1 - enable StyleCop for repo
    exit /B
)

set REPOS_FILE_NAME=repositories
set REPOS_FILE=%HG_HOOKS_PATH%\%REPOS_FILE_NAME%
set TEMP_FILE=%HG_HOOKS_PATH%\%REPOS_FILE_NAME%.temp

if exist %TEMP_FILE% del %TEMP_FILE%
if not exist %REPOS_FILE% type NUL>%REPOS_FILE%

set found=0
set str=

if "%1"=="" (
    echo You must specify repo name!
    exit /B
)

if "%2"=="" (
    set status=1
) else (
    set status=%2
)

for /f "delims== tokens=1,2" %%i in (%REPOS_FILE%) do (
    call :SUB %%i %%j %1 %status%
)

if "%found%"=="0" (
    echo %1=%status% >>%TEMP_FILE%
)

del %REPOS_FILE%
rename %TEMP_FILE% %REPOS_FILE_NAME%

exit /B

:SUB currepo status repo status
if "%1"=="" GOTO CONTINUE
if "%1"==" " GOTO CONTINUE
if "%2"=="" GOTO CONTINUE

if "%1"=="%3" (
    echo %1=%4 >>%TEMP_FILE%
    set found=1
) else (
    echo %1=%2 >>%TEMP_FILE%
)
:CONTINUE

exit /B