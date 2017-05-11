@echo off

rem Для верной интерполяции переменных внутри цикла
setlocal EnableDelayedExpansion

rem Справка
if "%1"=="/?" (
    echo syntax:
    echo    manage_repositories.bat repo_name [status]
    echo    status: 0^|1    0 - disable StyleCop for repo, 1 - enable StyleCop for repo
    exit /B
)

set REPOS_FILE_NAME=repositories
set REPOS_FILE=%HG_HOOKS_PATH%\%REPOS_FILE_NAME%

rem Временный файл используем как буфер, куда накапливаются строки из исходного файла
rem Не можем использовать для этого переменную, так как в переменной нельзя хранить переносы строк
set TEMP_FILE=%HG_HOOKS_PATH%\%REPOS_FILE_NAME%.temp

rem Мы будем дописывать строки во временный файл, поэтому изначально его нужно очислить
if exist %TEMP_FILE% del %TEMP_FILE%

rem Если файла repositories нет - создаём пустой
if not exist %REPOS_FILE% type NUL>%REPOS_FILE%

set found=0

rem прекращаем выполнение, если пользователь не указал первый аргумент - путь до репозитория
if "%1"=="" (
    echo You must specify repo name!
    exit /B
)

rem второй аргумент - статус репозитория. Если не указан - по умолчанию ставим 1
if "%2"=="" (
    set status=1
) else (
    set status=%2
)

rem Итерируемся по файлу repositories, сплитим каждую строку по "=" и обрабатываем её
for /f "delims== tokens=1,2" %%i in (%REPOS_FILE%) do (
    call :SUB %%i %1 %status% %%j
)

rem если нужного репозитория нет в файле - дописываем его в конец
if "%found%"=="0" (
    echo %1=%status% >>%TEMP_FILE%
)

del %REPOS_FILE%
rename %TEMP_FILE% %REPOS_FILE_NAME%

exit /B

:SUB currepo repo status curstatus
rem Если случайно встретили пустую строку - пропускаем её
if "%1"=="" GOTO CONTINUE
if "%1"==" " GOTO CONTINUE

rem если нашли наш репозиторий в файле - копируем его во временный файл с нужным статусом
if "%1"=="%2" (
    echo %1=%3 >>%TEMP_FILE%
    set found=1
rem ...иначе - копируем исходную строку во временный файл. Как нашли - со знаком "=" или без него
) else (
    if "%4"=="" (
        echo %1 >> %TEMP_FILE%
    ) else (
        echo %1=%4 >> %TEMP_FILE%
    )
)
:CONTINUE

exit /B