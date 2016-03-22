@   echo off

:main /? | [/v] [/update] destination-folder [source-folder]

rmdir /s /q "C:\Users\jabba\Documents\My Albums\Michelle"

:: = DESCRIPTION
:: =   !PROG_NAME! - a script to make a jAlbum project using an existing
:: =   folder structure as source.
:: =
:: =   OBS: Sub-folders will exist as actual folders inside the project, while
:: =        all images and movies will exist as links to the originals.
:: =
:: = OPTIONS
:: =   /v       Be verbose.
:: =   /update  Update destionation folder. Do not complain if the destination
:: =            already exist.
:: =
:: = EXAMPLES:
:: =   Creating a new jAlbum project:
:: =
:: =     C:> cd /d E:\Billedarkiv\2014
:: =     C:> !PROG_NAME! /v "C:\Users\jabba\Documents\My Albums\2014"
:: =     Source folder:        E:\Billedarkiv\2014
:: =     Destination folder:   C:\Users\jabba\Documents\My Albums\2014
:: =     Default settings      C:\Users\jabba\AppData\Roaming\jAlbum\defaults.jap
:: =     Destination settings: C:\Users\jabba\Documents\My Albums\2014\jalbum-settings.jap
:: =
:: =     Creating jAlbum project  in "C:\Users\jabba\Documents\My Albums\2014".
:: =     Creating jAlbum settings in "C:\Users\jabba\Documents\My Albums\2014\jalbum-settings.jap".
:: =     Creating jAlbum links    in "C:\Users\jabba\Documents\My Albums\2014".
:: =
:: =   Updating an existing jAlbum project:
:: =
:: =     C:> !PROG_NAME! /v /update "C:\Users\jabba\Documents\My Albums\2014" "E:\Billedarkiv\2014"
:: =     Source folder:        E:\Billedarkiv\2014
:: =     Destination folder:   C:\Users\jabba\Documents\My Albums\2014
:: =
:: =     Updating jAlbum project  in "C:\Users\jabba\Documents\My Albums\2014".
:: =     Updating jAlbum links    in "C:\Users\jabba\Documents\My Albums\2014".
:: =
:: = FILES
:: =   !def_cfg!
:: =   <destination>\jalbum-settings.jap
:: =   <destination>\albumfiles.txt
:: =   <destination>\......\albumfiles.txt

:: @author Jan Bruun Andersen
:: @version @(#) Version: 2016-03-16

    verify 2>NUL: other
    setlocal EnableExtensions
    if ErrorLevel 1 (
	echo Error: Unable to enable extensions.
	goto :EOF
    )

    for %%F in (cl_init.cmd) do if "" == "%%~$PATH:F" set "PATH=%~dp0cmd-lib.lib;%PATH%"
    call cl_init "%~dpf0" "%~1" || (echo Failed to initialise cmd-lib. & goto :exit)
    if /i "%~1" == "/trace" shift /1 & prompt $G$G & echo on

:defaults
    set "PROG_FULL=%~f0"
    set "PROG_NAME=%~n0"
    set "PROG_DIR=%~dp0"

    rem Change codepage to Unicode (UTF-8).
    rem Without this, albumfiles.txt will not list the paths in a way that
    rem jAlbum can understand.

    chcp 65001 >NUL:

    set "show_help=false"
    set "verbosity=0"
    set "update=false"
    set "action="
    set "src_folder=."
    set "dst_folder="
    set "def_cfg=%AppData%\jAlbum\defaults.jap"
    set "dst_cfg="

:getopts
    if /i "%~1" == "/?"		set "show_help=true"	& shift /1 & goto :getopts

    if /i "%~1" == "/v"		set /a "verbosity+=1"	& shift /1 & goto :getopts
    if /i "%~1" == "/update"	set "update=true"	& shift /1 & goto :getopts

    set "char1=%~1"
    set "char1=%char1:~0,1%"
    if "%char1%" == "/" (
	echo Error: Unknown option - %1.
	echo.
	call cl_usage "%PROG_FULL%"
	goto :error_exit
    )

    if "%show_help%" == "true" call cl_help "%~dpf0" & goto :EOF

    if "%~1" == "" (
	echo Error: Destination folder must be specified,
	goto :error_exit
    )

    if not "%~1" == "" set "dst_folder=%~1"
    if not "%~2" == "" set "src_folder=%~2"

    call cl_abspath "%src_folder%" >NUL: || goto :EOF
    if defined _abspath set "src_folder=%_abspath%"

    call cl_abspath "%dst_folder%" >NUL: || goto :EOF
    if defined _abspath set "dst_folder=%_abspath%"

    if "%update%" == "false" (
	set "action=Creating"
	if exist "%dst_folder%\" (
	    echo.
	    echo Error: Destination folder already exists: "%dst_folder%"
	    goto :error_exit
	)
    ) else (
	set "action=Updating"
	if not exist "%dst_folder%\" (
	    echo.
	    echo Error: Destination folder does not exists: "%dst_folder%"
	    goto :error_exit
	)
    )

    set "dst_cfg=%dst_folder%\jalbum-settings.jap"

    if not exist "%src_folder%\" (
	echo.
	echo Error: Source folder does not exists: "%src_folder%"
	goto :error_exit
    )

    if not exist "%def_cfg%" (
	echo.
	echo Error: Default settings for jAlbum was not found: "%settings%"
	goto :error_exit
    )

    rem .----------------------------------------------------------------------
    rem | This is where the real fun begins!
    rem '----------------------------------------------------------------------

    if 0%verbosity% geq 1 (
	echo %action% jAlbum project.
	echo Source folder:        %src_folder%
	echo Destination folder:   %dst_folder%

	if not exist "%dst_cfg%" (
	echo Default settings      %def_cfg%
	echo Destination settings: %dst_cfg%
	)
	echo.
    )

    call :add_dirs  "%src_folder%" "%dst_folder%"

    if not exist "%dst_cfg%" (
	rem xcopy options:
	rem
	rem   /y = yes, overwrite the dummy file produced by echo above.

	echo # > "%dst_cfg%"
	xcopy "%def_cfg%" "%dst_cfg%" /y >NUL:
    )
