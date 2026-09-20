// Fill these in once. Everything else on the page reads from here.
window.BAAA = {
  // Product id from the Dodo Payments dashboard (Products → your product → "pdt_...").
  // Live product. Test-mode twin: pdt_0NnvrB7JxweiL6XksiPSB (set DODO_TEST to true to use it).
  DODO_PRODUCT_ID: "pdt_0NnvtWeB56KBh3VoNkzAH",
  DODO_TEST: false,

  // Latest GitHub Release asset (repo is public). Switch to "downloads/Baaapp.dmg" if
  // you move the file onto Firebase Hosting after upgrading to Blaze.
  DOWNLOAD_URL: "https://github.com/s4tr2/baaa/releases/latest/download/Baaapp.dmg",

  // Backend = Firebase Functions behind Hosting rewrites (/api/checkout, /api/webhook).
  // Same origin, so this stays empty; the static Dodo link is the fallback if /api fails.
  API_BASE: "",

  PRICE: "$1.99",
  MAX_DEVICES: 2,
  VERSION: "0.2.0",
  MIN_MACOS: "macOS 14 Sonoma",
  SUPPORT_EMAIL: "hello@baaa.app",

  // Google Analytics 4 web stream (property "Baaapp" under account 339144949, linked to
  // the Firebase project). The gtag loader in each page's <head> uses the same id.
  GA_MEASUREMENT_ID: "G-ZZVN0C3XXE",
};
