package monitor

import (
	"net"
	"net/http"
	"io"
	"time"
)

// IPInfo contains network information
type IPInfo struct {
	Hostname   string
	LocalIP    string
	ExternalIP string
}

// GetIPInfo retrieves network information
func GetIPInfo() (*IPInfo, error) {
	info := &IPInfo{}

	// Get hostname
	hostname, err := net.LookupHost(GetHostname())
	if err == nil && len(hostname) > 0 {
		info.Hostname = GetHostname()
		info.LocalIP = hostname[0]
	} else {
		info.Hostname = "N/A"
		info.LocalIP = "N/A"
	}

	// Get external IP
	externalIP, err := GetExternalIP()
	if err != nil {
		info.ExternalIP = "N/A"
	} else {
		info.ExternalIP = externalIP
	}

	return info, nil
}

// GetHostname returns the system hostname
func GetHostname() string {
	hostname, err := net.LookupHost("localhost")
	if err != nil {
		return "N/A"
	}
	if len(hostname) > 0 {
		return hostname[0]
	}
	return "N/A"
}

// GetExternalIP retrieves the external IP address
func GetExternalIP() (string, error) {
	client := &http.Client{
		Timeout: 5 * time.Second,
	}

	resp, err := client.Get("https://api.ipify.org?format=text")
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	ip, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	return string(ip), nil
}
