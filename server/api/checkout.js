// POST /api/checkout  { email?, name?, source?, return_url? }  → { checkout_url, session_id }
// Creates a single-use Dodo checkout session for Baaa Pro. The static payment link
// still works without this; sessions just let us pin return_url and metadata server-side.
import { config, cors, dodo } from "./_dodo.js";

export default async function handler(req, res) {
  if (cors(req, res)) return;
  if (req.method !== "POST") return res.status(405).json({ error: "POST only" });
  if (!config.apiKey || !config.productId) {
    return res.status(503).json({ error: "Checkout is not configured (DODO_API_KEY / DODO_PRODUCT_ID missing)." });
  }

  const body = typeof req.body === "object" && req.body ? req.body : {};
  const email = typeof body.email === "string" && /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(body.email) ? body.email : undefined;
  const name = typeof body.name === "string" ? body.name.slice(0, 120) : undefined;
  const source = typeof body.source === "string" ? body.source.slice(0, 40) : "site";

  // Only ever send buyers back to our own thanks page.
  let returnUrl = `${config.siteUrl}/thanks`;
  try {
    const u = new URL(body.return_url || "");
    if (u.origin === config.siteUrl || u.hostname === "localhost") returnUrl = u.href;
  } catch { /* keep default */ }

  try {
    const session = await dodo("/checkouts", {
      product_cart: [{ product_id: config.productId, quantity: 1 }],
      ...(email ? { customer: { email, ...(name ? { name } : {}) } } : {}),
      return_url: returnUrl,
      metadata: { source, app: "baaa" },
      feature_flags: { allow_discount_code: true },
    });
    res.status(200).json({ checkout_url: session.checkout_url, session_id: session.session_id });
  } catch (e) {
    console.error("checkout session failed", e.status, e.body || e.message);
    res.status(502).json({ error: "Could not start checkout. Please try again." });
  }
}
