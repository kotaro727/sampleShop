# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SwiftUI-based iOS shopping application using modern iOS 16+ navigation and state management patterns.

## Build and Test Commands

```bash
# Build the app
xcodebuild -scheme sampleShop -project sampleShop.xcodeproj build

# Run tests
xcodebuild -scheme sampleShop -project sampleShop.xcodeproj test

# Run specific test
xcodebuild -scheme sampleShop -project sampleShop.xcodeproj -only-testing:sampleShopTests/<TestClassName>/<testMethodName> test

# Run UI tests
xcodebuild -scheme sampleShop -project sampleShop.xcodeproj -only-testing:sampleShopUITests test
```

## Architecture

### State Management Pattern

The app uses SwiftUI's ObservableObject pattern for shared state:

1. **Cart (ObservableObject)**: Global shopping cart state managed as `ObservableObject`
   - Created with `@StateObject` in `sampleShopApp.swift:13`
   - Injected via `.environmentObject(cart)` at app root (`sampleShopApp.swift:18`)
   - Accessed with `@EnvironmentObject` in child views (e.g., `ProductDetailView.swift:5`)
   - Uses `@Published` for reactive properties that trigger view updates

This pattern ensures a single source of truth for cart data accessible throughout the view hierarchy.

### Navigation

Uses `NavigationStack` (iOS 16+) for type-safe navigation between ContentView (product list) and ProductDetailView (details).

### Data Layer

- **Models**: Simple structs in `Model/` directory (`Product`, `Cart`)
- **Sample Data**: Hardcoded `sampleProducts` array in `Model/Product.swift:17`
- **Core Data**: `Persistence.swift` exists but is currently unused (legacy from Xcode template)

### Project Structure

```
sampleShop/
├── sampleShopApp.swift          # App entry point, creates Cart @StateObject
├── ContentView.swift            # Product list with NavigationStack
├── Views/
│   └── ProductDetailView.swift  # Product detail, accesses Cart via @EnvironmentObject
├── Model/
│   ├── Product.swift           # Product model + sample data
│   └── Cart.swift              # Cart ObservableObject with @Published items
└── Persistence.swift           # Unused Core Data setup
```

## Key Patterns

When adding new shared state:
1. Create an `ObservableObject` class with `@Published` properties
2. Initialize as `@StateObject` in `sampleShopApp.swift`
3. Inject via `.environmentObject()` at appropriate level
4. Access with `@EnvironmentObject` in views that need it
