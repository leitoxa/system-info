package telegram

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
	"system-monitor/monitor"
)

const telegramAPIURL = "https://api.telegram.org/bot%s/sendMessage"

// SendMessage sends a message to Telegram
func SendMessage(token, chatID, message string) error {
	url := fmt.Sprintf(telegramAPIURL, token)

	payload := map[string]interface{}{
		"chat_id":    chatID,
		"text":       message,
		"parse_mode": "HTML",
	}

	jsonPayload, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	resp, err := client.Post(url, "application/json", bytes.NewBuffer(jsonPayload))
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("telegram API returned status %d", resp.StatusCode)
	}

	return nil
}

// CreateReport creates a formatted system report
func CreateReport(computerName string) (string, error) {
	var report string

	// Header
	report += "📊 <b>Отчет о состоянии системы</b>\n\n"
	
	// Computer name
	if computerName != "" {
		report += fmt.Sprintf("🖥️ <b>Компьютер:</b> %s\n", computerName)
	}
	
	report += fmt.Sprintf("🕐 <b>Время:</b> %s\n\n", time.Now().Format("02.01.2006 15:04:05"))

	// Network info
	ipInfo, err := monitor.GetIPInfo()
	if err == nil {
		report += "🌐 <b>Сеть:</b>\n"
		report += fmt.Sprintf("├ Имя хоста: %s\n", ipInfo.Hostname)
		report += fmt.Sprintf("├ Локальный IP: %s\n", ipInfo.LocalIP)
		report += fmt.Sprintf("└ Внешний IP: %s\n\n", ipInfo.ExternalIP)
	}

	// CPU info
	cpuInfo, err := monitor.GetCPUInfo()
	if err == nil {
		report += "💻 <b>Процессор:</b>\n"
		report += fmt.Sprintf("├ Ядер: %d\n", cpuInfo.Count)
		report += fmt.Sprintf("└ Загрузка: %.1f%%\n\n", cpuInfo.Percent)
	}

	// Memory info
	memInfo, err := monitor.GetMemoryInfo()
	if err == nil {
		report += "🧠 <b>Память:</b>\n"
		report += fmt.Sprintf("├ Всего: %s\n", monitor.FormatBytes(memInfo.Total))
		report += fmt.Sprintf("├ Использовано: %s (%.1f%%)\n", monitor.FormatBytes(memInfo.Used), memInfo.Percent)
		report += fmt.Sprintf("└ Доступно: %s\n\n", monitor.FormatBytes(memInfo.Available))
	}

	// Disk info
	disks, err := monitor.GetDiskInfo()
	if err == nil && len(disks) > 0 {
		report += "💾 <b>Диски:</b>\n"
		for i, disk := range disks {
			isLast := i == len(disks)-1
			prefix := "└"
			subPrefix := "  "
			if !isLast {
				prefix = "├"
				subPrefix = "│ "
			}

			report += fmt.Sprintf("%s <b>%s</b>\n", prefix, disk.Mountpoint)
			report += fmt.Sprintf("%s├ Всего: %s\n", subPrefix, monitor.FormatBytes(disk.Total))
			report += fmt.Sprintf("%s├ Использовано: %s (%.1f%%)\n", subPrefix, monitor.FormatBytes(disk.Used), disk.Percent)
			report += fmt.Sprintf("%s└ Свободно: %s\n", subPrefix, monitor.FormatBytes(disk.Free))
			if !isLast {
				report += "\n"
			}
		}
		report += "\n"
	}

	// Top CPU processes
	topCPU, err := monitor.GetTopProcessesByCPU(5)
	if err == nil && len(topCPU) > 0 {
		report += "⚡ <b>Топ процессы (CPU):</b>\n"
		for i, proc := range topCPU {
			isLast := i == len(topCPU)-1
			prefix := "└"
			if !isLast {
				prefix = "├"
			}
			report += fmt.Sprintf("%s %s: %.1f%% (PID: %d)\n", prefix, proc.Name, proc.CPUPercent, proc.PID)
		}
		report += "\n"
	}

	// Top memory processes
	topMem, err := monitor.GetTopProcessesByMemory(5)
	if err == nil && len(topMem) > 0 {
		report += "🔥 <b>Топ процессы (Память):</b>\n"
		for i, proc := range topMem {
			isLast := i == len(topMem)-1
			prefix := "└"
			if !isLast {
				prefix = "├"
			}
			report += fmt.Sprintf("%s %s: %.0f МБ (%.1f%%)\n", prefix, proc.Name, proc.MemoryMB, proc.MemoryPercent)
		}
	}

	return report, nil
}
