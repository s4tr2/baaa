// Shared Dodo Payments helpers for the Firebase backend.
import { createHmac, timingSafeEqual } from "node:crypto";

export function apiBase(mode) {
  return mode === "test" ? "https://test.dodopayments.com" : "https://live.dodopayments.com";
}

export async function dodo(apiKey, mode, path, body) {
  const r = await fetch(apiBase(mode) + path, {
    method: "POST",
    headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify(body),
  });
  const text = await r.text();
  let json = {};
  try { json = text ? JSON.parse(text) : {}; } catch { json = { message: text }; }
  if (!r.ok) throw Object.assign(new Error(json.message || `Dodo returned ${r.status}`), { status: r.status, body: json });
  return json;
}

/** Standard Webhooks: HMAC-SHA256 over `${id}.${timestamp}.${rawBody}`, secret is whsec_<base64>. */
export function verifyWebhook(secretValue, headers, rawBody) {
  const id = headers["webhook-id"];
  const ts = headers["webhook-timestamp"];
  const sigHeader = headers["webhook-signature"];
  if (!id || !ts || !sigHeader) return { ok: false, reason: "missing signature headers" };
  const age = Math.abs(Date.now() / 1000 - Number(ts));
  if (!Number.isFinite(age) || age > 5 * 60) return { ok: false, reason: "timestamp outside tolerance" };
  const secret = secretValue.startsWith("whsec_") ? Buffer.from(secretValue.slice(6), "base64") : Buffer.from(secretValue, "utf8");
  const expected = createHmac("sha256", secret).update(`${id}.${ts}.${rawBody}`).digest();
  for (const part of String(sigHeader).split(" ")) {
    const b64 = part.includes(",") ? part.split(",")[1] : part;
    const got = Buffer.from(b64, "base64");
    if (got.length === expected.length && timingSafeEqual(got, expected)) return { ok: true };
  }
  return { ok: false, reason: "signature mismatch" };
}

const allowedOrigins = new Set([
  "https://baaa-app.web.app",
  "https://baaa-app.firebaseapp.com",
  "https://baaa.app",
  "https://www.baaa.app",
]);

export function cors(req, res) {
  const origin = req.headers.origin || "";
  if (allowedOrigins.has(origin) || /^http:\/\/localhost:\d+$/.test(origin)) {
    res.set("Access-Control-Allow-Origin", origin);
    res.set("Vary", "Origin");
  }
  res.set("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  res.set("Access-Control-Max-Age", "86400");
  if (req.method === "OPTIONS") { res.status(204).end(); return true; }
  return false;
}
