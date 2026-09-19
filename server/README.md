# Baaa backend (Vercel)

Three tiny serverless functions that hold the Dodo Payments secrets so they never
ship inside the app or the landing page.

| Route | Purpose |
|---|---|
| `POST /api/checkout` | Creates a single-use Dodo checkout session for Baaa Pro and returns `checkout_url`. The site calls this; if it fails it falls back to the static payment link. |
| `POST /api/webhook` | Verifies Dodo webhooks (Standard Webhooks HMAC) and logs payments, license keys, refunds. |
| `GET /api/health` | Shows which env vars are set. |

## Environment variables (Vercel → Project → Settings → Environment Variables)

| Name | Where to get it |
|---|---|
| `DODO_API_KEY` | Dodo dashboard → Developer → API Keys |
| `DODO_WEBHOOK_SECRET` | Dodo dashboard → Developer → Webhooks → your endpoint → signing secret |
| `DODO_PRODUCT_ID` | Products → Baaa Pro → `pdt_...` |
| `DODO_MODE` | `test` while trying test cards, then `live` |
| `SITE_URL` | `https://baaa-app.web.app` (or your custom domain) |

Set them with the CLI if you prefer:

```sh
cd server
vercel env add DODO_API_KEY production
vercel env add DODO_WEBHOOK_SECRET production
vercel env add DODO_PRODUCT_ID production
vercel --prod
```

Webhook URL to register in Dodo: `https://baaa-api.vercel.app/api/webhook`.

## The full flow

1. Buyer clicks **Get Baaa Pro** → site asks `/api/checkout` → Dodo checkout opens.
2. Dodo charges, generates a license key, emails it, and redirects to
   `/thanks?payment_id=…&status=succeeded&email=…&license_key=…`.
3. The thanks page shows the key and opens `baaa://activate?key=…`; the app
   activates it against Dodo's public `/licenses/activate` endpoint and stores the
   instance id. Manual paste in Settings → Pro is the fallback.
4. The app re-validates every 3 days with `/licenses/validate`. Refunds disable the
   key on Dodo's side, so Pro drops off automatically.
