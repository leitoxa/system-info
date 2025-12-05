package bot

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"
	"system-monitor/config"
	"system-monitor/telegram"
)

const (
	telegramAPIURL = "https://api.telegram.org/bot%s"
	pollTimeout    = 30
)

// Update represents a Telegram update
type Update struct {
	UpdateID int `json:"update_id"`
	Message  *Message `json:"message,omitempty"`
	CallbackQuery *CallbackQuery `json:"callback_query,omitempty"`
}

// Message represents a Telegram message
type Message struct {
	MessageID int    `json:"message_id"`
	From      *User  `json:"from"`
	Chat      *Chat  `json:"chat"`
	Text      string `json:"text"`
}

// CallbackQuery represents a callback from inline keyboard
type CallbackQuery struct {
	ID      string   `json:"id"`
	From    *User    `json:"from"`
	Message *Message `json:"message"`
	Data    string   `json:"data"`
}

// User represents a Telegram user
type User struct {
	ID        int64  `json:"id"`
	FirstName string `json:"first_name"`
	Username  string `json:"username,omitempty"`
}

// Chat represents a Telegram chat
type Chat struct {
	ID   int64  `json:"id"`
	Type string `json:"type"`
}

// InlineKeyboardMarkup represents inline keyboard
type InlineKeyboardMarkup struct {
	InlineKeyboard [][]InlineKeyboardButton `json:"inline_keyboard"`
}

// InlineKeyboardButton represents a button
type InlineKeyboardButton struct {
	Text         string `json:"text"`
	CallbackData string `json:"callback_data,omitempty"`
}

// ComputerInfo stores active computer information
type ComputerInfo struct {
	ID       string
	Name     string
	LastSeen time.Time
}

// Poller manages Telegram bot polling
type Poller struct {
	token         string
	chatID        string
	cfg           *config.Config
	offset        int
	computers     map[string]*ComputerInfo
	computersMux  sync.RWMutex
}

// NewPoller creates a new poller
func NewPoller(cfg *config.Config) *Poller {
	return &Poller{
		token:     cfg.TelegramToken,
		chatID:    cfg.ChatID,
		cfg:       cfg,
		computers: make(map[string]*ComputerInfo),
	}
}

// RegisterComputer registers this computer
func (p *Poller) RegisterComputer() {
	p.computersMux.Lock()
	defer p.computersMux.Unlock()
	
	p.computers[p.cfg.ComputerID] = &ComputerInfo{
		ID:       p.cfg.ComputerID,
		Name:     p.cfg.ComputerName,
		LastSeen: time.Now(),
	}
}

// UpdateLastSeen updates computer's last seen time
func (p *Poller) UpdateLastSeen() {
	p.computersMux.Lock()
	defer p.computersMux.Unlock()
	
	if comp, exists := p.computers[p.cfg.ComputerID]; exists {
		comp.LastSeen = time.Now()
	}
}

// StartPolling starts the polling loop
func (p *Poller) StartPolling() {
	log.Println("Запуск Telegram polling...")
	
	// Register this computer
	p.RegisterComputer()
	
	for {
		updates, err := p.getUpdates()
		if err != nil {
			log.Printf("Ошибка получения обновлений: %v", err)
			time.Sleep(5 * time.Second)
			continue
		}

		for _, update := range updates {
			p.processUpdate(update)
			p.offset = update.UpdateID + 1
		}
	}
}

