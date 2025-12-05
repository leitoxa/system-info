@echo off
chcp 65001 >nul
echo ========================================
echo Git - Быстрая инициализация и первый Push
echo ========================================
echo.

REM Проверка Git
git --version >nul 2>&1
if errorlevel 1 (
    echo [ОШИБКА] Git не найден!
    echo Установите Git с https://git-scm.com/
    pause
    exit /b 1
)

echo [OK] Git установлен
echo.

REM Инициализация если нужно
if not exist .git (
    echo [INFO] Инициализация репозитория...
    git init
    echo [OK] Репозиторий инициализирован
    echo.
    
    REM Настройка пользователя
    echo [INFO] Настройка автора...
    git config user.name "Serik Muftakhidinov"
    git config user.email "leitoxa@example.com"
    echo [OK] Автор настроен
    echo.
)

REM Настройка remote
set REPO_URL=https://github.com/leitoxa/system-info.git
echo [INFO] Настройка remote: %REPO_URL%
git remote remove origin 2>nul
git remote add origin %REPO_URL%
echo [OK] Remote настроен
echo.

REM Переименование в main
git branch -M main 2>nul
echo.

REM Добавление файлов
echo [INFO] Добавление файлов...
git add .
echo [OK] Файлы добавлены
echo.

REM Коммит
echo [INFO] Создание коммита...
git commit -m "Initial commit: System Monitor Telegram Bot by Serik Muftakhidinov"
if errorlevel 1 (
    echo [INFO] Нет изменений для коммита
    echo.
) else (
    echo [OK] Коммит создан
    echo.
)

REM Push
echo [INFO] Отправка на GitHub...
git push -u origin main

if errorlevel 1 (
    echo.
    echo [ВНИМАНИЕ] Не удалось выполнить push!
    echo.
    echo Возможные причины:
    echo - Требуется авторизация (используйте Personal Access Token)
    echo - Репозиторий не существует на GitHub
    echo - Нет прав доступа
    echo.
    echo Попробуйте выполнить вручную:
    echo   git push -u origin main
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Успешно отправлено на GitHub!
echo ========================================
echo Repository: %REPO_URL%
echo.
pause
