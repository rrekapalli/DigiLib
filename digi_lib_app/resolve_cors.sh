#!/bin/bash

# CORS Development Helper Script
# This script provides different methods to resolve CORS issues during development

echo "🔧 DigiLib CORS Resolution Helper"
echo "================================="
echo ""

echo "1. Run Flutter with specific web port:"
echo "   flutter run -d chrome --web-port 9091 --web-hostname localhost"
echo ""

echo "2. Launch Chrome with disabled web security (DEVELOPMENT ONLY):"
echo "   Linux:"
echo "     google-chrome --disable-web-security --disable-features=VizDisplayCompositor --user-data-dir=/tmp/chrome_dev"
echo ""
echo "   macOS:"
echo "     open -n -a /Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome --args --user-data-dir=/tmp/chrome_dev --disable-web-security"
echo ""
echo "   Windows:"
echo "     chrome.exe --disable-web-security --disable-features=VizDisplayCompositor --user-data-dir=c:\\temp\\chrome_dev"
echo ""

echo "3. Use Flutter web with proxy:"
echo "   flutter run -d web-server --web-port 9091 --web-hostname 0.0.0.0"
echo ""

echo "4. Configure your API server to allow CORS:"
echo "   Add these headers to your API responses:"
echo "   - Access-Control-Allow-Origin: *"
echo "   - Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS"
echo "   - Access-Control-Allow-Headers: Origin, Content-Type, Accept, Authorization"
echo ""

echo "⚠️  WARNING: Never use --disable-web-security in production!"
echo "   It's only for development purposes."