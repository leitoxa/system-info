@echo off
chcp 65001 >nul
echo ========================================
echo Сборка установочного пакета
echo ========================================
echo.

REM Проверка наличия output
if not exist output (
    echo [INFO] Создание папки output...
    mkdir output
)

REM Очистка старых файлов
echo [INFO] Очистка старых файлов...
if exist output\system-monitor-bot-installer.zip del /q output\system-monitor-bot-installer.zip

REM Список файлов для включения в установщик
echo [INFO] Подготовка файлов...

REM Создание временной папки
set TEMP_DIR=output\temp_build
if exist %TEMP_DIR% rmdir /s /q %TEMP_DIR%
mkdir %TEMP_DIR%

REM Копирование файлов
echo [INFO] Копирование файлов...
copy LICENSE %TEMP_DIR%\ >nul
copy README.md %TEMP_DIR%\ >nul
copy monitor.py %TEMP_DIR%\ >nul
copy requirements.txt %TEMP_DIR%\ >nul
copy setup.bat %TEMP_DIR%\ >nul
copy run.bat %TEMP_DIR%\ >nul
copy install_service.bat %TEMP_DIR%\ >nul
copy .gitignore %TEMP_DIR%\ >nul

REM Создание config-template.json (без токенов)
echo [INFO] Создание config-template.json...
(
echo {
echo   "telegram_token": "YOUR_BOT_TOKEN_HERE",
echo   "chat_id": "YOUR_CHAT_ID_HERE",
echo   "schedule_time": "08:00",
echo   "monitor_all_disks": true,
echo   "language": "ru",
echo   "log_file": "monitor.log"
echo }
) > %TEMP_DIR%\config-template.json

REM Создание README для установщика
echo [INFO] Создание инструкции по установке...
(
echo # System Monitor - Telegram Bot
echo.
echo Установщик для Windows
echo Автор: Serik Muftakhidinov
echo.
echo ## Быстрая установка
echo.
echo 1. Запустите setup.bat
echo 2. Следуйте инструкциям на экране
echo 3. Введите токен Telegram бота
echo 4. Введите Chat ID
echo 5. Выберите время отправки отчетов
echo.
echo ## Требования
echo.
echo - Windows 7/8/10/11
echo - Python 3.8 или выше
echo.
echo ## Поддержка
echo.
echo Полная документация в файле README.md
echo.
echo Лицензия: MIT
) > %TEMP_DIR%\INSTALL.txt

REM Проверка наличия PowerShell для создания ZIP
echo [INFO] Создание ZIP архива...
powershell -Command "Compress-Archive -Path '%TEMP_DIR%\*' -DestinationPath 'output\system-monitor-bot-installer.zip' -Force"

if errorlevel 1 (
    echo.
    echo [ОШИБКА] Не удалось создать ZIP архив
    echo.
    echo Файлы находятся в папке: %TEMP_DIR%
    echo Вы можете создать архив вручную
    echo.
    pause
    exit /b 1
)

REM Очистка временной папки
echo [INFO] Очистка...
rmdir /s /q %TEMP_DIR%

echo.
echo ========================================
echo Сборка завершена успешно!
echo ========================================
echo.
echo Установщик создан:
echo   output\system-monitor-bot-installer.zip
echo.
echo Размер архива:
dir output\system-monitor-bot-installer.zip | find "system-monitor-bot-installer.zip"
echo.
echo Этот архив можно распространять и устанавливать на других компьютерах.
echo.
echo Для установки:
echo 1. Распакуйте архив
echo 2. Запустите setup.bat
echo 3. Следуйте инструкциям
echo.
pause
