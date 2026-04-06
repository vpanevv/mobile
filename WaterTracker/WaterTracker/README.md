# WaterTracker

Simple native iOS water intake tracking for a first TestFlight launch.

## V1 Scope

- Quick add buttons for common drink sizes
- Custom amount entry
- Daily progress ring
- Adjustable daily goal
- Local persistence with `UserDefaults`
- Same-day history and reset action

## Build

```bash
xcodebuild -project /Users/panev/panev-ios/mobile/WaterTracker/WaterTracker.xcodeproj -destination 'generic/platform=iOS' -scheme WaterTracker -derivedDataPath /tmp/WaterTrackerDerived CODE_SIGNING_ALLOWED=NO build
```
