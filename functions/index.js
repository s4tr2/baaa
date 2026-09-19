// Baaa backend on Firebase Functions (2nd gen). Hosting rewrites /api/** here.
// Secrets (set once, after upgrading the project to Blaze):
//   firebase functions:secrets:set DODO_API_KEY
//   firebase functions:secrets:set DODO_WEBHOOK_SECRET
// Plain config:
//   DODO_PRODUCT_ID, DODO_MODE ("test" | "live"), SITE_URL  → functions/.env
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret, defineString } from "firebase-functions/params";
import { logger } from "firebase-functions";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { dodo, verifyWebhook, cors } from "./dodo.js";

initializeApp();

const DODO_API_KEY = defineSecret("DODO_API_KEY");
const DODO_WEBHOOK_SECRET = defineSecret("DODO_WEBHOOK_SECRET");
const DODO_PRODUCT_ID = defineString("DODO_PRODUCT_ID", { default: "" });
const DODO_MODE = defineString("DODO_MODE", { default: "live" });
const SITE_URL = defineString("SITE_URL", { default: "https://baaa-app.web.app" });

const region = "us-central1";
const siteUrl = () => SITE_URL.value().replace(/\/$/, "");

export const health = onRequest({ region, cors: false }, (req, res) => {
  if (cors(req, res)) return;
  res.json({
    ok: true,
    mode: DODO_MODE.value(),
    configured: { productId: !!DODO_PRODUCT_ID.value() },
  });
});

/** POST /api/checkout { email?, name?, source?, return_url? } → { checkout_url, session_id } */
export const checkout = onRequest({ region, cors: false, secrets: [DODO_API_KEY] }, async (req, res) => {
  if (cors(req, res)) return;
  if (req.method !== "POST") return res.status(405).json({ error: "POST only" });
  const apiKey = DODO_API_KEY.value();
  const productId = DODO_PRODUCT_ID.value();
  if (!apiKey || !productId) return res.status(503).json({ error: "Checkout is not configured." });

  const body = req.body && typeof req.body === "object" ? req.body : {};
  const email = typeof body.email === "string" && /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(body.email) ? body.email : undefined;
  const name = typeof body.name === "string" ? body.name.slice(0, 120) : undefined;
  const source = typeof body.source === "string" ? body.source.slice(0, 40) : "site";

  let returnUrl = `${siteUrl()}/thanks`;
  try {
    const u = new URL(body.return_url || "");
    if (u.origin === siteUrl() || u.hostname === "localhost") returnUrl = u.href;
  } catch { /* default */ }

  try {
    const session = await dodo(apiKey, DODO_MODE.value(), "/checkouts", {
      product_cart: [{ product_id: productId, quantity: 1 }],
      ...(email ? { customer: { email, ...(name ? { name } : {}) } } : {}),
      return_url: returnUrl,
      metadata: { source, app: "baaa" },
      feature_flags: { allow_discount_code: true },
    });
    res.json({ checkout_url: session.checkout_url, session_id: session.session_id });
  } catch (e) {
    logger.error("checkout session failed", { status: e.status, body: e.body || e.message });
    res.status(502).json({ error: "Could not start checkout. Please try again." });
  }
});

/** POST /api/webhook — verified Dodo events, recorded in Firestore for support lookups. */
export const webhook = onRequest({ region, cors: false, secrets: [DODO_WEBHOOK_SECRET] }, async (req, res) => {
  if (req.method !== "POST") return res.status(405).end();
  const raw = req.rawBody ? req.rawBody.toString("utf8") : JSON.stringify(req.body || {});
  const v = verifyWebhook(DODO_WEBHOOK_SECRET.value(), req.headers, raw);
  if (!v.ok) {
    logger.warn("webhook rejected", { reason: v.reason });
    return res.status(401).json({ error: v.reason });
  }

  let event;
  try { event = JSON.parse(raw); } catch { return res.status(400).json({ error: "invalid JSON" }); }
  const d = event.data || {};
  const db = getFirestore();
  const eventId = req.headers["webhook-id"];

  // Idempotent: Dodo retries, so key documents by webhook id.
  const ref = db.collection("dodo_events").doc(String(eventId));
  if ((await ref.get()).exists) return res.json({ received: true, duplicate: true });

  const record = { type: event.type, at: FieldValue.serverTimestamp(), payment_id: d.payment_id || null };
  switch (event.type) {
    case "payment.succeeded":
      Object.assign(record, { email: d.customer?.email || null, amount: d.total_amount ?? null, currency: d.currency || null, metadata: d.metadata || null });
      break;
    case "license_key.created":
      // Full key stays only in Dodo and the buyer's email; we keep the tail for support.
      Object.assign(record, { email: d.customer?.email || null, key_tail: String(d.key || "").slice(-4), license_key_id: d.id || null, activations_limit: d.activations_limit ?? null });
      break;
    case "refund.succeeded":
    case "dispute.opened":
      // Dodo disables the key itself; the app's periodic validate call drops Pro.
      break;
    default:
      break;
  }
  await ref.set(record);
  logger.info("dodo event", record);
  res.json({ received: true });
});
