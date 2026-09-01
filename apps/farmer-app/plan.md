# Citadel Farmer App — Flutter Build Plan

> **Your role**: Workstream 04 — Farmer mobile app  
> **Goal**: Build the farmer-facing action surface in Flutter, progressing as far as possible *without* waiting on firmware, AI, backend, or dashboard teammates.

---

## 1. What you own

The farmer app is the **end-of-chain consumer**. It receives farm state & advisories from the edge API and lets a farmer act on them. You do **not** own sensor logic, AI models, advisory rules, or the backend — but you **do** own:

- The entire mobile UI/UX  
- Offline-first data layer (local caching, stale-data indicators)  
- Image capture & submission flow  
- Advisory display and farmer interaction (acknowledge, approve irrigation, etc.)  
- Hindi / English language support  
- All navigation, theming, and accessibility

---

## 2. What you can build right now (zero dependencies)

Everything below can be completed using **hardcoded mock data** that mirrors the contracts the backend will eventually serve. This is the majority of the app.

### Phase A — Project scaffold & design system

- [ ] Create a new Flutter project inside `apps/farmer-app/` (replace the existing React Native scaffold — the team has agreed to use Flutter)
- [ ] Set up folder structure:
  ```
  lib/
  ├── main.dart
  ├── app.dart                  # MaterialApp, routing, theme
  ├── core/
  │   ├── theme/                # Colors, typography, spacing tokens
  │   ├── constants/            # API URLs, timeouts, severity mappings
  │   └── l10n/                 # Hindi + English string maps
  ├── data/
  │   ├── models/               # Dart data classes for Reading, Advisory, FarmState, CropResult
  │   ├── mock/                 # Hardcoded mock JSON responses
  │   └── repositories/         # FarmStateRepository (mock → later real HTTP)
  ├── features/
  │   ├── home/                 # Dashboard home screen
  │   ├── advisory_detail/      # Full advisory detail + action buttons
  │   ├── scan/                 # Camera capture & result display
  │   ├── history/              # Recent readings/advisories list
  │   └── settings/             # Language toggle, edge API URL config
  └── widgets/                  # Shared reusable widgets (cards, badges, indicators)
  ```
- [ ] Define the app theme — earthy greens, clear severity colours (amber warning, red critical, green ok), large readable text for field use.
- [ ] Add Google Fonts dependency (e.g., Noto Sans for Hindi support).

### Phase B — Data models & mock layer

Create Dart data classes that **exactly match** the backend contracts already defined in the repo:

- [ ] **`Reading`** model (mirrors `packages/contracts/src/events.js`):
  ```dart
  class Reading {
    final String deviceId;
    final String zoneId;
    final double soilMoisturePct;
    final double temperatureC;
    final double humidityPct;
    final double rainfallMm;
    final double waterLevelPct;
    final DateTime capturedAt;
  }
  ```

- [ ] **`Advisory`** model (mirrors `services/edge-api/src/advisory.js` output):
  ```dart
  class Advisory {
    final String type;      // irrigation | disease | pest | heat | flood
    final String severity;  // warning | critical | info
    final String title;
    final String message;
    final String action;    // START_IRRIGATION | SCHEDULE_EVENING_IRRIGATION | CHECK_DRAINAGE
  }
  ```

- [ ] **`FarmState`** model (mirrors `GET /v1/farm-state` response):
  ```dart
  class FarmState {
    final Reading reading;
    final List<Advisory> advisories;
  }
  ```

- [ ] **`CropHealthResult`** model (mirrors Workstream 02 output):
  ```dart
  class CropHealthResult {
    final String kind;         // "crop_health"
    final String crop;         // "tomato"
    final String label;        // "healthy" | "possible_early_blight" | ...
    final double confidence;
    final String imageQuality; // "acceptable" | "poor"
  }
  ```

- [ ] Create `data/mock/mock_farm_state.dart` with realistic sample data covering all scenarios:
  - Normal healthy state (no advisories)
  - Low moisture → irrigation advisory (warning)
  - High temp + dry soil → heat-stress advisory (warning)
  - High water level → flood-risk advisory (critical)
  - Disease detection result
  - Pest detection result

### Phase C — Core screens (all mockable)

