(function () {
  const C = window.BAAA || {};
  const checkoutBase = C.DODO_TEST ? "https://test.checkout.dodopayments.com/buy/" : "https://checkout.dodopayments.com/buy/";
  const redirect = new URL("thanks.html", location.href).href;
  const checkoutURL = checkoutBase + C.DODO_PRODUCT_ID + "?quantity=1&redirect_url=" + encodeURIComponent(redirect);
  const configured = C.DODO_PRODUCT_ID && !/REPLACE_ME/.test(C.DODO_PRODUCT_ID);

  // Fill config-driven bits.
  document.querySelectorAll("[data-price]").forEach(el => el.textContent = C.PRICE);
  document.querySelectorAll("[data-devices]").forEach(el => el.textContent = C.MAX_DEVICES);
  document.querySelectorAll("[data-version]").forEach(el => el.textContent = "v" + C.VERSION);
  document.querySelectorAll("[data-min-macos]").forEach(el => el.textContent = C.MIN_MACOS);
  document.querySelectorAll("[data-support]").forEach(el => { el.textContent = C.SUPPORT_EMAIL; el.href = "mailto:" + C.SUPPORT_EMAIL; });
  document.querySelectorAll("[data-download]").forEach(el => { el.href = C.DOWNLOAD_URL; el.setAttribute("download", ""); });
  document.querySelectorAll("[data-checkout]").forEach(el => {
    el.href = checkoutURL;
    el.target = "_blank";
    el.rel = "noopener";
    if (!configured) {
      el.addEventListener("click", e => { e.preventDefault(); alert("Checkout isn't configured yet. Set DODO_PRODUCT_ID in config.js."); });
    }
  });

  // Thanks page: reflect Dodo's redirect params (payment_id, status).
  const title = document.getElementById("thanksTitle");
  if (title) {
    const status = new URLSearchParams(location.search).get("status");
    if (status && status !== "succeeded" && status !== "processing") {
      title.textContent = "Hmm. Payment didn't go through.";
      document.getElementById("thanksLede").textContent =
        "Dodo reported: " + status + ". Nothing was charged. Try again from the pricing section, or write to us if it keeps happening.";
    }
  }

  // Hero demo: cycle through lines, reacting with Papa's face like the real app.
  const block = document.getElementById("demoBlock");
  if (!block) return;
  const bubble = document.getElementById("demoBubble");
  const papa = document.getElementById("demoPapa");
  const speaker = document.getElementById("demoSpeaker");
  const line = document.getElementById("demoLine");
  const gloss = document.getElementById("demoGloss");
  const done = document.getElementById("demoDone");

  const demos = [
    { speaker: "Papa", line: "Khaana khaya? 'Baad mein' nahi. Abhi jao.", gloss: "Have you eaten? Not 'later'. Go now.", face: "stern" },
    { speaker: "அப்பா", line: "அம்மா உன் குரல் கேட்டா சந்தோஷப்படுவா. ஒரு போன் பண்ணு.", gloss: "Amma would be happy to hear your voice. Give her a call.", face: "happy" },
    { speaker: "पापा", line: "पानी। चाय नहीं। पानी।", gloss: "Water. Not chai. Water.", face: "neutral" },
    { speaker: "Papa", line: "Battery kam hai. Charger lagao. Kitni baar bolna padega?", gloss: "Battery is low. Plug in the charger. How many times must I say it?", face: "worried" },
    { speaker: "ਪਾਪਾ ਜੀ", line: "ਰਾਤ ਹੋ ਗਈ। ਲੈਪਟਾਪ ਬੰਦ। ਸੌਂ ਜਾ।", gloss: "It's night. Laptop off. Sleep.", face: "stern" },
    { speaker: "Dad", line: "Your chair has become your best friend. Time to make it jealous.", gloss: "", face: "neutral" },
  ];
  const face = n => "assets/papa-" + n + ".png";
  let i = 0, timer;
  const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;

  function show(d) {
    speaker.textContent = d.speaker;
    line.textContent = d.line;
    gloss.textContent = d.gloss;
    gloss.style.display = d.gloss ? "" : "none";
    papa.src = face("neutral");
    block.classList.add("open");
    bubble.classList.add("open");
    setTimeout(() => { if (block.classList.contains("open")) papa.src = face(d.face); }, 750);
  }
  function hide(cb) {
    block.classList.remove("open");
    bubble.classList.remove("open");
    setTimeout(cb, reduce ? 0 : 500);
  }
  function loop() {
    show(demos[i % demos.length]);
    i++;
    timer = setTimeout(() => hide(() => { timer = setTimeout(loop, 700); }), 5200);
  }
  done.addEventListener("click", () => {
    clearTimeout(timer);
    papa.src = face("happy");
    setTimeout(() => hide(() => { timer = setTimeout(loop, 600); }), 650);
  });
  setTimeout(loop, 700);
})();
