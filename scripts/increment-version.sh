#!/bin/bash
# Bundle Version Auto-Increment Script - Enhanced Edition
# Dynamically discovers Info.plist location and ensures unique, ascending versions
# Author: Azure Pipeline Automation
# Version: 2.0 - Enhanced with dynamic path discovery

set -e  # Exit immediately on any error

# Configuration - Constants that define our application
readonly BUNDLE_ID="com.gleidsonlm.businesscard"
readonly SCRIPT_NAME="increment-version.sh"
readonly SCRIPT_VERSION="2.0"

# Colors for better readability in logs
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m' # No Color

# Global variables (will be set by functions)
INFO_PLIST_PATH=""
CURRENT_VERSION=""
CURRENT_BUILD=""
NEW_BUILD=""

# Logging functions for clean, consistent output
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

log_debug() {
    echo -e "${PURPLE}🔍 DEBUG${NC}: $1"
}

# Main function - orchestrates the entire process
main() {
    log_info "=== Bundle Version Auto-Increment Started ==="
    log_info "Script: $SCRIPT_NAME v$SCRIPT_VERSION"
    log_info "Bundle ID: $BUNDLE_ID"
    log_info "Timestamp: $(date '+%Y-%m-%d %H:%M:%S UTC')"
    log_info "Working Directory: $(pwd)"
    echo ""
    
    validate_environment
    discover_info_plist
    read_current_versions
    calculate_new_version
    update_info_plist
    verify_update
    set_pipeline_variables
    
    log_success "=== Bundle Version Auto-Increment Complete ==="
}

# Environment validation - ensures we have required tools
validate_environment() {
    log_info "Validating environment..."
    
    # Check if we're on macOS (required for PlistBuddy)
    if ! command -v /usr/libexec/PlistBuddy &> /dev/null; then
        log_error "PlistBuddy not found - this script requires macOS"
        log_error "Current OS: $(uname -s)"
        exit 1
    fi
    
    # Check if find command is available
    if ! command -v find &> /dev/null; then
        log_error "find command not available"
        exit 1
    fi
    
    log_success "Environment validation passed"
}

