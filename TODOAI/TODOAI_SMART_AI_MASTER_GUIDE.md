# TODOAI Smart AI Master Guide

This document is the single reference file for the new Smart AI system in TODOAI.

It explains:

- what Quick AI and Smart AI are
- how subscriptions work
- how StoreKit 2 fits into the app
- how the Smart AI backend works
- why the OpenAI key must stay server-side
- what is already implemented
- what is production-ready now
- what still needs operational hardening

## 1. Product model

TODOAI now has two AI layers:

### Quick AI

- Runs locally in the app
- Uses extraction logic, not a large language model
- Fast
- Cheap
- Private
- Good for short task compression like:
  - `Volleyball game`
  - `Birthday party tonight`

### Smart AI

- Premium feature
- Uses StoreKit-backed paid access
- Calls your own backend proxy
- The backend then calls OpenAI
- Produces stronger planning suggestions than local extraction
- Can infer better prep tasks and planning structure

Example:

Input:

`Today I have an important volleyball game and I'm on a birthday party tonight`

Possible Smart AI output:

- `Pack volleyball gear`
- `Volleyball game`
- `Birthday party tonight`

## 2. Why Smart AI must use a backend

Putting the OpenAI key inside the iOS app is not safe.

If the API key is shipped inside the app bundle:

- it can be extracted
- it can be abused outside the app
- you lose billing control
- rate limiting becomes harder
- users can bypass your intended product rules

Because of that, TODOAI now uses this safe pattern:

1. iOS app sends Smart AI request to your backend
2. Backend checks policy
3. Backend calls OpenAI using the server-side API key
4. Backend returns only cleaned task suggestions

This is the correct production direction.

## 3. Subscription architecture

Smart AI is now gated by StoreKit 2 in the app.

Implemented in:

- [SmartAISubscriptionStore.swift](/Users/panev/panev-ios/mobile/TODOAI/ToDoAI/SmartAISubscriptionStore.swift)

What it does:

- loads the Smart AI subscription product
- purchases the product
- restores purchases
- listens for transaction updates
- derives whether the user currently has Smart AI access

Current product ID config:

- `todoai.smartai.monthly`

Configured in:

- [Info.plist](/Users/panev/panev-ios/mobile/TODOAI/ToDoAI/Info.plist)

## 4. iOS Smart AI flow

The app UI is implemented in:

- [AIAssistSheet.swift](/Users/panev/panev-ios/mobile/TODOAI/ToDoAI/AIAssistSheet.swift)

Flow:

1. User opens AI Assist
2. Default mode is `Quick AI`
3. If the user selects `Smart AI`
4. A premium paywall appears
5. If the subscription is active, Smart AI can run
6. The app sends the note to your backend proxy
7. The backend returns structured tasks
8. The app renders those tasks and allows adding them to today

## 5. Backend architecture

Backend files:

- [backend/server.mjs](/Users/panev/panev-ios/mobile/TODOAI/backend/server.mjs)
- [backend/package.json](/Users/panev/panev-ios/mobile/TODOAI/backend/package.json)
- [backend/.env.example](/Users/panev/panev-ios/mobile/TODOAI/backend/.env.example)
- [backend/README.md](/Users/panev/panev-ios/mobile/TODOAI/backend/README.md)

The backend exposes:

- `GET /health`
- `POST /v1/smart-ai/suggestions`

Request shape from the app:

```json
{
  "note": "Today I have an important volleyball game and a birthday party tonight",
  "userName": "Pavel",
  "requestedAt": "2026-03-14T08:00:00Z",
  "maxTasks": 5,
  "entitlement": {
    "signedTransactionInfo": "eyJhbGciOiJFUzI1NiIs...",
    "transactionId": "2000001234567890",
    "originalTransactionId": "2000001234500000",
    "appAccountToken": "E0EAA4A2-DB58-4E67-B6B8-60D1305B0D96"
  }
}
```

Response shape to the app:

```json
{
  "tasks": [
    { "title": "Pack volleyball gear", "priority": "high" },
    { "title": "Volleyball game", "priority": "important" },
    { "title": "Birthday party tonight", "priority": "quick" }
  ]
}
```

## 6. OpenAI usage

