// Fill these in once. Everything else on the page reads from here.
window.BAAA = {
  // Product id from the Dodo Payments dashboard (Products → your product → "pdt_...").
  // Set DODO_TEST to true while trying test-mode purchases.
  DODO_PRODUCT_ID: "pdt_REPLACE_ME",
  DODO_TEST: false,

  // The DMG is attached to each GitHub Release (`make release`); Firebase's free plan
  // won't host executables. "latest" always resolves to the newest release.
  DOWNLOAD_URL: "https://github.com/s4tr2/baaa/releases/latest/download/Baaa.dmg",

  // Optional serverless backend (see server/). When set, "Get Pro" creates a single-use
  // Dodo checkout session through it; when empty, Dodo's static payment link is used,
  // which already returns the license key to the thanks page.
  API_BASE: "",

  PRICE: "$2.99",
  MAX_DEVICES: 2,
  VERSION: "0.2.0",
  MIN_MACOS: "macOS 14 Sonoma",
  SUPPORT_EMAIL: "hello@baaa.app",
};