// getUpdates fetches updates from Telegram
func (p *Poller) getUpdates() ([]Update, error) {
	url := fmt.Sprintf(telegramAPIURL+"/getUpdates?offset=%d&timeout=%d", 
		p.token, p.offset, pollTimeout)

	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var response struct {
		OK     bool     `json:"ok"`
		Result []Update `json:"result"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, err
	}

	if !response.OK {
		return nil, fmt.Errorf("telegram API error")
	}

	return response.Result, nil
}

// processUpdate processes a single update
func (p *Poller) processUpdate(update Update) {
	// Handle text messages (commands)
	if update.Message != nil && update.Message.Text != "" {
		p.handleCommand(update.Message)
		return
	}

	// Handle callback queries (button presses)
	if update.CallbackQuery != nil {
		p.handleCallback(update.CallbackQuery)
		return
	}
}

// handleCommand processes text commands
func (p *Poller) handleCommand(msg *Message) {
	command := msg.Text
	
	log.Printf("Получена команда: %s от %s", command, msg.From.Username)
	
	switch command {
	case "/info":
		p.handleInfo()
	case "/status":
		p.handleStatus()
	case "/help", "/start":
		p.handleHelp()
	default:
		p.sendMessage("Неизвестная команда. Используйте /help для списка команд.")
	}
}

// handleInfo shows computer selection menu
func (p *Poller) handleInfo() {
	p.computersMux.RLock()
	defer p.computersMux.RUnlock()
	
	if len(p.computers) == 0 {
		p.sendMessage("Нет доступных компьютеров")
		return
	}
	
	// Create keyboard with computer buttons
	keyboard := p.createComputerKeyboard()
	p.sendKeyboard("Выберите компьютер:", keyboard)
}

// handleStatus shows brief status of all computers
func (p *Poller) handleStatus() {
	p.computersMux.RLock()
	defer p.computersMux.RUnlock()
	
	if len(p.computers) == 0 {
		p.sendMessage("Нет зарегистрированных компьютеров")
		return
	}
	
	status := "📊 <b>Статус компьютеров:</b>\n\n"
	
	for _, comp := range p.computers {
		elapsed := time.Since(comp.LastSeen)
		statusIcon := "✅"
		statusText := "Online"
		
		if elapsed > 10*time.Minute {
			statusIcon = "❌"
			statusText = "Offline"
		}
		
		status += fmt.Sprintf("%s <b>%s</b> - %s\n", statusIcon, comp.Name, statusText)
		status += fmt.Sprintf("   Последняя активность: %v назад\n\n", elapsed.Round(time.Minute))
	}
	
	p.sendMessage(status)
}

// handleHelp shows help message
func (p *Poller) handleHelp() {
	help := `📖 <b>Доступные команды:</b>

/info - Получить подробную информацию о компьютере
/status - Краткий статус всех компьютеров  
/help - Показать эту справку

💡 <b>Как использовать:</b>
1. Отправьте /info
2. Выберите компьютер из списка
3. Получите полный отчет

Автоматические отчеты отправляются ежедневно в 08:00`

	p.sendMessage(help)
}

// handleCallback processes button presses
func (p *Poller) handleCallback(query *CallbackQuery) {
	computerID := query.Data
	
	log.Printf("Запрос информации о компьютере: %s", computerID)
	
	// Answer callback query first
	p.answerCallbackQuery(query.ID)
	
	// Check if this is our computer
	if computerID == p.cfg.ComputerID {
		// Send report
		report, err :=telegram.CreateReport(p.cfg.ComputerName)
		if err != nil {
			p.sendMessage(fmt.Sprintf("Ошибка создания отчета: %v", err))
			return
		}
		
		p.sendMessage(report)
		p.UpdateLastSeen()
	}
}

// createComputerKeyboard creates inline keyboard with computer buttons
func (p *Poller) createComputerKeyboard() InlineKeyboardMarkup {
	var buttons [][]InlineKeyboardButton
	var row []InlineKeyboardButton
	
	i := 0
	for _, comp := range p.computers {
		button := InlineKeyboardButton{
			Text:         comp.Name,
			CallbackData: comp.ID,
		}
		
		row = append(row, button)
		i++
		
		// 2 buttons per row
		if i%2 == 0 {
			buttons = append(buttons, row)
			row = []InlineKeyboardButton{}
		}
	}
	
	// Add remaining buttons
	if len(row) > 0 {
		buttons = append(buttons, row)
	}
	
	return InlineKeyboardMarkup{InlineKeyboard: buttons}
}

// sendMessage sends a text message
func (p *Poller) sendMessage(text string) error {
	return telegram.SendMessage(p.token, p.chatID, text)
}

// sendKeyboard sends a message with inline keyboard
func (p *Poller) sendKeyboard(text string, keyboard InlineKeyboardMarkup) error {
	url := fmt.Sprintf(telegramAPIURL+"/sendMessage", p.token)
	
	payload := map[string]interface{}{
		"chat_id":      p.chatID,
		"text":         text,
		"parse_mode":   "HTML",
		"reply_markup": keyboard,
	}
	
	jsonPayload, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	
	resp, err := http.Post(url, "application/json", bytes.NewBuffer(jsonPayload))
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	
	return nil
}

// answerCallbackQuery answers a callback query
func (p *Poller) answerCallbackQuery(queryID string) {
	url := fmt.Sprintf(telegramAPIURL+"/answerCallbackQuery", p.token)
	
	payload := map[string]string{
		"callback_query_id": queryID,
	}
	
	jsonPayload, _ := json.Marshal(payload)
	http.Post(url, "application/json", bytes.NewBuffer(jsonPayload))
}
