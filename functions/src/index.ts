import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

// ---------------------------------------------------------------------------
// In-memory rate limiter (per Cloud Function instance)
// ---------------------------------------------------------------------------
const rateLimitMap = new Map<string, number[]>();
const RATE_LIMIT_MAX = 20; // max requests per window
const RATE_LIMIT_WINDOW_MS = 60_000; // 1 minute

function isRateLimited(uid: string): boolean {
  const now = Date.now();
  const timestamps = rateLimitMap.get(uid) || [];
  const recent = timestamps.filter((t) => now - t < RATE_LIMIT_WINDOW_MS);

  if (recent.length >= RATE_LIMIT_MAX) {
    rateLimitMap.set(uid, recent);
    return true;
  }

  recent.push(now);
  rateLimitMap.set(uid, recent);
  return false;
}

// ---------------------------------------------------------------------------
// Request / response types
// ---------------------------------------------------------------------------
interface ClaudeMessage {
  role: string;
  content: string;
}

interface ClaudeRequestBody {
  model: string;
  max_tokens: number;
  system: string;
  messages: ClaudeMessage[];
}

// ---------------------------------------------------------------------------
// Cloud Function: claudeProxy
// ---------------------------------------------------------------------------
export const claudeProxy = functions
  .runWith({ timeoutSeconds: 120, memory: "256MB", secrets: ["ANTHROPIC_API_KEY"] })
  .https.onRequest(async (req, res) => {
    // CORS (safe to include for potential future web usage)
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    // -----------------------------------------------------------------------
    // 1. Authenticate: verify Firebase ID token
    // -----------------------------------------------------------------------
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({ error: "Missing or invalid Authorization header" });
      return;
    }

    const idToken = authHeader.split("Bearer ")[1];
    let uid: string;
    try {
      const decoded = await admin.auth().verifyIdToken(idToken);
      uid = decoded.uid;
    } catch {
      res.status(401).json({ error: "Invalid Firebase ID token" });
      return;
    }

    // -----------------------------------------------------------------------
    // 2. Rate limit
    // -----------------------------------------------------------------------
    if (isRateLimited(uid)) {
      res.status(429).json({ error: "Rate limit exceeded. Please wait and try again." });
      return;
    }

    // -----------------------------------------------------------------------
    // 3. Validate request body
    // -----------------------------------------------------------------------
    const body = req.body as ClaudeRequestBody;
    if (!body.model || !body.max_tokens || !body.system || !body.messages) {
      res.status(400).json({
        error: "Missing required fields: model, max_tokens, system, messages",
      });
      return;
    }

    // -----------------------------------------------------------------------
    // 4. Get Anthropic API key from environment
    // -----------------------------------------------------------------------
    const anthropicApiKey = process.env.ANTHROPIC_API_KEY;
    if (!anthropicApiKey) {
      console.error("ANTHROPIC_API_KEY not configured in environment");
      res.status(500).json({ error: "Server configuration error" });
      return;
    }

    // -----------------------------------------------------------------------
    // 5. Forward request to Anthropic API
    // -----------------------------------------------------------------------
    try {
      const anthropicResponse = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "x-api-key": anthropicApiKey,
          "anthropic-version": "2023-06-01",
          "content-type": "application/json",
        },
        body: JSON.stringify({
          model: body.model,
          max_tokens: body.max_tokens,
          system: body.system,
          messages: body.messages,
        }),
      });

      const responseData = await anthropicResponse.json();

      if (!anthropicResponse.ok) {
        res.status(anthropicResponse.status).json(responseData);
        return;
      }

      res.status(200).json(responseData);
    } catch (error) {
      console.error("Error calling Anthropic API:", error);
      res.status(502).json({ error: "Failed to reach AI service" });
    }
  });
