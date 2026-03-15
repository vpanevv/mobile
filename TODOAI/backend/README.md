# TODOAI Smart AI Backend

This backend keeps the OpenAI API key server-side and exposes one app-facing endpoint:

- `POST /v1/smart-ai/suggestions`

It uses Node's built-in `http` server plus Apple's App Store Server library for subscription verification.

## Run locally

1. Copy `.env.example` to `.env`
2. Set `OPENAI_API_KEY`
3. Set your App Store Server API credentials:
   - `TODOAI_APPSTORE_ISSUER_ID`
   - `TODOAI_APPSTORE_KEY_ID`
   - `TODOAI_APPSTORE_PRIVATE_KEY_PATH` or `TODOAI_APPSTORE_PRIVATE_KEY`
4. Only for local development, you can temporarily set `TODOAI_SUBSCRIPTION_BYPASS=true`
5. Start the server:

```bash
cd backend
npm start
```

The server will listen on `http://localhost:8787` by default.

## Connect the iOS app

Set this key in `ToDoAI/Info.plist`:

- `TODOAI_SMART_AI_PROXY_URL`

Example value:

```text
http://localhost:8787/v1/smart-ai/suggestions
```

## Request contract

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

## Response contract

```json
{
  "tasks": [
    { "title": "Pack volleyball gear", "priority": "high" },
    { "title": "Volleyball game", "priority": "important" },
    { "title": "Birthday party tonight", "priority": "quick" }
  ]
}
```

## How entitlement verification works

For production, the backend now verifies Smart AI access in two steps:

1. It verifies the Apple-signed `signedTransactionInfo` JWS sent by the app.
2. It calls Apple's App Store Server API to confirm the original transaction still has an active Smart AI subscription status.

The backend only grants access when:

- the bundle ID matches your app
- the product ID matches the Smart AI subscription
- the app account token matches the purchase
- the entitlement is not revoked or expired
- Apple reports an active or grace-period subscription for that original transaction

## Request protection

Before the backend calls OpenAI, it also enforces:

- max input length: 1000 characters
- daily Smart AI quota: 4 requests per user per day
- user identity for quota tracking: the verified `appAccountToken` from the Apple-signed entitlement
- max OpenAI response size: capped with `max_output_tokens`

If the input exceeds 1000 characters, the backend returns HTTP `400` with:

- `Input too long. Maximum allowed length is 1000 characters.`

If the user has already generated 4 Smart AI plans that day, the backend returns HTTP `429` with:

- `Daily Smart AI limit reached. You can generate up to 4 Smart AI plans per day.`

## Production note

`TODOAI_SUBSCRIPTION_BYPASS=true` should only be used during local development.
Production should keep it `false` and provide valid App Store Server API credentials.