#### C1. Home screen
- [ ] **Status banner** at top: zone name, device connection status (online/offline/stale), last reading timestamp with relative time ("2 min ago")
- [ ] **Urgent advisory cards** — sorted by severity (critical first). Each card shows:
  - Severity icon + colour strip (red = critical, amber = warning, green = info)
  - Title in large text
  - One-line message
  - Tap to open detail
- [ ] **Sensor summary strip** — compact row of current values:
  - 💧 Soil moisture (%)
  - 🌡️ Temperature (°C)
  - 💨 Humidity (%)
  - 🌧️ Rainfall (mm)
  - 🌊 Water level (%)
- [ ] **Quick actions**: "Scan Crop" button (opens camera), "View History" button
- [ ] **Stale data banner** — if the last reading is older than a configurable threshold (e.g., 10 min), show a subtle warning: *"Data may be outdated. Last sync: 15 min ago"*

#### C2. Advisory detail screen
- [ ] Full advisory info: type icon, severity, title, detailed message
- [ ] **Action button** based on advisory type:
  - `START_IRRIGATION` → "Approve Irrigation" / "Decline" buttons
  - `SCHEDULE_EVENING_IRRIGATION` → "Remind me at 6 PM" button
  - `CHECK_DRAINAGE` → "Mark as Checked" button
- [ ] Clear wording: irrigation is *recommended*, not *performed* — distinguish recommendation from actuation
- [ ] Timestamp of when advisory was generated
- [ ] Supporting sensor readings that triggered this advisory

#### C3. Crop scan screen
- [ ] Camera capture using `image_picker` or `camera` package
- [ ] Gallery selection option
- [ ] Loading indicator with "Analysing leaf…" text while awaiting result
- [ ] Result display card showing:
  - Crop name, detected condition, confidence percentage
  - Colour-coded severity (green = healthy, amber = possible issue, red = confirmed disease)
  - Human-readable explanation
  - Image quality feedback if poor
- [ ] For now: **return a hardcoded mock result** after a 2-second delay to simulate processing

#### C4. History screen
- [ ] Simple chronological list of past advisories and readings
- [ ] Each entry shows timestamp, type icon, title
- [ ] Tap to expand details
- [ ] For now: populate from a static mock list

#### C5. Settings screen
- [ ] Language toggle: English ↔ हिन्दी (Hindi)
- [ ] Edge API URL input field (default: `http://localhost:3001`)
- [ ] "Test Connection" button → hits `GET /health` and shows result
- [ ] About section with app version

### Phase D — Offline-first architecture

- [ ] Use a local data store (`shared_preferences`, `hive`, or `sqflite`) to cache the last known `FarmState`
- [ ] On app launch: show cached state immediately, then attempt to fetch fresh data
- [ ] Visual indicator for data freshness:
  - 🟢 "Live" — received within last 2 minutes
  - 🟡 "Stale" — received 2–15 minutes ago
  - 🔴 "Offline" — no successful fetch in 15+ minutes
- [ ] Graceful error handling: if the edge API is unreachable, show last cached data with offline banner — **never show an empty/error screen**
- [ ] Queue farmer actions (irrigation approval, photo submission) locally when offline; send when connectivity returns

### Phase E — Localization (Hindi + English)

- [ ] Set up Flutter's `intl` / `l10n` support
- [ ] Create string maps for all UI text in both languages
- [ ] All advisory titles and messages should also be translatable — define a mapping for the known advisory types
- [ ] Use large, clear fonts (minimum 16sp body text) — the app is used outdoors in bright light

---

## 3. Integration points (build later when teammates deliver)

These are the **seams** where you'll swap mock data for real data. Design for them now, implement when ready.

| Seam | What you mock now | What you'll connect to | When |
|------|-------------------|----------------------|------|
| Farm state fetch | `mock_farm_state.dart` | `GET http://<edge-ip>:3001/v1/farm-state` | When backend (WS05) is running |
| Image submission | Return mock `CropHealthResult` after delay | `POST` to image-analysis endpoint (TBD by WS02/WS05) | When AI pipeline (WS02) has an endpoint |
| Irrigation approval | Log to console | `POST` to actuation endpoint (TBD by WS05) | When backend adds actuation route |
| Sensor readings (direct) | N/A — you consume `FarmState`, not raw readings | Unchanged — backend aggregates for you | N/A |

### How to connect when ready

Your `FarmStateRepository` should have a simple interface:

