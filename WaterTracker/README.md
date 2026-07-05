# Gym Cut Tracker

`Gym Cut Tracker` is a premium dark-mode SwiftUI MVP for tracking a 3-day cutting-phase gym program.

It focuses on:

- Monday / Wednesday / Friday workout setup seeded from the uploaded screenshots
- editable exercises with sets, target reps, rest, muscle group, and notes
- session tracking for weight, reps, RPE, completion, and notes
- workout history, exercise progress, recommendations, and body weight check-ins
- local persistence between launches

## Project

Open the [Xcode project](/Users/panev/panev-ios/mobile/WaterTracker/WaterTracker.xcodeproj) and run the `WaterTracker` scheme. The app display name and product name are `Gym Cut Tracker`.

The app source lives under [WaterTracker](/Users/panev/panev-ios/mobile/WaterTracker/WaterTracker).

## Build

```bash
xcodebuild -project /Users/panev/panev-ios/mobile/WaterTracker/WaterTracker.xcodeproj -scheme WaterTracker -sdk iphoneos -derivedDataPath /tmp/WaterTrackerDerived CODE_SIGNING_ALLOWED=NO build
```

## Notes

In this environment, `xcodebuild` is currently blocked at the asset compilation stage by an unavailable CoreSimulator service, but the Swift source files typecheck successfully with:

```bash
swiftc -typecheck -sdk "$(xcrun --sdk iphoneos --show-sdk-path)" -target arm64-apple-ios17.0 /Users/panev/panev-ios/mobile/WaterTracker/WaterTracker/WaterTrackerApp.swift /Users/panev/panev-ios/mobile/WaterTracker/WaterTracker/Models/FitnessModels.swift /Users/panev/panev-ios/mobile/WaterTracker/WaterTracker/Stores/FitnessStore.swift /Users/panev/panev-ios/mobile/WaterTracker/WaterTracker/Views/ContentView.swift /Users/panev/panev-ios/mobile/WaterTracker/WaterTracker/Views/OnboardingView.swift
```
