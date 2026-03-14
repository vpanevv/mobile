import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { URL } from "node:url";
import {
  AppStoreServerAPIClient,
  Environment,
  SignedDataVerifier,
  Status
} from "@apple/app-store-server-library";

loadEnvFile();

const port = Number(process.env.PORT || 8787);
const openAIAPIKey = process.env.OPENAI_API_KEY || "";
const openAIModel = process.env.OPENAI_MODEL || "gpt-4.1-mini";
const allowedOrigin = process.env.TODOAI_ALLOWED_ORIGIN || "*";
const bypassSubscriptionCheck = process.env.TODOAI_SUBSCRIPTION_BYPASS === "true";
const bundleId = process.env.TODOAI_BUNDLE_ID || "com.example.ToDoAI";
const smartAIProductId = process.env.TODOAI_SMART_AI_PRODUCT_ID || "todoai.smartai.monthly";
const appleEnvironment = normalizeEnvironment(process.env.TODOAI_APPLE_ENVIRONMENT || "Sandbox");
const appAppleId = process.env.TODOAI_APPLE_APP_ID ? Number(process.env.TODOAI_APPLE_APP_ID) : undefined;
const appStoreIssuerId = process.env.TODOAI_APPSTORE_ISSUER_ID || "";
const appStoreKeyId = process.env.TODOAI_APPSTORE_KEY_ID || "";
const appStorePrivateKey = loadAppStorePrivateKey();

let verifierPromise;
let appStoreClientPromise;

const server = http.createServer(async (req, res) => {
  try {
    applyCORS(res);

    if (req.method === "OPTIONS") {
      res.writeHead(204);
      res.end();
      return;
    }

    const url = new URL(req.url || "/", `http://${req.headers.host || "localhost"}`);

    if (req.method === "GET" && url.pathname === "/health") {
      sendJSON(res, 200, {
        ok: true,
        service: "todoai-smart-ai-backend",
        openAIConfigured: Boolean(openAIAPIKey),
        appStoreConfigured: Boolean(appStoreIssuerId && appStoreKeyId && appStorePrivateKey),
        subscriptionBypassEnabled: bypassSubscriptionCheck,
        appleEnvironment: process.env.TODOAI_APPLE_ENVIRONMENT || "Sandbox"
      });
      return;
    }

    if (req.method === "POST" && url.pathname === "/v1/smart-ai/suggestions") {
      if (!openAIAPIKey) {
        sendJSON(res, 500, { error: "OPENAI_API_KEY is not configured on the backend." });
        return;
      }

      const body = await readJSON(req);
      const validationError = validateSuggestionRequest(body);
      if (validationError) {
        sendJSON(res, 400, { error: validationError });
        return;
      }

      const authorized = await authorizeSmartAIRequest(body);
      if (!authorized.ok) {
        sendJSON(res, authorized.statusCode, { error: authorized.message });
        return;
      }

      const tasks = await fetchSmartAISuggestions(body);
      sendJSON(res, 200, { tasks });
      return;
    }

    sendJSON(res, 404, { error: "Not found" });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown server error";
    sendJSON(res, 500, { error: message });
  }
});

server.listen(port, () => {
  console.log(`TODOAI Smart AI backend listening on http://localhost:${port}`);
});

function applyCORS(res) {
  res.setHeader("Access-Control-Allow-Origin", allowedOrigin);
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
}

