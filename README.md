# iOS Business Card App

This project is an iOS application intended to serve as a digital business card. It will eventually feature a tree-link style interface and a QR code for sharing vCard information.

## Current Status

The project has been initialized with a basic "Hello, World!" application. Key characteristics of the current setup include:

*   **SwiftUI**: The user interface is built using SwiftUI.
*   **MVVM Architecture**: The Model-View-ViewModel architectural pattern is being followed.
    *   `Views/HelloWorldView.swift`: Displays the UI.
    *   `ViewModels/HelloWorldViewModel.swift`: Manages the data and logic for the view.
*   **Coding Standards**: We aim to follow Swift best practices and maintain clean, readable code.

## Project Structure

```
ios_business_card/
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
└── README.md                     # This file
```

## Next Steps

Future development will focus on:
*   Designing and implementing the main business card UI.
*   Adding functionality for managing and displaying multiple links (tree-link style).
*   Generating and displaying a QR code for vCard export.

## Contributing

Details on contributing will be added as the project progresses. Please ensure any code contributions adhere to Swift best practices and aim for clarity and maintainability.
