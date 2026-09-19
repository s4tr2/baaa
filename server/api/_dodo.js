// Shared helpers for the Baaa backend. Secrets come from Vercel env vars:
//   DODO_API_KEY         Dodo Payments API key (Developer → API keys)
//   DODO_WEBHOOK_SECRET  Webhook signing secret (Developer → Webhooks), starts with whsec_
//   DODO_PRODUCT_ID      Baaa Pro product id (pdt_...)
//   DODO_MODE            "test" or "live" (default live)
//   SITE_URL             https://baaa-app.web.app (used for CORS and return_url)
import { createHmac, timingSafeEqual } from "node:crypto";

export const config = {
  apiKey: process.env.DODO_API_KEY || "",
  webhookSecret: process.env.DODO_WEBHOOK_SECRET || "",
  productId: process.env.DODO_PRODUCT_ID || "",
  mode: process.env.DODO_MODE === "test" ? "test" : "live",
  siteUrl: (process.env.SITE_URL || "https://baaa-app.web.app").replace(/\/$/, ""),
};

export const apiBase = config.mode === "test" ? "https://test.dodopayments.com" : "https://live.dodopayments.com";

const allowedOrigins = new Set([
  config.siteUrl,
  "https://baaa-app.web.app",
  "https://baaa-app.firebaseapp.com",
  "https://baaa.app",
  "https://www.baaa.app",
  "http://localhost:8080",
]);

export function cors(req, res) {
  const origin = req.headers.origin || "";
  if (allowedOrigins.has(origin) || /^http:\/\/localhost:\d+$/.test(origin)) {
    res.setHeader("Access-Control-Allow-Origin", origin);
    res.setHeader("Vary", "Origin");
  }
  res.setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  res.setHeader("Access-Control-Max-Age", "86400");
  if (req.method === "OPTIONS") { res.status(204).end(); return true; }
  return false;
}

export async function dodo(path, body) {
  const r = await fetch(apiBase + path, {
    method: "POST",
    headers: { Authorization: `Bearer ${config.apiKey}`, "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify(body),
  });
  const text = await r.text();
  let json = {};
  try { json = text ? JSON.parse(text) : {}; } catch { json = { message: text }; }
  if (!r.ok) throw Object.assign(new Error(json.message || `Dodo returned ${r.status}`), { status: r.status, body: json });
  return json;
}

/** Standard Webhooks verification: HMAC-SHA256 over `${id}.${timestamp}.${rawBody}`. */
export function verifyWebhook(headers, rawBody) {
  const id = headers["webhook-id"];
  const ts = headers["webhook-timestamp"];
  const sigHeader = headers["webhook-signature"];
  if (!id || !ts || !sigHeader) return { ok: false, reason: "missing signature headers" };

  const age = Math.abs(Date.now() / 1000 - Number(ts));
  if (!Number.isFinite(age) || age > 5 * 60) return { ok: false, reason: "timestamp outside tolerance" };

  const secret = config.webhookSecret.startsWith("whsec_")
    ? Buffer.from(config.webhookSecret.slice(6), "base64")
    : Buffer.from(config.webhookSecret, "utf8");
  const expected = createHmac("sha256", secret).update(`${id}.${ts}.${rawBody}`).digest();

  // Header may carry several space-separated "v1,<base64>" signatures during secret rotation.
  const candidates = String(sigHeader).split(" ").map(s => s.includes(",") ? s.split(",")[1] : s);
  for (const c of candidates) {
    const got = Buffer.from(c, "base64");
    if (got.length === expected.length && timingSafeEqual(got, expected)) return { ok: true };
  }
  return { ok: false, reason: "signature mismatch" };
}

export function readRawBody(req) {
  // If a body parser already ran, use what it left us; strings/Buffers are exact,
  // objects are a best effort (bodyParser is disabled on the webhook route so this is rare).
  if (typeof req.body === "string") return Promise.resolve(req.body);
  if (Buffer.isBuffer(req.body)) return Promise.resolve(req.body.toString("utf8"));
  if (req.body && typeof req.body === "object") return Promise.resolve(JSON.stringify(req.body));
  return new Promise((resolve, reject) => {
    let data = "";
    req.setEncoding("utf8");
    req.on("data", chunk => { data += chunk; });
    req.on("end", () => resolve(data));
    req.on("error", reject);
  });
}
