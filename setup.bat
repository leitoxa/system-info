@echo off
chcp 65001 >nul
echo ========================================
echo Установка System Monitor Bot
echo ========================================
echo.

REM Проверка Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [ОШИБКА] Python не найден!
    echo Пожалуйста, установите Python 3.8 или выше с https://www.python.org/
    pause
    exit /b 1
)

echo [OK] Python найден
echo.

REM Создание виртуального окружения
if exist venv (
    echo [INFO] Виртуальное окружение уже существует
) else (
    echo [INFO] Создание виртуального окружения...
    python -m venv venv
    if errorlevel 1 (
        echo [ОШИБКА] Не удалось создать виртуальное окружение
        pause
        exit /b 1
    )
    echo [OK] Виртуальное окружение создано
)
echo.

REM Активация виртуального окружения и установка зависимостей
echo [INFO] Установка зависимостей...
call venv\Scripts\activate.bat
python -m pip install --upgrade pip
pip install -r requirements.txt
if errorlevel 1 (
    echo [ОШИБКА] Не удалось установить зависимости
    pause
    exit /b 1
)
echo [OK] Зависимости установлены
echo.

REM Проверка config.json
if not exist config.json (
    echo [ОШИБКА] Файл config.json не найден!
    pause
    exit /b 1
)

echo ========================================
echo Установка завершена успешно!
echo ========================================
echo.
echo СЛЕДУЮЩИЕ ШАГИ:
echo 1. Создайте Telegram бота через @BotFather
echo 2. Получите токен бота
echo 3. Получите ваш Chat ID (используйте @userinfobot)
echo 4. Откройте config.json и укажите:
echo    - telegram_token
echo    - chat_id
echo 5. Запустите run.bat для тестирования
echo 6. Запустите install_service.bat для установки как службы
echo.
pause
