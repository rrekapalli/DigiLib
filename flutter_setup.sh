#!/bin/bash

# Flutter Setup Launcher
# Main entry point for Flutter direct installation and troubleshooting

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    Flutter Setup Toolkit                    ║${NC}"
echo -e "${CYAN}║              Fix Linux Native Build Issues                  ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${YELLOW}Problem:${NC} Flutter snap package causes library conflicts"
echo -e "${YELLOW}Solution:${NC} Remove snap Flutter and install directly"
echo

# Check current Flutter status
if command -v flutter &> /dev/null; then
    FLUTTER_PATH=$(which flutter)
    if [[ "$FLUTTER_PATH" == *"snap"* ]]; then
        echo -e "${RED}⚠️  Current Flutter: SNAP VERSION (problematic)${NC}"
        echo -e "   Location: $FLUTTER_PATH"
        echo -e "${YELLOW}   Recommendation: Run setup to fix${NC}"
    elif [[ "$FLUTTER_PATH" == *"flutter/bin"* ]]; then
        echo -e "${GREEN}✅ Current Flutter: DIRECT VERSION (good)${NC}"
        echo -e "   Location: $FLUTTER_PATH"
        FLUTTER_VERSION=$(flutter --version 2>/dev/null | head -n1 | cut -d' ' -f2 || echo "unknown")
        echo -e "   Version: $FLUTTER_VERSION"
    else
        echo -e "${YELLOW}⚠️  Current Flutter: UNKNOWN VERSION${NC}"
        echo -e "   Location: $FLUTTER_PATH"
    fi
else
    echo -e "${RED}❌ Flutter not found in PATH${NC}"
fi

echo
echo -e "${BLUE}Available Actions:${NC}"
echo
echo -e "${GREEN}1.${NC} 🚀 ${YELLOW}Setup Flutter Direct${NC} - Remove snap and install Flutter directly"
echo -e "${GREEN}2.${NC} 🧪 ${YELLOW}Test Flutter Linux${NC} - Test current installation and Linux support"
echo -e "${GREEN}3.${NC} 🔧 ${YELLOW}Troubleshoot Issues${NC} - Interactive problem-solving menu"
echo -e "${GREEN}4.${NC} 📖 ${YELLOW}View Documentation${NC} - Show setup instructions and README"
echo -e "${GREEN}5.${NC} ▶️  ${YELLOW}Run DigiLib App${NC} - Quick launch options"
echo -e "${GREEN}6.${NC} ❌ ${YELLOW}Exit${NC}"
echo

read -p "Choose an option (1-6): " choice

case $choice in
    1)
        echo -e "${BLUE}Starting Flutter Direct Setup...${NC}"
        if [ -f "./setup_flutter_direct.sh" ]; then
            ./setup_flutter_direct.sh
        else
            echo -e "${RED}Error: setup_flutter_direct.sh not found${NC}"
        fi
        ;;
    2)
        echo -e "${BLUE}Testing Flutter Linux Support...${NC}"
        if [ -f "./test_flutter_linux.sh" ]; then
            ./test_flutter_linux.sh
        else
            echo -e "${RED}Error: test_flutter_linux.sh not found${NC}"
        fi
        ;;
    3)
        echo -e "${BLUE}Opening Troubleshooting Menu...${NC}"
        if [ -f "./troubleshoot_flutter.sh" ]; then
            ./troubleshoot_flutter.sh
        else
            echo -e "${RED}Error: troubleshoot_flutter.sh not found${NC}"
        fi
        ;;
    4)
        echo -e "${BLUE}Viewing Documentation...${NC}"
        if [ -f "./FLUTTER_SETUP_README.md" ]; then
            less ./FLUTTER_SETUP_README.md
        else
            echo -e "${RED}Error: FLUTTER_SETUP_README.md not found${NC}"
        fi
        ;;
    5)
        echo -e "${BLUE}DigiLib App Launch Options:${NC}"
        echo
        echo -e "${GREEN}a.${NC} Run on Linux Desktop (native)"
        echo -e "${GREEN}b.${NC} Run on Web (Chrome)"
        echo
        read -p "Choose launch option (a/b): " launch_choice
        
        APP_DIR="/home/raja/code/digi-lib/digi_lib_app"
        if [ -d "$APP_DIR" ]; then
            cd "$APP_DIR"
            case $launch_choice in
                a|A)
                    echo -e "${BLUE}Launching on Linux Desktop...${NC}"
                    flutter run -d linux
                    ;;
                b|B)
                    echo -e "${BLUE}Launching on Web (Chrome)...${NC}"
                    flutter run -d chrome
                    ;;
                *)
                    echo -e "${RED}Invalid option${NC}"
                    ;;
            esac
        else
            echo -e "${RED}Error: DigiLib app directory not found at $APP_DIR${NC}"
        fi
        ;;
    6)
        echo -e "${GREEN}Goodbye! 👋${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option. Please choose 1-6.${NC}"
        sleep 2
        exec "$0"  # Restart the script
        ;;
esac

echo
echo -e "${YELLOW}Press any key to return to main menu...${NC}"
read -n 1 -s
exec "$0"  # Restart the script
