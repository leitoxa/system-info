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

REM Добавление remote
set REPO_URL=https://github.com/leitoxa/system-info.git
echo [INFO] Добавление remote репозитория...
echo URL: %REPO_URL%

git remote add origin %REPO_URL% 2>nul
if errorlevel 1 (
    echo [INFO] Remote origin уже существует, обновляем URL...
    git remote set-url origin %REPO_URL%
)
echo [OK] Remote настроен
echo.

REM Переименование ветки в main
echo [INFO] Переименование ветки в main...
git branch -M main
echo [OK] Ветка переименована
echo.

echo ========================================
echo Репозиторий готов!
echo ========================================
echo.
echo Remote URL: %REPO_URL%
echo.
echo СЛЕДУЮЩИЙ ШАГ:
echo Выполните первый push командой:
echo    git push -u origin main
echo.
echo Или используйте git_push.bat
echo.
pause
