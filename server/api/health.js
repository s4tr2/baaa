import { config, cors } from "./_dodo.js";

export default function handler(req, res) {
  if (cors(req, res)) return;
  res.status(200).json({
    ok: true,
    mode: config.mode,
    configured: { apiKey: !!config.apiKey, webhookSecret: !!config.webhookSecret, productId: !!config.productId },
  });
}
