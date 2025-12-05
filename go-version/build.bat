@echo off
chcp 65001 >nul
echo ========================================
echo Сборка System Monitor (Go версия)
echo ========================================
echo.

REM Проверка Go
set GO_CMD=go
where go >nul 2>&1
if errorlevel 1 (
    if exist "C:\Program Files\Go\bin\go.exe" (
        set "GO_CMD=C:\Program Files\Go\bin\go.exe"
        echo [INFO] Go найден в C:\Program Files\Go\bin
    ) else (
        echo [ОШИБКА] Go не найден!
        echo.
        echo Пожалуйста, установите Go с https://go.dev/dl/
        echo И перезапустите терминал.
        echo.
        pause
        exit /b 1
    )
)

"%GO_CMD%" version
echo [OK] Go установлен
echo.

REM Загрузка зависимостей
echo [INFO] Загрузка зависимостей...
"%GO_CMD%" mod tidy
"%GO_CMD%" mod download
if errorlevel 1 (
    echo [ОШИБКА] Не удалось загрузить зависимости
    pause
    exit /b 1
)
echo [OK] Зависимости загружены
echo.

REM Сборка для Windows
echo [INFO] Сборка исполняемого файла...
"%GO_CMD%" build -ldflags="-s -w" -o system-monitor.exe
if errorlevel 1 (
    echo [ОШИБКА] Не удалось собрать проект
    pause
    exit /b 1
)
echo [OK] Сборка завершена
echo.

REM Информация о файле
echo ========================================
echo Успешно!
echo ========================================
echo.
echo Создан файл: system-monitor.exe
dir system-monitor.exe | find "system-monitor.exe"
echo.
echo Примерный размер: 6-10 MB (без зависимостей!)
echo.
echo Использование:
echo   system-monitor.exe          - запуск сервиса
echo   system-monitor.exe --test   - тестовая отправка
echo   system-monitor.exe --version - показать версию
echo.
pause
