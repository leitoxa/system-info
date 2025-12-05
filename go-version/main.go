package main

import (
	"flag"
	"log"
	"os"
	"system-monitor/bot"
	"system-monitor/config"
	"system-monitor/scheduler"
)

const (
	version = "1.0.0"
	author  = "Serik Muftakhidinov"
)

func main() {
	// Parse command line flags
	testMode := flag.Bool("test", false, "Run in test mode (send report immediately)")
	configPath := flag.String("config", "config.json", "Path to config file")
	showVersion := flag.Bool("version", false, "Show version information")
	flag.Parse()

	if *showVersion {
		log.Printf("System Monitor v%s by %s", version, author)
		return
	}

	// Load configuration
	cfg, err := config.LoadConfig(*configPath)
	if err != nil {
		log.Fatalf("Ошибка загрузки конфигурации: %v", err)
	}

	// Setup logging
	if cfg.LogFile != "" {
		logFile, err := os.OpenFile(cfg.LogFile, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
		if err == nil {
			defer logFile.Close()
			log.SetOutput(logFile)
		}
	}

	log.Printf("System Monitor v%s starting...", version)
	log.Printf("Computer: %s (%s)", cfg.ComputerName, cfg.ComputerID)

	// Run in test or service mode
	if *testMode {
		if err := scheduler.RunTest(cfg); err != nil {
			log.Fatalf("Ошибка в тестовом режиме: %v", err)
		}
		log.Println("Тестовая отправка завершена")
		return
	}

	// Run scheduler in background
	go func() {
		if err := scheduler.Run(cfg); err != nil {
			log.Fatalf("Ошибка запуска планировщика: %v", err)
		}
	}()

	// Run polling if enabled
	if cfg.EnablePolling {
		log.Println("Interactive mode enabled")
		poller := bot.NewPoller(cfg)
		poller.StartPolling()
	} else {
		log.Println("Polling disabled, running in scheduled mode only")
		// Keep running
		select {}
	}
}
