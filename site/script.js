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
  // Checkout: prefer a single-use session from our backend (carries return_url and
  // metadata server-side); fall back to Dodo's static payment link.
  document.querySelectorAll("[data-checkout]").forEach(el => {
    el.href = configured ? checkoutURL : "#pricing";
    el.rel = "noopener";
    el.addEventListener("click", async e => {
      if (!configured) { e.preventDefault(); alert("Checkout isn't configured yet. Set DODO_PRODUCT_ID in config.js."); return; }
      e.preventDefault();
      const label = el.innerHTML;
      el.innerHTML = "<span>Opening checkout…</span>";
      try {
        const r = await fetch((C.API_BASE || "").replace(/\/$/, "") + "/api/checkout", {
          method: "POST", headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ source: "site", return_url: redirect })
        });
        const j = await r.json();
        if (!r.ok || !j.checkout_url) throw new Error(j.error || "no checkout_url");
        location.href = j.checkout_url;
      } catch (err) {
        console.warn("checkout session failed, using static link", err);
        location.href = checkoutURL;
        el.innerHTML = label;
      }
    });
  });

  // Thanks page: Dodo redirects here with payment_id, status, email and license_key.
  const title = document.getElementById("thanksTitle");
  if (title) {
    const q = new URLSearchParams(location.search);
    const status = q.get("status");
    const keys = (q.get("license_key") || "").split(",").map(k => k.trim()).filter(Boolean);
    const lede = document.getElementById("thanksLede");
    const keyBox = document.getElementById("keyBox");
    const keyText = document.getElementById("keyText");
    const activate = document.getElementById("activateLink");
    const copyBtn = document.getElementById("copyKey");
    const emailNote = document.getElementById("emailNote");

    if (status && status !== "succeeded" && status !== "processing") {
      title.textContent = "Hmm. Payment didn't go through.";
      lede.textContent = "Dodo reported: " + status + ". Nothing was charged. You can try again, or write to us if it keeps happening.";
      document.getElementById("steps").hidden = true;
      document.getElementById("retryRow").hidden = false;
    } else if (keys.length) {
      const key = keys[0];
      keyText.textContent = key;
      keyBox.hidden = false;
      activate.href = "baaa://activate?key=" + encodeURIComponent(key);
      lede.textContent = keys.length > 1
        ? "Here are your " + keys.length + " license keys. Each one works on " + C.MAX_DEVICES + " Macs."
        : "Here's your license key. It works on " + C.MAX_DEVICES + " Macs, and we've emailed a copy too.";
      if (keys.length > 1) keyText.textContent = keys.join("\n");
      const email = q.get("email");
      if (email) emailNote.textContent = "A copy went to " + email + ".";
      copyBtn.addEventListener("click", async () => {
        try { await navigator.clipboard.writeText(keys.join("\n")); copyBtn.textContent = "Copied"; setTimeout(() => copyBtn.textContent = "Copy", 1500); }
        catch { copyBtn.textContent = "Select and copy"; }
      });
      // Try to hand the key to the app straight away; the button stays as the manual path.
      // (?noapp=1 skips this, handy when checking the page in a browser without Baaa.)
      if (!q.get("noapp")) setTimeout(() => { location.href = activate.href; }, 900);
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
