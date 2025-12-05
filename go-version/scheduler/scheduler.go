package scheduler

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"system-monitor/config"
	"system-monitor/telegram"
	
	"github.com/go-co-op/gocron"
)

// Run starts the scheduler
func Run(cfg *config.Config) error {
	s := gocron.NewScheduler(nil)

	// Schedule daily report
	_, err := s.Every(1).Day().At(cfg.ScheduleTime).Do(func() {
		log.Printf("Создание и отправка отчета...")
		if err := sendReport(cfg); err != nil {
			log.Printf("Ошибка при отправке отчета: %v", err)
		} else {
			log.Printf("Отчет успешно отправлен")
		}
	})

	if err != nil {
		return fmt.Errorf("failed to schedule task: %w", err)
	}

	log.Printf("Сервис запущен. Отправка отчетов запланирована на %s", cfg.ScheduleTime)

	// Start the scheduler
	s.StartAsync()

	// Wait for interrupt signal
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	log.Println("Остановка сервиса...")
	s.Stop()

	return nil
}

// RunTest sends a test report immediately
func RunTest(cfg *config.Config) error {
	log.Println("Запуск в тестовом режиме")
	return sendReport(cfg)
}

func sendReport(cfg *config.Config) error {
	report, err := telegram.CreateReport(cfg.ComputerName)
	if err != nil {
		return fmt.Errorf("failed to create report: %w", err)
	}

	if err := telegram.SendMessage(cfg.TelegramToken, cfg.ChatID, report); err != nil {
		return fmt.Errorf("failed to send message: %w", err)
	}

	return nil
}
