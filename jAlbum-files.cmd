@   echo off

:main /? | [/v] [/delete] [folder]

:: = DESCRIPTION
:: =   !PROG_NAME! - a script to list jAlbum files (and optionally delete them),
:: =
:: = OPTIONS
:: =   /v       Be verbose.
:: =   /delete  Delete the jAlbum files, turning the folder into a clean,
:: =            non-jAlbum folder.
:: = FILES
:: =   These files will be deleted:
:: =     albumfiles.txt
:: =     album.rss
:: =     comments.properties
:: =     meta.properties
:: =     .jalbum\*.info
:: =     .jalbum\cache\*
:: =
:: =   These folders will be deleted:
:: =     .jalbum\cache
:: =     .jalbum
:: =
:: = VERSION
:: =   @(#) Version: 2015-12-01
:: =
:: = AUTHOR
:: =   Written by Jan Bruun Andersen.

    verify 2>NUL: other
    setlocal EnableExtensions
    if ErrorLevel 1 (
	echo Error - Unable to enable extensions.
	goto :EOF
    )

:defaults
    set "PROG_FULL=%~f0"
    set "PROG_NAME=%~n0"
    set "PROG_DIR=%~dp0"

    if /i "%~1" == "/trace" shift & prompt $G$G & echo on

    PATH %PROG_DIR%\cmd-lib.lib;%PATH%

    set "show_help=false"
    set "verbosity=0"
    set "folder=."
    set "action=show"

:getopts
    if /i "%~1" == "/?"		set "show_help=true"	& shift & goto getopts

    if /i "%~1" == "/v"		set /a "verbosity+=1"	& shift	& goto getopts
    if /i "%~1" == "/delete"	set "action=delete"	& shift	& goto getopts

    set "char1=%~1"
    set "char1=%char1:~0,1%"
    if "%char1%" == "/" echo Unknown option - %1. & echo. & call cl_usage "%PROG_FULL%" & goto error_exit

    if "%show_help%" == "true" call cl_help "%PROG_FULL%" & goto :EOF

    if not "%~1" == "" set "folder=%~1" & shift

    if not exist "%folder%\" (
	echo.
	echo ERROR: No such folder: "%folder%"
	goto :EOF
    )

    rem .----------------------------------------------------------------------
    rem | This is where the real fun begins!
    rem '----------------------------------------------------------------------

    for /R "%folder%" %%F in (
	albumfiles.txt
	album.rss
	comments.properties
	meta.properties
	.jalbum\*.info
	.jalbum\cache\*
    ) do if exist "%%F"  call :process "file" "%action%" "%%F" || goto :EOF

    for /R "%folder%" %%D in (
	.jalbum\cache
    	.jalbum
    ) do if exist "%%D\" call :process folder "%action%" "%%D" || goto :EOF
goto :EOF

:process type action path
    if "%~1" == "" echo Error in function '%PROG_NAME%:process'. Parameter 1 ^(type^) is null   & goto error_exit
    if "%~2" == "" echo Error in function '%PROG_NAME%:process'. Parameter 2 ^(action^) is null & goto error_exit
    if "%~3" == "" echo Error in function '%PROG_NAME%:process'. Parameter 3 ^(path^) is null   & goto error_exit

    if "%~2" == "show" (
	if "%~1" == "folder" if exist "%~3\" echo Directory "%~3" & goto :EOF
	if "%~1" == "file"   if exist "%~3"  echo File      "%~3" & goto :EOF
    )

    if "%~2" == "delete" (
	rem if 0%verbosity% gtr 0 echo Deleting "%~3"

	if "%~1" == "folder" if exist "%~3\" rmdir   "%~3" & goto :EOF
	if "%~1" == "file"   if exist "%~3"  del  /p "%~3" & goto :EOF
    )
goto :EOF

rem .--------------------------------------------------------------------------
rem | Displays a selection of variables belonging to this script.
rem | Very handy when debugging.
rem '--------------------------------------------------------------------------
:dump_variables
    echo =======
    echo cwd            = "%CD%"
    echo tmp_dir        = "%tmp_dir%"

    echo show_help      = "%show_help%"
    echo verbosity      = "%verbosity%"
    echo folder         = "%folder%"
    echo action         = "%action%"

    if defined tmp_dir if exist "%tmp_dir%\" (
	echo.
	dir %tmp_dir%
    )

    echo =======
goto :EOF

:no_error
    time 2>NUL: /t
goto :EOF

:error_exit
    verify 2>NUL: other
goto :EOF

rem vim: set filetype=dosbatch tabstop=8 softtabstop=4 shiftwidth=4 noexpandtab:
rem vim: set foldmethod=indent
