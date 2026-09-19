// Fill these in once. Everything else on the page reads from here.
window.BAAA = {
  // Product id from the Dodo Payments dashboard (Products → your product → "pdt_...").
  // Set DODO_TEST to true while trying test-mode purchases.
  DODO_PRODUCT_ID: "pdt_REPLACE_ME",
  DODO_TEST: false,

  // Where the DMG lives. `make site` copies it to downloads/Baaa.dmg.
  // Point this at a GitHub Release asset instead if you'd rather not host the file here.
  DOWNLOAD_URL: "downloads/Baaa.dmg",

  PRICE: "$2.99",
  MAX_DEVICES: 2,
  VERSION: "0.2.0",
  MIN_MACOS: "macOS 14 Sonoma",
  SUPPORT_EMAIL: "hello@baaa.app",
};
