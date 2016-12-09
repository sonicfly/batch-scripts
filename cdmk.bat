@echo off
:: # zqcd: Zkk quick CD command library
:: Interactive cd command for marked path

set ZQCD_RECORD_SEPARATOR=
:: Global variable name for mark array
:: In command line, you can reference the marked path as '%CDMK[{index}]%'.
:: Change the variable name if it conflicts with name defined by other library.
set ZQCD_CACHE_VAR_NAME=CDMK

setlocal EnableDelayedExpansion

set COLOR_RED=[91m
set COLOR_BLUE=[94m
set COLOR_RESET=[0m
(SET NEWLINE=^
%=KEEP THIS LINE=%
)
:: record file path
set RECORD_FILE=%USERPROFILE%\.config\zqcd\cdmk.cfg
:: Full shortcut option list, expand if you need more
set OPTIONS=1 2 3 4 5 6 7 8 9 0 a b c d e f g h i j k l m n o p q r s t u v w x y z
:: Maximum number of shortcut marks recorded, overflow mark will be dropped
:: You can change it to bigger (or smaller) number if you like,
:: but remember to make full shortcut option list fit as well
set CACHE_SIZE=20

:: initialize local variable in case there is global variablw with same name
set markCount=0
set newMark=
set updateEnv=
set updateFile=
set selection=
set target=

:parse_mark_cache

	set /a index=!markCount!+1
	if not defined %ZQCD_CACHE_VAR_NAME%[!index!] (
		goto check_argument
	)

	set markCount=!index!
	for %%A in (!index!) do (
		set mark[%%A]=!%ZQCD_CACHE_VAR_NAME%[%%A]!
	)

	goto parse_mark_cache

:check_argument

	if [%1]==[] (
		goto check_mark_cache
	) else if [%1]==[-h] (
		goto print_help
	) else if [%1]==[--help] (
		goto print_help
	) else if [%1]==[-a] (
		goto mark_current_path
	) else if [%1]==[--add] (
		goto mark_current_path
	) else if [%1]==[-c] (
		goto clean_all_marks
	) else if [%1]==[--clean] (
		goto clean_all_marks
	) else if [%1]==[-r] (
		goto reload_config
	) else if [%1]==[--reload] (
		goto reload_config
	) else if [%1]==[--] (
		if not [%2]==[] (
			set selection=%2
		)
		goto check_mark_cache
	) else (
		set selection=%1
		goto check_mark_cache
	)
:: loop

:print_help

	echo cdmk [(-h^|--help)] [(-a^|--add)] [(-c^|--clean)] [(-r^|--reload)] [SHORTCUT]
	endlocal
	exit /b
:: end

:mark_current_path

	set newMark=%CD%
	goto check_mark_cache

:clean_all_marks

	if exist %RECORD_FILE% (
		del %RECORD_FILE%
	)
	set markCount=0
	echo All marks cleaned^!
	goto end_command

:reload_config

	set markCount=0
	shift
	goto check_argument

:check_mark_cache

	if %markCount% neq 0 (
		goto handle_new_mark
	)
	
	if not exist %RECORD_FILE% (
		goto handle_new_mark
	)

	:: load marks from file
	set markCount=0
	for /f "usebackq delims=" %%A in ("%RECORD_FILE%") do (
		call :process_file_line %%A
	)
	if %markCount% gtr 0 (
		set updateEnv=true
	)

:handle_new_mark

	if not defined newMark (
		goto validate_marks
	)
	
	for /l %%I in (1,1,%markCount%) do (
		if %newMark%==!mark[%%I]! (
			if %%I equ 1 (
				echo Existed mark: %newMark%
			) else (
				echo Bump exited mark: %newMark%
				set /a startIndex=%%I-1
				for /l %%J in (!startIndex!,-1,1) do (
					set /a index=%%J+1
					set mark[!index!]=!mark[%%J]!
				)
				set mark[1]=%newMark%
				set updateFile=true
			)
			goto validate_marks
		)
	)
	
	echo Add mark: %newMark%
	for /l %%I in (%markCount%, -1, 1) do (
		set /a index=%%I+1
		set mark[!index!]=!mark[%%I]!
	)
	set /a markCount+=1
	set mark[1]=%newMark%
	set updateFile=true

:validate_marks

	set index=0
	for /l %%I in (1, 1, %markCount%) do (
		if exist !mark[%%I]! (
			set /a index=!index!+1
			if %%I neq !index! (
				set mark[!index!]=!mark[%%I]!
			)
		) else (
			echo %COLOR_RED%Info^> Remove invalid path: !mark[%%I]!%COLOR_RESET%
			set updateFile=true
		)
	)
	set markCount=%index%

:: save mark list to persistent file
	
	if not defined updateFile (
		goto get_selection
	)

	set updateEnv=true
	
	for /f %%A in ("%RECORD_FILE%") do set recordDir=%%~dpA
	if not exist recordDir (
		md !recordDir! > NUL 2>&1
	)

	(
		for /l %%I in (1, 1, %markCount%) do (
			echo !mark[%%I]!
		)
	)> %RECORD_FILE%

:get_selection

	if defined newMark (
		:: end of mark current path
		goto end_command
	)
	
	if %markCount% equ 0 (
		echo %COLOR_RED%Error^> No mark found, use 'mkcd' to mark current path.%COLOR_RESET%
		goto end_command
	)

	set index=1
	for %%A in (%OPTIONS%) do (
		set options[!index!]=%%A
		set /a index+=1
	)
	
	if defined selection (
		goto find_target_path
	)

	echo Please select a path shortcut:
	for /l %%I in (1,1,%markCount%) do (
		echo !options[%%I]!^) !mark[%%I]!
	)
	set /p selection=%COLOR_BLUE%Select^>%COLOR_RESET%

	if not defined selection (
		goto end_command
	)

:find_target_path

	for /l %%I in (1, 1, %markCount%) do (
		if %selection%==!options[%%I]! (
			set target=!mark[%%I]!
			goto end_command
		)
	)
	
	echo %COLOR_RED%Error^> Unknown shortcut "%selection%".%COLOR_RESET%

:end_command

	if %markCount% equ 0 (
		set markList=
	) else (
		set markList=!mark[1]!
		for /l %%I in (2, 1, %markCount%) do (
			set markList=!markList!%ZQCD_RECORD_SEPARATOR%!mark[%%I]!
		)
	)
	
	endlocal & set "ZQCD_CDMK=%markList%" & set "ZQCD_TARGET=%target%"

	set ZQCD_index=1

	if not defined ZQCD_CDMK (
		goto clean_expired_mark
	)

:set_environment_mark

	for /f "usebackq tokens=1,* delims=%ZQCD_RECORD_SEPARATOR%" %%A in ('%ZQCD_CDMK%') do (
		set %ZQCD_CACHE_VAR_NAME%[%ZQCD_index%]=%%A
		set ZQCD_CDMK=%%B
		set /a ZQCD_index=%ZQCD_index%+1
	)

	if defined ZQCD_CDMK (
		goto set_environment_mark
	)

:clean_expired_mark

	if defined %ZQCD_CACHE_VAR_NAME%[%ZQCD_index%] (
		set %ZQCD_CACHE_VAR_NAME%[%ZQCD_index%]=
		set /a ZQCD_index=%ZQCD_index%+1
		goto clean_expired_mark
	)

	set ZQCD_index=
	set ZQCD_RECORD_SEPARATOR=
	set ZQCD_CACHE_VAR_NAME=

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
	
	set /a markCount+=1
	set mark[!markCount!]=!line!
	exit /b

