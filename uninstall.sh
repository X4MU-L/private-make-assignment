#!/bin/bash

# Get project name from argument or use default
PROJECT_NAME=${1:-"system-monitor"}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

if [ -f "Makefile" ]; then
    # No need for sudo here since we're already root
    make uninstall PROJECT_NAME="$PROJECT_NAME"
    echo "Uninstallation of $PROJECT_NAME complete"
else
    echo "Makefile not found, installation failed"
    exit 1
fi
