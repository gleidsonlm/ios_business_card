#!/bin/bash
# scripts/update-export-options-automatic.sh
# Update export options to work with automatic signing

set -e

readonly EXPORT_OPTIONS_PATH="scripts/ExportOptions-Automatic.plist"

echo "=== Creating Automatic Signing Export Options ==="
echo "Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo ""

# Create export options optimized for automatic signing
mkdir -p "$(dirname "$EXPORT_OPTIONS_PATH")"

cat > "$EXPORT_OPTIONS_PATH" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Distribution Method: App Store for TestFlight -->
    <key>method</key>
    <string>app-store</string>
    
    <!-- Signing Style: Automatic (Xcode manages everything) -->
    <key>signingStyle</key>
    <string>automatic</string>
    
    <!-- Let Xcode determine team automatically -->
    <!-- No manual teamID specification needed -->
    
    <!-- Upload symbols for crash reporting -->
    <key>uploadSymbols</key>
    <true/>
    
    <!-- Modern iOS doesn't require bitcode -->
    <key>uploadBitcode</key>
    <false/>
    
    <!-- Enable compilation bitcode for app thinning -->
    <key>compileBitcode</key>
    <true/>
    
    <!-- Strip Swift symbols to reduce IPA size -->
    <key>stripSwiftSymbols</key>
    <true/>
    
    <!-- No specific device targeting -->
    <key>thinning</key>
    <string>&lt;none&gt;</string>
    
    <!-- Don't let export process modify version numbers -->
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
    
    <!-- Export destination -->
    <key>destination</key>
    <string>export</string>
    
    <!-- Allow Xcode to update provisioning as needed -->
    <key>iCloudContainerEnvironment</key>
    <string>Production</string>
    
</dict>
</plist>
EOF

echo "✅ Created automatic signing export options: $EXPORT_OPTIONS_PATH"
echo ""
echo "📋 Key changes for automatic signing:"
echo "   • signingStyle: automatic"
echo "   • Removed manual teamID specification"
echo "   • Removed manual provisioning profile configuration"
echo "   • Xcode will handle all certificate-profile relationships"
echo ""
echo "🔄 Next steps:"
echo "1. Update Xcode project to use automatic signing"
echo "2. Use this export options file for IPA creation"
echo "3. Test archive and export process"
echo ""