function sendJSON(res, statusCode, payload) {
  res.writeHead(statusCode, { "Content-Type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(payload));
}

async function readJSON(req) {
  const chunks = [];

  for await (const chunk of req) {
    chunks.push(Buffer.from(chunk));
  }

  const text = Buffer.concat(chunks).toString("utf8");
  if (!text) {
    return {};
  }

  try {
    return JSON.parse(text);
  } catch {
    throw new Error("Request body must be valid JSON.");
  }
}

function validateSuggestionRequest(body) {
  if (!body || typeof body !== "object") {
    return "Request body must be an object.";
  }

  if (typeof body.note !== "string" || body.note.trim().length < 3) {
    return "Field 'note' must be a non-empty string.";
  }

  if (typeof body.userName !== "string" || !body.userName.trim()) {
    return "Field 'userName' must be a non-empty string.";
  }

  if (body.requestedAt && Number.isNaN(Date.parse(body.requestedAt))) {
    return "Field 'requestedAt' must be an ISO-8601 date string.";
  }

  if (body.maxTasks !== undefined) {
    const maxTasks = Number(body.maxTasks);
    if (!Number.isInteger(maxTasks) || maxTasks < 1 || maxTasks > 5) {
      return "Field 'maxTasks' must be an integer between 1 and 5.";
    }
  }

  const entitlement = body.entitlement;
  if (!entitlement || typeof entitlement !== "object") {
    return "Field 'entitlement' is required.";
  }

  if (typeof entitlement.signedTransactionInfo !== "string" || !entitlement.signedTransactionInfo.trim()) {
    return "Field 'entitlement.signedTransactionInfo' must be a non-empty string.";
  }

  if (typeof entitlement.transactionId !== "string" || !entitlement.transactionId.trim()) {
    return "Field 'entitlement.transactionId' must be a non-empty string.";
  }

  if (typeof entitlement.originalTransactionId !== "string" || !entitlement.originalTransactionId.trim()) {
    return "Field 'entitlement.originalTransactionId' must be a non-empty string.";
  }

  if (typeof entitlement.appAccountToken !== "string" || !entitlement.appAccountToken.trim()) {
    return "Field 'entitlement.appAccountToken' must be a non-empty string.";
  }

  return null;
}

async function authorizeSmartAIRequest(body) {
  if (bypassSubscriptionCheck) {
    return {
      ok: true,
      statusCode: 200,
      message: "Subscription bypass is enabled."
    };
  }

  try {
    const verifier = await getSignedDataVerifier();
    const signedInfo = body.entitlement.signedTransactionInfo;
    const decoded = await verifier.verifyAndDecodeTransaction(signedInfo);

    const decodedBundleId = readField(decoded, ["bundleId", "bundleID"]);
    const decodedProductId = readField(decoded, ["productId", "productID"]);
    const decodedTransactionId = String(readField(decoded, ["transactionId", "transactionID", "transactionIdRaw"]) || "");
    const decodedOriginalTransactionId = String(readField(decoded, ["originalTransactionId", "originalTransactionID"]) || "");
    const decodedAppAccountToken = readField(decoded, ["appAccountToken"]);
    const decodedExpiration = readField(decoded, ["expiresDate", "expirationDate"]);
    const decodedRevocation = readField(decoded, ["revocationDate"]);
    const decodedEnvironment = readField(decoded, ["environment"]);

    if (decodedBundleId !== bundleId) {
      return forbidden("Entitlement bundle ID does not match this app.");
    }

    if (decodedProductId !== smartAIProductId) {
      return forbidden("Entitlement product ID does not match Smart AI.");
    }

    if (decodedTransactionId !== body.entitlement.transactionId) {
      return forbidden("Entitlement transaction ID mismatch.");
    }

    if (decodedOriginalTransactionId !== body.entitlement.originalTransactionId) {
      return forbidden("Entitlement original transaction ID mismatch.");
    }

    if (decodedAppAccountToken && decodedAppAccountToken !== body.entitlement.appAccountToken) {
      return forbidden("Entitlement app account token mismatch.");
    }

    if (!decodedAppAccountToken) {
      return forbidden("Entitlement is missing the app account token.");
    }

    if (decodedEnvironment && decodedEnvironment !== appleEnvironment) {
      return forbidden("Entitlement environment does not match the configured backend.");
    }

    if (decodedRevocation) {
      return forbidden("Entitlement has been revoked.");
    }

    if (decodedExpiration && new Date(Number(decodedExpiration)) < new Date()) {
      return forbidden("Entitlement has expired.");
    }

    const subscriptionStatus = await verifySubscriptionStatus({
      originalTransactionId: decodedOriginalTransactionId,
      appAccountToken: body.entitlement.appAccountToken
    });
    if (!subscriptionStatus.ok) {
      return subscriptionStatus;
    }

    return {
      ok: true,
      statusCode: 200,
      message: "Verified active Smart AI entitlement."
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : "Entitlement verification failed.";
    return {
      ok: false,
      statusCode: 403,
      message
    };
  }
}

async function verifySubscriptionStatus({ originalTransactionId, appAccountToken }) {
  try {
    const client = await getAppStoreServerAPIClient();
    const verifier = await getSignedDataVerifier();
    const response = await client.getAllSubscriptionStatuses(
      originalTransactionId,
      [Status.ACTIVE, Status.BILLING_GRACE_PERIOD]
    );

    const groups = Array.isArray(response.data) ? response.data : [];
    for (const group of groups) {
      const lastTransactions = Array.isArray(group.lastTransactions) ? group.lastTransactions : [];
      for (const item of lastTransactions) {
        if (item.originalTransactionId !== originalTransactionId) {
          continue;
        }

        if (item.status !== Status.ACTIVE && item.status !== Status.BILLING_GRACE_PERIOD) {
          continue;
        }

        if (!item.signedTransactionInfo) {
          continue;
        }

        const transaction = await verifier.verifyAndDecodeTransaction(item.signedTransactionInfo);
        if (transaction.productId !== smartAIProductId) {
          continue;
        }

        if (transaction.originalTransactionId !== originalTransactionId) {
          continue;
        }

        if ((transaction.appAccountToken || "").toLowerCase() !== appAccountToken.toLowerCase()) {
          continue;
        }

        if (transaction.revocationDate) {
          continue;
        }

        if (transaction.expiresDate && new Date(transaction.expiresDate) < new Date()) {
          continue;
        }

        return {
          ok: true,
          statusCode: 200,
          message: "Verified active Smart AI subscription status."
        };
      }
    }

    return forbidden("No active Smart AI subscription status was found for this entitlement.");
  } catch (error) {
    const message = error instanceof Error ? error.message : "Subscription status verification failed.";
    return {
      ok: false,
      statusCode: 403,
      message
    };
  }
}

async function fetchSmartAISuggestions(body) {
  const maxTasks = Math.min(Number(body.maxTasks || 5), 5);
  const promptDate = body.requestedAt ? new Date(body.requestedAt) : new Date();

  const requestBody = {
    model: openAIModel,
    input: [
      {
        role: "system",
        content: [
          {
            type: "input_text",
            text: buildSystemPrompt(promptDate)
          }
        ]
      },
      {
        role: "user",
        content: [
          {
            type: "input_text",
            text: buildUserPrompt(body.note, body.userName, maxTasks)
          }
        ]
      }
    ],
    text: {
      format: {
        type: "json_schema",
        name: "todoai_suggestions",
        strict: true,
        schema: buildResponseSchema(maxTasks)
      }
    }
  };

  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${openAIAPIKey}`
    },
    body: JSON.stringify(requestBody)
  });

  const rawText = await response.text();
  if (!response.ok) {
    throw new Error(`OpenAI request failed: ${rawText}`);
  }

  let payload;
  try {
    payload = JSON.parse(rawText);
  } catch {
    throw new Error("OpenAI returned invalid JSON.");
  }

  const modelJSON = extractOutputText(payload);
  if (!modelJSON) {
    throw new Error("OpenAI did not return structured task output.");
  }

  let parsed;
  try {
    parsed = JSON.parse(modelJSON);
  } catch {
    throw new Error("OpenAI structured payload could not be parsed.");
  }

  const tasks = Array.isArray(parsed.tasks) ? parsed.tasks : [];
  const cleaned = tasks
    .map((task) => ({
      title: String(task.title || "").trim(),
      priority: normalizePriority(task.priority)
    }))
    .filter((task) => task.title)
    .slice(0, maxTasks);

  if (!cleaned.length) {
    throw new Error("OpenAI returned no usable tasks.");
  }

  return cleaned;
}

function buildSystemPrompt(now) {
  return [
    "You are TODOAI's premium planning engine.",
    `Current time: ${now.toISOString()}.`,
    "Convert the user's messy daily note into concise, useful task suggestions.",
    "Rules:",
    "- Return 2 to 5 tasks.",
    "- Prefer short titles under 5 words.",
    "- Do not copy the user's sentence back verbatim.",
    "- If there is an event, include the event itself and only strong preparation tasks.",
    "- Do not invent facts beyond the user's note.",
    "- Priority must be one of: high, important, quick, steady."
  ].join("\n");
}

function buildUserPrompt(note, userName, maxTasks) {
  return [
    `User name: ${userName}`,
    `Max tasks: ${maxTasks}`,
    `Planning note: ${note}`
  ].join("\n");
}

function buildResponseSchema(maxTasks) {
  return {
    type: "object",
    additionalProperties: false,
    properties: {
      tasks: {
        type: "array",
        minItems: 2,
        maxItems: maxTasks,
        items: {
          type: "object",
          additionalProperties: false,
          properties: {
            title: {
              type: "string",
              description: "A concise task title under 5 words."
            },
            priority: {
              type: "string",
              enum: ["high", "important", "quick", "steady"]
            }
          },
          required: ["title", "priority"]
        }
      }
    },
    required: ["tasks"]
  };
}

function extractOutputText(payload) {
  if (!Array.isArray(payload.output)) {
    return null;
  }

  for (const item of payload.output) {
    if (!Array.isArray(item.content)) {
      continue;
    }

    for (const contentItem of item.content) {
      if (typeof contentItem.text === "string" && contentItem.text.trim()) {
        return contentItem.text;
      }
    }
  }

  return null;
}

function normalizePriority(value) {
  const priority = String(value || "").trim().toLowerCase();
  if (priority === "high" || priority === "important" || priority === "quick" || priority === "steady") {
    return priority;
  }

  return "important";
}

async function createSignedDataVerifier() {
  const rootCertificates = await loadAppleRootCertificates();

  return new SignedDataVerifier(
    rootCertificates,
    true,
    appleEnvironment,
    bundleId,
    appleEnvironment === Environment.PRODUCTION ? appAppleId : undefined
  );
}

async function createAppStoreServerAPIClient() {
  if (!appStoreIssuerId || !appStoreKeyId || !appStorePrivateKey) {
    throw new Error(
      "App Store Server API credentials are missing. Set TODOAI_APPSTORE_ISSUER_ID, TODOAI_APPSTORE_KEY_ID, and TODOAI_APPSTORE_PRIVATE_KEY or TODOAI_APPSTORE_PRIVATE_KEY_PATH."
    );
  }

  return new AppStoreServerAPIClient(
    appStorePrivateKey,
    appStoreKeyId,
    appStoreIssuerId,
    bundleId,
    appleEnvironment
  );
}

async function getSignedDataVerifier() {
  if (bypassSubscriptionCheck) {
    return null;
  }

  if (!verifierPromise) {
    verifierPromise = createSignedDataVerifier();
  }

  return verifierPromise;
}

async function getAppStoreServerAPIClient() {
  if (bypassSubscriptionCheck) {
    return null;
  }

  if (!appStoreClientPromise) {
    appStoreClientPromise = createAppStoreServerAPIClient();
  }

  return appStoreClientPromise;
}

async function loadAppleRootCertificates() {
  const cacheDir = path.join(process.cwd(), "backend", ".cache", "apple-root-certs");
  fs.mkdirSync(cacheDir, { recursive: true });

  const certificateURLs = [
    "https://www.apple.com/certificateauthority/AppleRootCA-G2.cer",
    "https://www.apple.com/certificateauthority/AppleRootCA-G3.cer",
    "https://www.apple.com/certificateauthority/AppleIncRootCertificate.cer"
  ];

  const certificates = [];

  for (const certificateURL of certificateURLs) {
    const fileName = new URL(certificateURL).pathname.split("/").pop();
    const filePath = path.join(cacheDir, fileName);

    if (!fs.existsSync(filePath)) {
      const response = await fetch(certificateURL);
      if (!response.ok) {
        throw new Error(`Failed to download Apple root certificate: ${certificateURL}`);
      }

      const buffer = Buffer.from(await response.arrayBuffer());
      fs.writeFileSync(filePath, buffer);
    }

    certificates.push(fs.readFileSync(filePath));
  }

  return certificates;
}

function normalizeEnvironment(value) {
  const normalized = String(value).toLowerCase();
  if (normalized === "production") {
    return Environment.PRODUCTION;
  }

  return Environment.SANDBOX;
}

function readField(source, keys) {
  for (const key of keys) {
    if (source && source[key] !== undefined && source[key] !== null) {
      return source[key];
    }
  }

  return undefined;
}

function forbidden(message) {
  return {
    ok: false,
    statusCode: 403,
    message
  };
}

function loadEnvFile() {
  const envPath = path.join(process.cwd(), "backend", ".env");

  if (!fs.existsSync(envPath)) {
    return;
  }

  const contents = fs.readFileSync(envPath, "utf8");
  for (const line of contents.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) {
      continue;
    }

    const separatorIndex = trimmed.indexOf("=");
    if (separatorIndex === -1) {
      continue;
    }

    const key = trimmed.slice(0, separatorIndex).trim();
    const value = trimmed.slice(separatorIndex + 1).trim();
    if (!(key in process.env)) {
      process.env[key] = value;
    }
  }
}

function loadAppStorePrivateKey() {
  const inlineKey = process.env.TODOAI_APPSTORE_PRIVATE_KEY || "";
  if (inlineKey.trim()) {
    return inlineKey.replace(/\\n/g, "\n");
  }

  const keyPath = process.env.TODOAI_APPSTORE_PRIVATE_KEY_PATH || "";
  if (!keyPath.trim()) {
    return "";
  }

  return fs.readFileSync(path.resolve(keyPath), "utf8");
}