# Dynamic Info.plist discovery - finds the correct file automatically
discover_info_plist() {
    log_info "Discovering Info.plist location..."
    
    # Search for all Info.plist files in the project
    local info_plists=()
    while IFS= read -r -d '' plist; do
        info_plists+=("$plist")
    done < <(find "." -name "Info.plist" -type f -print0 2>/dev/null)
    
    log_debug "Found ${#info_plists[@]} Info.plist files"
    
    if [ ${#info_plists[@]} -eq 0 ]; then
        log_error "No Info.plist files found in the project"
        log_error "Search started from: $(pwd)"
        log_error "Please ensure the project contains an iOS app with Info.plist"
        exit 1
    fi
    
    # Find the main app's Info.plist by checking bundle identifier
    local main_app_plists=()
    
    for plist in "${info_plists[@]}"; do
        log_debug "Checking: $plist"
        
        # Try to read bundle identifier
        local bundle_id=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$plist" 2>/dev/null || echo "")
        
        if [ "$bundle_id" = "$BUNDLE_ID" ]; then
            log_success "Found main app Info.plist: $plist"
            log_info "Bundle ID matches: $bundle_id"
            main_app_plists+=("$plist")
        else
            log_debug "Skipping (different bundle ID): $bundle_id"
        fi
    done
    
    # Validate we found exactly one main app Info.plist
    if [ ${#main_app_plists[@]} -eq 0 ]; then
        log_error "No Info.plist found with bundle ID: $BUNDLE_ID"
        log_error ""
        log_error "Found Info.plist files and their bundle IDs:"
        for plist in "${info_plists[@]}"; do
            local bundle_id=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$plist" 2>/dev/null || echo "unknown")
            log_error "  $plist -> $bundle_id"
        done
        log_error ""
        log_error "Please verify the bundle ID in your main app's Info.plist matches: $BUNDLE_ID"
        exit 1
    elif [ ${#main_app_plists[@]} -gt 1 ]; then
        log_error "Multiple Info.plist files found with bundle ID: $BUNDLE_ID"
        log_error ""
        log_error "Conflicting files:"
        for plist in "${main_app_plists[@]}"; do
            log_error "  $plist"
        done
        log_error ""
        log_error "Please ensure only one main app target has this bundle ID"
        exit 1
    fi
    
    # Set the global variable
    INFO_PLIST_PATH="${main_app_plists[0]}"
    log_success "Using Info.plist: $INFO_PLIST_PATH"
}

# Read current version information from the discovered Info.plist
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
        log_info "Converting to numeric value for calculation"
        # Extract numeric part or default to 1
        CURRENT_BUILD=$(echo "$CURRENT_BUILD" | grep -o '[0-9]*' | head -1)
        if [ -z "$CURRENT_BUILD" ]; then
            CURRENT_BUILD=1
        fi
        log_info "Using numeric build number: $CURRENT_BUILD"
    fi
}

# Calculate new version using timestamp-based approach for uniqueness
calculate_new_version() {
    log_info "Calculating new build number..."
    
    # Generate timestamp-based build number (YYYYMMDDHHmm format)
    # This ensures uniqueness even with multiple builds per day
    local timestamp_build=$(date '+%Y%m%d%H%M')
    
    log_debug "Timestamp-based build: $timestamp_build"
    log_debug "Current build number: $CURRENT_BUILD"
    
    # Ensure new build is higher than current build
    if [ "$timestamp_build" -le "$CURRENT_BUILD" ]; then
        # If timestamp is not higher, use simple increment
        NEW_BUILD=$((CURRENT_BUILD + 1))
        log_warning "Timestamp build ($timestamp_build) not higher than current ($CURRENT_BUILD)"
        log_info "Using incremented approach: $NEW_BUILD"
    else
        NEW_BUILD=$timestamp_build
        log_info "Using timestamp-based build: $NEW_BUILD"
    fi
    
    log_success "New build number calculated: $NEW_BUILD"
    log_info "Version progression: $CURRENT_BUILD → $NEW_BUILD (+$((NEW_BUILD - CURRENT_BUILD)))"
}

# Update Info.plist with new version
update_info_plist() {
    log_info "Updating Info.plist with new build number..."
    
    # Create backup of Info.plist (safety measure)
    local backup_path="$INFO_PLIST_PATH.backup-$(date +%s)"
    cp "$INFO_PLIST_PATH" "$backup_path"
    log_debug "Created backup: $backup_path"
    
    # Update the bundle version
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD" "$INFO_PLIST_PATH"
    
    log_success "Info.plist updated with build number: $NEW_BUILD"
    log_debug "Updated file: $INFO_PLIST_PATH"
    
    # Clean up backup (keep only if something goes wrong)
    rm -f "$backup_path"
}

# Verify the update was successful
verify_update() {
    log_info "Verifying update..."
    
    # Read the updated value
    local updated_build=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$INFO_PLIST_PATH" 2>/dev/null)
    local updated_version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$INFO_PLIST_PATH" 2>/dev/null)
    
    if [ "$updated_build" = "$NEW_BUILD" ]; then
        log_success "Verification passed!"
        log_info "Final App Version: $updated_version"
        log_info "Final Build Number: $updated_build"
        log_info "File Location: $INFO_PLIST_PATH"
    else
        log_error "Verification failed!"
        log_error "Expected build number: $NEW_BUILD"
        log_error "Actual build number: $updated_build"
        log_error "File: $INFO_PLIST_PATH"
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
    echo "##vso[task.setvariable variable=infoPlistPath;isOutput=true]$INFO_PLIST_PATH"
    
    log_success "Pipeline variables set:"
    log_info "  - newBundleVersion: $NEW_BUILD"
    log_info "  - currentAppVersion: $CURRENT_VERSION"
    log_info "  - previousBundleVersion: $CURRENT_BUILD"
    log_info "  - infoPlistPath: $INFO_PLIST_PATH"
}

# Execute main function with all arguments
main "$@"