# Release QA Checklist

## Authentication
- First launch shows Sign in with Apple when no local profile exists.
- Sign in with Apple success creates or updates a local profile.
- Sign in cancellation leaves the user on the sign-in screen without crashing.
- Missing name/email falls back to a safe local display name.
- Sign out returns to the sign-in screen.
- Relaunch after sign in opens the garage for the active local profile.

## Garage
- Empty state appears when there are no cars.
- Add first car with make, model, year, mileage, and unit.
- Add multiple cars.
- Add car without photo.
- Add car with photo.
- Delete car and verify related records, notes, and reminders are gone.

## Service records
- Add oil change.
- Add insurance.
- Add inspection.
- Add repair.
- Add record with EUR.
- Add record with USD.
- Delete record after confirmation.
- Validate required fields before saving.

## Notes
- Add mechanic note.
- Add high-priority note.
- Delete note after confirmation.

## Reminders
- Add reminder.
- Request notification permission only when saving a reminder with a reminder date.
- Schedule notification.
- Mark reminder completed.
- Delete reminder after confirmation.

## Settings
- Change currency.
- Change mileage unit.
- Verify development-only data reset controls appear only in DEBUG builds.
- Dark mode.
- Large text / Dynamic Type.

## Stability
- Relaunch app.
- Airplane mode.
- No photo permission.
- Notification permission denied.
- Empty SwiftData store.
- Large number of records.
