# TODOAI

TODOAI is an AI-first daily planner built in SwiftUI for iPhone and iPad.

It is designed for one thing: helping a user open the app, understand the day fast, and turn vague intentions into tasks they can actually finish.

## Why it is different

Most to-do apps feel like storage.
TODOAI is built to feel like momentum.

- A cinematic intro screen makes the product feel like a focused tool, not a template app
- The dashboard gives the user a live sense of progress, urgency, carry-over, and completed wins
- AI Assist helps turn messy thoughts into cleaner actionable tasks
- The UI is intentionally polished to make daily planning feel rewarding

## What users get

- A branded AI-style home intro with animated visuals
- A dashboard with greeting, live clock, task stats, and a stronger “Today” focus area
- Manual task creation directly from the main workflow
- AI-assisted task generation for faster planning
- Swipe-to-delete for yesterday carry-over tasks with confirmation
- A celebratory daily summary section
- A separate completed tasks view with bulk clear support
- Local persistence with no account required

## Core product flow

1. Open TODOAI
2. Enter the experience through the intro screen
3. Review today’s focus and current rhythm
4. Create a task manually or use AI Assist
5. Complete tasks and watch the dashboard respond visually
6. Review completed tasks and clean them up when needed

## AI Assist direction

The AI layer is meant to reduce friction, not add complexity.

Instead of asking users to perfectly phrase every task, TODOAI can take rough intent like:

`I need to get ready for tomorrow's client meeting`

and help transform it into clearer next actions such as:

- `Review meeting notes`
- `Prepare key talking points`
- `Send follow-up agenda`

The goal is practical AI: faster clarity, less planning drag.

## Product feel

TODOAI is being shaped around:

- Immediate clarity
- High visual polish
- Small dopamine hits from progress
- Lightweight local-first usage
- AI as a useful partner in daily planning

## Tech

- Swift
- SwiftUI
- Local JSON persistence
- Xcode project app structure

## Smart AI backend

Smart AI should never call OpenAI directly from the iOS app.
The app is now wired to call your own backend proxy instead.

Configure this key in [Info.plist](/Users/panev/panev-ios/mobile/TODOAI/ToDoAI/Info.plist):

- `TODOAI_SMART_AI_PROXY_URL`

Expected request body from the app:

```json
{
  "note": "Today I have an important volleyball game and a birthday party tonight",
  "userName": "Pavel",
  "requestedAt": "2026-03-14T08:00:00Z",
  "maxTasks": 5
}
```

Expected response body from your backend:

```json
{
  "tasks": [
    { "title": "Pack volleyball gear", "priority": "high" },
    { "title": "Volleyball game", "priority": "important" },
    { "title": "Birthday party tonight", "priority": "quick" }
  ]
}
```

Backend responsibilities:

- Verify the user has Smart AI access
- Call OpenAI with the server-side API key
- Enforce short structured task output
- Return only sanitized task titles and priorities

## Why someone should try it

If you want a task app that feels more modern, more visual, and more assistive than a plain checklist, TODOAI is the pitch:

- open fast
- understand the day immediately
- create tasks quickly
- let AI help when your thoughts are messy
- feel progress as you move through the day

## Status

The current version already includes the core branded experience and daily planning loop.

Next iterations can push further into:

- smarter AI task grouping
- richer daily planning suggestions
- recurring routines
- better personalization
- deeper completion insights
