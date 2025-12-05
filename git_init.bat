@echo off
chcp 65001 >nul
echo ========================================
echo Инициализация Git репозитория
echo ========================================
echo.

REM Проверка установки Git
git --version >nul 2>&1
if errorlevel 1 (
    echo [ОШИБКА] Git не найден!
    echo Пожалуйста, установите Git с https://git-scm.com/
    pause
    exit /b 1
)

echo [OK] Git установлен
echo.

REM Инициализация репозитория
if exist .git (
    echo [INFO] Git репозиторий уже инициализирован
) else (
    echo [INFO] Инициализация нового репозитория...
    git init
    echo [OK] Репозиторий инициализирован
)
echo.

REM Настройка пользователя (опционально)
echo [INFO] Настройка автора коммитов...
git config user.name "Serik Muftakhidinov"
git config user.email "your.email@example.com"
echo [OK] Автор настроен
echo.

REM Добавление всех файлов
echo [INFO] Добавление файлов в индекс...
git add .
echo [OK] Файлы добавлены
echo.

REM Первый коммит
echo [INFO] Создание первого коммита...
git commit -m "Initial commit: System Monitor Telegram Bot"
echo [OK] Коммит создан
echo.

echo ========================================
echo Репозиторий готов!
echo ========================================
echo.
echo СЛЕДУЮЩИЕ ШАГИ:
echo 1. Создайте репозиторий на GitHub
echo 2. Скопируйте URL репозитория
echo 3. Выполните команду:
echo    git remote add origin https://github.com/ВАШ_USERNAME/system-monitor-bot.git
echo 4. Выполните первый пуш:
echo    git push -u origin main
echo.
echo Или используйте git_push.bat для регулярных обновлений
echo.
pause
