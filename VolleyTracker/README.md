# ToDoAI

ToDoAI is a focused iOS daily planner built with SwiftUI for people who want a clean task list, a little intelligence, and zero clutter.

It starts with a simple setup flow, learns only your name, and drops you into a futuristic dashboard where you can plan the day, carry unfinished work forward, and complete tasks one by one. The app is intentionally lightweight, but it still feels premium: liquid-glass cards, animated AI-inspired background motion, and a UI that keeps the important actions visible.

## Highlights

- Personal onboarding with a single-field setup
- Time-aware greeting on the main dashboard
- Daily task planning for today
- Carry-over section for unfinished tasks from yesterday
- One-tap task completion
- Swipe-to-delete with confirmation
- Daily summary of completed tasks
- Priority-based task creation: `High`, `Important`, `Quick`, `Steady`
- AI Task Assist for generating suggested tasks from a daily goal
- Local persistence across launches
- iOS 26+ SwiftUI app experience with glass-style visuals

## App Flow

### 1. Setup

On first launch, the user enters only their name.

### 2. Daily Dashboard

The second screen shows:

- a dynamic greeting based on the current time
- current date and live clock
- today’s active tasks
- unfinished tasks from yesterday
- daily completion summary
- quick actions for adding tasks or asking AI for help

### 3. AI Task Assist

The AI assistant takes a short description of the user’s day and turns it into suggested tasks for today. It is designed to help users get unstuck quickly and turn vague plans into concrete actions.

## Tech Stack

- `SwiftUI`
- Local JSON-based persistence
- Native iOS UI patterns and animations
- Xcode project targeting `iOS 26.0+`

## Project Structure

- [ToDoAI](/Users/panev/panev-ios/mobile/VolleyTracker/ToDoAI): SwiftUI source files
- [ToDoAI.xcodeproj](/Users/panev/panev-ios/mobile/VolleyTracker/ToDoAI.xcodeproj): Xcode project

Key files:

- [ToDoAI/ToDoAIApp.swift](/Users/panev/panev-ios/mobile/VolleyTracker/ToDoAI/ToDoAIApp.swift)
- [ToDoAI/ContentView.swift](/Users/panev/panev-ios/mobile/VolleyTracker/ToDoAI/ContentView.swift)
- [ToDoAI/DashboardView.swift](/Users/panev/panev-ios/mobile/VolleyTracker/ToDoAI/DashboardView.swift)
- [ToDoAI/AIAssistSheet.swift](/Users/panev/panev-ios/mobile/VolleyTracker/ToDoAI/AIAssistSheet.swift)
- [ToDoAI/Models.swift](/Users/panev/panev-ios/mobile/VolleyTracker/ToDoAI/Models.swift)

## Build

Open the project in Xcode:

```bash
open ToDoAI.xcodeproj
```

Or build from the command line:

```bash
xcodebuild -project ToDoAI.xcodeproj \
  -scheme ToDoAI \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Product Direction

ToDoAI is intentionally simple:

- one user
- one daily plan
- one clear dashboard
- one AI assist entry point

The goal is not to become a heavy productivity suite. The goal is to make daily planning feel fast, calm, and smart.
