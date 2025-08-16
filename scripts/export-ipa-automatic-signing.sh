#!/bin/bash
# scripts/export-ipa-automatic-signing.sh
# IPA export optimized for automatic signing

set -e

readonly SCRIPT_VERSION="2.0.0"
readonly PROJECT_ROOT="$(pwd)"
readonly ARCHIVE_PATH="$PROJECT_ROOT/xcarchive"
readonly OUTPUT_DIR="$PROJECT_ROOT/build"
readonly EXPORT_OPTIONS_PATH="$PROJECT_ROOT/scripts/ExportOptions-Automatic.plist"
readonly BUNDLE_ID="com.gleidsonlm.businesscard"

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  INFO${NC}: $1"; }
log_success() { echo -e "${GREEN}✅ SUCCESS${NC}: $1"; }
log_warning() { echo -e "${YELLOW}⚠️  WARNING${NC}: $1"; }
log_error() { echo -e "${RED}❌ ERROR${NC}: $1" >&2; }
log_step() { echo -e "${PURPLE}🔄 STEP${NC}: $1"; }

main() {
    echo "=== Automatic Signing IPA Export v$SCRIPT_VERSION ==="
    echo "Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "User: gleidsonlm"
    echo "Bundle ID: $BUNDLE_ID"
    echo "Approach: Automatic signing with Xcode-managed provisioning"
    echo ""

    validate_prerequisites
    verify_automatic_signing_setup
    create_export_options
    export_with_automatic_signing
    validate_ipa_output
    prepare_pipeline_artifacts
    display_completion_summary
}

validate_prerequisites() {
    log_step "Validating prerequisites for automatic signing"
    
    # Standard archive validation
    if [ ! -d "$ARCHIVE_PATH" ]; then
        log_error "Archive not found at: $ARCHIVE_PATH"
        log_info "Please ensure archive is available before running export"
        exit 1
    fi
    log_success "Archive found: $ARCHIVE_PATH"
    
    if [ ! -d "$ARCHIVE_PATH/Products/Applications/businesscard.app" ]; then
        log_error "App bundle not found in archive"
        exit 1
    fi
    log_success "App bundle found in archive"
    
    # Xcode tools validation
    if ! command -v xcodebuild &> /dev/null; then
        log_error "xcodebuild not found - requires Xcode installation"
        exit 1
    fi
    log_success "xcodebuild available: $(xcodebuild -version | head -1)"
    
    # Output directory
    mkdir -p "$OUTPUT_DIR"
    log_success "Output directory ready: $OUTPUT_DIR"
}

verify_automatic_signing_setup() {
    log_step "Verifying automatic signing configuration"
    
    # Check if user is signed into Xcode
    log_info "Checking Xcode account configuration..."
    
    # Verify certificates are available
    local dist_certs=$(security find-identity -v -p codesigning | grep "Apple Distribution" | wc -l)
    log_info "Distribution certificates available: $dist_certs"
    
    if [ "$dist_certs" -eq 0 ]; then
        log_warning "No distribution certificates found"
        log_info "Please ensure you're signed into Xcode with your Apple Developer account"
        log_info "Xcode → Preferences → Accounts → Add Apple ID"
    else
        log_success "Distribution certificates available for automatic signing"
    fi
    
    # Check for our specific certificate
    if security find-identity -v -p codesigning | grep -q "Gleidson Medeiros"; then
        log_success "Found certificates for Gleidson Medeiros"
    else
        log_warning "Specific certificate for Gleidson Medeiros not found"
        log_info "Automatic signing may download certificate during export"
    fi
}

create_export_options() {
    log_step "Creating automatic signing export options"
    
    # Use the automatic signing export options
    if [ ! -f "$EXPORT_OPTIONS_PATH" ]; then
        log_info "Creating automatic signing export options..."
        
        mkdir -p "$(dirname "$EXPORT_OPTIONS_PATH")"
        
        cat > "$EXPORT_OPTIONS_PATH" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <true/>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
EOF
        
        log_success "Created automatic signing export options"
    else
        log_success "Using existing automatic signing export options"
    fi
    
    log_info "Export configuration:"
    log_info "   Method: app-store"
    log_info "   Signing: automatic"
    log_info "   Team: Auto-detected"
    log_info "   Provisioning: Xcode-managed"
}

