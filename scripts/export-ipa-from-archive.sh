#!/bin/bash
# scripts/export-ipa-from-archive.sh
# Converts Xcode archive to distribution-ready IPA

set -e

readonly SCRIPT_VERSION="1.0.0"
readonly PROJECT_ROOT="$(pwd)"
readonly ARCHIVE_PATH="$PROJECT_ROOT/xcarchive"
readonly OUTPUT_DIR="$PROJECT_ROOT/build"
readonly EXPORT_OPTIONS_PATH="$PROJECT_ROOT/scripts/ExportOptions.plist"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ️  INFO${NC}: $1"; }
log_success() { echo -e "${GREEN}✅ SUCCESS${NC}: $1"; }
log_warning() { echo -e "${YELLOW}⚠️  WARNING${NC}: $1"; }
log_error() { echo -e "${RED}❌ ERROR${NC}: $1" >&2; }
log_step() { echo -e "${PURPLE}🔄 STEP${NC}: $1"; }

main() {
    echo "=== IPA Export from Archive Script v$SCRIPT_VERSION ==="
    echo "Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "User: gleidsonlm"
    echo "Project: Business Card App"
    echo ""

    validate_prerequisites
    create_export_options
    export_archive_to_ipa
    validate_ipa_output
    prepare_pipeline_artifacts
    display_summary
}

validate_prerequisites() {
    log_step "Validating prerequisites"
    
    # Check if archive exists
    if [ ! -d "$ARCHIVE_PATH" ]; then
        log_error "Archive not found at: $ARCHIVE_PATH"
        log_info "Expected structure: xcarchive/Products/Applications/businesscard.app"
        exit 1
    fi
    log_success "Archive found: $ARCHIVE_PATH"
    
    # Check if app bundle exists
    if [ ! -d "$ARCHIVE_PATH/Products/Applications/businesscard.app" ]; then
        log_error "App bundle not found in archive"
        exit 1
    fi
    log_success "App bundle found: businesscard.app"
    
    # Check if xcodebuild is available
    if ! command -v xcodebuild &> /dev/null; then
        log_error "xcodebuild not found. This script must run on macOS with Xcode installed."
        exit 1
    fi
    log_success "xcodebuild available: $(xcodebuild -version | head -1)"
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    log_success "Output directory ready: $OUTPUT_DIR"
}

create_export_options() {
    log_step "Creating export options configuration"
    
    mkdir -p "$(dirname "$EXPORT_OPTIONS_PATH")"
    
    cat > "$EXPORT_OPTIONS_PATH" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Export Method: app-store-connect for TestFlight/App Store distribution -->
    <key>method</key>
    <string>app-store-connect</string>
    
    <!-- Team ID: Your Apple Developer Team ID -->
    <key>teamID</key>
    <string>"$AppleDeveloperTeamID"</string>
    
    <!-- Upload Symbols: Include for crash reporting -->
    <key>uploadSymbols</key>
    <true/>
    
    <!-- Upload Bitcode: Include if app uses bitcode -->
    <key>uploadBitcode</key>
    <false/>
    
    <!-- Compilation Bitcode: For app thinning -->
    <key>compileBitcode</key>
    <true/>
    
    <!-- Strip Swift Symbols: Reduce IPA size -->
    <key>stripSwiftSymbols</key>
    <true/>
    
    <!-- Thinning: Create optimized variants -->
    <key>thinning</key>
    <string>&lt;none&gt;</string>
    
    <!-- Provisioning Profiles: Let Xcode manage automatically -->
    <key>provisioningProfiles</key>
    <dict>
        <key>com.gleidsonlm.businesscard</key>
        <string>match AppStore com.gleidsonlm.businesscard</string>
    </dict>
    
    <!-- Signing Certificate: Distribution certificate -->
    <key>signingCertificate</key>
    <string>iPhone Distribution</string>
    
    <!-- Signing Style: Automatic or Manual -->
    <key>signingStyle</key>
    <string>automatic</string>
    
    <!-- Export Compliance: Already configured in Info.plist -->
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
</dict>
</plist>
EOF

    log_success "Export options created: $EXPORT_OPTIONS_PATH"
    log_warning "Export environment variable "$AppleDeveloperTeamID" with your actual Apple Developer Team ID"
}

