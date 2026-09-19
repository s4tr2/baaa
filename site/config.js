// Fill these in once. Everything else on the page reads from here.
window.BAAA = {
  // Product id from the Dodo Payments dashboard (Products → your product → "pdt_...").
  // Set DODO_TEST to true while trying test-mode purchases.
  DODO_PRODUCT_ID: "pdt_0NnvrB7JxweiL6XksiPSB",
  DODO_TEST: true,

  // Served by Firebase Hosting (needs the Blaze plan; Spark refuses executables).
  // Alternative: "https://github.com/s4tr2/baaa/releases/latest/download/Baaa.dmg"
  // once the GitHub repo is public.
  DOWNLOAD_URL: "downloads/Baaa.dmg",

  // Backend = Firebase Functions behind Hosting rewrites (/api/checkout, /api/webhook).
  // Same origin, so this stays empty; the static Dodo link is the fallback if /api fails.
  API_BASE: "",

  PRICE: "$1.99",
  MAX_DEVICES: 2,
  VERSION: "0.2.0",
  MIN_MACOS: "macOS 14 Sonoma",
  SUPPORT_EMAIL: "hello@baaa.app",
};
