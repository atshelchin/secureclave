# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI-based iOS/macOS application that uses SwiftData for persistence. The app is built using Xcode and follows Apple's modern SwiftUI architecture patterns.

## Development Commands

### Building
```bash
# Build the main app
xcodebuild -scheme secureenclave -configuration Debug build

# Build for release
xcodebuild -scheme secureenclave -configuration Release build
```

### Testing
```bash
# Run unit tests
xcodebuild -scheme secureenclave test

# Run specific test target
xcodebuild -scheme secureenclave -only-testing:secureenclaveTests test

# Run UI tests
xcodebuild -scheme secureenclave -only-testing:secureenclaveUITests test
```

### Clean Build
```bash
xcodebuild -scheme secureenclave clean
```

## Architecture

The application follows a standard SwiftUI + SwiftData architecture:

- **secureenclaveApp.swift**: Main app entry point that sets up the SwiftData ModelContainer
- **ContentView.swift**: Primary view with navigation split view pattern, handles CRUD operations for items
- **Item.swift**: SwiftData model representing the core data entity with timestamp property
- **Testing**: Uses Swift Testing framework (not XCTest) with the modern @Test macro syntax

## Key Technologies

- **SwiftUI**: Declarative UI framework
- **SwiftData**: Modern persistence framework using @Model and ModelContainer
- **Swift Testing**: Modern testing framework using @Test attributes
- **NavigationSplitView**: iPad/Mac-optimized navigation pattern

## Important Notes

- The app uses SwiftData's ModelContainer for persistence (not Core Data)
- Tests use the Swift Testing framework with @Test attributes, not XCTest
- The project is configured for remote notifications (see Info.plist)
- No Swift Package Manager file exists - dependencies are managed through Xcode project