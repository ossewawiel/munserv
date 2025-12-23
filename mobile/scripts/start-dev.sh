#!/bin/bash
# MunServ Mobile Development Startup Script
# Connects to Windows Android emulator from WSL2

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MunServ Mobile Dev Setup ===${NC}"

# Get Windows host IP (WSL2 vEthernet adapter)
WIN_HOST=$(ip route show | grep -i default | awk '{ print $3 }')
WIN_ADB="/mnt/c/Users/User-PC/AppData/Local/Android/Sdk/platform-tools/adb.exe"

# Check if Windows emulator is running
echo -e "${YELLOW}Checking for Windows emulator...${NC}"
if ! $WIN_ADB devices 2>/dev/null | grep -q "emulator\|device"; then
    echo -e "${RED}No emulator detected on Windows!${NC}"
    echo ""
    echo "Please start an emulator on Windows first:"
    echo "  1. Open Android Studio -> Device Manager -> Start emulator"
    echo "  2. Or run: %LOCALAPPDATA%\\Android\\Sdk\\emulator\\emulator -avd <avd_name>"
    echo ""
    exit 1
fi

# Enable tcpip mode on Windows emulator
echo -e "${YELLOW}Enabling TCP/IP mode on emulator...${NC}"
$WIN_ADB tcpip 5555
sleep 2

# Connect from WSL
echo -e "${YELLOW}Connecting from WSL2 to $WIN_HOST:5555...${NC}"
adb kill-server 2>/dev/null || true
adb start-server
adb connect $WIN_HOST:5555

# Verify connection
echo ""
echo -e "${GREEN}Connected devices:${NC}"
adb devices

echo ""
echo -e "${GREEN}Flutter devices:${NC}"
flutter devices

echo ""
echo -e "${GREEN}=== Ready! ===${NC}"
echo "Run 'flutter run' to start the app"
