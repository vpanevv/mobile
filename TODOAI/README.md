# TODOAI

TODOAI is a focused SwiftUI productivity app for iPhone and iPad that helps users plan today with a clean dashboard, manual task creation, and AI-assisted task breakdowns.

## What the app does

- Creates tasks for today with visible priorities: `High`, `Important`, `Quick`, and `Steady`
- Shows a live clock and a daily overview on the home screen
- Lets users generate task ideas from natural language with **AI Task Assist**
- Stores profile and task data locally so the app works without account setup

## AI in the app

AI is a core part of the product direction, not a label added on top.

The current AI Task Assist flow takes a user prompt such as:

`Tonight I have to prepare for the volleyball game with some videos`

and converts it into a smaller, actionable task such as:

`Watch videos for the volleyball game`

The goal is simple: turn vague plans into concrete tasks a user can actually complete today.

## Current product experience

- `Home`
  Daily greeting, live clock, today’s task list, carry-over tasks, and summary
- `New Task`
  Centered task composer with a clearer vertical priority picker
- `AI Task Assist`
  Centered assist flow with AI-generated task suggestions from user intent

## Tech stack

- Swift
- SwiftUI
- Local JSON persistence
- Xcode project-based iOS app structure

## Project status

The app currently focuses on:

- Strong visual polish for the core flows
- Fast task entry
- Better AI-generated task phrasing
- A lightweight local-first experience

Next steps can expand the AI behavior further, add smarter task grouping, and introduce richer planning logic.
