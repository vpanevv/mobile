# Privacy Checklist

## What data is stored
- User profile name, optional email, Apple user identifier, preferred currency, and mileage unit.
- Cars, including make, model, year, trim, plate number, VIN, mileage, and optional car photo.
- Service records, including service title, category, date, mileage, cost in integer minor units, currency code, shop name, notes, and optional receipt image.
- Mechanic notes, including note text, date, mileage, and priority.
- Reminders, including reminder title, type, due date, due mileage, reminder date, and completion status.

## Where it is stored
All app data is stored locally on the device using SwiftData. Images are compressed JPEG data stored in SwiftData for version 1.

## Whether data leaves the device
Version 1 does not send GarageMate car maintenance data to a backend server. Sign in with Apple is used only for local account identity.

## Permissions requested
- Photo Library: requested by PhotosUI when the user chooses to add a car or receipt photo.
- Notifications: requested only when the user creates a reminder with a reminder date.

## Why each permission is needed
- Photo Library lets users select photos of their cars and receipts.
- Notifications let GarageMate remind users about oil changes, insurance, inspections, tires, and custom maintenance tasks.

## App Store privacy nutrition label notes
- Data collection: no backend collection in version 1.
- Data linked to user: Sign in with Apple identifier is stored locally for identity.
- User content: car photos, receipt images, service notes, reminders, and maintenance records remain on device.
- Diagnostics/analytics: no analytics SDK or diagnostic collection is implemented in version 1.
- Location: GarageMate does not request location access.
- Contacts, calendar, microphone, camera: GarageMate does not request these permissions in version 1.
