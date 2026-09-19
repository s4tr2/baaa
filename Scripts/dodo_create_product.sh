#!/usr/bin/env bash
# Creates the Baaapp Pro product in Dodo Payments and writes its id into the app,
# the site and the Functions config.
#
#   DODO_API_KEY=… ./Scripts/dodo_create_product.sh            # live mode
#   DODO_API_KEY=… DODO_MODE=test ./Scripts/dodo_create_product.sh
#
# Optional: PRICE_CENTS (default 199), ACTIVATIONS (default 2), PRODUCT_NAME.
set -euo pipefail
cd "$(dirname "$0")/.."

: "${DODO_API_KEY:?Set DODO_API_KEY (Dodo dashboard → Developer → API Keys)}"
MODE="${DODO_MODE:-live}"
BASE="https://live.dodopayments.com"; [ "$MODE" = "test" ] && BASE="https://test.dodopayments.com"
PRICE_CENTS="${PRICE_CENTS:-199}"
ACTIVATIONS="${ACTIVATIONS:-2}"
PRODUCT_NAME="${PRODUCT_NAME:-Baaapp Pro}"

api() { # api METHOD PATH [JSON]
  local method="$1" path="$2" data="${3:-}"
  if [ -n "$data" ]; then
    curl -sS -X "$method" "$BASE$path" -H "Authorization: Bearer $DODO_API_KEY" \
      -H "Content-Type: application/json" -H "Accept: application/json" --data "$data" -w '\n%{http_code}'
  else
    curl -sS -X "$method" "$BASE$path" -H "Authorization: Bearer $DODO_API_KEY" -H "Accept: application/json" -w '\n%{http_code}'
  fi
}
json_get() { python3 -c "import sys,json; d=json.load(sys.stdin); print(d$1)" 2>/dev/null; }

echo "Mode: $MODE  ($BASE)"

# 1. License-key entitlement (the current way; falls back to the legacy product flags below).
ENT_BODY=$(python3 - "$ACTIVATIONS" <<'PY'
import json,sys
print(json.dumps({
  "name": "Baaapp Pro license key",
  "description": "Unlocks Baaapp Pro on up to %s Macs." % sys.argv[1],
  "integration_type": "license_key",
  "integration_config": {
    "activations_limit": int(sys.argv[1]),
    "fulfillment_mode": "auto",
    "activation_message": "Thank you! Open Baaapp from the menu bar → Settings → Pro, paste this key and press Activate. Or click the Activate button on the thank-you page."
  }
}))
PY
)
ENT_RESP=$(api POST /entitlements "$ENT_BODY")
ENT_CODE=$(tail -n1 <<<"$ENT_RESP"); ENT_JSON=$(sed '$d' <<<"$ENT_RESP")
ENT_ID=""
if [[ "$ENT_CODE" =~ ^2 ]]; then
  ENT_ID=$(json_get "['id']" <<<"$ENT_JSON" || true)
  echo "Entitlement created: $ENT_ID"
else
  echo "Entitlement API returned $ENT_CODE, using legacy license-key flags on the product instead." >&2
  echo "$ENT_JSON" >&2
fi

# 2. The product.
PROD_BODY=$(python3 - "$PRODUCT_NAME" "$PRICE_CENTS" "$ACTIVATIONS" "$ENT_ID" <<'PY'
import json,sys
name, cents, acts, ent = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
body = {
  "name": name,
  "description": "One-time purchase. Custom instructions, your own reminders, Strict & Filmy Papa, call home / low battery / eye breaks, and your own picture of Papa. Works on %d Macs." % acts,
  "tax_category": "saas",
  "price": {
    "type": "one_time_price",
    "currency": "USD",
    "price": cents,
    "discount_bps": 0,
    "purchasing_power_parity": False,
    "tax_inclusive": False,
  },
  "metadata": {"app": "baaa"},
}
if ent:
  body["entitlements"] = [{"entitlement_id": ent}]
else:
  body["license_key_enabled"] = True
  body["license_key_activations_limit"] = acts
  body["license_key_activation_message"] = "Open Baaapp from the menu bar → Settings → Pro, paste this key and press Activate."
print(json.dumps(body))
PY
)
PROD_RESP=$(api POST /products "$PROD_BODY")
PROD_CODE=$(tail -n1 <<<"$PROD_RESP"); PROD_JSON=$(sed '$d' <<<"$PROD_RESP")
[[ "$PROD_CODE" =~ ^2 ]] || { echo "Product creation failed ($PROD_CODE):" >&2; echo "$PROD_JSON" >&2; exit 1; }
PID=$(json_get "['product_id']" <<<"$PROD_JSON")
[ -n "$PID" ] || { echo "No product_id in response:" >&2; echo "$PROD_JSON" >&2; exit 1; }
echo "Product created: $PID  ($PRODUCT_NAME, \$$(python3 -c "print(f'{$PRICE_CENTS/100:.2f}')"))"

# 3. Wire it in.
sed -i '' "s/static let dodoProductID = \"[^\"]*\"/static let dodoProductID = \"$PID\"/" Baaa/Pro/ProConfig.swift
sed -i '' "s/DODO_PRODUCT_ID: \"[^\"]*\"/DODO_PRODUCT_ID: \"$PID\"/" site/config.js
if [ "$MODE" = "test" ]; then
  sed -i '' 's/static let environment: Environment = .live/static let environment: Environment = .test/' Baaa/Pro/ProConfig.swift
  sed -i '' 's/DODO_TEST: false/DODO_TEST: true/' site/config.js
else
  sed -i '' 's/static let environment: Environment = .test/static let environment: Environment = .live/' Baaa/Pro/ProConfig.swift
  sed -i '' 's/DODO_TEST: true/DODO_TEST: false/' site/config.js
fi
[ -f functions/.env ] || cp functions/.env.example functions/.env
sed -i '' "s/^DODO_PRODUCT_ID=.*/DODO_PRODUCT_ID=$PID/; s/^DODO_MODE=.*/DODO_MODE=$MODE/" functions/.env

CHECKOUT="https://checkout.dodopayments.com/buy/$PID"; [ "$MODE" = "test" ] && CHECKOUT="https://test.checkout.dodopayments.com/buy/$PID"
cat <<MSG

Wired into Baaa/Pro/ProConfig.swift, site/config.js and functions/.env.
Static checkout link: $CHECKOUT?quantity=1&redirect_url=https://baaa-app.web.app/thanks

Next: make install && make deploy   (deploy needs the Firebase project on Blaze)
MSG
