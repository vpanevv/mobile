# TimeMap

TimeMap is a SwiftUI world clock and timezone explorer for iPhone and iPad.

It helps users anchor themselves in their own local time, search for cities around the world, compare timezone differences instantly, and tap an interactive map to discover time visually.

## Product Focus

- Persistent local time that always stays prominent
- Fast city search with timezone-aware results
- Human-friendly time difference comparisons
- Map-based exploration of global time
- Premium, native-feeling visual design

## Core Experience

1. Launch TimeMap and immediately see your local time, date, place, and timezone.
2. Search for a city to compare its current time with your own.
3. View a polished detail card with flag, location, time, timezone, and comparison text.
4. Switch to the map and tap anywhere to resolve the nearest meaningful place.
5. Compare time across locations without losing sight of your own clock.

## Architecture

- `App`: app entry and dependency container
- `Models`: world location, search result, local time, and selection state
- `ViewModels`: main `TimeMapViewModel`
- `Views`: home shell and map experience
- `Components`: reusable hero cards, search field, result rows, and state cards
- `Services`: time formatting, ticking, search, reverse geocoding, and user location
- `Theme`: shared palette, surfaces, and visual styling primitives
- `Utilities`: helpers such as country flag generation

## Tech

- SwiftUI
- MapKit
- CoreLocation
- Apple-native date and timezone APIs
- MVVM

## Running The App

Open [`/Users/panev/panev-ios/mobile/TimeMap/TimeMap.xcodeproj`](/Users/panev/panev-ios/mobile/TimeMap/TimeMap.xcodeproj) in Xcode and run the `TimeMap` target.

For CLI verification, this build command succeeds without code signing:

```bash
xcodebuild -project /Users/panev/panev-ios/mobile/TimeMap/TimeMap.xcodeproj -scheme TimeMap -destination 'generic/platform=iOS' -derivedDataPath /tmp/TimeMapDerived CODE_SIGNING_ALLOWED=NO build
```
