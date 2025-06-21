# iOS Business Card App

This project is an iOS application intended to serve as a digital business card. It will eventually feature a tree-link style interface and a QR code for sharing vCard information.

## Current Status

The project has been initialized with a basic "Hello, World!" application. Key characteristics of the current setup include:

*   **SwiftUI**: The user interface is built using SwiftUI.
*   **MVVM Architecture**: The Model-View-ViewModel architectural pattern is being followed.
    *   `Views/HelloWorldView.swift`: Displays the UI.
    *   `ViewModels/HelloWorldViewModel.swift`: Manages the data and logic for the view.
*   **SwiftLint**: Code linting is set up to ensure code quality and adherence to Swift best practices.
    *   A `.swiftlint.yml` configuration file is included in the project root.
    *   Manual steps for integrating SwiftLint into the Xcode build process are documented in `MANUAL_SWIFTLINT_SETUP.md`.

## SwiftLint Setup (Important for macOS 12 Users)

The latest versions of SwiftLint (typically installed via Homebrew) require macOS Ventura (13.0) or newer. If you are using macOS 12 (Monterey) or older, you will encounter issues installing SwiftLint via the standard Homebrew command.

Please refer to `MANUAL_SWIFTLINT_SETUP.md` for detailed instructions, which include:
*   Standard SwiftLint installation for compatible macOS versions.
*   Alternative installation methods for macOS 12 (Monterey) and older, such as:
    *   Installing an older, compatible version of SwiftLint.
    *   Building a specific compatible version from source.
*   Steps to integrate SwiftLint into your Xcode project's build phases.

## Project Structure

```
ios_business_card/
├── .swiftlint.yml
├── businesscard/
│   ├── Views/
│   │   └── HelloWorldView.swift
│   ├── ViewModels/
│   │   └── HelloWorldViewModel.swift
│   ├── Models/                   # Placeholder for future models
│   ├── Resources/                # Placeholder for future resources (e.g., images, colors)
│   ├── Assets.xcassets/          # App icons, accent colors, etc.
│   ├── Preview Content/
│   ├── businesscardApp.swift     # Main application entry point
│   └── businesscard.entitlements
├── businesscard.xcodeproj/
├── LICENSE
├── MANUAL_SWIFTLINT_SETUP.md     # SwiftLint setup instructions
└── README.md                     # This file
```

## Next Steps

Future development will focus on:
*   Designing and implementing the main business card UI.
*   Adding functionality for managing and displaying multiple links (tree-link style).
*   Generating and displaying a QR code for vCard export.

## Contributing

Details on contributing will be added as the project progresses. For now, ensure any code contributions adhere to the SwiftLint rules defined in `.swiftlint.yml`.