```dart
abstract class FarmStateRepository {
  Future<FarmState> getFarmState();
  Future<CropHealthResult> submitImage(File image);
  Future<void> approveIrrigation(String advisoryId);
}
```

Start with `MockFarmStateRepository`. When the backend is live, create `HttpFarmStateRepository` that hits the real API. Switch via a single flag or dependency injection.

---

## 4. Recommended build order

```
Week 1 (Days 1-3)           Week 1 (Days 4-7)              Week 2
─────────────────           ──────────────────              ──────
Phase A: Scaffold           Phase C: All 5 screens          Phase D: Offline cache
Phase B: Models + mocks     Phase E: Hindi + English        Integration testing
                                                            Connect to live backend
```

### Day-by-day suggestion

| Day | Tasks |
|-----|-------|
| **Day 1** | Flutter project setup, folder structure, theme, add dependencies (`http`, `image_picker`, `provider`/`riverpod`, `shared_preferences`, `intl`) |
| **Day 2** | Data models, mock data, `FarmStateRepository` interface + mock implementation |
| **Day 3** | Home screen with advisory cards + sensor strip, using mock data |
| **Day 4** | Advisory detail screen with action buttons, crop scan screen with camera + mock result |
| **Day 5** | History screen, settings screen, navigation wiring |
| **Day 6** | Offline caching layer, stale-data indicators, error handling |
| **Day 7** | Hindi strings, language toggle, UI polish, field-readability pass (text sizes, contrast) |
| **Day 8+** | Connect to live edge API, test with real sensor data, integration fixes |

---

## 5. Key dependencies to add (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0            # API calls to edge server
  provider: ^6.1.0         # State management (or riverpod)
  image_picker: ^1.0.0     # Camera + gallery
  shared_preferences: ^2.2.0  # Offline cache (simple key-value)
  intl: ^0.19.0            # Localization
  flutter_localizations:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0          # Unit testing with mocks
```

---

## 6. What you CANNOT do without other workstreams

Be honest about these boundaries — they are **not blockers**, just integration milestones:

| Capability | Depends on | Your workaround |
|-----------|-----------|-----------------|
| Real sensor data on home screen | WS01 (firmware) + WS05 (backend) | Mock `FarmState` with realistic values |
| Real crop disease detection | WS02 (crop AI) + WS05 (backend endpoint) | Mock `CropHealthResult` with delay |
| Real pest detection | WS03 (pest AI) | Same as above |
| Real advisory generation | WS03 (risk logic) + WS05 (backend) | Mock advisories covering all 5 types |
| Actual pump control | WS01 (relay) + WS05 (actuation API) | Log action locally, show "Request sent" |
| Dashboard consistency | WS06 (dashboard) | Align on shared advisory type/severity vocabulary from `packages/contracts` |

> **Bottom line**: You can build **~90% of the app** independently. The remaining 10% is swapping mock implementations for real HTTP calls — which is a one-line change per feature if you structure the repository layer correctly.

---

## 7. Testing strategy

- [ ] **Unit tests**: Model serialization/deserialization, repository mock behaviour
- [ ] **Widget tests**: Each screen renders correctly with various advisory combinations (0 advisories, 1 critical, mixed)
- [ ] **Manual test scenarios** to rehearse for demo:
  1. App starts with cached data (offline) → shows last known state
  2. Edge API comes online → data refreshes, "Live" indicator appears
  3. Low moisture reading → irrigation advisory card appears
  4. High water level → flood-risk card appears with critical styling
  5. Farmer taps "Scan Crop" → camera opens → mock result shown
  6. Farmer approves irrigation → confirmation displayed
  7. Switch language to Hindi → all text changes

---

## 8. Demo readiness checklist

For the SIH demo (see `docs/demo.md`), your app needs to:

- [ ] Show the irrigation advisory matching the dashboard's initial low-moisture state
- [ ] React when farm state changes (flood-risk scenario) — either via polling or manual refresh
- [ ] Be presentable as the "offline, local-language-friendly action surface" (step 6 in demo script)
- [ ] Work on a physical Android device connected to the same local network as the edge API
- [ ] Look polished and farmer-appropriate — not a developer debug screen

---

*This plan is designed so you can start coding **today** with zero external dependencies. Every screen, every interaction, and every edge case can be built and tested with mock data. When your teammates deliver their pieces, integration is a repository swap.*