The backend calls the OpenAI Responses API.

Key design choices:

- strict prompt constraints
- strict JSON schema output
- short task titles only
- fixed allowed priorities
- server sanitization before returning data to iOS

This matters because free-form model output is unreliable for app UIs.

The model is asked to:

- return only 2 to 5 tasks
- avoid repeating user sentences
- avoid inventing facts
- produce concise task-style outputs

## 7. What is safer now

These things are now materially safer than before:

- OpenAI key is no longer in the app
- iOS app no longer talks directly to OpenAI
- Smart AI is behind a paid StoreKit entitlement on the client
- Backend controls the final LLM request
- Backend controls output shape before returning data

## 8. Server-side entitlement verification

This is the most important section.

The production backend now verifies Smart AI access in two separate layers.

Layer 1: device proof verification

- the app sends the signed StoreKit transaction JWS
- the backend verifies the JWS signature with Apple's root certificates
- the backend checks bundle ID, product ID, transaction ID, original transaction ID, app account token, environment, revocation, and expiration

Layer 2: App Store server status verification

- the backend calls Apple's App Store Server API using the original transaction ID
- it confirms there is still an active Smart AI subscription for that purchase
- it only accepts statuses that still represent service access

This is much harder to abuse than client-only gating because an attacker now needs both:

- a valid Apple-signed entitlement
- a still-active subscription on Apple's side

Required backend credentials:

- `TODOAI_APPSTORE_ISSUER_ID`
- `TODOAI_APPSTORE_KEY_ID`
- `TODOAI_APPSTORE_PRIVATE_KEY_PATH` or `TODOAI_APPSTORE_PRIVATE_KEY`

Development-only bypass:

- `TODOAI_SUBSCRIPTION_BYPASS=true`

That bypass should never be enabled in production.

## 9. What is safe now

These parts are now implemented end-to-end:

- Quick AI stays local in the app
- Smart AI is gated by StoreKit 2 in iOS
- the app sends signed entitlement proof to the backend
- the backend keeps the OpenAI key server-side
- the backend verifies Apple-signed transaction proof
- the backend confirms active subscription state with Apple's server API
- the backend forces structured JSON task output

## 10. Recommended next steps

Priority order:

1. Deploy the backend somewhere stable
2. Set `TODOAI_SMART_AI_PROXY_URL` in the app
3. Configure the real App Store Connect subscription product
4. Add the App Store Server API credentials to the backend environment
5. Test purchase, restore, and Smart AI generation together in Sandbox
6. Add logging, rate limiting, and request tracing

## 11. Suggested backend deployment targets

Good choices:

- Fly.io
- Render
- Railway
- a small VPS
- Cloud Run
- Vercel serverless function, if you adapt the handler

## 12. Suggested operational protections

Before scale, add:

- rate limiting per device or user
- structured request logging without storing raw notes longer than needed
- backend auth if you later add TODOAI accounts
- alerting for repeated entitlement failures
- timeout handling
- response caching for repeated prompts if desired
- error monitoring
- abuse detection

## 13. App configuration reference

Current iOS config keys in:

- [Info.plist](/Users/panev/panev-ios/mobile/TODOAI/ToDoAI/Info.plist)

Keys:

- `TODOAI_SMART_AI_PRODUCT_ID`
- `TODOAI_SMART_AI_PROXY_URL`

Current backend env values in:

- [backend/.env.example](/Users/panev/panev-ios/mobile/TODOAI/backend/.env.example)

Keys:

- `PORT`
- `OPENAI_API_KEY`
- `OPENAI_MODEL`
- `TODOAI_ALLOWED_ORIGIN`
- `TODOAI_SUBSCRIPTION_BYPASS`

## 14. What the user experiences now

From a user perspective:

- free users can always use Quick AI
- premium users can unlock Smart AI
- Smart AI feels more advanced and cloud-powered
- the app architecture now matches that product promise

## 15. Bottom line

TODOAI now has:

- a local AI layer for fast free suggestions
- a premium StoreKit-gated Smart AI mode
- a backend-proxy architecture that protects the OpenAI key
- a clear path to full production hardening

The one big remaining backend requirement is entitlement verification on the server.

That is the next real security milestone.
