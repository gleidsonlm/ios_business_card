# Troubleshooting Guide for Fastlane TestFlight Deployment

This document provides solutions to common issues when using Fastlane for TestFlight deployment of the iOS Business Card app.

## Table of Contents

- [Setup Issues](#setup-issues)
- [Authentication Problems](#authentication-problems)
- [Build and Archive Issues](#build-and-archive-issues)
- [TestFlight Upload Problems](#testflight-upload-problems)
- [CI/CD Integration Issues](#cicd-integration-issues)
- [Environment and Configuration](#environment-and-configuration)

## Setup Issues

### 1. Fastlane Not Found

**Error:**
```
fastlane: command not found
```

**Solutions:**
```bash
# Install via Homebrew (recommended for macOS)
brew install fastlane

# Or install via RubyGems
sudo gem install fastlane

# For CI/CD environments
bundle install
bundle exec fastlane
```

### 2. Bundle/Gem Permission Errors

**Error:**
```
You don't have write permissions for the /var/lib/gems directory
```

**Solutions:**
```bash
# Use bundler to manage gems locally
gem install bundler --user-install
bundle install --path vendor/bundle

# Or use rbenv/rvm for Ruby version management
# This avoids system-wide gem installations
```

### 3. Ruby Version Issues

**Error:**
```
Your Ruby version is X.X.X, but your Gemfile specified Y.Y.Y
```

**Solutions:**
```bash
# Check Ruby version
ruby --version

# Install correct Ruby version (using rbenv)
rbenv install 3.2.0
rbenv global 3.2.0

# Or update Gemfile to match current Ruby version
```

## Authentication Problems

### 1. App Store Connect API Key Issues

**Error:**
```
App Store Connect API key not found
```

**Solutions:**

1. **Verify API Key Configuration:**
   ```bash
   # Check your .env file has all required values
   cat .env | grep APP_STORE_CONNECT
   ```

2. **Regenerate API Key:**
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Users and Access → API Keys
   - Create new key with "App Manager" role
   - Download .p8 file

3. **Correct Base64 Encoding:**
   ```bash
   # Convert .p8 file to base64
   base64 -i AuthKey_ABC123DEF4.p8 | pbcopy
   
   # Verify it starts with something like: LS0tLS1CRUdJTi...
   ```

### 2. Team ID Problems

**Error:**
```
Multiple teams found; please include the `team_id`
```

**Solutions:**

1. **Find Your Team ID:**
   ```bash
   # Using Fastlane
   fastlane spaceship list_teams
   
   # Or check Apple Developer Portal
   # developer.apple.com → Membership → Team ID
   ```

2. **Update Configuration:**
   ```bash
   # Add to .env file
   TEAM_ID=ABC123DEF4
   ITUNES_CONNECT_TEAM_ID=987654321  # If different
   ```

### 3. Two-Factor Authentication Issues

**Error:**
```
Please enter the 6 digit code from your phone
```

**Solutions:**
- Use App Store Connect API keys instead of username/password
- API keys bypass 2FA requirements
- See setup instructions in `fastlane/README.md`

## Build and Archive Issues

### 1. Code Signing Errors

**Error:**
```
Code signing error: No matching provisioning profile found
```

**Solutions:**

1. **Verify Certificate and Profile:**
   ```bash
   # Check available profiles
   security find-identity -v -p codesigning
   
   # List provisioning profiles
   fastlane match development --readonly
   ```

2. **Update Provisioning:**
   ```bash
   # Download latest profiles
   fastlane match appstore --readonly
   
   # Or create new ones
   fastlane match appstore
   ```

### 2. Archive Not Found

**Error:**
```
Archive not found at path: ./build/businesscard.xcarchive
```

**Solutions:**

1. **Check Build Path:**
   ```bash
   # Verify archive was created
   ls -la ./build/
   
   # Check xcodebuild output for actual path
   xcodebuild -showBuildSettings | grep ARCHIVE
   ```

2. **Fix Archive Command:**
   ```bash
   # Ensure proper scheme and configuration
   xcodebuild -list  # Check available schemes
   
   # Use correct scheme name
   xcodebuild -scheme businesscard -configuration Release archive
   ```

## TestFlight Upload Problems

### 1. IPA Upload Timeout

**Error:**
```
Timeout while uploading to TestFlight
```

**Solutions:**

1. **Use Skip Wait Option:**
   ```bash
   fastlane deploy_to_testflight \
     ipa_path:"/path/to/app.ipa" \
     skip_waiting_for_build_processing:true
   ```

2. **Check Network Connection:**
   ```bash
   # Test upload speed
   speedtest-cli
   
   # Use cellular/different network if WiFi is slow
   ```

3. **Retry with Smaller IPA:**
   ```bash
   # Check IPA size
   ls -lh /path/to/app.ipa
   
   # Optimize app size if > 200MB
   ```

### 2. Build Processing Failed

**Error:**
```
Build processing failed on App Store Connect
```

**Solutions:**

1. **Check App Store Connect:**
   - Go to App Store Connect → TestFlight
   - Look for processing errors
   - Check email for detailed error reports

2. **Common Processing Issues:**
   - Missing Privacy Manifest (`PrivacyInfo.xcprivacy`)
   - Invalid bundle identifier
   - Unsigned frameworks or libraries
   - Missing required device capabilities

3. **Fix Privacy Issues:**
   ```bash
   # Verify Privacy Manifest exists
   find . -name "PrivacyInfo.xcprivacy"
   
   # Check content matches app usage
   ```

### 3. TestFlight Group Not Found

**Error:**
```
TestFlight group 'GroupName' not found
```

**Solutions:**

1. **Check Group Names:**
   - Go to App Store Connect → TestFlight → Internal/External Groups
   - Use exact group names (case-sensitive)

2. **Create Missing Groups:**
   ```bash
   # List existing groups first
   fastlane pilot list_groups
   
   # Create new group if needed
   fastlane pilot add_group group_name:"New Testers"
   ```

## CI/CD Integration Issues

### 1. GitHub Actions Failures

**Error:**
```
Environment variable not available in CI
```

**Solutions:**

1. **Set Repository Secrets:**
   - Go to Repository → Settings → Secrets and Variables → Actions
   - Add all required secrets from `.env.example`

2. **Check Secret Names:**
   ```yaml
   # Ensure names match exactly
   APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
   ```

3. **Debug Environment:**
   ```yaml
   - name: Debug Environment
     run: |
       echo "Checking environment variables..."
       env | grep -E "(APP_STORE|TEAM_ID)" | sed 's/=.*/=***/'
   ```

### 2. macOS Runner Issues

**Error:**
```
Xcode not found on runner
```

**Solutions:**

1. **Use Correct Runner:**
   ```yaml
   runs-on: macos-14  # or macos-13, macos-12
   ```

2. **Install Xcode:**
   ```yaml
   - name: Setup Xcode
     uses: maxim-lobanov/setup-xcode@v1
     with:
       xcode-version: '15.0'
   ```

### 3. Git Issues in CI

**Error:**
```
Git repository is dirty
```

**Solutions:**

1. **Skip Git Check:**
   ```yaml
   env:
     SKIP_GIT_CHECK: true
   ```

2. **Clean Repository:**
   ```yaml
   - name: Clean git
     run: git clean -fdx
   ```

## Environment and Configuration

### 1. Missing Environment Variables

**Error:**
```
Environment variable APP_IDENTIFIER not set
```

**Solutions:**

1. **Copy Template:**
   ```bash
   cp .env.example .env
   cp fastlane/.env.example fastlane/.env
   ```

2. **Validate Configuration:**
   ```bash
   ./scripts/validate-fastlane-setup.sh
   ```

3. **Check Variable Loading:**
   ```bash
   # Test if variables are loaded
   source .env
   echo $APP_IDENTIFIER
   ```

### 2. Fastfile Syntax Errors

**Error:**
```
Syntax error in Fastfile
```

**Solutions:**

1. **Check Syntax:**
   ```bash
   ruby -c fastlane/Fastfile
   ruby -c fastlane/Appfile
   ```

2. **Validate Fastlane:**
   ```bash
   fastlane validate_testflight_setup
   ```

### 3. Dependency Conflicts

**Error:**
```
Gem version conflicts
```

**Solutions:**

1. **Clean Dependencies:**
   ```bash
   rm -rf vendor/bundle Gemfile.lock
   bundle install
   ```

2. **Update Fastlane:**
   ```bash
   bundle update fastlane
   ```

## Getting Help

### 1. Enable Debug Mode

```bash
# Run with verbose output
fastlane deploy_to_testflight ipa_path:"/path/to/app.ipa" --verbose

# Or with debug level
FASTLANE_DEBUG=1 fastlane deploy_to_testflight ipa_path:"/path/to/app.ipa"
```

### 2. Check Logs

```bash
# Fastlane logs
cat fastlane/report.xml

# System logs (macOS)
log show --predicate 'process == "Xcode"' --last 1h
```

### 3. Validation Tools

```bash
# Run our validation script
./scripts/validate-fastlane-setup.sh

# Test deployment configuration
fastlane test_deployment

# Validate TestFlight setup
fastlane validate_testflight_setup
```

### 4. Community Resources

- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Fastlane GitHub Issues](https://github.com/fastlane/fastlane/issues)
- [Apple Developer Forums](https://developer.apple.com/forums/)
- [Stack Overflow - Fastlane Tag](https://stackoverflow.com/questions/tagged/fastlane)

### 5. Project-Specific Help

For issues specific to this iOS Business Card app:

1. Open a GitHub issue with:
   - Error message and full logs
   - Output from `./scripts/validate-fastlane-setup.sh`
   - Environment details (OS, Xcode version, etc.)

2. Include relevant configuration (with credentials removed):
   ```bash
   # Safe configuration dump
   cat fastlane/Fastfile | head -20
   cat .env.example
   ```

---

**Note:** Always remove sensitive information (API keys, passwords, team IDs) when sharing configuration for troubleshooting.