# MyGarageMate App Recap

MyGarageMate is a native iOS car maintenance companion built with SwiftUI and SwiftData. It is designed to feel clean, premium, and Apple-native, with large-title navigation, rounded cards, SF Symbols, sheets, haptics, local notifications, PhotosUI image picking, and a polished iOS-style interface.

## Core Purpose

MyGarageMate helps users keep all important car maintenance information in one local, private place. Users can create a local profile, add multiple cars, upload car photos, track mileage, record service history, manage reminders, write mechanic notes, and review repair costs.

## Main Features

- Sign in with Apple, with a local-only profile flow.
- Optional local/demo account path for development.
- User profile stored locally with name, email, preferences, and profile photo.
- Multiple cars per profile.
- Car photo upload using PhotosUI.
- Make, model, year, trim, plate, VIN, and mileage tracking.
- Compact Garage list showing each car one under another.
- Car detail screen with hero photo, mileage editing, image editing, summary cards, and segmented tabs.
- Service records for oil, tires, brakes, engine, transmission, battery, suspension, insurance, inspection, and other categories.
- Service history editing and deleting with confirmation.
- Mechanic notes with priority, mileage, date, editing, and deleting.
- Reminders for oil changes, insurance, inspections, tire changes, and custom tasks.
- Upcoming tab for incomplete reminders across all cars.
- Local notifications for reminder dates.
- Settings for preferred currency, mileage unit, profile photo, sign out, and debug-only local data controls.

## Technical Stack

- SwiftUI for the user interface.
- SwiftData for all persistent local storage.
- AuthenticationServices for Sign in with Apple.
- PhotosUI for car, receipt, and profile image selection.
- UserNotifications for local reminder notifications.
- Foundation and native Apple frameworks only.
- No backend server.
- No third-party dependencies.

## Data Storage

All app data is stored locally on the device using SwiftData. Money values are stored as integer minor units, such as `4250` for `€42.50`. Images are compressed and stored as JPEG `Data` in SwiftData for version 1.

Stored data includes:

- User profile details.
- Profile photo.
- Cars and car photos.
- Service records and receipt images.
- Reminders.
- Mechanic notes.
- Currency and mileage preferences.

## Privacy Summary

MyGarageMate is local-first. Version 1 does not use a backend server, analytics, live currency conversion, OCR, or cloud sync. Sign in with Apple is used only for account identity. Photos are requested only when the user chooses to select an image, and notifications are requested only when the user creates a reminder.

## Current App Name and Bundle

- App name: MyGarageMate
- Bundle identifier: `com.vpanev.mygaragemate`
- Minimum deployment target: iOS 26.0

## Release Notes Summary

The app is ready as a polished MVP for beta testing. Testers should focus on authentication, adding cars, uploading photos, editing mileage, adding and editing service records, adding and editing notes, creating reminders, receiving notifications, deleting data with confirmations, switching currency and mileage units, dark mode, and Dynamic Type.

