#!/bin/bash
# scripts/diagnose-provisioning.sh
# Comprehensive provisioning profile analysis and diagnosis

set -e

readonly SCRIPT_VERSION="1.0.0"
readonly BUNDLE_ID="com.gleidsonlm.businesscard"
readonly BLUE='\033[0;34m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  INFO${NC}: $1"; }
log_success() { echo -e "${GREEN}✅ SUCCESS${NC}: $1"; }
log_warning() { echo -e "${YELLOW}⚠️  WARNING${NC}: $1"; }
log_error() { echo -e "${RED}❌ ERROR${NC}: $1" >&2; }
log_step() { echo -e "${PURPLE}🔄 STEP${NC}: $1"; }

main() {
    echo "=== Provisioning Profile Diagnostic v$SCRIPT_VERSION ==="
    echo "Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "User: gleidsonlm"
    echo "Bundle ID: $BUNDLE_ID"
    echo ""

    check_apple_developer_setup
    analyze_local_provisioning_profiles
    check_xcode_project_settings
    analyze_archive_signing
    suggest_solutions
    create_export_options_fix
}

check_apple_developer_setup() {
    log_step "Checking Apple Developer account setup"
    
    # Check if logged into Xcode
    log_info "Checking Xcode account configuration..."
    
    # List available development teams
    if command -v security &> /dev/null; then
        echo "🔍 Available certificates in keychain:"
        security find-identity -v -p codesigning | grep -E "(iPhone|Apple)" || echo "   No iOS certificates found"
    fi
    
    log_info "Please verify in Xcode → Preferences → Accounts:"
    log_info "   • Apple ID is signed in"
    log_info "   • Team shows 'gleidsonlm' or your developer account"
    log_info "   • Both Development and Distribution certificates are present"
}

