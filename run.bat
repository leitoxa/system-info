@echo off
chcp 65001 >nul
echo ========================================
echo Запуск System Monitor Bot
echo ========================================
echo.

REM Проверка виртуального окружения
if not exist venv (
    echo [ОШИБКА] Виртуальное окружение не найдено!
    echo Пожалуйста, запустите setup.bat сначала
    pause
    exit /b 1
)

REM Активация виртуального окружения
call venv\Scripts\activate.bat

REM Запуск монитора
if "%1"=="--test" (
    echo [INFO] Запуск в тестовом режиме...
    python monitor.py --test
) else (
    echo [INFO] Запуск в режиме службы...
    echo [INFO] Отчеты будут отправляться ежедневно согласно расписанию
    echo [INFO] Для остановки нажмите Ctrl+C
    echo.
    python monitor.py
)

pause
