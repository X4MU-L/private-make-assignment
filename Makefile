# Configuration
PREFIX ?= $(HOME)/mylocal
PROJECT_NAME ?= system-monitor
INSTALL_DIR = $(PREFIX)/lib/$(PROJECT_NAME)
LOG_DIR = $(PREFIX)/log/$(PROJECT_NAME)
LOCAL_DIR = $(HOME)/mylocal
.PHONY: all install uninstall clean

all: check-deps

check-deps:
	@echo "Checking dependencies..."
	@for cmd in df free top curl logger systemd-cat awk sort head nproc lscpu; do \
		which $$cmd >/dev/null 2>&1 || { echo "$$cmd is required but not installed."; exit 1; } \
	done

install: check-deps
	@echo "Installing $(PROJECT_NAME)..."
# Create directories
	sudo mkdir -p $(INSTALL_DIR)
	sudo mkdir -p $(LOG_DIR)
	sudo mkdir -p $(LOCAL_DIR)
	sudo mkdir -p $(LOCAL_DIR)/journald.conf.d
	
# sudo mkdir -p /etc/profile.d
	sudo mkdir -p $(LOCAL_DIR)/profile.d
#  sudo mkdir -p /etc/logrotate.d
	sudo mkdir -p $(LOCAL_DIR)/logrotate.d

    # Copy and process source files
	sudo cp -r src/* $(INSTALL_DIR)/
    
    # Process and install systemd templates
	sed "s/\$${PROJECT_NAME}/$(PROJECT_NAME)/g" src/systemd/service.template \
        | sudo tee "$(LOCAL_DIR)/$(PROJECT_NAME).service" > /dev/null
	sed "s/\$${PROJECT_NAME}/$(PROJECT_NAME)/g" src/systemd/timer.template \
        | sudo tee "$(LOCAL_DIR)/$(PROJECT_NAME).timer" > /dev/null
	sed "s/\$${PROJECT_NAME}/$(PROJECT_NAME)/g" src/systemd/journal.conf.template \
        | sudo tee "$(LOCAL_DIR)/journald.conf.d/$(PROJECT_NAME)-journal.conf" > /dev/null

    # Install wrapper script
	sudo tee "$(LOCAL_DIR)/bin/$(PROJECT_NAME)" > /dev/null << EOF
	#!/bin/bash
	$(INSTALL_DIR)/main.sh "\$$@"
	EOF

    # Set permissions
	sudo chmod +x "$(LOCAL_DIR)/bin/$(PROJECT_NAME)"
	sudo chmod +x "$(INSTALL_DIR)/main.sh"
	sudo chmod 755 $(LOG_DIR)

    # Install environment file
	sudo tee "$(LOCAL_DIR)/profile.d/$(PROJECT_NAME)-env.sh" > /dev/null << EOF
	export ${PROJECT_NAME}_LOG_FILE="$(LOG_DIR)/$(PROJECT_NAME).log"
	export ${PROJECT_NAME}_ERROR_LOG="$(LOG_DIR)/$(PROJECT_NAME).error.log"
	EOF

    # Setup logrotate
	sudo tee "$(LOCAL_DIR)/logrotate.d/$(PROJECT_NAME)" > /dev/null << EOF
	$(LOG_DIR)/*.log {
		daily
		rotate 7
		compress
		delaycompress
		missingok
		notifempty
		create 0640 root root
		postrotate
			/usr/bin/systemctl kill -s HUP $(PROJECT_NAME).service
		endscript
	}
	EOF
	
# Enable and start service
# sudo systemctl daemon-reload
# sudo systemctl enable $(PROJECT_NAME).timer
# sudo systemctl start $(PROJECT_NAME).timer

	@echo "Installation complete!"
	@echo "Service name: $(PROJECT_NAME)"
	@echo "Timer status: sudo systemctl status $(PROJECT_NAME).timer"
	@echo "View logs: sudo journalctl -u $(PROJECT_NAME).service"
	@echo "Log files are in: $(LOG_DIR)"

uninstall:
	@echo "Uninstalling $(PROJECT_NAME)..."
	sudo systemctl stop $(PROJECT_NAME).timer || true
	sudo systemctl disable $(PROJECT_NAME).timer || true
	sudo rm -f /etc/systemd/system/$(PROJECT_NAME).service
	sudo rm -f /etc/systemd/system/$(PROJECT_NAME).timer
	sudo rm -f /etc/systemd/journald.conf.d/$(PROJECT_NAME)-journal.conf
	sudo rm -f /etc/logrotate.d/$(PROJECT_NAME)
	sudo rm -f /etc/profile.d/$(PROJECT_NAME)-env.sh
	sudo rm -f /usr/local/bin/$(PROJECT_NAME)
	sudo rm -rf $(INSTALL_DIR)
	sudo rm -rf $(LOG_DIR)
	sudo systemctl daemon-reload
	@echo "Uninstallation complete!"

clean:
	@echo "Cleaning build artifacts..."
	rm -f *~