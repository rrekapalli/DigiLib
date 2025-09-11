#!/bin/bash

# Flutter Linux Native Test Script
# Tests the direct Flutter installation with DigiLib app

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[TEST]${NC} $1"
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

log "Flutter Linux Native Build Test"
log "==============================="

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    error "Flutter not found in PATH"
    error "Please run the setup script first or restart your terminal"
    exit 1
fi

# Display Flutter version
log "Flutter version:"
flutter --version

# Check flutter doctor
log "Running Flutter doctor..."
flutter doctor

# Navigate to DigiLib project
DIGI_LIB_PATH="/home/raja/code/digi-lib/digi_lib_app"
if [ ! -d "$DIGI_LIB_PATH" ]; then
    error "DigiLib project not found at $DIGI_LIB_PATH"
    exit 1
fi

cd "$DIGI_LIB_PATH"
log "Changed to DigiLib project directory: $(pwd)"

# Clean previous builds
log "Cleaning previous builds..."
flutter clean

# Get dependencies
log "Getting dependencies..."
flutter pub get

# Check for Linux desktop support
log "Checking Linux desktop support..."
flutter config --enable-linux-desktop

# List available devices
log "Available devices:"
flutter devices

# Check if Linux is available as target
if flutter devices | grep -q "Linux"; then
    log "✓ Linux desktop target available"
else
    error "✗ Linux desktop target not available"
    exit 1
fi

# Analyze the project
log "Analyzing project..."
flutter analyze --no-fatal-infos

# Try to build for Linux (without running)
log "Testing Linux build (dry run)..."
flutter build linux --debug --verbose 2>&1 | tee build_log.txt

# Check if build was successful
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    log "✓ Linux build test successful!"
    info "You can now run: flutter run -d linux"
else
    error "✗ Linux build test failed"
    warn "Check build_log.txt for details"
    
    # Check for common issues
    if grep -q "undefined reference" build_log.txt; then
        warn "Found undefined reference errors - library linking issues"
    fi
    
    if grep -q "libsecret" build_log.txt; then
        warn "libsecret issues detected, try: sudo apt install libsecret-1-dev"
    fi
    
    if grep -q "keybinder" build_log.txt; then
        warn "keybinder issues detected, try: sudo apt install libkeybinder-3.0-dev"
    fi
fi

# Suggest next steps
info ""
info "Test completed!"
info ""
info "If the build was successful, you can now run:"
info "  flutter run -d linux"
info ""
info "For web testing (always works):"
info "  flutter run -d chrome"
info ""
info "For debugging build issues:"
info "  cat build_log.txt"
