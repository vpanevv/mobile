# WaterTracker

`WaterTracker` is a simple native iOS app for a first TestFlight release.

It focuses on one job:

- log water quickly
- track progress toward a daily goal
- keep today history visible
- persist data locally between launches

## Project

Open the [WaterTracker Xcode project](/Users/panev/panev-ios/mobile/WaterTracker/WaterTracker.xcodeproj) and run the `WaterTracker` scheme.

The app source lives under [WaterTracker](/Users/panev/panev-ios/mobile/WaterTracker/WaterTracker).

## Build

```bash
xcodebuild -project /Users/panev/panev-ios/mobile/WaterTracker/WaterTracker.xcodeproj -scheme WaterTracker -sdk iphoneos -derivedDataPath /tmp/WaterTrackerDerived CODE_SIGNING_ALLOWED=NO build
```

## Notes

In this environment, `xcodebuild` is currently blocked at the asset compilation stage by an unavailable CoreSimulator service, but the Swift source files typecheck successfully with:

```bash
swiftc -typecheck -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.4.sdk -target arm64-apple-ios17.0 /Users/panev/panev-ios/mobile/WaterTracker/WaterTracker/WaterTrackerApp.swift /Users/panev/panev-ios/mobile/WaterTracker/WaterTracker/Models/HydrationEntry.swift /Users/panev/panev-ios/mobile/WaterTracker/WaterTracker/Stores/HydrationStore.swift /Users/panev/panev-ios/mobile/WaterTracker/WaterTracker/Views/ProgressRing.swift /Users/panev/panev-ios/mobile/WaterTracker/WaterTracker/Views/ContentView.swift /Users/panev/panev-ios/mobile/WaterTracker/WaterTracker/Views/OnboardingView.swift
```
