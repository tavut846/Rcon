package conf

import (
	"fmt"
	"log"
	"path/filepath"
	"strings"
	"time"

	"github.com/fsnotify/fsnotify"
)

func (p *Conf) Watch(filePath, xDnsPath string, reload func()) error {
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		return fmt.Errorf("new watcher error: %s", err)
	}
	go func() {
		// pre gates the debounce window; resetCh clears it after each reload
		// so subsequent edits are immediately accepted.
		var pre time.Time
		resetCh := make(chan struct{}, 1)
		defer watcher.Close()
		for {
			select {
			case e, ok := <-watcher.Events:
				if !ok {
					return
				}
				if e.Has(fsnotify.Chmod) {
					continue
				}
				// Coalesce bursts (e.g. multiple events from one save); a
				// single 3-second window is enough for filesystem settle.
				if pre.Add(3 * time.Second).After(time.Now()) {
					continue
				}
				pre = time.Now()
				eName := e.Name
				go func() {
					time.Sleep(2 * time.Second)
					switch filepath.Base(strings.TrimSuffix(eName, "~")) {
					case filepath.Base(xDnsPath):
						log.Println("DNS file changed, reloading...")
					default:
						log.Println("config file changed, reloading...")
					}
					*p = *New()
					if err := p.LoadFromPath(filePath); err != nil {
						log.Printf("reload config error: %s", err)
					} else {
						reload()
						log.Println("reload config success")
					}
					// Reset so the next edit is accepted immediately.
					resetCh <- struct{}{}
				}()
			case <-resetCh:
				pre = time.Time{}
			case err, ok := <-watcher.Errors:
				if !ok {
					return
				}
				if err != nil {
					log.Printf("File watcher error: %s", err)
				}
			}
		}
	}()
	err = watcher.Add(filePath)
	if err != nil {
		return fmt.Errorf("watch file error: %s", err)
	}
	if xDnsPath != "" {
		err = watcher.Add(xDnsPath)
		if err != nil {
			return fmt.Errorf("watch dns file error: %s", err)
		}
	}
	return nil
}
