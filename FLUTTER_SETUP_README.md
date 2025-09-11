# Flutter Direct Installation - Fix Linux Native Build

This directory contains scripts to fix the Flutter Linux native build issues by removing snap Flutter and installing Flutter SDK directly.

## Problem Summary

The Linux native build was failing due to library version conflicts between:
- Flutter's snap package (uses older bundled libraries)  
- System-installed libraries (newer versions)
- Native plugins compiled against newer system libraries

**Error symptoms:**
```
clang: error: linker command failed with exit code 1
undefined reference to 'g_task_set_static_name'
undefined reference to 'g_time_zone_new_identifier'
```

## Solution Scripts

### 1. `setup_flutter_direct.sh` - Main Installation Script

**What it does:**
- Removes Flutter snap package
- Downloads and installs Flutter SDK directly from Google
- Sets up proper PATH configuration
- Installs all required Linux development dependencies
- Configures Flutter for Linux desktop development
- Tests the installation

**Usage:**
```bash
./setup_flutter_direct.sh
```

**Key benefits:**
- Uses system libraries instead of bundled ones
- No version conflicts
- Full Flutter SDK access
- Better Linux compatibility

### 2. `test_flutter_linux.sh` - Test Installation

**What it does:**
- Verifies Flutter installation
- Tests Linux desktop support
- Attempts a build without running
- Provides diagnostic information

**Usage:**
```bash
./test_flutter_linux.sh
```

### 3. `troubleshoot_flutter.sh` - Interactive Troubleshooting

**What it does:**
- Fixes common dependency issues
- Cleans Flutter caches
- Resolves pubspec.yaml conflicts
- Fixes environment variables
- Interactive menu for targeted fixes

**Usage:**
```bash
./troubleshoot_flutter.sh
```

## Step-by-Step Installation

### Step 1: Run the main setup script
```bash
cd /home/raja/code/digi-lib
./setup_flutter_direct.sh
```

**This will:**
1. Backup current Flutter configuration
2. Remove snap Flutter
3. Install Flutter SDK directly to `~/flutter`
4. Update PATH in `.bashrc` and `.profile`
5. Install all Linux dependencies
6. Test with your DigiLib project

### Step 2: Restart terminal or reload environment
```bash
source ~/.bashrc
# OR restart your terminal
```

### Step 3: Verify installation
```bash
flutter --version
flutter doctor
```

### Step 4: Test Linux build
```bash
cd /home/raja/code/digi-lib/digi_lib_app
flutter run -d linux
```

### Step 5: If issues persist, run troubleshooting
```bash
cd /home/raja/code/digi-lib
./troubleshoot_flutter.sh
```

## What Changes

**Before (Snap Flutter):**
- Flutter installed via: `/snap/flutter/`
- Uses bundled libraries: `/snap/flutter/current/usr/lib/`
- Limited access to SDK
- Library version conflicts

**After (Direct Flutter):**
- Flutter installed to: `~/flutter/`
- Uses system libraries: `/usr/lib/x86_64-linux-gnu/`
- Full SDK access
- No version conflicts

## Dependencies Installed

The script installs these critical dependencies:
```bash
# Build tools
clang cmake ninja-build pkg-config

# GTK development
libgtk-3-dev liblzma-dev libstdc++-12-dev

# Flutter Linux plugins
libkeybinder-3.0-dev          # For hotkey_manager
libayatana-appindicator3-dev   # For system_tray  
libsecret-1-dev               # For flutter_secure_storage
libsqlite3-dev                # For sqflite

# Additional system libraries
libglib2.0-dev libdbus-1-dev libblkid-dev
```

## Expected Results

After installation, you should be able to:

1. **Run Linux native app:**
   ```bash
   flutter run -d linux
   ```

2. **Build without errors:**
   ```bash
   flutter build linux
   ```

3. **See clean flutter doctor:**
   ```bash
   flutter doctor
   ```

## Fallback Options

If Linux native still has issues:

1. **Use web version (always works):**
   ```bash
   flutter run -d chrome
   ```

2. **Remove problematic plugins temporarily:**
   - Comment out `hotkey_manager`, `system_tray`, `desktop_drop` in `pubspec.yaml`
   - Run `flutter pub get`
   - Try building again

## Troubleshooting Common Issues

### Issue: "Flutter not found"
**Solution:** 
```bash
export PATH="$HOME/flutter/bin:$PATH"
source ~/.bashrc
```

### Issue: "Linux desktop not available"
**Solution:**
```bash
flutter config --enable-linux-desktop
flutter doctor
```

### Issue: "Dependencies conflict"
**Solution:**
```bash
./troubleshoot_flutter.sh
# Choose option 2 (Fix pubspec.yaml conflicts)
```

### Issue: "Build still fails"
**Solution:**
```bash
./troubleshoot_flutter.sh
# Choose option 6 (Run all fixes)
```

## File Locations

- **Flutter SDK:** `~/flutter/`
- **Flutter binary:** `~/flutter/bin/flutter`
- **Project location:** `/home/raja/code/digi-lib/digi_lib_app/`
- **Build output:** `/home/raja/code/digi-lib/digi_lib_app/build/linux/`

## Verification Commands

```bash
# Check Flutter version
flutter --version

# Check system status  
flutter doctor -v

# Check Linux support
flutter devices | grep Linux

# Check dependencies
ldd ~/flutter/bin/flutter

# Test build
flutter build linux --debug
```

This approach should resolve the library conflicts and enable successful Linux native builds for your DigiLib application! 🚀
