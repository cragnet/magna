# Magna

AI-powered notification manager for Android. Summarize, automate & declutter your alerts.

Built on a robust Flutter + Kotlin foundation, Magna intercepts your notifications, applies intelligent rules, and delivers exactly the information you need — without the noise.

---

## Features

### The Glance
One clean, persistent, expandable summary notification replaces dozens of pings. Tap to expand, swipe to clear, or let it stay until you are ready.

### Dual-Engine AI
- **Local AI** (Gemini Nano on-device) — 100% private, offline summarization and importance tagging
- **Cloud AI** — OpenAI, Google Gemini, Claude, OpenRouter, Ollama, or any OpenAI-compatible endpoint
- **Auto tier** — tries local first, falls back to cloud automatically
- Per-rule engine selection: choose which AI powers each automation rule

### Magic Rule Builder
Create powerful notification automations in plain English, then fine-tune with a block-based precision editor:
- **Conditions:** App, keyword, regex, time & day range, OTP detection
- **Actions:** Add to Glance, dismiss, summarize, batch release, copy OTP, TTS readout, custom vibration, webhook
- **Priority system:** higher-priority rules evaluate first
- **AI tier per rule:** control exactly which engine handles each workflow

### Power Automation
- **Batch release** — hold notifications and release them as a single digest on screen unlock
- **OTP copy** — automatically copy verification codes to clipboard
- **TTS readout** — speak summaries aloud via Android Text-to-Speech
- **Custom vibrations** — Heartbeat, SOS, Double-tap patterns
- **Webhook integrations** — POST notification data as JSON to Home Assistant, IFTTT, Zapier, Node-RED, or any custom server

### Scheduled Digest Summaries
Flush and summarise at fixed times, recurring intervals, daily, or weekly schedules — regardless of threshold. Per-app digest filtering and a separate digest AI prompt included.

### Analytics & History
- Searchable notification history (last 30 days)
- Hourly/daily volume charts
- Per-app breakdowns and top distracting apps
- Service log with filterable levels

### Privacy & Security
- **Biometric app lock** — fingerprint / face / PIN gate with configurable timeout
- Local AI keeps data on-device
- Cloud AI data is encrypted in transit and deleted immediately after processing
- No ads. Works fully offline.

### Provider Resilience
- Up to 2 backup providers with automatic fallback chain
- WiFi-based provider switching — use local Ollama at home, cloud elsewhere
- Retry queue for failed AI calls with exponential backoff

### Other Features
- Per-app thresholds, cooldowns, and custom notification colours
- Original actions preserved (Reply, Mark as read)
- App icons & colours on summary notifications
- Dark, Light, or System theme
- Import / Export settings
- In-app service restart (recover from force-stop without system settings)
- Cloud CI builds via GitHub Actions

---

## Supported AI Providers

| Provider | API Key | Notes |
|----------|---------|-------|
| OpenAI / Compatible | Yes | Any OpenAI-compatible endpoint |
| Google Gemini | Yes | Cloud Gemini models |
| Gemini Nano | No | On-device via ML Kit (Pixel 8+ / supported devices) |
| Claude (Anthropic) | Yes | Direct or via OpenRouter |
| OpenRouter | Yes | Access to many models including free tiers |
| Ollama | Optional | Self-hosted local server |

---

## Quick Start

1. **Install APK** from releases or build locally
2. **Grant permissions:**
   - Notification access
   - App usage access
   - Battery optimisation exclusion
3. **Configure AI Provider:** Settings → AI Provider → select engine, enter API key
4. **Enable The Glance** (optional) — replaces per-app pings with one persistent summary
5. **Create Rules** (optional) — automate how different apps, keywords, or times are handled
6. **Select Apps:** choose which apps to monitor

---

## Building

### Cloud Build (Recommended)
APKs are built automatically via GitHub Actions on every push to `master`.

### Local Build
**Requirements:** Flutter SDK, Android SDK (API 26+), Java 17

```bash
flutter pub get
flutter build apk --release
```

---

## Architecture

- **Flutter** — configuration, visualisation, rule editor, analytics
- **Native Kotlin** — notification interception, rule evaluation, AI dispatch, webhook execution, TTS, vibrations
- **SharedPreferences** — lightweight bridge between native and Flutter layers

---

## License

MIT License — feel free to fork and modify.
