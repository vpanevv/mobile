// WishlyAI — server-side wish generator.
//
// Holds the Anthropic API key as a Supabase secret (ANTHROPIC_API_KEY) so it
// never ships inside the app binary. The app sends STRUCTURED wish parameters;
// the prompt is built here, so this endpoint can only ever produce wishes —
// it cannot be used as a general-purpose Claude proxy.
//
// Deploy:  supabase functions deploy wishlyai-generate-wish
// Secret:  supabase secrets set ANTHROPIC_API_KEY=sk-ant-...

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const MODEL = "claude-sonnet-4-6";
const MAX_TOKENS = 400;

// ── Prompt tables (ported from the iOS enums) ──────────────────────────────

const TONE: Record<number, string> = {
  0: "Write in a formal, respectful, eloquent tone. Suitable for official or ceremonial relationships. Use refined language.",
  1: "Write in a polished, professional tone. Appropriate for colleagues, clients, or business acquaintances. Courteous and composed.",
  2: "Write in a warm, sincere, heartfelt tone. Express genuine care and affection without being overly casual.",
  3: "Write in a casual, friendly tone — like a good friend speaking naturally. Approachable and kind.",
  4: "Write in a light, playful tone with cheerful energy and a touch of whimsy. Upbeat and fun.",
  5: "Write in a humorous, witty tone with a clever joke or playful twist. Keep it tasteful and genuinely funny.",
};

const LENGTH: Record<string, string> = {
  Short:  "Keep it very short: exactly 1 sentence, max 20 words. Perfect for SMS.",
  Medium: "Write 2 to 3 sentences. Warm but concise, suitable for a chat message.",
  Long:   "Write 4 to 6 sentences with a proper opening, body, and closing. Suitable for an email or card.",
};

const LANGUAGE: Record<string, string> = {
  English:    "Write the wish in English.",
  Bulgarian:  "Напиши пожеланието на български език.",
  Spanish:    "Escribe el deseo en español.",
  French:     "Écris le vœu en français.",
  German:     "Schreibe den Wunsch auf Deutsch.",
  Italian:    "Scrivi il desiderio in italiano.",
  Portuguese: "Escreva o desejo em português.",
  Dutch:      "Schrijf de wens in het Nederlands.",
  Polish:     "Napisz życzenie po polsku.",
  Russian:    "Напиши пожелание на русском языке.",
};

const VALENTINES_GUIDANCE =
  " This is a Valentine's Day message — romantic, affectionate, and warm. Adapt the level of romance to the chosen tone: Formal/Professional → a tasteful, warm note suitable for friends, family, or coworkers; Warm/Friendly → a sweet, sincere message; Playful/Funny → a flirty, lighthearted message with charm. Do not assume the recipient is a romantic partner unless the context makes it clear — keep the message versatile.";

function clean(s: unknown): string {
  return typeof s === "string" ? s.trim() : "";
}

function weddingClause(p1: string, p2: string): string {
  const a = clean(p1), b = clean(p2);
  if (a && b) return `Congratulate ${a} and ${b} on their wedding. Use both names naturally.`;
  if (a)      return `Congratulate ${a} on their wedding. Use the name ${a}.`;
  if (b)      return `Congratulate ${b} on their wedding. Use the name ${b}.`;
  return "Congratulate the couple on their wedding. No specific names — keep it warm and celebratory.";
}

function newBabyClause(parent: string, baby: string): string {
  const p = clean(parent), b = clean(baby);
  if (p && b) return `Congratulate ${p} on the arrival of their new baby ${b}. Use both names naturally.`;
  if (p)      return `Congratulate ${p} on the arrival of their new baby. Use the parent's name ${p}.`;
  if (b)      return `Congratulate the family on the arrival of baby ${b}. Use the baby's name ${b}.`;
  return "Congratulate the family on the arrival of their new baby. No specific names — keep it warm and general.";
}

function buildPrompts(body: Record<string, unknown>): { system: string; user: string } {
  const occasion = clean(body.occasion) || "Birthday";
  const toneRaw = typeof body.tone === "number" ? body.tone : 3;
  const lengthRaw = clean(body.length) || "Medium";
  const languageRaw = clean(body.language) || "English";

  const toneInstr = TONE[toneRaw] ?? TONE[3];
  const lengthInstr = LENGTH[lengthRaw] ?? LENGTH.Medium;
  const languageInstr = LANGUAGE[languageRaw] ?? LANGUAGE.English;

  const system =
    `You are WishlyAI, a creative wish generator. ${toneInstr} ${lengthInstr} ` +
    `Never use clichés like 'May your day be filled with joy'. Be original and specific. ` +
    `Return ONLY the wish text — no quotes, no labels, no extra formatting.`;

  let guidance = "";
  if (occasion === "Valentine's Day") guidance = VALENTINES_GUIDANCE;

  let base: string;
  if (occasion === "New Baby") {
    base = `Generate a new baby congratulations message. ${newBabyClause(clean(body.parentName), clean(body.babyName))}`;
  } else if (occasion === "Wedding") {
    base = `Generate a wedding congratulations message. ${weddingClause(clean(body.partner1Name), clean(body.partner2Name))}`;
  } else {
    const name = clean(body.name);
    base = name
      ? `Generate a ${occasion.toLowerCase()} wish for ${name}.`
      : `Generate a ${occasion.toLowerCase()} wish.`;
  }

  const user = `${base}${guidance} ${languageInstr}`;
  return { system, user };
}

// ── Handler ────────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, apikey, content-type",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
      },
    });
  }

  if (req.method !== "POST") {
    return json({ error: { message: "Method not allowed" } }, 405);
  }

  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) {
    return json({ error: { message: "Server is missing ANTHROPIC_API_KEY secret." } }, 500);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: { message: "Invalid JSON body." } }, 400);
  }

  const { system, user } = buildPrompts(body);
  const stream = body.stream === true;

  const upstream = await fetch(ANTHROPIC_URL, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system,
      messages: [{ role: "user", content: user }],
      stream,
    }),
  });

  // Pass the upstream status + body straight through. For streaming this
  // forwards Anthropic's SSE frames verbatim, which the iOS client already
  // knows how to parse.
  if (stream && upstream.ok && upstream.body) {
    return new Response(upstream.body, {
      status: 200,
      headers: {
        "content-type": "text/event-stream",
        "cache-control": "no-cache",
        "connection": "keep-alive",
        "Access-Control-Allow-Origin": "*",
      },
    });
  }

  const text = await upstream.text();
  return new Response(text, {
    status: upstream.status,
    headers: {
      "content-type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
});

function json(obj: unknown, status: number): Response {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "content-type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}
