@echo off
chcp 65001 >nul
cls
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                                                                ║
echo ║   System Monitor - Telegram Bot                               ║
echo ║   Установщик с интерактивной настройкой                       ║
echo ║                                                                ║
echo ║   Автор: Serik Muftakhidinov                                  ║
echo ║                                                                ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
echo.

REM Проверка Python
echo [1/6] Проверка Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo [ОШИБКА] Python не найден!
    echo.
    echo Пожалуйста, установите Python 3.8 или выше:
    echo https://www.python.org/downloads/
    echo.
    echo При установке обязательно отметьте "Add Python to PATH"
    echo.
    pause
    exit /b 1
)
python --version
echo [OK] Python установлен
echo.

REM Создание виртуального окружения
echo [2/6] Создание виртуального окружения...
if exist venv (
    echo [INFO] Виртуальное окружение уже существует
) else (
    python -m venv venv
    if errorlevel 1 (
        echo [ОШИБКА] Не удалось создать виртуальное окружение
        pause
        exit /b 1
    )
    echo [OK] Виртуальное окружение создано
)
echo.

REM Установка зависимостей
echo [3/6] Установка зависимостей...
call venv\Scripts\activate.bat
python -m pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
if errorlevel 1 (
    echo [ОШИБКА] Не удалось установить зависимости
    pause
    exit /b 1
)
echo [OK] Зависимости установлены
echo.

REM ===== ИНТЕРАКТИВНАЯ НАСТРОЙКА =====
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                  НАСТРОЙКА TELEGRAM БОТА                       ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
echo Для работы сервиса нужны следующие данные:
echo.
echo 1. Токен Telegram бота (получить у @BotFather)
echo 2. Chat ID (получить у @userinfobot)
echo 3. Время отправки ежедневных отчетов
echo.
pause
cls

REM Токен бота
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                    ШАГ 1: ТОКЕН БОТА                           ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
echo Как получить токен бота:
echo 1. Найдите @BotFather в Telegram
echo 2. Отправьте команду /newbot
echo 3. Следуйте инструкциям
echo 4. Скопируйте токен (формат: 123456789:ABCdefGHIjklMNO...)
echo.
set /p BOT_TOKEN="Введите токен бота: "
if "%BOT_TOKEN%"=="" (
    echo [ОШИБКА] Токен не может быть пустым!
    pause
    exit /b 1
)
echo.

REM Chat ID
cls
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                     ШАГ 2: CHAT ID                             ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
echo Как получить Chat ID:
echo 1. Найдите @userinfobot в Telegram
echo 2. Отправьте ему любое сообщение
echo 3. Бот ответит вашим Chat ID (например: 123456789)
echo.
echo Альтернативный способ:
echo 1. Напишите вашему боту любое сообщение
echo 2. Откройте: https://api.telegram.org/bot[ВАШ_ТОКЕН]/getUpdates
echo 3. Найдите "chat":{"id":123456789}
echo.
set /p CHAT_ID="Введите Chat ID: "
if "%CHAT_ID%"=="" (
    echo [ОШИБКА] Chat ID не может быть пустым!
    pause
    exit /b 1
)
echo.

REM Время отправки
cls
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                ШАГ 3: ВРЕМЯ ОТПРАВКИ ОТЧЕТОВ                   ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
echo Введите время ежедневной отправки отчетов в формате ЧЧ:ММ
echo Примеры: 08:00, 09:30, 18:00
echo.
set /p SCHEDULE_TIME="Введите время (по умолчанию 08:00): "
if "%SCHEDULE_TIME%"=="" set SCHEDULE_TIME=08:00
echo.

REM Создание конфигурационного файла
echo [4/6] Создание конфигурационного файла...
(
echo {
echo   "telegram_token": "%BOT_TOKEN%",
echo   "chat_id": "%CHAT_ID%",
echo   "schedule_time": "%SCHEDULE_TIME%",
echo   "monitor_all_disks": true,
echo   "language": "ru",
echo   "log_file": "monitor.log"
echo }
) > config.json
echo [OK] Конфигурация сохранена
echo.

REM Тестовая отправка
cls
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                   ТЕСТИРОВАНИЕ НАСТРОЕК                        ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
set /p DO_TEST="Выполнить тестовую отправку сообщения? (yes/no): "
if /i "%DO_TEST%"=="yes" (
    echo.
    echo [5/6] Отправка тестового отчета...
    echo Ожидайте, это может занять несколько секунд...
    python monitor.py --test
    echo.
    echo Проверьте Telegram - должно прийти сообщение с отчетом о системе!
    echo.
) else (
    echo [5/6] Тестовая отправка пропущена
    echo.
)

REM Установка как служба
echo [6/6] Установка как служба Windows...
echo.
set /p INSTALL_SERVICE="Установить как службу Windows (автозапуск)? (yes/no): "
if /i "%INSTALL_SERVICE%"=="yes" (
    echo.
    echo Для установки службы требуются права администратора.
    echo Сейчас откроется окно установки службы...
    pause
    powershell -Command "Start-Process '%~dp0install_service.bat' -Verb RunAs"
    echo.
    echo [INFO] Скрипт установки службы запущен отдельным окном
) else (
    echo [INFO] Служба не установлена
    echo.
    echo Для ручного запуска используйте:
    echo   run.bat          - запуск в обычном режиме
    echo   run.bat --test   - тестовая отправка
)
echo.

REM Завершение
cls
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                    УСТАНОВКА ЗАВЕРШЕНА!                        ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
echo ✓ Python и зависимости установлены
echo ✓ Конфигурация настроена:
echo   - Токен бота: %BOT_TOKEN:~0,15%...
echo   - Chat ID: %CHAT_ID%
echo   - Время отправки: %SCHEDULE_TIME%
echo.
echo ═══════════════════════════════════════════════════════════════
echo   УПРАВЛЕНИЕ СЕРВИСОМ
echo ═══════════════════════════════════════════════════════════════
echo.
echo   run.bat                - Запуск в режиме мониторинга
echo   run.bat --test         - Тестовая отправка отчета
echo   install_service.bat    - Установка как служба Windows
echo   git_push.bat           - Сохранить изменения на GitHub
echo.
echo ═══════════════════════════════════════════════════════════════
echo   ФАЙЛЫ
echo ═══════════════════════════════════════════════════════════════
echo.
echo   config.json            - Настройки (токен, chat_id, время)
echo   monitor.log            - Лог работы сервиса
echo   README.md              - Полная документация
echo.
echo Автор: Serik Muftakhidinov
echo Лицензия: MIT
echo.
pause
