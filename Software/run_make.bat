@echo off
REM Windows batch script to run make commands without Makefile.c interference
REM Usage: run_make.bat [make_target]
REM Example: run_make.bat check_sources

echo Running MinCPU make on Windows...

REM Check if Makefile.c exists and rename it temporarily
if exist Makefile.c (
    echo Temporarily renaming Makefile.c to avoid conflicts...
    rename Makefile.c Makefile_c.temp
    set RENAMED=1
) else (
    set RENAMED=0
)

REM Run the make command with all arguments
if "%1"=="" (
    echo Running: make all
    make all
) else (
    echo Running: make %*
    make %*
)

REM Store the exit code
set MAKE_EXIT_CODE=%ERRORLEVEL%

REM Restore Makefile.c if we renamed it
if %RENAMED%==1 (
    echo Restoring Makefile.c...
    rename Makefile_c.temp Makefile.c
)

REM Exit with the same code as make
exit /b %MAKE_EXIT_CODE% 