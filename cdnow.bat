@echo off
:: ZQCD: Zkk quick CD command library
:: cdnow - Interactive cd command for predefined shortcut paths
setlocal EnableDelayedExpansion

set COLOR_RED=[91m
set COLOR_BLUE=[94m
set COLOR_RESET=[0m
set RECORD_SEPARATOR=
set CONFIG_FILE=%USERPROFILE%\.config\zqcd\cdnow.cfg
set "cache=%ZQCD_CDNOW%"
:: initialize local variable in case there is global variablw with same name
set selection=
set target=

:: check argument
:check_argument

	if [%1]==[] (
		goto check_shortcut_cache
	) else if [%1]==[-h] (
		goto print_help
	) else if [%1]==[--help] (
		goto print_help
	) else if [%1]==[-e] (
		goto edit_config
	) else if [%1]==[--edit] (
		goto edit_config
	) else if [%1]==[-r] (
		goto reload_config
	) else if [%1]==[--reload] (
		goto reload_config
	) else if [%1]==[--] (
		if not [%2]==[] (
			set selection=%2
		)
		goto check_shortcut_cache
	) else (
		set selection=%1
		goto check_shortcut_cache
	)
:: loop

:print_help

	echo cdnow [(-h^|--help)] [(-e^|--edit)] [(-r^|--reload)] [SHORTCUT]
	endlocal
	exit /b
:: end

:edit_config

	if not exist %CONFIG_FILE% (
		for /f %%A in ("!CONFIG_FILE!") do set configDir=%%~dpA
		md !configDir! > NUL 2>&1
		(
			echo # Format:
			echo #	[identifier] = [path]
			echo # Example:
			echo #	pictures = C:\Users\chzhou\Pictures
		)> %CONFIG_FILE%
	)
	where gvim >NUL 2>&1
	if %ERRORLEVEL% equ 0 (
		call gvim %CONFIG_FILE%
		endlocal & set ZQCD_CDNOW=
		exit /b
	)
	where notepad >NUL 2>&1
	if %ERRORLEVEL% equ 0 (
		call notepad %CONFIG_FILE%
		endlocal & set ZQCD_CDNOW=
		exit /b
	)
	echo Please edit config file: %CONFIG_FILE%
	endlocal & set ZQCD_CDNOW=
	exit /b
::end

:reload_config

	set cache=
	shift
	goto check_argument

:check_shortcut_cache

	if not defined cache (
		goto construct_cache
	)
	set shortcutTotal=0
	set "shortcutCache=!cache!"

:parsing_cache_loop

	for /f "usebackq tokens=1,* delims=%RECORD_SEPARATOR%" %%A in ('!shortcutCache!') do (
		set /a shortcutTotal+=1
		set shortcuts[!shortcutTotal!]=%%A
		set shortcutCache=%%B
	)
	
	if defined shortcutCache (
		goto parsing_cache_loop
	)

	set /a validation=%shortcutTotal% %% 3

	if %validation% equ 0 (
		set index=0
		set /a shortcutCount=%shortcutTotal%/3
		for %%X in (options identifiers paths) do (
			for /l %%I in (1, 1, !shortcutCount!) do (
				set /a index+=1
				for %%A in (!index!) do (
					set %%X[%%I]=!shortcuts[%%A]!
				)
			)
		)
		goto get_selection
	)
	
	:: clear cache for construction
	set cache=
	
:construct_cache

	:: shortcut 0 - home path
	set shortcutCount=1
	set options[1]=0
	set identifiers[1]=^<user home directory^>
	set paths[1]=%USERPROFILE%

	:: load shortcuts from config file
	if exist %CONFIG_FILE% (
		set lineNum=0
		set index=0
		for /f "usebackq delims=" %%A in ("%CONFIG_FILE%") do (
			set /a lineNum+=1
			call :process_file_line %%A
		)

		if !shortcutCount! equ 1 (
			echo %COLOR_RED%Info^> No valid shortcut found in config file.%COLOR_RESET%
		)
	) else (
		echo %COLOR_RED%Info^> Cannot load config file, use 'cdnow --edit' to build one.%COLOR_RESET%
	)

	:: shortcut ! - script path
	set /a shortcutCount+=1
	set options[%shortcutCount%]=@
	set identifiers[%shortcutCount%]=^<custom shell script directory^>
	set paths[%shortcutCount%]=%~dp0

	for /l %%I in (1, 1, %shortcutCount%) do (
		set cache=!cache!%RECORD_SEPARATOR%!options[%%I]!
	)
	for /l %%I in (1, 1, %shortcutCount%) do (
		set cache=!cache!%RECORD_SEPARATOR%!identifiers[%%I]!
	)
	for /l %%I in (1, 1, %shortcutCount%) do (
		set cache=!cache!%RECORD_SEPARATOR%!paths[%%I]!
	)

:get_selection

	if defined selection (
		goto find_target_path
	)
	
	echo Please select a path shortcut:
	for /l %%I in (1, 1, %shortcutCount%) do (
		echo !options[%%I]!^) !identifiers[%%I]!
	)
	set /p selection=%COLOR_BLUE%Select^>%COLOR_RESET%

	if not defined selection (
		goto end_command
	)
	
:find_target_path
	
	for /l %%I in (1, 1, %shortcutCount%) do (
		if %selection%==!options[%%I]! (
			set target=!paths[%%I]!
			goto end_command
		)
	)
	
	for /l %%I in (1, 1, %shortcutCount%) do (
		if %selection%==!identifiers[%%I]! (
			set target=!paths[%%I]!
			goto end_command
		)
	)
	
	echo %COLOR_RED%Error^> Unknown shortcut "%selection%".%COLOR_RESET%

:end_command
	
	endlocal & set "ZQCD_CDNOW=%cache%" & set "ZQCD_TARGET=%target%"

	if defined ZQCD_TARGET (
		echo cd ^>^>^> %ZQCD_TARGET%
		chdir /d %ZQCD_TARGET%
		set ZQCD_TARGET=
	)
	exit /b
:: COMMAND END

:: subroutine process_file_line(line)
:process_file_line

	if [%1]==[] (
		exit /b
	)
	
	set line=%*
	if "!line:~0,1!"=="#" (
		exit /b
	)
	
	for /f "usebackq tokens=1,* delims==" %%I in ('!line!') do (
		if not [%%J]==[] (
			set /a index+=1
			set /a shortcutCount+=1
			set options[!shortcutCount!]=!index!
			set identifiers[!shortcutCount!]=%%I
			set paths[!shortcutCount!]=%%J
			call :trim identifiers[!shortcutCount!]
			call :trim paths[!shortcutCount!]
		) else (
			echo %COLOR_RED%Info^> Cannot parse line^(%lineNum%^) in config file: !line!%COLOR_RESET%
		)
	)
	exit /b

:: subroutine trim(varName)
:trim

	setlocal EnableDelayedExpansion
	call :trimsub %%%1%%
	endlocal & set %1=%trimTempVar%
	exit /b

:trimsub

	set trimTempVar=%*
	exit /b
