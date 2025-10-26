#!/bin/bash
# Setup script for LogLineOS Xcode project
# This script helps create the Xcode project structure

set -e

echo "🚀 LogLineOS Setup Script"
echo "========================="
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode is not installed or xcodebuild is not in PATH"
    echo "Please install Xcode from the App Store"
    exit 1
fi

echo "✅ Xcode found: $(xcodebuild -version | head -1)"
echo ""

# Check current directory
if [ ! -d "LogLineOS" ]; then
    echo "❌ Error: LogLineOS directory not found"
    echo "Please run this script from the repository root"
    exit 1
fi

echo "📁 Source files found:"
find LogLineOS -name "*.swift" | wc -l | xargs echo "   Swift files:"
echo ""

echo "📝 Next steps:"
echo "1. Open Xcode"
echo "2. Create new project: File → New → Project"
echo "3. Choose: iOS → App"
echo "4. Settings:"
echo "   - Product Name: LogLineOS"
echo "   - Organization: com.yourorg (or your choice)"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo "   - Minimum iOS: 17.0"
echo "5. Save the project in a temporary location"
echo "6. Delete the default ContentView.swift and other template files"
echo "7. Drag the LogLineOS folder from this repository into Xcode"
echo "8. Build and run!"
echo ""
echo "For detailed instructions, see IMPLEMENTATION.md"
echo ""

# Optionally, we can try to use swift package generate-xcodeproj if available
if command -v swift &> /dev/null; then
    echo "💡 Tip: You can also open this project in Xcode directly:"
    echo "   xed ."
    echo ""
    echo "   Or use Swift Package Manager for development:"
    echo "   swift build"
    echo "   swift test"
fi

echo "✨ Setup guide complete!"
