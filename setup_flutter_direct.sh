#!/bin/bash

# Flutter Direct Installation Script
# This script removes snap Flutter and installs Flutter SDK directly
# to fix Linux native build library conflicts

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
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

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    error "Please run this script as a regular user (not root/sudo)"
    exit 1
fi

log "Starting Flutter Direct Installation Setup..."

# Step 1: Backup current Flutter configuration
log "Step 1: Backing up current Flutter configuration..."
if [ -d "$HOME/.flutter" ]; then
    cp -r "$HOME/.flutter" "$HOME/.flutter_snap_backup_$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    log "Flutter configuration backed up"
fi

# Backup pub cache
if [ -d "$HOME/.pub-cache" ]; then
    log "Pub cache directory exists, it will be preserved"
fi

# Step 2: Remove snap Flutter
log "Step 2: Removing snap Flutter..."
if snap list flutter &>/dev/null; then
    log "Removing Flutter snap package..."
    sudo snap remove flutter
    log "Flutter snap package removed successfully"
else
    warn "Flutter snap package not found, skipping removal"
fi

# Step 3: Remove snap Flutter from PATH if it exists
log "Step 3: Cleaning up PATH references..."
# Remove snap flutter paths from various shell configs
for config_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.bash_profile"; do
    if [ -f "$config_file" ]; then
        if grep -q "/snap/flutter" "$config_file"; then
            log "Removing snap flutter paths from $config_file"
            sed -i '/\/snap\/flutter/d' "$config_file"
        fi
    fi
done

# Step 4: Install prerequisites
log "Step 4: Installing prerequisites..."
sudo apt update
sudo apt install -y curl git unzip xz-utils zip libglu1-mesa wget

# Step 5: Download and install Flutter SDK directly
log "Step 5: Downloading Flutter SDK..."
FLUTTER_VERSION="3.35.2"  # Current stable version
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
FLUTTER_DIR="$HOME/flutter"

# Remove existing Flutter directory if it exists
if [ -d "$FLUTTER_DIR" ]; then
    warn "Existing Flutter directory found at $FLUTTER_DIR"
    read -p "Do you want to remove it and install fresh? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$FLUTTER_DIR"
        log "Removed existing Flutter directory"
    else
        error "Installation cancelled"
        exit 1
    fi
fi

# Download Flutter
log "Downloading Flutter SDK v${FLUTTER_VERSION}..."
cd "$HOME"
wget -O flutter_linux.tar.xz "$FLUTTER_URL"

if [ ! -f "flutter_linux.tar.xz" ]; then
    error "Failed to download Flutter SDK"
    exit 1
fi

# Extract Flutter
log "Extracting Flutter SDK..."
tar xf flutter_linux.tar.xz
rm flutter_linux.tar.xz

if [ ! -d "$FLUTTER_DIR" ]; then
    error "Flutter extraction failed"
    exit 1
fi

log "Flutter SDK extracted to $FLUTTER_DIR"

# Step 6: Update PATH
log "Step 6: Updating PATH..."
FLUTTER_PATH="export PATH=\"\$HOME/flutter/bin:\$PATH\""

# Add to .bashrc
if ! grep -q "flutter/bin" "$HOME/.bashrc"; then
    echo "" >> "$HOME/.bashrc"
    echo "# Flutter SDK" >> "$HOME/.bashrc"
    echo "$FLUTTER_PATH" >> "$HOME/.bashrc"
    log "Added Flutter to .bashrc"
fi

# Add to .profile for universal shell support
if ! grep -q "flutter/bin" "$HOME/.profile"; then
    echo "" >> "$HOME/.profile"
    echo "# Flutter SDK" >> "$HOME/.profile"
    echo "$FLUTTER_PATH" >> "$HOME/.profile"
    log "Added Flutter to .profile"
fi

# Step 7: Set up Flutter for current session
log "Step 7: Setting up Flutter for current session..."
export PATH="$HOME/flutter/bin:$PATH"

# Step 8: Verify installation and run flutter doctor
log "Step 8: Verifying Flutter installation..."
"$HOME/flutter/bin/flutter" --version
log "Running flutter doctor..."
"$HOME/flutter/bin/flutter" doctor

# Step 9: Pre-download necessary artifacts
log "Step 9: Pre-downloading Flutter artifacts..."
"$HOME/flutter/bin/flutter" precache --linux

# Step 10: Verify Linux desktop support
log "Step 10: Enabling and verifying Linux desktop support..."
"$HOME/flutter/bin/flutter" config --enable-linux-desktop
"$HOME/flutter/bin/flutter" doctor --verbose | grep -E "(Linux|Desktop)" || true

# Step 11: Install additional Linux development dependencies
log "Step 11: Installing additional Linux development dependencies..."
sudo apt install -y \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    libstdc++-12-dev

# Step 12: Install Flutter-specific Linux dependencies  
log "Step 12: Installing Flutter Linux plugin dependencies..."
sudo apt install -y \
    libkeybinder-3.0-dev \
    libayatana-appindicator3-dev \
    libsecret-1-dev \
    libsqlite3-dev

# Step 13: Test the installation with the DigiLib project
log "Step 13: Testing installation with DigiLib project..."
DIGI_LIB_PATH="/home/raja/code/digi-lib/digi_lib_app"

if [ -d "$DIGI_LIB_PATH" ]; then
    log "Testing Flutter with DigiLib project..."
    cd "$DIGI_LIB_PATH"
    
    # Clean previous builds
    "$HOME/flutter/bin/flutter" clean
    
    # Get dependencies
    "$HOME/flutter/bin/flutter" pub get
    
    # Check for any issues
    "$HOME/flutter/bin/flutter" analyze --no-fatal-infos
    
    log "DigiLib project setup completed"
else
    warn "DigiLib project not found at $DIGI_LIB_PATH"
fi

# Step 14: Create convenient aliases
log "Step 14: Creating convenient aliases..."
ALIAS_FILE="$HOME/.bash_aliases"
if [ ! -f "$ALIAS_FILE" ]; then
    touch "$ALIAS_FILE"
fi

if ! grep -q "alias flutter=" "$ALIAS_FILE"; then
    echo "# Flutter aliases" >> "$ALIAS_FILE"
    echo "alias flutter='$HOME/flutter/bin/flutter'" >> "$ALIAS_FILE"
    echo "alias dart='$HOME/flutter/bin/dart'" >> "$ALIAS_FILE"
    log "Flutter aliases created"
fi

# Step 15: Final verification
log "Step 15: Final verification..."
info "Flutter installation completed successfully!"
info ""
info "Next steps:"
info "1. Restart your terminal or run: source ~/.bashrc"
info "2. Verify installation: flutter --version"
info "3. Check Linux support: flutter doctor"
info "4. Test DigiLib app: cd $DIGI_LIB_PATH && flutter run -d linux"
info ""
info "Key differences from snap version:"
info "- Uses system libraries instead of bundled ones"
info "- Better compatibility with Linux development"
info "- No library version conflicts"
info "- Full access to Flutter SDK source"
info ""

# Display current Flutter info
info "Current Flutter installation:"
"$HOME/flutter/bin/flutter" --version | head -n 1

warn "Please restart your terminal or run 'source ~/.bashrc' before using Flutter"

log "Setup complete! 🚀"