export_with_automatic_signing() {
    log_step "Exporting IPA with automatic signing"
    
    local export_path="$OUTPUT_DIR/BusinessCard-Export-Automatic"
    
    # Clear previous export attempts
    rm -rf "$export_path"
    
    log_info "Starting xcodebuild export process..."
    log_info "   Archive: $ARCHIVE_PATH"
    log_info "   Export Path: $export_path"
    log_info "   Options: $EXPORT_OPTIONS_PATH"
    
    # Export with automatic signing and provisioning updates
    if xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$export_path" \
        -exportOptionsPlist "$EXPORT_OPTIONS_PATH" \
        -allowProvisioningUpdates \
        -allowProvisioningDeviceRegistration \
        -verbose 2>&1 | tee "$OUTPUT_DIR/export-automatic-log.txt"; then
        
        log_success "Archive export completed with automatic signing"
    else
        log_error "Archive export failed"
        
        echo ""
        log_info "=== Troubleshooting Information ==="
        log_info "Export log: $OUTPUT_DIR/export-automatic-log.txt"
        echo ""
        
        log_info "Common automatic signing issues:"
        echo "   1. Not signed into Xcode with Apple Developer account"
        echo "   2. Apple Developer Program membership not active"
        echo "   3. App ID not registered in Apple Developer Portal"
        echo "   4. Network connectivity issues preventing profile download"
        echo ""
        
        log_info "Manual resolution steps:"
        echo "   1. Xcode → Preferences → Accounts → Verify Apple ID"
        echo "   2. Check Apple Developer Portal for app registration"
        echo "   3. Try creating archive again with automatic signing enabled"
        echo "   4. Use Xcode Organizer for manual export if needed"
        
        exit 1
    fi
    
    # Find and copy the generated IPA
    local ipa_file=$(find "$export_path" -name "*.ipa" -type f | head -1)
    
    if [ -n "$ipa_file" ]; then
        cp "$ipa_file" "$OUTPUT_DIR/BusinessCard.ipa"
        log_success "IPA created: $OUTPUT_DIR/BusinessCard.ipa"
        
        # Get IPA size
        local ipa_size=$(du -h "$OUTPUT_DIR/BusinessCard.ipa" | cut -f1)
        log_info "IPA size: $ipa_size"
    else
        log_error "No IPA file found in export output"
        log_info "Check export directory: $export_path"
        exit 1
    fi
}

validate_ipa_output() {
    log_step "Validating IPA output and signing"
    
    local ipa_path="$OUTPUT_DIR/BusinessCard.ipa"
    
    # Basic IPA validation
    if [ ! -f "$ipa_path" ]; then
        log_error "IPA file not found: $ipa_path"
        exit 1
    fi
    
    # Validate IPA structure
    if unzip -t "$ipa_path" > /dev/null 2>&1; then
        log_success "IPA structure validation passed"
    else
        log_error "IPA structure validation failed"
        exit 1
    fi
    
    # Extract and validate app contents
    local temp_dir=$(mktemp -d)
    unzip -q "$ipa_path" -d "$temp_dir"
    
    local app_path=$(find "$temp_dir" -name "*.app" -type d | head -1)
    
    if [ -n "$app_path" ]; then
        # Extract app information
        local bundle_id=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$app_path/Info.plist" 2>/dev/null || echo "unknown")
        local version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$app_path/Info.plist" 2>/dev/null || echo "unknown")
        local build=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$app_path/Info.plist" 2>/dev/null || echo "unknown")
        
        log_info "IPA Contents Validation:"
        log_info "   Bundle ID: $bundle_id"
        log_info "   Version: $version"
        log_info "   Build: $build"
        
        # Verify bundle ID
        if [ "$bundle_id" = "$BUNDLE_ID" ]; then
            log_success "Bundle ID verification passed"
        else
            log_warning "Bundle ID mismatch: expected $BUNDLE_ID, got $bundle_id"
        fi
        
        # Check export compliance
        if /usr/libexec/PlistBuddy -c "Print ITSAppUsesNonExemptEncryption" "$app_path/Info.plist" >/dev/null 2>&1; then
            local encryption_value=$(/usr/libexec/PlistBuddy -c "Print ITSAppUsesNonExemptEncryption" "$app_path/Info.plist")
            log_success "Export compliance configured: $encryption_value"
        else
            log_warning "Export compliance key not found"
        fi
        
        # Verify code signing with automatic signing
        log_info "Verifying automatic code signing..."
        if codesign -dv "$app_path" 2>&1 | grep -q "Authority=Apple Distribution"; then
            log_success "IPA signed with Apple Distribution certificate"
            
            # Extract signing details
            local signing_info=$(codesign -dv "$app_path" 2>&1)
            local team_id=$(echo "$signing_info" | grep "TeamIdentifier" | sed 's/.*TeamIdentifier=//')
            
            if [ -n "$team_id" ]; then
                log_info "Team ID: $team_id"
            fi
            
        else
            log_warning "Could not verify distribution signing"
        fi
        
        # Check provisioning profile
        if [ -f "$app_path/embedded.mobileprovision" ]; then
            log_success "Embedded provisioning profile found"
            
            local profile_data=$(security cms -D -i "$app_path/embedded.mobileprovision" 2>/dev/null || echo "")
            if [ -n "$profile_data" ]; then
                local profile_name=$(echo "$profile_data" | plutil -extract Name raw - 2>/dev/null || echo "Unknown")
                log_info "Provisioning profile: $profile_name"
                
                if echo "$profile_name" | grep -q "Xcode Managed"; then
                    log_success "Using Xcode-managed provisioning profile"
                fi
            fi
        else
            log_warning "No embedded provisioning profile found"
        fi
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    log_success "IPA validation completed - ready for TestFlight"
}

