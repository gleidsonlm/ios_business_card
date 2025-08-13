# Build & Archive Guide for iOS Business Card App

This guide provides step-by-step instructions for building, running, testing, and exporting the iOS Business Card app. Follow these instructions for both local development and distribution builds.

---

## Prerequisites

- **macOS**: Required for iOS development.
- **Xcode 15.0+**: Install from the Mac App Store.
- **Xcode Command Line Tools**:  
  Run in Terminal:  
  ```bash
  xcode-select --install
  ```

---

## Building & Running the App

### 1. **Open the Project in Xcode**
- Double-click `businesscard.xcodeproj` inside the `businesscard/` directory.
- Choose your target device or simulator (e.g., iPhone 15).

### 2. **Build and Run in Simulator**
- Press <kbd>Cmd</kbd> + <kbd>R</kbd> or click the ▶️ Run button.
- The app will launch in the selected simulator.

### 3. **Build from Terminal (Advanced)**
```bash
cd businesscard
xcodebuild -project businesscard.xcodeproj -scheme businesscard -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' build
```

---

## Running Tests

### 1. **Unit Tests**
```bash
xcodebuild test -project businesscard.xcodeproj -scheme businesscard -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' -only-testing:businesscardTests
```

### 2. **UI Tests**
```bash
xcodebuild test -project businesscard.xcodeproj -scheme businesscard -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' -only-testing:businesscardUITests
```

---

## Exporting an .ipa Installation File

> **Note:** You need a valid Apple Developer account and provisioning profile to export for physical devices.

### 1. **Archive in Xcode GUI**
- In Xcode, select a physical device as target.
- Go to `Product` → `Archive`.
- When finished, Xcode Organizer will open.
- Click "Distribute App" → choose method (Ad Hoc, App Store, etc.) → export `.ipa`.

### 2. **Archive & Export via Terminal**
```bash
# Archive
xcodebuild -scheme businesscard -configuration Release -archivePath ./build/businesscard.xcarchive archive

# Export .ipa (requires ExportOptions.plist, see below)
xcodebuild -exportArchive -archivePath ./build/businesscard.xcarchive -exportPath ./build/ipa -exportOptionsPlist ExportOptions.plist
```

#### Sample `ExportOptions.plist` for Ad-Hoc Distribution
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>ad-hoc</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>stripSwiftSymbols</key>
    <true/>
</dict>
</plist>
```

---

## Troubleshooting

- **Provisioning Errors:**  
  Check your Apple Developer account, certificates, and profiles.
- **Simulator Not Found:**  
  Run `xcrun simctl list devices` to see available simulators.
- **Build Failures:**  
  Try "Product → Clean Build Folder" in Xcode (<kbd>Shift</kbd> + <kbd>Cmd</kbd> + <kbd>K</kbd>).
- **SwiftData Issues:**  
  Ensure model changes are compatible. Clean and rebuild if errors occur.

---

## Versioning

- Remember to increment your project version in `businesscard.xcodeproj` after major changes.
- Document any build or setup changes in this file.

---

## Additional Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Xcode Help](https://developer.apple.com/xcode/)

---

_Support: If you have any issues, open a GitHub issue or contact the project maintainer._