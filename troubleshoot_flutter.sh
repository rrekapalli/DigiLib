#!/bin/bash

# Flutter Linux Troubleshooting Script
# Fixes common issues with Flutter Linux native builds

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[FIX]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log "Flutter Linux Troubleshooting & Fix Script"
log "=========================================="

# Function to fix library dependencies
fix_dependencies() {
    log "Installing/updating all Flutter Linux dependencies..."
    
    # Core build tools
    sudo apt update
    sudo apt install -y \
        build-essential \
        clang \
        cmake \
        ninja-build \
        pkg-config \
        libgtk-3-dev \
        liblzma-dev \
        libstdc++-12-dev
    
    # Flutter-specific Linux dependencies
    sudo apt install -y \
        libkeybinder-3.0-dev \
        libayatana-appindicator3-dev \
        libsecret-1-dev \
        libsqlite3-dev \
        libglib2.0-dev \
        libdbus-1-dev
    
    # Additional GTK and system libraries
    sudo apt install -y \
        libgtk-3-dev \
        libblkid-dev \
        liblzma-dev \
        libgcrypt-dev \
        libgpg-error-dev \
        uuid-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        libx11-dev \
        libxcursor-dev \
        libxrandr-dev \
        libxi-dev \
        libxinerama-dev \
        libgl1-mesa-dev
    
    log "Dependencies installed successfully"
}

# Function to fix pubspec.yaml dependency conflicts
fix_pubspec_conflicts() {
    log "Checking for pubspec.yaml dependency conflicts..."
    
    local pubspec_file="/home/raja/code/digi-lib/digi_lib_app/pubspec.yaml"
    if [ -f "$pubspec_file" ]; then
        cd "/home/raja/code/digi-lib/digi_lib_app"
        
        # Check for outdated packages
        flutter pub outdated
        
        # Suggest updating compatible packages
        info "To fix version conflicts, you can:"
        info "1. Update compatible packages: flutter pub upgrade"
        info "2. Or manually update versions in pubspec.yaml"
        info "3. Or remove conflicting packages temporarily"
        
        # Ask if user wants to upgrade
        read -p "Do you want to upgrade packages automatically? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Upgrading packages..."
            flutter pub upgrade
            flutter pub get
        fi
    else
        warn "pubspec.yaml not found at expected location"
    fi
}

# Function to clean Flutter caches
clean_flutter_caches() {
    log "Cleaning Flutter caches and rebuilding..."
    
    cd "/home/raja/code/digi-lib/digi_lib_app" 2>/dev/null || {
        warn "Could not navigate to DigiLib app directory"
        return
    }
    
    # Clean Flutter
    flutter clean
    
    # Clear pub cache for the project
    rm -rf .dart_tool
    rm -rf build
    
    # Get dependencies fresh
    flutter pub get
    
    # Precache Linux artifacts
    flutter precache --linux
    
    log "Caches cleaned and rebuilt"
}

# Function to fix environment variables
fix_environment() {
    log "Checking and fixing environment variables..."
    
    # Ensure Flutter is in PATH
    if ! command -v flutter &> /dev/null; then
        error "Flutter not found in PATH"
        info "Please run: export PATH=\"\$HOME/flutter/bin:\$PATH\""
        return 1
    fi
    
    # Set Linux development environment
    export FLUTTER_LINUX_DESKTOP=1
    
    # Add to shell config if not present
    local config_file="$HOME/.bashrc"
    if ! grep -q "FLUTTER_LINUX_DESKTOP" "$config_file"; then
        echo "export FLUTTER_LINUX_DESKTOP=1" >> "$config_file"
        log "Added FLUTTER_LINUX_DESKTOP environment variable"
    fi
    
    log "Environment configured"
}

# Function to fix specific plugin issues
fix_plugin_issues() {
    log "Fixing common plugin issues..."
    
    local app_dir="/home/raja/code/digi-lib/digi_lib_app"
    if [ ! -d "$app_dir" ]; then
        warn "DigiLib app directory not found"
        return
    fi
    
    cd "$app_dir"
    
    # Check for problematic plugins
    local problematic_plugins=("hotkey_manager" "system_tray" "desktop_drop")
    
    for plugin in "${problematic_plugins[@]}"; do
        if grep -q "$plugin" pubspec.yaml; then
            warn "Found potentially problematic plugin: $plugin"
            info "Consider temporarily commenting out $plugin in pubspec.yaml if build fails"
        fi
    done
    
    # Regenerate plugin registrants
    flutter packages get
    
    log "Plugin issues checked"
}

# Function to test the fixes
test_fixes() {
    log "Testing the fixes..."
    
    cd "/home/raja/code/digi-lib/digi_lib_app" 2>/dev/null || {
        error "Could not navigate to DigiLib app directory"
        return 1
    }
    
    # Test flutter doctor
    log "Running flutter doctor..."
    flutter doctor
    
    # Test analysis
    log "Running flutter analyze..."
    flutter analyze --no-fatal-infos
    
    # Test build (without running)
    log "Testing flutter build..."
    if flutter build linux --debug --target lib/main.dart; then
        log "✓ Build test successful!"
        info "You can now try: flutter run -d linux"
    else
        error "✗ Build test failed"
        warn "Try running individual fix functions or check build logs"
    fi
}

# Main menu
main_menu() {
    info "Flutter Linux Troubleshooting Options:"
    info "1. Fix all dependencies"
    info "2. Fix pubspec.yaml conflicts"
    info "3. Clean Flutter caches"
    info "4. Fix environment variables"
    info "5. Fix plugin issues"
    info "6. Run all fixes"
    info "7. Test fixes"
    info "8. Exit"
    echo
    
    read -p "Choose an option (1-8): " choice
    
    case $choice in
        1) fix_dependencies ;;
        2) fix_pubspec_conflicts ;;
        3) clean_flutter_caches ;;
        4) fix_environment ;;
        5) fix_plugin_issues ;;
        6) 
            log "Running all fixes..."
            fix_dependencies
            fix_environment
            clean_flutter_caches
            fix_plugin_issues
            fix_pubspec_conflicts
            ;;
        7) test_fixes ;;
        8) log "Exiting..."; exit 0 ;;
        *) warn "Invalid option"; main_menu ;;
    esac
    
    echo
    read -p "Press Enter to return to menu or Ctrl+C to exit..."
    main_menu
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    error "Flutter not found!"
    error "Please run setup_flutter_direct.sh first"
    exit 1
fi

# Start main menu
main_menu
