# Copilot Instructions for iOS Business Card App

## Repository Overview

This repository contains an iOS application written in Swift using SwiftUI and SwiftData. The app is designed as a business card application but currently implements basic list management functionality with timestamped items. The project was created on August 13, 2025, by Gleidson L Medeiros and follows standard iOS development patterns.

**Repository Details:**
- **Project Type:** iOS Native Application 
- **Language:** Swift 5.0+
- **Framework:** SwiftUI with SwiftData persistence
- **Target Platform:** iOS (with macOS sandbox entitlements)
- **Project Size:** Small (~6 Swift files, standard iOS template structure)
- **Architecture:** MVVM with SwiftUI and declarative data management

## Build and Development Requirements

### Prerequisites
**Always ensure these requirements before starting development:**
- macOS development environment (required for iOS development)
- Xcode 15.0+ installed with iOS SDK
- Xcode Command Line Tools: `xcode-select --install`

### Build Instructions

**Important:** This is an iOS project that requires Xcode. All build commands must be run on macOS.

#### Building the Project
```bash
# Navigate to the project directory
cd businesscard

# Build for iOS Simulator (fastest for development)
xcodebuild -project businesscard.xcodeproj -scheme businesscard -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' build

# Build for iOS device (requires provisioning profile)
xcodebuild -project businesscard.xcodeproj -scheme businesscard -destination 'generic/platform=iOS' build
```

#### Running Tests
**Always run tests in this order:**
```bash
# Run unit tests first
xcodebuild test -project businesscard.xcodeproj -scheme businesscard -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' -only-testing:businesscardTests

# Run UI tests (takes longer, ~2-3 minutes)
xcodebuild test -project businesscard.xcodeproj -scheme businesscard -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' -only-testing:businesscardUITests
```

#### Development Workflow
```bash
# Open in Xcode for development (recommended)
open businesscard/businesscard.xcodeproj

# Or build and run in simulator from command line
xcodebuild -project businesscard.xcodeproj -scheme businesscard -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' -configuration Debug
```

### Common Issues and Workarounds
- **Build timeout:** iOS builds can take 5-10 minutes on slower machines
- **Simulator not found:** Use `xcrun simctl list devices` to find available simulators
- **Provisioning errors:** For device builds, ensure valid Apple Developer account and certificates
- **SwiftData issues:** Clean build folder (`Product → Clean Build Folder` in Xcode) if data model changes cause issues

## Project Architecture and Layout

### Directory Structure
```
/
├── .github/                    # GitHub configuration (you are here)
├── .gitignore                  # Xcode and iOS specific ignores
├── LICENSE                     # GNU Affero General Public License v3.0
└── businesscard/               # Main Xcode project directory
    ├── businesscard.xcodeproj/ # Xcode project file
    ├── businesscard/           # Main app source code
    │   ├── businesscardApp.swift      # App entry point (@main)
    │   ├── ContentView.swift          # Main UI view
    │   ├── Item.swift                 # SwiftData model
    │   ├── Assets.xcassets/           # App icons and assets
    │   └── businesscard.entitlements  # App capabilities (sandbox)
    ├── businesscardTests/      # Unit tests
    │   └── businesscardTests.swift    # Basic test structure
    └── businesscardUITests/    # UI automation tests
        ├── businesscardUITests.swift         # UI test cases
        └── businesscardUITestsLaunchTests.swift # Launch performance tests
```

### Key Components

**Main App (`businesscardApp.swift`):**
- Entry point using `@main` attribute
- Configures SwiftData ModelContainer with `Item` schema
- Sets up in-memory storage option for previews

**Content View (`ContentView.swift`):**
- NavigationSplitView with master-detail layout
- List management with add/delete functionality
- SwiftData `@Query` for reactive data binding
- Platform-specific UI adjustments (`#if os(macOS)`, `#if os(iOS)`)

**Data Model (`Item.swift`):**
- Simple SwiftData `@Model` with timestamp property
- Used for demonstration purposes (to be replaced with business card data)

### App Capabilities and Constraints
- **Sandbox Enabled:** App runs in sandbox environment with restricted file access
- **File Access:** Read-only access to user-selected files only
- **Platform Support:** Configured for iOS with macOS compatibility
- **Persistence:** Uses SwiftData for local storage (SQLite under the hood)

### Development Guidelines

**Code Style:**
- Follow Swift naming conventions (camelCase for properties, PascalCase for types)
- Use SwiftUI declarative patterns
- Leverage SwiftData for persistence rather than Core Data
- Maintain platform-specific conditional compilation where needed

**Testing:**
- Unit tests use new Swift Testing framework (`import Testing`)
- UI tests use XCTest framework with `XCUIApplication`
- Launch performance tests measure app startup time

**Key Dependencies:**
- SwiftUI (declarative UI framework)
- SwiftData (declarative data persistence)
- XCTest (testing framework)
- No external package dependencies currently

### Important Notes for Coding Agents

1. **Always use Xcode project:** This is not a command-line Swift project. Always work with the `.xcodeproj` file.

2. **SwiftData over Core Data:** The project uses SwiftData (new declarative approach) rather than Core Data. Maintain this pattern.

3. **Platform conditionals:** Preserve existing `#if os(iOS)` and `#if os(macOS)` conditionals for cross-platform compatibility.

4. **Sandbox compliance:** Any file operations must respect the sandbox entitlements defined in `businesscard.entitlements`.

5. **Trust these instructions:** Only search for additional information if these instructions are incomplete or incorrect. This will minimize exploration time and reduce command failures.

**When making changes:**
- Always build and test on iOS Simulator first
- Ensure SwiftData model changes are backward compatible
- Maintain existing navigation patterns (NavigationSplitView)
- Preserve accessibility and platform-specific UI adaptations