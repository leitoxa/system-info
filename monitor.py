#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Сервис мониторинга системы с отправкой данных через Telegram

Author: Serik Muftakhidinov
License: MIT License
Copyright (c) 2025 Serik Muftakhidinov
"""

import json
import logging
import os
import socket
import sys
import time
from datetime import datetime
import psutil
import requests
import schedule


class SystemMonitor:
    """Класс для сбора и отправки данных о системе"""
    
    def __init__(self, config_path='config.json'):
        """Инициализация монитора"""
        self.config = self.load_config(config_path)
        self.setup_logging()
        self.logger.info("SystemMonitor инициализирован")
    
    def load_config(self, config_path):
        """Загрузка конфигурации из JSON файла"""
        if not os.path.exists(config_path):
            raise FileNotFoundError(f"Файл конфигурации {config_path} не найден")
        
        with open(config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
        
        # Проверка обязательных параметров
        if config['telegram_token'] == 'YOUR_BOT_TOKEN_HERE':
            raise ValueError("Необходимо указать telegram_token в config.json")
        if config['chat_id'] == 'YOUR_CHAT_ID_HERE':
            raise ValueError("Необходимо указать chat_id в config.json")
        
        return config
    
    def setup_logging(self):
        """Настройка логирования"""
        log_file = self.config.get('log_file', 'monitor.log')
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file, encoding='utf-8'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger('SystemMonitor')
    
    def get_cpu_info(self):
        """Получение информации о загрузке CPU"""
        cpu_percent = psutil.cpu_percent(interval=1)
        cpu_count = psutil.cpu_count()
        return {
            'percent': cpu_percent,
            'count': cpu_count
        }
    
    def get_memory_info(self):
        """Получение информации о памяти"""
        mem = psutil.virtual_memory()
        return {
            'total': mem.total,
            'available': mem.available,
            'used': mem.used,
            'percent': mem.percent
        }
    
    def get_disk_info(self):
        """Получение информации о дисках"""
        disks = []
        
        if self.config.get('monitor_all_disks', True):
            # Мониторинг всех дисков
            for partition in psutil.disk_partitions():
                try:
                    usage = psutil.disk_usage(partition.mountpoint)
                    disks.append({
                        'device': partition.device,
                        'mountpoint': partition.mountpoint,
                        'fstype': partition.fstype,
                        'total': usage.total,
                        'used': usage.used,
                        'free': usage.free,
                        'percent': usage.percent
                    })
                except PermissionError:
                    # Пропускаем диски, к которым нет доступа
                    continue
        
        return disks
    
    def get_ip_addresses(self):
        """Получение IP адресов"""
        ip_info = {}
        
        # Локальный IP адрес
        try:
            hostname = socket.gethostname()
            local_ip = socket.gethostbyname(hostname)
            ip_info['local'] = local_ip
            ip_info['hostname'] = hostname
        except Exception as e:
            self.logger.warning(f"Не удалось получить локальный IP: {e}")
            ip_info['local'] = 'N/A'
            ip_info['hostname'] = 'N/A'
        
        # Внешний IP адрес (опционально)
        try:
            response = requests.get('https://api.ipify.org?format=json', timeout=5)
            if response.status_code == 200:
                ip_info['external'] = response.json()['ip']
            else:
                ip_info['external'] = 'N/A'
        except Exception as e:
            self.logger.warning(f"Не удалось получить внешний IP: {e}")
            ip_info['external'] = 'N/A'
        
        return ip_info
    
    def get_top_processes(self, top_n=10):
        """Получение топ процессов по использованию CPU и памяти"""
        processes = []
        
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent', 'memory_info']):
            try:
                pinfo = proc.info
                processes.append({
                    'pid': pinfo['pid'],
                    'name': pinfo['name'],
                    'cpu_percent': pinfo['cpu_percent'] or 0.0,
                    'memory_percent': pinfo['memory_percent'] or 0.0,
                    'memory_mb': pinfo['memory_info'].rss / (1024 * 1024) if pinfo['memory_info'] else 0
                })
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                pass
        
        # Сортировка по CPU
        top_cpu = sorted(processes, key=lambda x: x['cpu_percent'], reverse=True)[:top_n]
        
        # Сортировка по памяти
        top_memory = sorted(processes, key=lambda x: x['memory_percent'], reverse=True)[:top_n]
        
        return {
            'top_cpu': top_cpu,
            'top_memory': top_memory
        }
    
    def format_bytes(self, bytes_value):
        """Форматирование байтов в читаемый вид"""
        for unit in ['Б', 'КБ', 'МБ', 'ГБ', 'ТБ']:
            if bytes_value < 1024.0:
                return f"{bytes_value:.2f} {unit}"
            bytes_value /= 1024.0
        return f"{bytes_value:.2f} ПБ"
    
    def create_report(self):
        """Создание отчета о состоянии системы"""
        cpu_info = self.get_cpu_info()
        mem_info = self.get_memory_info()
        disk_info = self.get_disk_info()
        ip_info = self.get_ip_addresses()
        process_info = self.get_top_processes(top_n=5)
        
        # Формирование сообщения на русском языке
        report = "📊 <b>Отчет о состоянии системы</b>\n\n"
        report += f"🕐 <b>Время:</b> {datetime.now().strftime('%d.%m.%Y %H:%M:%S')}\n\n"
        
        # Сетевая информация
        report += "🌐 <b>Сеть:</b>\n"
        report += f"├ Имя хоста: {ip_info['hostname']}\n"
        report += f"├ Локальный IP: {ip_info['local']}\n"
        report += f"└ Внешний IP: {ip_info['external']}\n\n"
        
        # Процессор
        report += "💻 <b>Процессор:</b>\n"
        report += f"├ Ядер: {cpu_info['count']}\n"
        report += f"└ Загрузка: {cpu_info['percent']}%\n\n"
        
        # Память
        report += "🧠 <b>Память:</b>\n"
        report += f"├ Всего: {self.format_bytes(mem_info['total'])}\n"
        report += f"├ Использовано: {self.format_bytes(mem_info['used'])} ({mem_info['percent']}%)\n"
        report += f"└ Доступно: {self.format_bytes(mem_info['available'])}\n\n"
        
        # Диски
        report += "💾 <b>Диски:</b>\n"
        for i, disk in enumerate(disk_info):
            is_last = (i == len(disk_info) - 1)
            prefix = "└" if is_last else "├"
            
            report += f"{prefix} <b>{disk['mountpoint']}</b>\n"
            sub_prefix = "  " if is_last else "│ "
            report += f"{sub_prefix}├ Всего: {self.format_bytes(disk['total'])}\n"
            report += f"{sub_prefix}├ Использовано: {self.format_bytes(disk['used'])} ({disk['percent']}%)\n"
            report += f"{sub_prefix}└ Свободно: {self.format_bytes(disk['free'])}\n"
            if not is_last:
                report += "\n"
        
        report += "\n"
        
        # Топ процессы по CPU
        report += "⚡ <b>Топ процессы (CPU):</b>\n"
        for i, proc in enumerate(process_info['top_cpu'][:5]):
            is_last = (i == len(process_info['top_cpu'][:5]) - 1)
            prefix = "└" if is_last else "├"
            report += f"{prefix} {proc['name']}: {proc['cpu_percent']:.1f}% (PID: {proc['pid']})\n"
        
        report += "\n"
        
        # Топ процессы по памяти
        report += "🔥 <b>Топ процессы (Память):</b>\n"
        for i, proc in enumerate(process_info['top_memory'][:5]):
            is_last = (i == len(process_info['top_memory'][:5]) - 1)
            prefix = "└" if is_last else "├"
            report += f"{prefix} {proc['name']}: {proc['memory_mb']:.0f} МБ ({proc['memory_percent']:.1f}%)\n"
        
        return report
    
    def send_telegram_message(self, message):
        """Отправка сообщения в Telegram"""
        url = f"https://api.telegram.org/bot{self.config['telegram_token']}/sendMessage"
        
        payload = {
            'chat_id': self.config['chat_id'],
            'text': message,
            'parse_mode': 'HTML'
        }
        
        try:
            response = requests.post(url, json=payload, timeout=10)
            response.raise_for_status()
            self.logger.info("Отчет успешно отправлен в Telegram")
            return True
        except requests.exceptions.RequestException as e:
            self.logger.error(f"Ошибка при отправке сообщения в Telegram: {e}")
            return False
    
    def send_report(self):
        """Создание и отправка отчета"""
        self.logger.info("Создание отчета о системе...")
        report = self.create_report()
        self.send_telegram_message(report)
    
    def run_test(self):
        """Тестовый запуск - отправка отчета немедленно"""
        self.logger.info("Запуск в тестовом режиме")
        self.send_report()
    
    def run_service(self):
        """Запуск сервиса в режиме планировщика"""
        schedule_time = self.config.get('schedule_time', '08:00')
        self.logger.info(f"Сервис запущен. Отправка отчетов запланирована на {schedule_time}")
        
        # Планирование ежедневной отправки
        schedule.every().day.at(schedule_time).do(self.send_report)
        
        # Отправка первого отчета при запуске (опционально)
        # self.send_report()
        
        # Главный цикл
        try:
            while True:
                schedule.run_pending()
                time.sleep(60)  # Проверка каждую минуту
        except KeyboardInterrupt:
            self.logger.info("Остановка сервиса...")
        except Exception as e:
            self.logger.error(f"Критическая ошибка: {e}")
            raise


def main():
    """Главная функция"""
    # Проверка аргументов командной строки
    test_mode = '--test' in sys.argv
    
    try:
        monitor = SystemMonitor()
        
        if test_mode:
            monitor.run_test()
        else:
            monitor.run_service()
    
    except Exception as e:
        logging.error(f"Ошибка при запуске: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
