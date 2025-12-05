@echo off
chcp 65001 >nul
echo ========================================
echo Упаковка Go версии в ZIP
echo ========================================
echo.

REM Проверка наличия .exe
if not exist system-monitor.exe (
    echo [ОШИБКА] system-monitor.exe не найден!
    echo Сначала запустите build.bat
    pause
    exit /b 1
)

REM Создание папки release
if exist release rmdir /s /q release
mkdir release

echo [INFO] Копирование файлов...
copy system-monitor.exe release\ >nul
copy config.json release\ >nul
copy README.md release\ >nul
copy INTERACTIVE.md release\ >nul

copy START.txt release\ >nul

echo [INFO] Создание архива...
powershell -Command "Compress-Archive -Path 'release\*' -DestinationPath 'system-monitor-go.zip' -Force"

REM Очистка
rmdir /s /q release

echo.
echo ========================================
echo Готово!
echo ========================================
echo.
echo Архив создан: system-monitor-go.zip
dir system-monitor-go.zip | find "system-monitor-go.zip"
echo.

