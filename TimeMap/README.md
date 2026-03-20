# TimeMap

> Tap the world. Know the time.

**TimeMap** is a premium SwiftUI world clock and timezone explorer designed to make global time feel visual, intuitive, and alive.

From a glowing local-time dashboard to immersive city mood cards, TimeMap turns every location into a living snapshot of its current moment.

## Why TimeMap

- 🌍 Explore time across the world with a clean, map-first experience
- 🕒 See your own local time instantly and keep it anchored on screen
- ✨ Search cities and reveal mood-rich time cards with premium visuals
- 🌙 Understand day, night, and atmosphere at a glance
- 📍 Tap the map to discover time by place, not just by list

## Experience Highlights

### 🏠 A Beautiful First Impression
TimeMap opens with a cinematic welcome screen built around an animated globe, premium gradients, and a focused call to action.

### ⏰ Your Local Time, Always Clear
The home screen keeps your current time, city or region, and timezone front and center without overwhelming the interface.

### 🔎 Instant City Search
Start typing any city name and compare it against your own local time in seconds.

### 🗺️ Explore by Map
Tap anywhere on the map and TimeMap resolves the nearest meaningful place so you can inspect its current moment instantly.

### 🎨 Time Mood Cards
Selected cities are presented as expressive atmospheric cards that reflect their local time of day with:

- sunrise, daylight, evening, or night moods
- adaptive gradients and glow
- sun or moon visual cues
- strong time-first visual hierarchy

## What Makes It Feel Special

- 📱 Native SwiftUI architecture with a modern iOS feel
- 🧊 Glassy surfaces and layered depth
- 🌅 Mood-aware visual storytelling for each selected city
- 🛰️ World exploration aesthetic instead of a generic utility-app layout
- ⚡ Fast, Apple-native time, map, and geocoding APIs

## Built With

- `SwiftUI`
- `MapKit`
- `CoreLocation`
- `MVVM`
- Apple-native date, calendar, and timezone APIs

## Project Structure

- `App` — app entry, root flow, dependency container
- `Models` — time, location, and selection state
- `ViewModels` — `TimeMapViewModel`
- `Views` — onboarding, home, and map screens
- `Components` — reusable premium UI building blocks
- `Services` — time ticking, search, location resolution, and geocoding
- `Theme` — shared palette, gradients, glass surfaces, and metrics
- `Utilities` — helpers like flag generation

## Run TimeMap

Open the Xcode project:

[`/Users/panev/panev-ios/mobile/TimeMap/TimeMap.xcodeproj`](/Users/panev/panev-ios/mobile/TimeMap/TimeMap.xcodeproj)

Run the `TimeMap` target in Xcode.

## CLI Build

For local verification without code signing:

```bash
xcodebuild -project /Users/panev/panev-ios/mobile/TimeMap/TimeMap.xcodeproj -scheme TimeMap -destination 'generic/platform=iOS' -derivedDataPath /tmp/TimeMapDerived CODE_SIGNING_ALLOWED=NO build
```

## Vision

TimeMap is built to make world time feel less like data and more like presence.

Different cities should not only show different numbers. They should feel different.

That is the heart of TimeMap.
