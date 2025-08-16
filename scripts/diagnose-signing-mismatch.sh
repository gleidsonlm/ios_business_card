#!/bin/bash
# scripts/diagnose-signing-mismatch.sh
# Comprehensive analysis of certificate-profile relationship issues

set -e

readonly SCRIPT_VERSION="1.0.0"
readonly BUNDLE_ID="com.gleidsonlm.businesscard"
readonly CERT_NAME="Apple Distribution: Gleidson Medeiros (6N4F2PK5R3)"
readonly TEAM_ID="6N4F2PK5R3"

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
    echo "=== Certificate-Profile Mismatch Diagnosis v$SCRIPT_VERSION ==="
    echo "Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "User: gleidsonlm"
    echo "Bundle ID: $BUNDLE_ID"
    echo "Certificate: $CERT_NAME"
    echo "Team ID: $TEAM_ID"
    echo ""

    analyze_available_certificates
    analyze_provisioning_profiles
    check_certificate_profile_relationship
    analyze_xcode_project_settings
    provide_solution_recommendations
}

analyze_available_certificates() {
    log_step "Analyzing available certificates in keychain"
    
    echo "🔍 All iOS signing certificates:"
    security find-identity -v -p codesigning | grep -E "(iPhone|Apple)" | while read -r line; do
        echo "   $line"
    done
    echo ""
    
    # Check specifically for our distribution certificate
    if security find-identity -v -p codesigning | grep -q "$CERT_NAME"; then
        log_success "Target distribution certificate found in keychain"
        
        # Get certificate details
        local cert_sha1=$(security find-identity -v -p codesigning | grep "$CERT_NAME" | awk '{print $2}')
        log_info "Certificate SHA1: $cert_sha1"
        
        # Check certificate validity
        local cert_info=$(security find-certificate -c "$CERT_NAME" -p | openssl x509 -text -noout 2>/dev/null || echo "Could not parse certificate")
        local not_after=$(echo "$cert_info" | grep "Not After" | sed 's/.*Not After : //' || echo "Unknown expiry")
        
        log_info "Certificate expires: $not_after"
        
        # Check if certificate is valid for code signing
        if echo "$cert_info" | grep -q "Code Signing"; then
            log_success "Certificate is valid for code signing"
        else
            log_warning "Certificate may not be configured for code signing"
        fi
        
    else
        log_error "Target distribution certificate NOT found in keychain"
        log_info "Available distribution certificates:"
        security find-identity -v -p codesigning | grep "Apple Distribution" | sed 's/^/   /' || echo "   None found"
    fi
}