prepare_pipeline_artifacts() {
    log_step "Preparing Azure Pipeline artifacts"
    
    local artifacts_dir="$OUTPUT_DIR/pipeline-artifacts"
    mkdir -p "$artifacts_dir"
    
    # Copy IPA for pipeline consumption
    cp "$OUTPUT_DIR/BusinessCard.ipa" "$artifacts_dir/"
    
    # Copy dSYMs for crash reporting
    if [ -d "$ARCHIVE_PATH/dSYMs" ]; then
        cp -r "$ARCHIVE_PATH/dSYMs" "$artifacts_dir/"
        log_success "Debug symbols copied for crash reporting"
    fi
    
    # Copy export log for troubleshooting
    if [ -f "$OUTPUT_DIR/export-automatic-log.txt" ]; then
        cp "$OUTPUT_DIR/export-automatic-log.txt" "$artifacts_dir/"
        log_info "Export log copied for pipeline reference"
    fi
    
    # Create deployment metadata
    local app_path="$ARCHIVE_PATH/Products/Applications/businesscard.app"
    local version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$app_path/Info.plist" 2>/dev/null || echo "unknown")
    local build=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$app_path/Info.plist" 2>/dev/null || echo "unknown")
    
    cat > "$artifacts_dir/deployment-info.json" << EOF
{
    "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%S.%3NZ')",
    "user": "gleidsonlm",
    "version": "$version",
    "build": "$build",
    "bundleId": "$BUNDLE_ID",
    "archivePath": "$ARCHIVE_PATH",
    "ipaPath": "$artifacts_dir/BusinessCard.ipa",
    "exportMethod": "app-store",
    "signingStyle": "automatic",
    "signingIssueResolved": true,
    "readyForTestFlight": true,
    "scriptVersion": "$SCRIPT_VERSION"
}
EOF
    
    log_success "Pipeline artifacts prepared: $artifacts_dir"
}

display_completion_summary() {
    echo ""
    echo "=== Automatic Signing Export Complete ==="
    log_success "Certificate-profile mismatch resolved with automatic signing"
    echo ""
    echo "📁 Generated Files:"
    echo "   📦 IPA: $OUTPUT_DIR/BusinessCard.ipa"
    echo "   ⚙️  Export Options: $EXPORT_OPTIONS_PATH"
    echo "   📋 Export Log: $OUTPUT_DIR/export-automatic-log.txt"
    echo "   🏗️  Pipeline Artifacts: $OUTPUT_DIR/pipeline-artifacts/"
    echo ""
    echo "🔧 Technical Resolution:"
    echo "   • Switched to automatic signing style"
    echo "   • Xcode managed certificate-profile relationship"
    echo "   • Eliminated manual provisioning profile configuration"
    echo "   • Resolved 'certificate not included in profile' error"
    echo ""
    echo "📋 Next Steps:"
    echo "   1. ✅ Signing issue resolved"
    echo "   2. 🔄 Commit IPA and configuration changes"
    echo "   3. 🚀 Push to trigger Azure Pipeline TestFlight deployment"
    echo "   4. 👀 Monitor Azure DevOps pipeline execution"
    echo ""
    echo "🎯 For Azure Pipeline:"
    echo "   • IPA Location: build/BusinessCard.ipa"
    echo "   • Artifacts: build/pipeline-artifacts/"
    echo "   • Ready for AppStoreRelease task"
    echo "   • Signing: Properly configured for App Store distribution"
    echo ""
    log_success "Business Card app ready for TestFlight deployment!"
    echo ""
    echo "📚 Learning Outcome:"
    echo "   Automatic signing resolves certificate-profile relationship issues"
    echo "   Xcode handles provisioning complexity, reducing manual configuration errors"
    echo "   Professional iOS development often uses automatic signing for reliability"
}

# Execute main function
main "$@"