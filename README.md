# Baaapp

Gentle (and not so gentle) nudges from Papa, straight out of your Mac's notch.

Baaapp is the father-shaped sibling of [Maaa](https://www.maaa.app/). It lives in the
menu bar, and every so often an Indian dad slides out of the notch to ask whether
you have eaten, drunk water, called home, or gone to bed.

## What it does

- **Notch UI.** A black block grows out of the hardware notch and Papa peeks over
  its edge with both hands. His line sits in a white speech bubble beside it, with
  the English translation in grey underneath. Hover to reveal "Theek hai Papa" and
  snooze; click the bubble to dismiss. Only the block and bubble take clicks, the
  rest of the panel is click-through. On Macs without a notch it floats just under
  the menu bar instead.
- **Indian father avatar.** Vector-drawn and fully customisable: skin tone, mustache
  (classic, walrus, pencil, clean shaven), glasses, hair and hair colour, optional
  tilak. He blinks, and his expression changes with the reminder (stern for skipped
  meals, happy when it's time to call Mummy).
- **3D Papa by default.** The app ships with rendered Papas, one per expression
  (`Baaa/Resources/papa-<expression>.png`; sources and cutouts in `Assets/`). Moods
  without a render fall back to the neutral face. Settings, Papa, Choose picture…
  swaps in your own PNG with size and peek sliders, and a toggle switches back to the
  hand-drawn Papa. `make papa` regenerates every bundled face from `Assets/papa-*-source.png`
  using Vision for background removal and a head-and-collar crop.
- **Reminders.** Meals at fixed times, water and movement on intervals, weekly
  call-home, bedtime, good morning, low battery, unplug-the-charger when it hits
  100%, eye breaks, and an "empty the Trash" nag when the bin piles up. Add your own
  reminders with your own messages and schedule.
- **Customisable messages.** Add lines per reminder, or tell Papa to use only yours.
  `{name}` becomes what he calls you, `{papa}` becomes his name. Append ` // ` and an
  English line to show a grey translation under your message.
- **Languages and tones.** English, Hinglish, Hindi, Tamil and Punjabi have three
  voices each (Strict Papa, Soft Papa, Filmy Papa). Marathi, Gujarati, Bengali,
  Malayalam, Telugu and Kannada ship with one voice for now.
- **Respectful pacing.** Quiet hours (default 22:00 to 08:00, bedtime and morning
  are allowed through), a daily cap, nothing while you're idle, snooze, and pause
  from the menu bar.
- **Private.** Everything is stored locally in UserDefaults. No account, no network.

## Pro, payments, backend and the landing page

Baaapp has a free tier and a one-time **Baaapp Pro** purchase ($1.99, 2 Macs) sold through
[Dodo Payments](https://dodopayments.com) license keys. Free: meals, water, movement,
bedtime, good morning, all languages, Soft Papa, the 3D Papa. Pro: custom instructions
(your own lines per reminder), your own reminders, Strict and Filmy Papa, call home /
low battery / unplug / eye breaks / Trash, and your own picture.

**Purchase flow.** Get Pro → Dodo checkout → Dodo emails the key and redirects to
`/thanks?payment_id=…&status=succeeded&license_key=…` → the page shows the key and opens
`baaa://activate?key=…` → the app activates it with Dodo's public `/licenses/activate`
endpoint (no API key involved) and re-validates every three days. Refunds disable the
key on Dodo's side, so Pro drops off by itself.

**Create the product** (needs a Dodo API key from Developer → API Keys):

```sh
DODO_API_KEY=… ./Scripts/dodo_create_product.sh          # live
DODO_API_KEY=… DODO_MODE=test ./Scripts/dodo_create_product.sh
```

It creates the $1.99 product with a 2-activation license key and writes the `pdt_…` id
into `Baaa/Pro/ProConfig.swift`, `site/config.js` and `functions/.env`.

**Backend** is Firebase Functions in `functions/`, reached through Hosting rewrites:

| Route | Purpose |
|---|---|
| `POST /api/checkout` | Single-use Dodo checkout session (the site falls back to the static link if this fails) |
| `POST /api/webhook` | Verifies Dodo webhooks (Standard Webhooks HMAC) and records events in Firestore |
| `GET /api/health` | Shows what is configured |

Firebase project: `baaa-app`. **It must be on the Blaze plan**: Spark refuses `.dmg`
files on Hosting and has no Cloud Functions. Then, once:

```sh
firebase functions:secrets:set DODO_API_KEY
firebase functions:secrets:set DODO_WEBHOOK_SECRET     # from Dodo → Developer → Webhooks
cp functions/.env.example functions/.env               # DODO_PRODUCT_ID, DODO_MODE, SITE_URL
make deploy                                            # DMG + site + functions
```

Register `https://baaa-app.web.app/api/webhook` as the webhook URL in Dodo.

Landing page lives in `site/` (plain HTML/CSS/JS, no build step):

```sh
make dmg        # build/Baaapp.dmg
make release    # GitHub Release with the DMG attached (alternative download host)
make deploy     # refresh site/, deploy hosting + functions to Firebase
make serve      # preview at http://localhost:8080
```

## Build

Requires Xcode 26 (macOS 14 deployment target) and [xcodegen](https://github.com/yonaskolb/XcodeGen).

```sh
make            # regenerates the Xcode project, builds Release into build/Baaapp.app
make run        # builds then launches
make icon       # re-renders the app icon from Scripts/generate_icon.swift
make papa       # rebuilds the bundled Papa faces from Assets/papa-*-source.png
make install    # copies build/Baaapp.app to /Applications
```

Or open `Baaa.xcodeproj` after `xcodegen generate` and hit Run.

## Project layout

```
Baaa/
  App/        main.swift, AppDelegate, StatusBarController (menu bar)
  Models/     AppSettings, ReminderKind, Schedule, Language/Tone, SettingsStore
  Messages/   MessageLibrary — built-in lines (with English gloss) per language × tone × reminder
  Engine/     ReminderEngine (when to speak), battery + idle monitors, launch at login
  Notch/      NotchGeometry (finds the notch), NotchPanel, NotchController, NotchView
  Avatar/     PapaAvatarView / PeekingPapaView (vector father), AvatarConfig, AvatarImageStore
  Settings/   Settings window: General, Reminders, Messages, Papa, About
Scripts/      generate_icon.swift
```

## Notes

- The app is an agent (`LSUIElement`), so there is no Dock icon. Use the mustache
  in the menu bar.
- The build is ad-hoc signed and unsandboxed. Before a public download, sign with a
  Developer ID and notarize, otherwise Gatekeeper shows "damaged" (the FAQ on the site
  explains the right-click → Open workaround for early testers).
