# Baaa

Gentle (and not so gentle) nudges from Papa, straight out of your Mac's notch.

Baaa is the father-shaped sibling of [Maaa](https://www.maaa.app/). It lives in the
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
  call-home, bedtime, good morning, low battery, and eye breaks. Add your own
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

## Pro, payments and the landing page

Baaa has a free tier and a one-time **Baaa Pro** purchase sold through
[Dodo Payments](https://dodopayments.com) license keys. Free: meals, water, movement,
bedtime, good morning, all languages, Soft Papa, the 3D Papa. Pro: custom instructions
(your own lines per reminder), your own reminders, Strict and Filmy Papa, call home /
low battery / eye breaks, and your own picture.

Setup, once:

1. In the Dodo dashboard create a one-time product, enable **License keys**, set the
   activation limit to 2, and copy its id (`pdt_...`).
2. Paste it into `Baaa/Pro/ProConfig.swift` (`dodoProductID`) and `site/config.js`
   (`DODO_PRODUCT_ID`). Flip both to test mode while trying Dodo's test cards.
3. Set `redirect_url` handling: the checkout link already sends buyers to
   `thanks.html`, which tells them to paste the emailed key into Settings → Pro.

The app talks to Dodo's `licenses/activate`, `validate` and `deactivate` endpoints
directly (no server of yours involved), re-validates every three days, and keeps Pro
for 30 days offline before falling back to Free.

Landing page lives in `site/` (plain HTML/CSS/JS, no build step):

```sh
make dmg        # build/Baaa.dmg
make site       # copies the DMG and Papa's faces into site/
make serve      # preview at http://localhost:8080
```

Deploy `site/` to any static host (Vercel, Netlify, Cloudflare Pages, GitHub Pages).
`site/downloads/` is git-ignored; either upload the DMG with the site or point
`DOWNLOAD_URL` in `config.js` at a GitHub Release asset.

## Build

Requires Xcode 26 (macOS 14 deployment target) and [xcodegen](https://github.com/yonaskolb/XcodeGen).

```sh
make            # regenerates the Xcode project, builds Release into build/Baaa.app
make run        # builds then launches
make icon       # re-renders the app icon from Scripts/generate_icon.swift
make papa       # rebuilds the bundled Papa faces from Assets/papa-*-source.png
make install    # copies build/Baaa.app to /Applications
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
