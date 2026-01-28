# 🏐 VolleyTracker

**VolleyTracker** is a modern iOS application for volleyball coaches, built with **SwiftUI** and **SwiftData**.  
The app helps coaches manage their teams by tracking **coaches, groups, and players** in a clean, fast, and native iOS experience.

This repository represents **V1**, focused on architecture, data modeling, and a polished onboarding flow.

---

## ✨ Features (V1)

- ✅ Native iOS app (SwiftUI)
- ✅ Modern onboarding flow
- ✅ Coach profile creation
- ✅ Persistent local data using SwiftData
- ✅ Active coach concept
- ✅ Clean, iOS-style UI with glassmorphism
- 🚧 Groups & Players management (coming next)

---

## 📱 Screens (Current)

- **Welcome Screen**
  - Full-screen background image
  - Clear product messaging
  - Call-to-action to start setup

- **Create Coach**
  - Name validation
  - iOS-native form controls
  - Coach saved to persistent storage
  - Active coach is remembered

- **Groups (placeholder)**
  - Navigation flow is already in place

---

## 🛠️ Tech Stack

### Core
- **Swift 5**
- **SwiftUI** – declarative UI
- **SwiftData** – persistence layer (iOS 17+)

### Architecture
- MV-style SwiftUI views
- Environment-based data access
- Centralized `ModelContainer`
- Single source of truth for active coach

### Platform
- **iOS 17+**
- Built & tested using Xcode Simulator

---

## 🧠 Data Models (V1)

- `Coach`
  - `id`
  - `name`

- `AppSettings`
  - `activeCoachId`

SwiftData is used instead of Core Data for a cleaner, more modern approach aligned with SwiftUI.

---

## 🎯 Goals of This Project

This project is built to:

- Learn **modern iOS development** the right way
- Practice **SwiftUI + SwiftData** patterns
- Build a realistic, production-style app
- Showcase clean architecture and UX decisions
- Serve as a foundation for future features

---

## 🚀 Planned Features (Next Versions)

- Groups CRUD
- Players CRUD
- Attendance tracking
- Statistics per group / player
- Multiple coaches
- iCloud sync (future)
- iPad support

---

## 👤 Author

**Vladimir Panev**  
iOS Developer (Swift / SwiftUI)

---

## 📄 License

This project is for educational and portfolio purposes.
