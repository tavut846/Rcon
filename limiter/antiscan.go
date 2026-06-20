package limiter

import (
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/tavut846/Rcon/conf"
)

type ScanDetector struct {
	mu           sync.RWMutex
	destinations map[string]map[string]time.Time // clientIP -> destination -> lastAccessTime
	bannedIPs    map[string]time.Time           // clientIP -> banExpirationTime
	threshold    int
	window       time.Duration
	banDuration  time.Duration
	logPath      string
}

func NewScanDetector(cfg *conf.AntiScanConfig) *ScanDetector {
	threshold := 30
	window := 5 * time.Second
	banDuration := 3600 * time.Second
	logPath := "banned.log"

	if cfg != nil {
		if cfg.Threshold > 0 {
			threshold = cfg.Threshold
		}
		if cfg.Window > 0 {
			window = time.Duration(cfg.Window) * time.Second
		}
		if cfg.BanDuration >= 0 {
			banDuration = time.Duration(cfg.BanDuration) * time.Second
		}
		if cfg.LogPath != "" {
			logPath = cfg.LogPath
		}
	}

	return &ScanDetector{
		destinations: make(map[string]map[string]time.Time),
		bannedIPs:    make(map[string]time.Time),
		threshold:    threshold,
		window:       window,
		banDuration:  banDuration,
		logPath:      logPath,
	}
}

func (s *ScanDetector) RecordAndCheck(clientIP, destination string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := time.Now()

	// Clean up old destinations for this client
	dests, ok := s.destinations[clientIP]
	if !ok {
		dests = make(map[string]time.Time)
		s.destinations[clientIP] = dests
	}

	// Add/update destination
	dests[destination] = now

	// Count unique destinations in the window
	uniqueCount := 0
	for dest, t := range dests {
		if now.Sub(t) <= s.window {
			uniqueCount++
		} else {
			delete(dests, dest) // clean up expired entries
		}
	}

	if uniqueCount >= s.threshold {
		return true
	}
	return false
}

func (s *ScanDetector) Ban(clientIP string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := time.Now()
	var expireTime time.Time
	durationStr := "permanent"
	if s.banDuration > 0 {
		expireTime = now.Add(s.banDuration)
		durationStr = fmt.Sprintf("for %v", s.banDuration)
	} else {
		// zero/negative means permanent ban during runtime
		expireTime = now.Add(100 * 365 * 24 * time.Hour) // 100 years
	}

	s.bannedIPs[clientIP] = expireTime
	s.writeToBannedLog(clientIP, fmt.Sprintf("scanning detected (reached threshold of %d unique destinations), banned %s", s.threshold, durationStr))
}

func (s *ScanDetector) IsBanned(clientIP string) bool {
	s.mu.RLock()
	expireTime, exists := s.bannedIPs[clientIP]
	s.mu.RUnlock()

	if !exists {
		return false
	}

	if time.Now().After(expireTime) {
		s.mu.Lock()
		delete(s.bannedIPs, clientIP)
		s.mu.Unlock()
		return false
	}

	return true
}

func (s *ScanDetector) writeToBannedLog(clientIP, reason string) {
	// Ensure directory exists
	dir := filepath.Dir(s.logPath)
	if dir != "." && dir != "" {
		_ = os.MkdirAll(dir, 0755)
	}

	f, err := os.OpenFile(s.logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return
	}
	defer f.Close()

	logLine := fmt.Sprintf("[%s] Banned IP: %s | Reason: %s\n", time.Now().Format("2006-01-02 15:04:05"), clientIP, reason)
	_, _ = f.WriteString(logLine)
}