analyze_local_provisioning_profiles() {
    log_step "Analyzing local provisioning profiles"
    
    local profiles_dir="$HOME/Library/MobileDevice/Provisioning Profiles"
    
    if [ ! -d "$profiles_dir" ]; then
        log_warning "Provisioning profiles directory not found"
        log_info "This suggests no profiles have been downloaded to this Mac"
        return
    fi
    
    log_info "Scanning for profiles matching bundle ID: $BUNDLE_ID"
    
    local profile_count=0
    local app_store_profile_found=false
    
    for profile in "$profiles_dir"/*.mobileprovision; do
        if [ -f "$profile" ]; then
            # Extract profile info
            local profile_data=$(security cms -D -i "$profile" 2>/dev/null || echo "")
            
            if echo "$profile_data" | grep -q "$BUNDLE_ID"; then
                profile_count=$((profile_count + 1))
                
                # Extract profile details
                local profile_name=$(echo "$profile_data" | plutil -extract Name raw - 2>/dev/null || echo "Unknown")
                local team_id=$(echo "$profile_data" | plutil -extract TeamIdentifier.0 raw - 2>/dev/null || echo "Unknown")
                local expiry=$(echo "$profile_data" | plutil -extract ExpirationDate raw - 2>/dev/null || echo "Unknown")
                
                echo "📋 Profile found:"
                echo "   Name: $profile_name"
                echo "   Team ID: $team_id"
                echo "   Expiry: $expiry"
                echo "   File: $(basename "$profile")"
                
                # Check if it's an App Store profile
                if echo "$profile_data" | grep -q "ProvisionedDevices"; then
                    log_info "   Type: Development/Ad Hoc (has device list)"
                else
                    log_success "   Type: App Store Distribution (no device restrictions)"
                    app_store_profile_found=true
                fi
                echo ""
            fi
        fi
    done
    
    if [ "$profile_count" -eq 0 ]; then
        log_error "No provisioning profiles found for bundle ID: $BUNDLE_ID"
        log_info "This explains the export error"
    elif [ "$app_store_profile_found" = false ]; then
        log_warning "Found $profile_count profile(s) but none are App Store distribution profiles"
        log_info "App Store distribution requires a specific profile type"
    else
        log_success "Found App Store distribution profile"
    fi
}

check_xcode_project_settings() {
    log_step "Checking Xcode project signing settings"
    
    # Find the project file
    local xcodeproj=$(find . -name "*.xcodeproj" -type d | head -1)
    
    if [ -z "$xcodeproj" ]; then
        log_error "No Xcode project found"
        return
    fi
    
    log_info "Project: $xcodeproj"
    
    # Extract team ID from project settings
    local pbxproj="$xcodeproj/project.pbxproj"
    
    if [ -f "$pbxproj" ]; then
        local team_ids=$(grep -o 'DEVELOPMENT_TEAM = [^;]*' "$pbxproj" | sort -u | head -5)
        
        if [ -n "$team_ids" ]; then
            log_info "Development teams configured in project:"
            echo "$team_ids" | sed 's/^/   /'
        else
            log_warning "No development team configured in project"
            log_info "This may require manual team selection in Xcode"
        fi
        
        # Check bundle identifier configuration
        local bundle_ids=$(grep -o 'PRODUCT_BUNDLE_IDENTIFIER = [^;]*' "$pbxproj" | sort -u | head -3)
        
        if [ -n "$bundle_ids" ]; then
            log_info "Bundle identifiers in project:"
            echo "$bundle_ids" | sed 's/^/   /'
        fi
    fi
}

analyze_archive_signing() {
    log_step "Analyzing archive signing configuration"
    
    local archive_path="xcarchive"
    
    if [ ! -d "$archive_path" ]; then
        log_warning "Archive not found at: $archive_path"
        return
    fi
    
    local app_path="$archive_path/Products/Applications/businesscard.app"
    
    if [ ! -d "$app_path" ]; then
        log_error "App bundle not found in archive"
        return
    fi
    
    # Check embedded provisioning profile
    local embedded_profile="$app_path/embedded.mobileprovision"
    
    if [ -f "$embedded_profile" ]; then
        log_success "Embedded provisioning profile found in archive"
        
        # Extract profile info from embedded profile
        local profile_data=$(security cms -D -i "$embedded_profile" 2>/dev/null || echo "")
        
        if [ -n "$profile_data" ]; then
            local profile_name=$(echo "$profile_data" | plutil -extract Name raw - 2>/dev/null || echo "Unknown")
            local team_id=$(echo "$profile_data" | plutil -extract TeamIdentifier.0 raw - 2>/dev/null || echo "Unknown")
            
            log_info "Archive was signed with:"
            log_info "   Profile: $profile_name"
            log_info "   Team ID: $team_id"
            
            # Check if it's a development profile
            if echo "$profile_data" | grep -q "ProvisionedDevices"; then
                log_warning "Archive uses Development profile"
                log_info "Export requires App Store Distribution profile"
            else
                log_success "Archive uses Distribution profile"
            fi
        fi
    else
        log_error "No embedded provisioning profile found in archive"
    fi
    
    # Check code signing identity
    log_info "Checking code signing identity..."
    codesign -dv "$app_path" 2>&1 | grep -E "(Authority|TeamIdentifier)" | sed 's/^/   /' || log_warning "Could not extract signing info"
}

suggest_solutions() {
    log_step "Solution recommendations"
    
    echo ""
    echo "🎯 Based on the analysis, here are the recommended solutions:"
    echo ""
    
    echo "📋 Solution 1: Create App Store Distribution Profile (Recommended)"
    echo "   1. Go to Apple Developer Portal (developer.apple.com)"
    echo "   2. Sign in with your Apple ID"
    echo "   3. Navigate to Certificates, Identifiers & Profiles"
    echo "   4. Go to Profiles → Create new profile"
    echo "   5. Select 'App Store' distribution type"
    echo "   6. Choose your App ID: $BUNDLE_ID"
    echo "   7. Select your Distribution certificate"
    echo "   8. Download and install the profile"
    echo ""
    
    echo "📋 Solution 2: Use Automatic Signing (Easier)"
    echo "   1. Open project in Xcode"
    echo "   2. Select main app target"
    echo "   3. Signing & Capabilities tab"
    echo "   4. Enable 'Automatically manage signing'"
    echo "   5. Select your development team"
    echo "   6. Xcode will handle provisioning automatically"
    echo ""
    
    echo "📋 Solution 3: Fix ExportOptions.plist"
    echo "   1. Update ExportOptions.plist with correct team ID"
    echo "   2. Use 'automatic' signing style"
    echo "   3. Let Xcode select appropriate profiles"
    echo ""
}

create_export_options_fix() {
    log_step "Creating corrected ExportOptions.plist"
    
    local export_options_path="scripts/ExportOptions.plist"
    
    # Create corrected version
    cat > "$export_options_path" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Export Method: app-store for TestFlight/App Store distribution -->
    <key>method</key>
    <string>app-store</string>
    
    <!-- Signing Style: Let Xcode manage provisioning automatically -->
    <key>signingStyle</key>
    <string>automatic</string>
    
    <!-- Team ID: Will be detected automatically with automatic signing -->
    <!-- Remove specific teamID to let Xcode choose -->
    
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
    
    <!-- Let Xcode manage provisioning profiles automatically -->
    <!-- Remove specific provisioningProfiles to use automatic selection -->
    
    <!-- Export Compliance: Already configured in Info.plist -->
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
</dict>
</plist>
EOF

    log_success "Created automatic signing ExportOptions.plist"
    log_info "This version uses automatic signing to avoid provisioning issues"
}

# Execute main function
main "$@"