analyze_provisioning_profiles() {
    log_step "Analyzing provisioning profiles for bundle ID"
    
    local profiles_dir="$HOME/Library/MobileDevice/Provisioning Profiles"
    
    if [ ! -d "$profiles_dir" ]; then
        log_warning "Provisioning profiles directory not found"
        log_info "This suggests no profiles have been downloaded to this Mac"
        return
    fi
    
    local profile_count=0
    local matching_profiles=()
    
    log_info "Scanning for profiles matching bundle ID: $BUNDLE_ID"
    
    for profile in "$profiles_dir"/*.mobileprovision; do
        if [ -f "$profile" ]; then
            local profile_data=$(security cms -D -i "$profile" 2>/dev/null || echo "")
            
            if echo "$profile_data" | grep -q "$BUNDLE_ID"; then
                profile_count=$((profile_count + 1))
                
                # Extract profile details
                local profile_name=$(echo "$profile_data" | plutil -extract Name raw - 2>/dev/null || echo "Unknown")
                local team_id=$(echo "$profile_data" | plutil -extract TeamIdentifier.0 raw - 2>/dev/null || echo "Unknown")
                local expiry=$(echo "$profile_data" | plutil -extract ExpirationDate raw - 2>/dev/null || echo "Unknown")
                local creation_date=$(echo "$profile_data" | plutil -extract CreationDate raw - 2>/dev/null || echo "Unknown")
                
                echo ""
                echo "📋 Profile #$profile_count:"
                echo "   Name: $profile_name"
                echo "   Team ID: $team_id"
                echo "   Created: $creation_date"
                echo "   Expires: $expiry"
                echo "   File: $(basename "$profile")"
                
                # Check profile type
                if echo "$profile_data" | grep -q "ProvisionedDevices"; then
                    log_info "   Type: Development/Ad Hoc (has device list)"
                else
                    log_success "   Type: App Store Distribution (no device restrictions)"
                fi
                
                # Extract and analyze certificates in this profile
                log_info "   Analyzing certificates in this profile..."
                
                # Get certificate data from profile
                local cert_count=0
                if echo "$profile_data" | plutil -extract DeveloperCertificates raw - >/dev/null 2>&1; then
                    # Count certificates in profile
                    cert_count=$(echo "$profile_data" | plutil -extract DeveloperCertificates raw - | plutil -convert xml1 - -o - | grep -c "<data>" || echo "0")
                    log_info "   Certificates in profile: $cert_count"
                    
                    # Extract each certificate and check if it matches our target
                    for (( i=0; i<cert_count; i++ )); do
                        local cert_data=$(echo "$profile_data" | plutil -extract DeveloperCertificates.$i raw - 2>/dev/null | base64 -d 2>/dev/null | openssl x509 -text -noout 2>/dev/null || echo "")
                        
                        if [ -n "$cert_data" ]; then
                            local cert_subject=$(echo "$cert_data" | grep "Subject:" | sed 's/.*Subject: //' || echo "Unknown")
                            echo "      Certificate $((i+1)): $cert_subject"
                            
                            # Check if this certificate matches our target
                            if echo "$cert_subject" | grep -q "Gleidson Medeiros"; then
                                if echo "$cert_subject" | grep -q "$TEAM_ID"; then
                                    log_success "      ✅ MATCHES our target certificate!"
                                else
                                    log_warning "      ⚠️ Same name but different Team ID"
                                fi
                            else
                                log_info "      ℹ️ Different certificate owner"
                            fi
                        fi
                    done
                else
                    log_warning "   Could not extract certificate information from profile"
                fi
                
                matching_profiles+=("$profile")
            fi
        fi
    done
    
    if [ "$profile_count" -eq 0 ]; then
        log_error "No provisioning profiles found for bundle ID: $BUNDLE_ID"
        log_info "You need to create or download an App Store distribution profile"
    else
        log_info "Found $profile_count provisioning profile(s) for your app"
    fi
}

check_certificate_profile_relationship() {
    log_step "Checking certificate-profile relationship"
    
    echo ""
    echo "🔍 Certificate-Profile Compatibility Analysis:"
    echo ""
    
    # The core issue explanation
    log_info "The error indicates:"
    log_info "   • Your distribution certificate exists in keychain ✅"
    log_info "   • A provisioning profile exists for your app ✅"
    log_info "   • BUT: The profile doesn't include your specific certificate ❌"
    echo ""
    
    log_info "This happens when:"
    log_info "   1. Certificate was created/renewed after the profile"
    log_info "   2. Profile was created with a different certificate"
    log_info "   3. Multiple team members have different certificates"
    log_info "   4. Certificate was revoked and recreated"
    echo ""
    
    log_warning "Resolution required: Create new provisioning profile with current certificate"
}

analyze_xcode_project_settings() {
    log_step "Analyzing Xcode project signing settings"
    
    # Find the project file
    local xcodeproj=$(find . -name "*.xcodeproj" -type d | head -1)
    
    if [ -z "$xcodeproj" ]; then
        log_error "No Xcode project found"
        return
    fi
    
    log_info "Project: $xcodeproj"
    
    # Extract signing settings from project
    local pbxproj="$xcodeproj/project.pbxproj"
    
    if [ -f "$pbxproj" ]; then
        echo ""
        log_info "Current project signing configuration:"
        
        # Check development team
        local dev_teams=$(grep -o 'DEVELOPMENT_TEAM = [^;]*' "$pbxproj" | sort -u)
        if [ -n "$dev_teams" ]; then
            echo "$dev_teams" | sed 's/^/   /' | sed 's/DEVELOPMENT_TEAM = /Team ID: /'
        else
            log_warning "   No development team configured"
        fi
        
        # Check code sign style
        local sign_styles=$(grep -o 'CODE_SIGN_STYLE = [^;]*' "$pbxproj" | sort -u)
        if [ -n "$sign_styles" ]; then
            echo "$sign_styles" | sed 's/^/   /' | sed 's/CODE_SIGN_STYLE = /Signing Style: /'
        fi
        
        # Check provisioning profile specifier
        local profile_specs=$(grep -o 'PROVISIONING_PROFILE_SPECIFIER = [^;]*' "$pbxproj" | sort -u)
        if [ -n "$profile_specs" ]; then
            echo "$profile_specs" | sed 's/^/   /' | sed 's/PROVISIONING_PROFILE_SPECIFIER = /Profile Specifier: /'
        fi
        
        # Check code sign identity
        local sign_identities=$(grep -o 'CODE_SIGN_IDENTITY = [^;]*' "$pbxproj" | sort -u)
        if [ -n "$sign_identities" ]; then
            echo "$sign_identities" | sed 's/^/   /' | sed 's/CODE_SIGN_IDENTITY = /Sign Identity: /'
        fi
    fi
}

provide_solution_recommendations() {
    log_step "Solution recommendations"
    
    echo ""
    echo "🎯 Recommended Solutions (in order of preference):"
    echo ""
    
    echo "📋 Solution 1: Use Automatic Signing (Recommended)"
    echo "   Benefits: Xcode manages certificate-profile relationship automatically"
    echo "   Steps:"
    echo "   1. Open project in Xcode"
    echo "   2. Select main app target"
    echo "   3. Signing & Capabilities tab"
    echo "   4. ✅ Enable 'Automatically manage signing'"
    echo "   5. Select Team: $TEAM_ID (gleidsonlm)"
    echo "   6. Xcode will create/update provisioning profile automatically"
    echo ""
    
    echo "📋 Solution 2: Create New Provisioning Profile"
    echo "   Benefits: Full control over certificate-profile relationship"
    echo "   Steps:"
    echo "   1. Go to Apple Developer Portal (developer.apple.com)"
    echo "   2. Sign in with Apple ID (gleidsonlm)"
    echo "   3. Certificates, Identifiers & Profiles"
    echo "   4. Profiles → ➕ Create new profile"
    echo "   5. Select 'App Store' distribution type"
    echo "   6. Choose App ID: $BUNDLE_ID"
    echo "   7. ✅ Select certificate: $CERT_NAME"
    echo "   8. Download and install new profile"
    echo "   9. Update Xcode project to use new profile"
    echo ""
    
    echo "📋 Solution 3: Update Existing Profile"
    echo "   Benefits: Keeps existing profile name/configuration"
    echo "   Steps:"
    echo "   1. Go to Apple Developer Portal"
    echo "   2. Find existing provisioning profile for $BUNDLE_ID"
    echo "   3. Edit profile"
    echo "   4. ✅ Ensure $CERT_NAME is selected"
    echo "   5. ❌ Deselect any old/invalid certificates"
    echo "   6. Save and download updated profile"
    echo "   7. Install in Xcode"
    echo ""
    
    echo "📋 Solution 4: Certificate Verification"
    echo "   If certificate issues persist:"
    echo "   1. Verify certificate is valid and not expired"
    echo "   2. Check certificate is installed in correct keychain"
    echo "   3. Ensure certificate has private key"
    echo "   4. Consider revoking and creating new certificate if needed"
    echo ""
    
    log_success "Recommendation: Start with Solution 1 (Automatic Signing)"
    log_info "It's the most reliable and requires minimal manual configuration"
}

# Execute main function
main "$@"