# Configuration
PROJECT_NAME ?= system-monitor
LOCAL_DIR = /usr/local
INSTALL_DIR = $(LOCAL_DIR)/lib/$(PROJECT_NAME)
LOG_DIR = /var/log/$(PROJECT_NAME)

.PHONY: all install uninstall clean

all: check-deps check-root
check-root:
	@echo "Checking root privileges... $$(id -u)"
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "This script must be run as root. Please use sudo."; \
		exit 1; \
    fi

check-deps:
	@echo "Checking dependencies..."
	@for cmd in df free top curl logger systemd-cat awk sort head nproc lscpu; do \
		which $$cmd >/dev/null 2>&1 || { echo "$$cmd is required but not installed."; exit 1; } \
	done

install: check-root check-deps
	@echo "Installing $(PROJECT_NAME)..."
	# Create directories
	@mkdir -p $(INSTALL_DIR)
	@mkdir -p /etc/systemd/system
	@mkdir -p /etc/systemd/journald.conf.d
	@mkdir -p /etc/profile.d
	@mkdir -p $(LOCAL_DIR)/bin
	@mkdir -p $(LOG_DIR)

	# Copy and process source files
	@cp -r src/!(config) $(INSTALL_DIR)/
	
	# Process and install systemd templates
	@sed "s/\$${PROJECT_NAME}/$(PROJECT_NAME)/g" src/config/service.template \
        | tee "/etc/systemd/system/$(PROJECT_NAME).service" > /dev/null
	@sed "s/\$${PROJECT_NAME}/$(PROJECT_NAME)/g" src/config/timer.template \
        | tee "/etc/systemd/system/$(PROJECT_NAME).timer" > /dev/null
	@sed "s/\$${PROJECT_NAME}/$(PROJECT_NAME)/g" src/config/journal.conf.template \
        | tee "/etc/systemd/journald.conf.d/$(PROJECT_NAME)-journal.conf" > /dev/null
	
	# update wrapper script
	@sed "s|\$${INSTALL_DIR}|$(INSTALL_DIR)|g" src/config/wrapper.template \
		| tee "$(LOCAL_DIR)/bin/$(PROJECT_NAME)" > /dev/null
    
	# Set permissions
	@chmod +x "$(LOCAL_DIR)/bin/$(PROJECT_NAME)"
	@chmod +x "$(INSTALL_DIR)/main.sh"
	@chmod 755 $(LOG_DIR)

	# Install environment file
	# create upper and maintain shell session with ;
	@project_upper=$(shell echo $(PROJECT_NAME) | tr '-' '_' | tr '[:lower:]' '[:upper:]'); \
	echo "export $${project_upper}_LOG_FILE=$(LOG_DIR)/$(PROJECT_NAME).log" \
		| tee "/etc/profile.d/$(PROJECT_NAME)-env.sh" > /dev/null; \
	echo "export $${project_upper}_ERROR_LOG=$(LOG_DIR)/$(PROJECT_NAME).error.log" \
		| tee -a "/etc/profile.d/$(PROJECT_NAME)-env.sh" > /dev/null
	@chmod 644 "/etc/profile.d/$(PROJECT_NAME)-env.sh"
	
	# Setup logrotate
	@sed "s|\$${PROJECT_NAME}|$(PROJECT_NAME)|g" src/config/logrotate.template \
		| tee "/etc/logrotate.d/$(PROJECT_NAME)" > /dev/null
	
	# Enable and start service
	@systemctl daemon-reload
	@systemctl enable $(PROJECT_NAME).timer  > /dev/null
	@sudo systemctl start $(PROJECT_NAME).timer

	@echo "Installation complete!"
	@echo "Service name: $(PROJECT_NAME)"
	@echo "Timer status: sudo systemctl status $(PROJECT_NAME).timer"
	@echo "View logs: sudo journalctl -u $(PROJECT_NAME).service"
	@echo "Log files are in: $(LOG_DIR)"

uninstall: check-root
	@echo "Uninstalling $(PROJECT_NAME)..."
	@systemctl stop $(PROJECT_NAME).timer || true
	@systemctl disable $(PROJECT_NAME).timer || true
	@rm -f /etc/systemd/system/$(PROJECT_NAME).service
	@rm -f /etc/systemd/system/$(PROJECT_NAME).timer
	@rm -f /etc/systemd/journald.conf.d/$(PROJECT_NAME)-journal.conf
	@rm -f /etc/logrotate.d/$(PROJECT_NAME)
	@rm -f /etc/profile.d/$(PROJECT_NAME)-env.sh
	@rm -f /usr/local/bin/$(PROJECT_NAME)
	@rm -rf $(INSTALL_DIR)
	@rm -rf $(LOG_DIR)
	@systemctl daemon-reload
	@echo "Uninstallation complete!"

clean:
	@echo "Cleaning build artifacts..."
	rm -f *~