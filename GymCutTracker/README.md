# Gym Cut Tracker

`Gym Cut Tracker` is a premium dark-mode SwiftUI MVP for tracking a 3-day cutting-phase gym program.

It focuses on:

- Monday / Wednesday / Friday workout setup seeded from the uploaded screenshots
- editable exercises with sets, target reps, rest, muscle group, and notes
- session tracking for weight, reps, RPE, completion, and notes
- workout history, exercise progress, recommendations, and body weight check-ins
- weekly and monthly calendar activity with completion percentages
- session photos and shareable workout cards for completed sessions
- local persistence between launches

## Project

Open the [Xcode project](/Users/panev/panev-ios/mobile/GymCutTracker/GymCutTracker.xcodeproj) and run the `Gym Cut Tracker` scheme.

The app source lives under [GymCutTracker](/Users/panev/panev-ios/mobile/GymCutTracker/GymCutTracker).

## Build

```bash
xcodebuild -project /Users/panev/panev-ios/mobile/GymCutTracker/GymCutTracker.xcodeproj -scheme "Gym Cut Tracker" -sdk iphoneos -derivedDataPath /tmp/GymCutTrackerDerived CODE_SIGNING_ALLOWED=NO build
```

## Notes

In this environment, `xcodebuild` is currently blocked at the asset compilation stage by an unavailable CoreSimulator service, but the Swift source files typecheck successfully with:

```bash
swiftc -typecheck -sdk "$(xcrun --sdk iphoneos --show-sdk-path)" -target arm64-apple-ios17.0 /Users/panev/panev-ios/mobile/GymCutTracker/GymCutTracker/GymCutTrackerApp.swift /Users/panev/panev-ios/mobile/GymCutTracker/GymCutTracker/Models/FitnessModels.swift /Users/panev/panev-ios/mobile/GymCutTracker/GymCutTracker/Stores/FitnessStore.swift /Users/panev/panev-ios/mobile/GymCutTracker/GymCutTracker/Views/ContentView.swift /Users/panev/panev-ios/mobile/GymCutTracker/GymCutTracker/Views/OnboardingView.swift
```
