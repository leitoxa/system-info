package config

import (
	"encoding/json"
	"fmt"
	"os"
)

// Config represents the application configuration
type Config struct {
	ComputerID     string `json:"computer_id"`
	ComputerName   string `json:"computer_name"`
	TelegramToken  string `json:"telegram_token"`
	ChatID         string `json:"chat_id"`
	ScheduleTime   string `json:"schedule_time"`
	MonitorAllDisks bool  `json:"monitor_all_disks"`
	Language       string `json:"language"`
	LogFile        string `json:"log_file"`
	EnablePolling  bool   `json:"enable_polling"`
}

// LoadConfig loads configuration from a JSON file
func LoadConfig(path string) (*Config, error) {
	file, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var cfg Config
	if err := json.Unmarshal(file, &cfg); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}

	// Validate required fields
	if cfg.TelegramToken == "" || cfg.TelegramToken == "YOUR_BOT_TOKEN_HERE" {
		return nil, fmt.Errorf("telegram_token is required in config.json")
	}

	if cfg.ChatID == "" || cfg.ChatID == "YOUR_CHAT_ID_HERE" {
		return nil, fmt.Errorf("chat_id is required in config.json")
	}

	// Set defaults
	if cfg.ScheduleTime == "" {
		cfg.ScheduleTime = "08:00"
	}

	if cfg.Language == "" {
		cfg.Language = "ru"
	}

	if cfg.LogFile == "" {
		cfg.LogFile = "monitor.log"
	}

	if cfg.ComputerID == "" {
		// Generate from hostname if not specified
		hostname, _ := os.Hostname()
		cfg.ComputerID = hostname
	}

	if cfg.ComputerName == "" {
		cfg.ComputerName = cfg.ComputerID
	}

	return &cfg, nil
}
