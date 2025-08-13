# iOS Business Card App

An iOS application for managing business card information, built with SwiftUI and SwiftData.

## Features

- Local data storage using SwiftData
- List management for business card items
- Cross-platform support (iOS and macOS)
- Sandbox security model

## Privacy and Data Handling

This app takes user privacy seriously and follows Apple's App Store guidelines. A Privacy Manifest file (`PrivacyInfo.xcprivacy`) is included in the app bundle to provide transparency about data usage.

### Privacy Manifest Location

The Privacy Manifest file is located at:
```
businesscard/businesscard/PrivacyInfo.xcprivacy
```

### Current Privacy Impact

The app currently has minimal privacy impact:

**Data Collection:**
- No personal data is collected or transmitted to external servers
- All data is stored locally on the device using SwiftData

**System API Usage:**
- **File Timestamp APIs**: Used by SwiftData for local persistence (reason: C617.1)
- **User Defaults APIs**: Used by the system for app preferences and settings (reason: CA92.1) 
- **Disk Space APIs**: Used by SwiftData to manage local storage (reason: E174.1)

**Tracking:**
- No user tracking is performed
- No analytics or advertising SDKs are integrated

### Sandbox Entitlements

The app operates within Apple's App Sandbox with the following permissions:
- **App Sandbox**: Enabled for security
- **User Selected Files (Read-Only)**: Allows reading files selected by the user

### Future Privacy Considerations

As the app evolves to include business card features, the Privacy Manifest will be updated to reflect:
- Camera access (for QR code scanning)
- Contacts access (for importing/exporting business cards)
- Network access (if cloud sync features are added)
- Any third-party SDK integrations (e.g., Appdome protection)

## Development

### Requirements

- macOS with Xcode 15.0+
- iOS 17.6+ deployment target
- Swift 5.0+

### Building

See `BUILD.md` for detailed build instructions.

### Testing

The app includes both unit tests and UI tests. Run tests from Xcode or use the command line as documented in `BUILD.md`.

## Compliance

- **App Store Ready**: Includes required Privacy Manifest file
- **Privacy Compliant**: Follows Apple's privacy guidelines
- **Sandbox Compatible**: Operates within security constraints

## Version History

- **v1.1 (Build 2)**: Added Privacy Manifest file for App Store compliance
- **v1.0 (Build 1)**: Initial release with basic list management

## License

This project is licensed under the GNU Affero General Public License v3.0. See `LICENSE` for details.

## Support

For issues or questions, please open a GitHub issue or contact the project maintainer.