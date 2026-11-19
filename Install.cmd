@echo off
setlocal

set "GAME_DIR=%CD%"
set "GAME_EXE=%GAME_DIR%\Among Us.exe"
set "WORK_DIR=%TEMP%\SickoInstaller_%RANDOM%_%RANDOM%"
set "RESULT=1"

if not exist "%GAME_EXE%" (
    echo Among Us.exe was not found in the current folder.
    goto finish
)

where curl.exe >nul 2>&1
if errorlevel 1 (
    echo curl.exe was not found.
    goto finish
)

mkdir "%WORK_DIR%" >nul 2>&1

for /f "delims=" %%A in ('powershell.exe -NoProfile -Command "$b=[IO.File]::ReadAllBytes($env:GAME_EXE); $o=[BitConverter]::ToInt32($b,60); $m=[BitConverter]::ToUInt16($b,$o+4); if($m -eq 34404){'x64'} elseif($m -eq 332){'x86'}"') do set "ARCH=%%A"

if not defined ARCH (
    echo Could not detect the architecture of Among Us.exe.
    goto finish
)

if /i "%ARCH%"=="x64" (
    set "SICKO_ASSET=Release_x64.zip"
    set "BEPINEX_PREFIX=BepInEx-Unity.IL2CPP-win-x64-"
) else (
    set "SICKO_ASSET=Release_Itch_x86.zip"
    set "BEPINEX_PREFIX=BepInEx-Unity.IL2CPP-win-x86-"
)

for /f "delims=" %%U in ('powershell.exe -NoProfile -Command "$r=Invoke-RestMethod -Uri https://api.github.com/repos/g0aty/SickoMenu/releases/latest; ($r.assets | Where-Object { $_.name -eq $env:SICKO_ASSET } | Select-Object -First 1).browser_download_url"') do set "SICKO_URL=%%U"

for /f "delims=" %%U in ('powershell.exe -NoProfile -Command "$r=Invoke-RestMethod -Uri https://api.github.com/repos/MrDiamond64/Hydra/releases/latest; ($r.assets | Where-Object { $_.name.StartsWith($env:BEPINEX_PREFIX) -and $_.name.EndsWith('.zip') } | Select-Object -First 1).browser_download_url"') do set "BEPINEX_URL=%%U"

for /f "delims=" %%U in ('powershell.exe -NoProfile -Command "$r=Invoke-RestMethod -Uri https://api.github.com/repos/tybikkryt/BepInEx.DLLInjector/releases/latest; ($r.assets | Where-Object { $_.name -eq 'DLLInjector.BepInEx6.IL2CPP.zip' } | Select-Object -First 1).browser_download_url"') do set "INJECTOR_URL=%%U"

if not defined SICKO_URL (
    echo Could not find the matching Sicko Menu release.
    goto finish
)

if not defined BEPINEX_URL (
    echo Could not find the matching BepInEx release.
    goto finish
)

if not defined INJECTOR_URL (
    echo Could not find the BepInEx DLL Injector release.
    goto finish
)

set "SICKO_ZIP=%WORK_DIR%\SickoMenu.zip"
set "BEPINEX_ZIP=%WORK_DIR%\BepInEx.zip"
set "INJECTOR_ZIP=%WORK_DIR%\DLLInjector.zip"

echo Downloading Sicko Menu %ARCH%...
curl.exe --fail --location --silent --show-error "%SICKO_URL%" --output "%SICKO_ZIP%"
if errorlevel 1 goto finish

echo Downloading BepInEx %ARCH%...
curl.exe --fail --location --silent --show-error "%BEPINEX_URL%" --output "%BEPINEX_ZIP%"
if errorlevel 1 goto finish

echo Downloading the BepInEx DLL Injector...
curl.exe --fail --location --silent --show-error "%INJECTOR_URL%" --output "%INJECTOR_ZIP%"
if errorlevel 1 goto finish

echo Installing BepInEx, the injector, and Sicko Menu...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Expand-Archive -LiteralPath $env:BEPINEX_ZIP -DestinationPath $env:GAME_DIR -Force; Expand-Archive -LiteralPath $env:INJECTOR_ZIP -DestinationPath (Join-Path $env:GAME_DIR 'BepInEx') -Force; $stage=Join-Path $env:WORK_DIR 'SickoMenu'; Expand-Archive -LiteralPath $env:SICKO_ZIP -DestinationPath $stage -Force; $dll=Get-ChildItem -LiteralPath $stage -Filter SickoMenu.dll -File -Recurse | Select-Object -First 1; if(-not $dll){throw 'SickoMenu.dll was not found in the release archive.'}; $target=Join-Path $env:GAME_DIR 'BepInEx\plugins\DLLInjector\InjectionDLLs'; New-Item -ItemType Directory -Path $target -Force | Out-Null; Copy-Item -LiteralPath $dll.FullName -Destination (Join-Path $target 'SickoMenu.dll') -Force"
if errorlevel 1 goto finish

echo Sicko Menu was installed successfully.
set "RESULT=0"

:finish
if exist "%WORK_DIR%" rmdir /s /q "%WORK_DIR%"
del /f /q "%~f0" >nul 2>&1
exit /b %RESULT%