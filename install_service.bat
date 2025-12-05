@echo off
chcp 65001 >nul
echo ========================================
echo Установка System Monitor как службы Windows
echo ========================================
echo.

REM Проверка прав администратора
net session >nul 2>&1
if errorlevel 1 (
    echo [ОШИБКА] Требуются права администратора!
    echo Пожалуйста, запустите этот скрипт от имени администратора
    pause
    exit /b 1
)

REM Путь к текущей директории
set SERVICE_DIR=%~dp0
set SERVICE_NAME=SystemMonitorBot
set SERVICE_DISPLAY_NAME=System Monitor Telegram Bot
set SERVICE_DESCRIPTION=Сервис мониторинга системы с отправкой данных через Telegram

echo [INFO] Директория сервиса: %SERVICE_DIR%
echo.

REM Проверка NSSM
where nssm >nul 2>&1
if errorlevel 1 (
    echo [ОШИБКА] NSSM не найден!
    echo.
    echo Пожалуйста, установите NSSM (Non-Sucking Service Manager):
    echo 1. Скачайте с https://nssm.cc/download
    echo 2. Распакуйте архив
    echo 3. Скопируйте nssm.exe в C:\Windows\System32
    echo    (или добавьте путь к nssm в PATH)
    echo.
    pause
    exit /b 1
)

echo [OK] NSSM найден
echo.

REM Проверка, не установлен ли сервис уже
sc query %SERVICE_NAME% >nul 2>&1
if not errorlevel 1 (
    echo [INFO] Сервис уже установлен. Останавливаем...
    nssm stop %SERVICE_NAME%
    timeout /t 2 /nobreak >nul
    echo [INFO] Удаляем старый сервис...
    nssm remove %SERVICE_NAME% confirm
    timeout /t 2 /nobreak >nul
)

REM Установка сервиса
echo [INFO] Установка сервиса...
nssm install %SERVICE_NAME% "%SERVICE_DIR%venv\Scripts\python.exe" "%SERVICE_DIR%monitor.py"

REM Настройка сервиса
echo [INFO] Настройка параметров сервиса...
nssm set %SERVICE_NAME% DisplayName "%SERVICE_DISPLAY_NAME%"
nssm set %SERVICE_NAME% Description "%SERVICE_DESCRIPTION%"
nssm set %SERVICE_NAME% AppDirectory "%SERVICE_DIR%"
nssm set %SERVICE_NAME% AppStdout "%SERVICE_DIR%service_stdout.log"
nssm set %SERVICE_NAME% AppStderr "%SERVICE_DIR%service_stderr.log"
nssm set %SERVICE_NAME% Start SERVICE_AUTO_START

REM Запуск сервиса
echo [INFO] Запуск сервиса...
nssm start %SERVICE_NAME%

echo.
echo ========================================
echo Сервис установлен и запущен!
echo ========================================
echo.
echo Имя сервиса: %SERVICE_NAME%
echo.
echo Управление сервисом:
echo - Просмотр статуса: sc query %SERVICE_NAME%
echo - Остановка: nssm stop %SERVICE_NAME%
echo - Запуск: nssm start %SERVICE_NAME%
echo - Удаление: nssm remove %SERVICE_NAME% confirm
echo.
echo Логи сервиса:
echo - %SERVICE_DIR%monitor.log
echo - %SERVICE_DIR%service_stdout.log
echo - %SERVICE_DIR%service_stderr.log
echo.
pause
