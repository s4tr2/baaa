// POST /api/webhook — receives Dodo events. Register this URL in Dodo → Developer → Webhooks
// and paste the signing secret into DODO_WEBHOOK_SECRET. Returns 2xx only for verified events.
import { config as cfg, verifyWebhook, readRawBody } from "./_dodo.js";

// Keep the raw body: the signature is computed over the exact bytes Dodo sent.
export const config = { api: { bodyParser: false } };

export default async function handler(req, res) {
  if (req.method !== "POST") return res.status(405).end();
  if (!cfg.webhookSecret) return res.status(503).json({ error: "DODO_WEBHOOK_SECRET not set" });

  const raw = await readRawBody(req);
  const v = verifyWebhook(req.headers, raw);
  if (!v.ok) {
    console.warn("webhook rejected:", v.reason);
    return res.status(401).json({ error: v.reason });
  }

  let event;
  try { event = JSON.parse(raw); } catch { return res.status(400).json({ error: "invalid JSON" }); }

  const d = event.data || {};
  switch (event.type) {
    case "payment.succeeded":
      console.log(JSON.stringify({ evt: event.type, payment_id: d.payment_id, email: d.customer?.email, amount: d.total_amount, currency: d.currency, metadata: d.metadata }));
      break;
    case "license_key.created":
      // Key is masked in logs on purpose; Dodo already emailed it and showed it on /thanks.
      console.log(JSON.stringify({ evt: event.type, payment_id: d.payment_id, email: d.customer?.email, key_tail: String(d.key || "").slice(-4), limit: d.activations_limit }));
      break;
    case "refund.succeeded":
    case "dispute.opened":
      // Dodo disables the key itself on refund; the app's periodic validate call will drop Pro.
      console.log(JSON.stringify({ evt: event.type, payment_id: d.payment_id }));
      break;
    default:
      console.log(JSON.stringify({ evt: event.type }));
  }
  res.status(200).json({ received: true });
}
