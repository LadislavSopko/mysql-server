@echo on
setlocal


set REPO=%~dp0
set REPO=%REPO:~0,-1%

REM set path to jom

set PATH=%REPO%;%PATH%

if "%~4"=="" goto blank_cmake

set CMAKE_COMMAND=%~4

goto next_cmake

:blank_cmake
set CMAKE_COMMAND=C:\Program Files (x86)\CMake\bin\cmake

:next_cmake

if "%~3"=="" goto blank_3rdp

set TRE_RDP=%~3
goto next_3rdp

:blank_3rdp
set TRE_RDP=C:\TRERDP_vc14\xw-3rdp

:next_3rdp

if "%~2"=="" goto blank_build

set BUILD=%~2
goto next_build

:blank_build
set BUILD=E:\MySql\build

:next_build

if "%~1"=="" goto blank

set PREFIX=%~1
goto next

:blank
set PREFIX=E:\MySql

:next 

set NUMJOBS=-j4

mkdir "%BUILD%"

if not exist "%PREFIX%"\bin mkdir "%PREFIX%"\bin

cd /d "%BUILD%" && "%CMAKE_COMMAND%" "%REPO%" -G"NMake Makefiles JOM"^
 -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_NO_WARNINGS:BOOL=1^
 -DWITH_EMBEDDED_SERVER:BOOL=0^
 -DCOMMUNITY_BUILD:BOOL=1^
 -DWITH_UNIT_TESTS:BOOL=0^
 -DWITH_ARCHIVE_STORAGE_ENGINE:BOOL=0^
 -DWINDOWS_RUNTIME_MD:BOOL=1^
 -DWITH_ASAN:BOOL=0^
 -DWITH_FEDERATED_STORAGE_ENGINE:BOOL=0^
 -DWITH_PARTITION_STORAGE_ENGINE:BOOL=0^
 -DMYSQL_DATADIR:PATH="%PREFIX%\data"^
 -DBOOST_INCLUDE_DIR:PATH="%TRE_RDP%\include\boost-1_59"^
 -DMYSQL_KEYRINGDIR:PATH="%PREFIX%\keyring"^
 -DWITH_BOOST:PATH="%TRE_RDP%\include\boost-1_59"^
 -DTMPDIR:PATH="%PREFIX%\tmp"^
 -DCMAKE_INSTALL_PREFIX:PATH="%PREFIX%"^
 -DCMAKE_BUILD_TYPE:STRING="RelWithDebInfo"^
 -DMYSQL_PROJECT_NAME:STRING="MySQL"

rem "%CMAKE_DIR%\cmake" --build "%BUILD%" --target INSTALL -- "%NUMJOBS%"
pushd "%BUILD%\libservices" && jom install "%NUMJOBS%"  && popd
pushd "%BUILD%\sql" && jom install "%NUMJOBS%" && copy mysqld.lib "%PREFIX%"\lib && popd

endlocal
