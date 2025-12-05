@echo off
chcp 65001 >nul
echo ========================================
echo Git Push - Автоматическая отправка
echo ========================================
echo.

REM Проверка Git
git --version >nul 2>&1
if errorlevel 1 (
    echo [ОШИБКА] Git не найден!
    pause
    exit /b 1
)

REM Проверка наличия репозитория
if not exist .git (
    echo [ОШИБКА] Git репозиторий не инициализирован!
    echo Запустите сначала git_init.bat
    pause
    exit /b 1
)

REM Проверка статуса
echo [INFO] Проверка изменений...
git status --short
echo.

REM Запрос сообщения коммита
set /p COMMIT_MSG="Введите сообщение коммита (или нажмите Enter для автосообщения): "

if "%COMMIT_MSG%"=="" (
    REM Автоматическое сообщение с датой и временем
    for /f "tokens=1-3 delims=/. " %%a in ('date /t') do set DATE=%%a-%%b-%%c
    for /f "tokens=1-2 delims=:. " %%a in ('time /t') do set TIME=%%a:%%b
    set COMMIT_MSG=Update: %DATE% %TIME%
)

echo.
echo [INFO] Добавление изменений...
git add .

echo [INFO] Создание коммита...
git commit -m "%COMMIT_MSG%"

if errorlevel 1 (
    echo [INFO] Нет изменений для коммита
) else (
    echo [OK] Коммит создан
)

echo.
echo [INFO] Отправка на сервер...
git push

if errorlevel 1 (
    echo.
    echo [ВНИМАНИЕ] Ошибка при отправке!
    echo.
    echo Возможные причины:
    echo - Remote не настроен (используйте: git remote add origin URL)
    echo - Нет прав доступа к репозиторию
    echo - Проблемы с подключением
    echo.
    echo Попробуйте выполнить команды вручную:
    echo   git remote add origin https://github.com/USERNAME/REPO.git
    echo   git push -u origin main
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Успешно отправлено на GitHub!
echo ========================================
echo.
pause