export_archive_to_ipa() {
    log_step "Exporting archive to IPA"
    
    local export_path="$OUTPUT_DIR/BusinessCard-Export"
    
    log_info "Starting xcodebuild -exportArchive..."
    log_info "Archive: $ARCHIVE_PATH"
    log_info "Export Path: $export_path"
    log_info "Options: $EXPORT_OPTIONS_PATH"
    
    # Export archive to IPA
    if xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$export_path" \
        -exportOptionsPlist "$EXPORT_OPTIONS_PATH" \
        -verbose; then
        
        log_success "Archive export completed"
    else
        log_error "Archive export failed"
        log_info "Common solutions:"
        log_info "1. Update Team ID in ExportOptions.plist"
        log_info "2. Verify provisioning profile matches bundle ID"
        log_info "3. Check signing certificate validity"
        exit 1
    fi
    
    # Find the generated IPA
    local ipa_file=$(find "$export_path" -name "*.ipa" -type f | head -1)
    if [ -n "$ipa_file" ]; then
        # Copy IPA to standard location for pipeline
        cp "$ipa_file" "$OUTPUT_DIR/BusinessCard.ipa"
        log_success "IPA copied to: $OUTPUT_DIR/BusinessCard.ipa"
    else
        log_error "No IPA file found in export output"
        exit 1
    fi
}

validate_ipa_output() {
    log_step "Validating IPA output"
    
    local ipa_path="$OUTPUT_DIR/BusinessCard.ipa"
    
    if [ ! -f "$ipa_path" ]; then
        log_error "IPA file not found: $ipa_path"
        exit 1
    fi
    
    # Check IPA size
    local ipa_size=$(du -h "$ipa_path" | cut -f1)
    log_success "IPA file created: $ipa_size"
    
    # Validate IPA structure (basic check)
    if unzip -t "$ipa_path" > /dev/null 2>&1; then
        log_success "IPA structure validation passed"
    else
        log_error "IPA structure validation failed"
        exit 1
    fi
    
    # Extract and display basic info
    local temp_dir=$(mktemp -d)
    unzip -q "$ipa_path" -d "$temp_dir"
    
    local app_path=$(find "$temp_dir" -name "*.app" -type d | head -1)
    if [ -n "$app_path" ]; then
        local bundle_id=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$app_path/Info.plist" 2>/dev/null || echo "unknown")
        local version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$app_path/Info.plist" 2>/dev/null || echo "unknown")
        local build=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$app_path/Info.plist" 2>/dev/null || echo "unknown")
        
        log_info "Bundle ID: $bundle_id"
        log_info "Version: $version"
        log_info "Build: $build"
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
}

prepare_pipeline_artifacts() {
    log_step "Preparing Azure Pipeline artifacts"
    
    # Create artifacts directory structure expected by pipeline
    local artifacts_dir="$OUTPUT_DIR/pipeline-artifacts"
    mkdir -p "$artifacts_dir"
    
    # Copy IPA for pipeline consumption
    cp "$OUTPUT_DIR/BusinessCard.ipa" "$artifacts_dir/"
    
    # Copy dSYMs for crash reporting
    if [ -d "$ARCHIVE_PATH/dSYMs" ]; then
        cp -r "$ARCHIVE_PATH/dSYMs" "$artifacts_dir/"
        log_success "Debug symbols copied for crash reporting"
    fi
    
    # Create deployment metadata
    cat > "$artifacts_dir/deployment-info.json" << EOF
{
    "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%S.%3NZ')",
    "user": "gleidsonlm",
    "version": "$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$ARCHIVE_PATH/Products/Applications/businesscard.app/Info.plist" 2>/dev/null || echo "unknown")",
    "build": "$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$ARCHIVE_PATH/Products/Applications/businesscard.app/Info.plist" 2>/dev/null || echo "unknown")",
    "bundleId": "com.gleidsonlm.businesscard",
    "archivePath": "$ARCHIVE_PATH",
    "ipaPath": "$artifacts_dir/BusinessCard.ipa",
    "exportMethod": "app-store-connect",
    "readyForTestFlight": true
}
EOF
    
    log_success "Pipeline artifacts prepared: $artifacts_dir"
}

display_summary() {
    echo ""
    echo "=== Export Summary ==="
    log_success "IPA export completed successfully"
    echo ""
    echo "📁 Generated Files:"
    echo "   📦 IPA: $OUTPUT_DIR/BusinessCard.ipa"
    echo "   ⚙️  Export Options: $EXPORT_OPTIONS_PATH"
    echo "   🏗️  Pipeline Artifacts: $OUTPUT_DIR/pipeline-artifacts/"
    echo ""
    echo "📋 Next Steps:"
    echo "   1. Update Team ID in ExportOptions.plist if needed"
    echo "   2. Commit IPA and artifacts to repository"
    echo "   3. Run Azure Pipeline for TestFlight deployment"
    echo "   4. Monitor pipeline execution and TestFlight upload"
    echo ""
    echo "🔗 Azure Pipeline will:"
    echo "   • Use pre-built IPA from build/BusinessCard.ipa"
    echo "   • Upload to TestFlight via AppStoreRelease task"
    echo "   • Include dSYMs for crash reporting"
    echo "   • Complete export compliance automatically"
    echo ""
    log_success "Ready for Azure Pipeline TestFlight deployment!"
}

# Execute main function
main "$@"
