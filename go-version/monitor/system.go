package monitor

import (
	"fmt"
	"sort"

	"github.com/shirou/gopsutil/v3/cpu"
	"github.com/shirou/gopsutil/v3/disk"
	"github.com/shirou/gopsutil/v3/mem"
	"github.com/shirou/gopsutil/v3/process"
)

// CPUInfo contains CPU information
type CPUInfo struct {
	Count   int
	Percent float64
}

// MemoryInfo contains memory information
type MemoryInfo struct {
	Total       uint64
	Used        uint64
	Available   uint64
	Percent     float64
}

// DiskInfo contains disk information
type DiskInfo struct {
	Device      string
	Mountpoint  string
	FSType      string
	Total       uint64
	Used        uint64
	Free        uint64
	Percent     float64
}

// ProcessInfo contains process information
type ProcessInfo struct {
	PID         int32
	Name        string
	CPUPercent  float64
	MemoryMB    float64
	MemoryPercent float32
}

// GetCPUInfo retrieves CPU information
func GetCPUInfo() (*CPUInfo, error) {
	count, err := cpu.Counts(true)
	if err != nil {
		return nil, err
	}

	percent, err := cpu.Percent(0, false)
	if err != nil {
		return nil, err
	}

	cpuPercent := 0.0
	if len(percent) > 0 {
		cpuPercent = percent[0]
	}

	return &CPUInfo{
		Count:   count,
		Percent: cpuPercent,
	}, nil
}

// GetMemoryInfo retrieves memory information
func GetMemoryInfo() (*MemoryInfo, error) {
	v, err := mem.VirtualMemory()
	if err != nil {
		return nil, err
	}

	return &MemoryInfo{
		Total:     v.Total,
		Used:      v.Used,
		Available: v.Available,
		Percent:   v.UsedPercent,
	}, nil
}

// GetDiskInfo retrieves disk information for all partitions
func GetDiskInfo() ([]*DiskInfo, error) {
	partitions, err := disk.Partitions(false)
	if err != nil {
		return nil, err
	}

	var disks []*DiskInfo
	for _, partition := range partitions {
		usage, err := disk.Usage(partition.Mountpoint)
		if err != nil {
			// Skip partitions we can't access
			continue
		}

		disks = append(disks, &DiskInfo{
			Device:     partition.Device,
			Mountpoint: partition.Mountpoint,
			FSType:     partition.Fstype,
			Total:      usage.Total,
			Used:       usage.Used,
			Free:       usage.Free,
			Percent:    usage.UsedPercent,
		})
	}

	return disks, nil
}

// GetTopProcessesByCPU returns top N processes by CPU usage
func GetTopProcessesByCPU(n int) ([]*ProcessInfo, error) {
	processes, err := process.Processes()
	if err != nil {
		return nil, err
	}

	var procInfos []*ProcessInfo
	for _, p := range processes {
		name, err := p.Name()
		if err != nil {
			continue
		}

		cpuPercent, err := p.CPUPercent()
		if err != nil {
			cpuPercent = 0
		}

		memInfo, err := p.MemoryInfo()
		memoryMB := 0.0
		if err == nil && memInfo != nil {
			memoryMB = float64(memInfo.RSS) / 1024 / 1024
		}

		memPercent, err := p.MemoryPercent()
		if err != nil {
			memPercent = 0
		}

		procInfos = append(procInfos, &ProcessInfo{
			PID:           p.Pid,
			Name:          name,
			CPUPercent:    cpuPercent,
			MemoryMB:      memoryMB,
			MemoryPercent: memPercent,
		})
	}

	// Sort by CPU percent
	sort.Slice(procInfos, func(i, j int) bool {
		return procInfos[i].CPUPercent > procInfos[j].CPUPercent
	})

	if len(procInfos) > n {
		procInfos = procInfos[:n]
	}

	return procInfos, nil
}

// GetTopProcessesByMemory returns top N processes by memory usage
func GetTopProcessesByMemory(n int) ([]*ProcessInfo, error) {
	processes, err := process.Processes()
	if err != nil {
		return nil, err
	}

	var procInfos []*ProcessInfo
	for _, p := range processes {
		name, err := p.Name()
		if err != nil {
			continue
		}

		memPercent, err := p.MemoryPercent()
		if err != nil {
			continue
		}

		memInfo, err := p.MemoryInfo()
		memoryMB := 0.0
		if err == nil && memInfo != nil {
			memoryMB = float64(memInfo.RSS) / 1024 / 1024
		}

		cpuPercent, err := p.CPUPercent()
		if err != nil {
			cpuPercent = 0
		}

		procInfos = append(procInfos, &ProcessInfo{
			PID:           p.Pid,
			Name:          name,
			CPUPercent:    cpuPercent,
			MemoryMB:      memoryMB,
			MemoryPercent: memPercent,
		})
	}

	// Sort by memory percent
	sort.Slice(procInfos, func(i, j int) bool {
		return procInfos[i].MemoryPercent > procInfos[j].MemoryPercent
	})

	if len(procInfos) > n {
		procInfos = procInfos[:n]
	}

	return procInfos, nil
}

// FormatBytes formats bytes into human-readable string
func FormatBytes(bytes uint64) string {
	const unit = 1024
	if bytes < unit {
		return fmt.Sprintf("%.2f Б", float64(bytes))
	}

	div, exp := uint64(unit), 0
	for n := bytes / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}

	units := []string{"КБ", "МБ", "ГБ", "ТБ", "ПБ"}
	return fmt.Sprintf("%.2f %s", float64(bytes)/float64(div), units[exp])
}
