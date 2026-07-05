# Gym Cut Tracker

Premium native iOS fitness notebook for tracking a Monday / Wednesday / Friday cutting-phase workout plan.

## V1 Scope

- editable workout program seeded from the uploaded screenshots
- set logging for weight, reps, RPE, completion, and notes
- saved workout sessions and exercise-level progress history
- dashboard for weekly completion, last workout, body weight, and strength trend
- body weight and measurement check-ins
- local persistence with `UserDefaults`

## Build

```bash
xcodebuild -project /Users/panev/panev-ios/mobile/WaterTracker/WaterTracker.xcodeproj -destination 'generic/platform=iOS' -scheme WaterTracker -derivedDataPath /tmp/WaterTrackerDerived CODE_SIGNING_ALLOWED=NO build
```