goto :EOF

:add_dirs src-folder dst-folder
    for /D %%D in ("%~1\*") do (
	call :chk_entry "%~2\albumfiles.txt" "%%~nxD" || (
	    if 0%verbosity% geq 1 echo Creating folder "%~2\%%~nxD".
	    mkdir "%~2\%%~nxD"
	    call :add_entry "%~2\albumfiles.txt" "%%~nxD"
	)
	call :add_dirs  "%~1\%%~nxD" "%~2\%%~nxD"
    )
    call :add_links "%~1" "%~2"
goto :EOF

rem .--------------------------------------------------------------------------
rem | Adds picture-links to the albumfiles.txt file.
rem |
rem | Currently the following file extensions are added:
rem |
rem |   *.gif
rem |   *.jpg *.jpeg
rem |   *.mov
rem |   *.mp4
rem |   *.png
rem |   *.raw
rem '--------------------------------------------------------------------------
:add_links src-folder dst-folder
    for %%F in (
	"%~1\*.gif"
	"%~1\*.jpg" "%%D\*.jpeg"
	"%~1\*.mov"
	"%~1\*.mp4"
	"%~1\*.png"
	"%~1\*.raw"
    ) do (
	call :chk_entry "%~2\albumfiles.txt" "%%~nxF" "%~1\%%~nxF" || (
	    call :add_entry "%~2\albumfiles.txt" "%%~nxF" "%~1\%%~nxF"
	)
    )
goto :EOF

rem .--------------------------------------------------------------------------
rem | Checks if an index-entry already exists in the index-file
rem | (albumfiles.txt).
rem '--------------------------------------------------------------------------
:chk_entry index-file index-entry
    if 0%verbosity% geq 2 echo Scanning "%~1" for index named "%~2".

    if exist "%~1" (
	for /F "usebackq eol=# tokens=1-3,* delims=	" %%A in ("%~1") do (
	    if "%~2" == "%%A" goto :no_error
	)
    )
    goto :error_exit
goto :EOF

rem .--------------------------------------------------------------------------
rem | Adds an index-entry to the index-file
rem | (albumfiles.txt).
rem '--------------------------------------------------------------------------
:add_entry index-file index-entry [pathname]
    if not exist "%~1" (
	if 0%verbosity% geq 2 echo %action% "%~1".

	echo # Created by "%PROG_NAME%".>>"%~1"
	echo.>>"%~1"
    )

    if "%update%" == "true"  if 0%verbosity% geq 1 echo Adding "%~2" to "%~1".
    if "%update%" == "false" if 0%verbosity% geq 2 echo Adding "%~2" to "%~1".

    if "%~3" == "" (
	echo %~2>>"%~1"
    ) else (
	echo %~2	%~3>>"%~1"
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

    echo PROG_DIR       = "%PROG_DIR%"
    echo PROG_NAME      = "%PROG_NAME%"

    echo show_help      = "%show_help%"
    echo verbosity      = "%verbosity%"
    echo update         = "%update%"
    echo action         = "%action%"
    echo src_folder     = "%src_folder%"
    echo dst_folder     = "%dst_folder%"
    echo def_cfg        = "%def_cfg%"
    echo dst_cfg        = "%dst_cfg%"

    if defined tmp_dir if exist "%tmp_dir%\" (
	echo.
	dir %tmp_dir%
    )

    echo =======
goto :EOF

rem .--------------------------------------------------------------------------
rem | Sets ErrorLevel and exit-status. Without a proper exit-status tests like
rem | 'command && echo Success || echo Failure' will not work,
rem |
rem | OBS: NO commands must follow the call to %ComSpec%, not even REM-arks,
rem |      or the exit-status will be destroyed. However, null commands like
rem |      labels (or ::) is okay.
rem '--------------------------------------------------------------------------
:no_error
    time >NUL: /t	& rem Set ErrorLevel = 0.
    goto :exit
:error_exit
    verify 2>NUL: other	& rem Set ErrorLevel = 1.
:exit
    %ComSpec% /c exit %ErrorLevel%

:: vim: set filetype=dosbatch tabstop=8 softtabstop=4 shiftwidth=4 noexpandtab:
:: vim: set foldmethod=indent
