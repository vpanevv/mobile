# Gym Cut Tracker

Premium native iOS fitness notebook for tracking a Monday / Wednesday / Friday cutting-phase workout plan.

## V1 Scope

- editable workout program seeded from the uploaded screenshots
- set logging for weight, reps, RPE, completion, and notes
- saved workout sessions and exercise-level progress history
- calendar activity for weekly and monthly completion percentages
- session photo attachment and generated share cards from workout summaries
- dashboard for weekly completion, last workout, body weight, and strength trend
- body weight and measurement check-ins
- local persistence with `UserDefaults`

## Build

```bash
xcodebuild -project /Users/panev/panev-ios/mobile/GymCutTracker/GymCutTracker.xcodeproj -destination 'generic/platform=iOS' -scheme "Gym Cut Tracker" -derivedDataPath /tmp/GymCutTrackerDerived CODE_SIGNING_ALLOWED=NO build
```
