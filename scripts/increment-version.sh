#!/bin/bash
# Bundle Version Auto-Increment Script
# Ensures each TestFlight upload has a unique, ascending version number
# Author: Azure Pipeline Automation
# Usage: ./scripts/increment-version.sh

set -e  # Exit immediately on any error

# Configuration - Single source of truth
readonly INFO_PLIST_PATH="businesscard/Info.plist"
readonly BUNDLE_ID="com.gleidsonlm.businesscard"
readonly SCRIPT_NAME="increment-version.sh"

# Colors for better readability (optional)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions for clean output
log_info() {
    echo -e "${BLUE}ℹ️  INFO${NC}: $1"
}

log_success() {
    echo -e "${GREEN}✅ SUCCESS${NC}: $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  WARNING${NC}: $1"
}

log_error() {
    echo -e "${RED}❌ ERROR${NC}: $1" >&2
}

# Main function - Single Responsibility Principle
main() {
    log_info "=== Bundle Version Auto-Increment Started ==="
    log_info "Script: $SCRIPT_NAME"
    log_info "Bundle ID: $BUNDLE_ID"
    log_info "Info.plist: $INFO_PLIST_PATH"
    log_info "Timestamp: $(date '+%Y-%m-%d %H:%M:%S UTC')"
    
    validate_environment
    read_current_versions
    calculate_new_version
    update_info_plist
    verify_update
    set_pipeline_variables
    
    log_success "=== Bundle Version Auto-Increment Complete ==="
}

# Environment validation - Fail Fast principle
validate_environment() {
    log_info "Validating environment..."
    
    # Check if Info.plist exists
    if [ ! -f "$INFO_PLIST_PATH" ]; then
        log_error "Info.plist not found at: $INFO_PLIST_PATH"
        log_error "Please ensure you're running this script from the project root"
        log_error "Expected structure: project-root/$INFO_PLIST_PATH"
        exit 1
    fi
    
    # Check if PlistBuddy is available (should be on macOS)
    if ! command -v /usr/libexec/PlistBuddy &> /dev/null; then
        log_error "PlistBuddy not found - this script requires macOS"
        exit 1
    fi
    
    log_success "Environment validation passed"
}

# Read current version information
read_current_versions() {
    log_info "Reading current version information..."
    
    # Get current app version (e.g., "1.0.0")
    CURRENT_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$INFO_PLIST_PATH" 2>/dev/null || echo "1.0.0")
    
    # Get current build number (e.g., "4")
    CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$INFO_PLIST_PATH" 2>/dev/null || echo "1")
    
    log_info "Current App Version: $CURRENT_VERSION"
    log_info "Current Build Number: $CURRENT_BUILD"
    
    # Validate current build is numeric
    if ! [[ "$CURRENT_BUILD" =~ ^[0-9]+$ ]]; then
        log_warning "Current build number '$CURRENT_BUILD' is not numeric"
        log_info "Setting current build to 1 for calculation"
        CURRENT_BUILD=1
    fi
}

# Calculate new version using timestamp-based approach
calculate_new_version() {
    log_info "Calculating new build number..."
    
    # Generate timestamp-based build number (YYYYMMDDHHmm format)
    # This ensures uniqueness even with multiple builds per day
    TIMESTAMP_BUILD=$(date '+%Y%m%d%H%M')
    
    log_info "Timestamp-based build: $TIMESTAMP_BUILD"
    log_info "Current build number: $CURRENT_BUILD"
    
    # Ensure new build is higher than current build
    if [ "$TIMESTAMP_BUILD" -le "$CURRENT_BUILD" ]; then
        # If timestamp is not higher, use simple increment
        NEW_BUILD=$((CURRENT_BUILD + 1))
        log_warning "Timestamp build ($TIMESTAMP_BUILD) not higher than current ($CURRENT_BUILD)"
        log_info "Using incremented approach: $NEW_BUILD"
    else
        NEW_BUILD=$TIMESTAMP_BUILD
        log_info "Using timestamp-based build: $NEW_BUILD"
    fi
    
    log_success "New build number calculated: $NEW_BUILD"
}

# Update Info.plist with new version
update_info_plist() {
    log_info "Updating Info.plist with new build number..."
    
    # Create backup of Info.plist (safety measure)
    cp "$INFO_PLIST_PATH" "$INFO_PLIST_PATH.backup"
    log_info "Created backup: $INFO_PLIST_PATH.backup"
    
    # Update the bundle version
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD" "$INFO_PLIST_PATH"
    
    log_success "Info.plist updated with build number: $NEW_BUILD"
}

# Verify the update was successful
verify_update() {
    log_info "Verifying update..."
    
    # Read the updated value
    UPDATED_BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$INFO_PLIST_PATH" 2>/dev/null)
    
    if [ "$UPDATED_BUILD" = "$NEW_BUILD" ]; then
        log_success "Verification passed - build number is now: $UPDATED_BUILD"
        
        # Clean up backup since update was successful
        rm -f "$INFO_PLIST_PATH.backup"
        log_info "Removed backup file"
    else
        log_error "Verification failed!"
        log_error "Expected: $NEW_BUILD"
        log_error "Actual: $UPDATED_BUILD"
        
        # Restore from backup
        mv "$INFO_PLIST_PATH.backup" "$INFO_PLIST_PATH"
        log_error "Restored Info.plist from backup"
        exit 1
    fi
}

# Set pipeline variables for downstream tasks
set_pipeline_variables() {
    log_info "Setting pipeline variables..."
    
    # These variables can be used by subsequent pipeline steps
    echo "##vso[task.setvariable variable=newBundleVersion;isOutput=true]$NEW_BUILD"
    echo "##vso[task.setvariable variable=currentAppVersion;isOutput=true]$CURRENT_VERSION"
    echo "##vso[task.setvariable variable=previousBundleVersion;isOutput=true]$CURRENT_BUILD"
    
    log_success "Pipeline variables set:"
    log_info "  - newBundleVersion: $NEW_BUILD"
    log_info "  - currentAppVersion: $CURRENT_VERSION"
    log_info "  - previousBundleVersion: $CURRENT_BUILD"
}

# Execute main function
main "$@"
