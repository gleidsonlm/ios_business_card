#!/bin/bash

# Fastlane Setup Validation Script for iOS Business Card App
# This script helps validate your Fastlane configuration before deployment

set -e

echo "🔍 Validating Fastlane Setup for iOS Business Card App"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

# Check prerequisites
echo "Checking prerequisites..."

# Check if running on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status 0 "Running on macOS"
else
    print_status 1 "Not running on macOS (required for iOS deployment)"
    echo "This script is for macOS systems with Xcode. For CI/CD, ensure your runners use macOS."
fi

# Check for Xcode
if command_exists xcodebuild; then
    XCODE_VERSION=$(xcodebuild -version | head -n 1)
    print_status 0 "Xcode installed: $XCODE_VERSION"
else
    print_status 1 "Xcode not found"
fi

# Check for Ruby
if command_exists ruby; then
    RUBY_VERSION=$(ruby --version)
    print_status 0 "Ruby installed: $RUBY_VERSION"
else
    print_status 1 "Ruby not found"
fi

# Check for Fastlane
if command_exists fastlane; then
    FASTLANE_VERSION=$(fastlane --version | head -n 1)
    print_status 0 "Fastlane installed: $FASTLANE_VERSION"
else
    print_status 1 "Fastlane not found"
    echo "Install with: brew install fastlane"
fi

# Check for Bundle
if command_exists bundle; then
    print_status 0 "Bundle installed"
else
    print_status 1 "Bundle not found"
    echo "Install with: gem install bundler"
fi

echo ""
echo "Checking configuration files..."

# Check for Gemfile
if [ -f "Gemfile" ]; then
    print_status 0 "Gemfile exists"
else
    print_status 1 "Gemfile not found"
fi

# Check for Fastfile
if [ -f "fastlane/Fastfile" ]; then
    print_status 0 "Fastfile exists"
else
    print_status 1 "Fastfile not found"
fi

# Check for Appfile
if [ -f "fastlane/Appfile" ]; then
    print_status 0 "Appfile exists"
else
    print_status 1 "Appfile not found"
fi

# Check for environment files
if [ -f ".env.example" ]; then
    print_status 0 ".env.example template exists"
else
    print_status 1 ".env.example template not found"
fi

if [ -f ".env" ]; then
    print_status 0 ".env file exists"
    echo "   📝 Remember to configure your actual values in .env"
else
    print_warning ".env file not found"
    echo "   📝 Copy .env.example to .env and configure your values"
fi

# Check Xcode project
if [ -f "businesscard/businesscard.xcodeproj/project.pbxproj" ]; then
    print_status 0 "Xcode project found"
else
    print_status 1 "Xcode project not found at expected location"
fi

echo ""
echo "Checking environment variables..."

# Check critical environment variables
if [ -n "$APP_STORE_CONNECT_API_KEY_ID" ]; then
    print_status 0 "APP_STORE_CONNECT_API_KEY_ID is set"
else
    print_warning "APP_STORE_CONNECT_API_KEY_ID not set"
fi

if [ -n "$APP_STORE_CONNECT_ISSUER_ID" ]; then
    print_status 0 "APP_STORE_CONNECT_ISSUER_ID is set"
else
    print_warning "APP_STORE_CONNECT_ISSUER_ID not set"
fi

if [ -n "$APP_STORE_CONNECT_API_KEY_CONTENT" ]; then
    print_status 0 "APP_STORE_CONNECT_API_KEY_CONTENT is set"
else
    print_warning "APP_STORE_CONNECT_API_KEY_CONTENT not set"
fi

if [ -n "$TEAM_ID" ]; then
    print_status 0 "TEAM_ID is set"
else
    print_warning "TEAM_ID not set"
fi

if [ -n "$APP_IDENTIFIER" ]; then
    print_status 0 "APP_IDENTIFIER is set"
else
    print_warning "APP_IDENTIFIER not set"
fi

echo ""
echo "Running Fastlane validation..."

# Try to run Fastlane validation if available
if command_exists fastlane && [ -f "fastlane/Fastfile" ]; then
    echo "Running fastlane validate_testflight_setup..."
    if fastlane validate_testflight_setup 2>/dev/null; then
        print_status 0 "Fastlane validation passed"
    else
        print_status 1 "Fastlane validation failed"
        echo "   Run 'fastlane validate_testflight_setup' for detailed output"
    fi
else
    print_warning "Cannot run Fastlane validation (Fastlane or Fastfile not available)"
fi

echo ""
echo "📋 Summary and Next Steps:"
echo "========================="

if [ ! -f ".env" ]; then
    echo "1. Copy .env.example to .env and configure your App Store Connect credentials"
fi

if ! command_exists fastlane; then
    echo "2. Install Fastlane: brew install fastlane"
fi

if [ -f "Gemfile" ] && command_exists bundle; then
    echo "3. Install Ruby dependencies: bundle install"
fi

echo "4. Test your configuration: fastlane test_deployment"
echo "5. Deploy to TestFlight: fastlane deploy_to_testflight ipa_path:/path/to/your.ipa"

echo ""
echo "📖 For detailed setup instructions, see: fastlane/README.md"

echo ""
echo "✅ Validation complete!"