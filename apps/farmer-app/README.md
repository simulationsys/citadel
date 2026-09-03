# Citadel Farmer App

This is the mobile application (Workstream 04) for the Citadel project: an offline-first smart farming assistant for Indian farms.

## What is done

A full Flutter application skeleton has been created based on the project's Phase 1 MVP requirements. The application is completely independent and currently uses mock data that mirrors the backend API contracts.

### Features Implemented
- **Project Scaffold:** Complete Flutter structure with Noto Sans for future Hindi localization and earthy green design tokens.
- **Data Models:** `Reading`, `Advisory`, `FarmState`, and `CropHealthResult` models accurately map to the `events.js`, `advisory.js`, and AI output contracts.
- **Repository Layer:** Abstracted `FarmStateRepository` with a `MockFarmStateRepository` implementation. It simulates network latency and returns realistic dummy data (e.g. low soil moisture, high temperature).
- **Home Screen:** Shows connection/freshness status, urgent advisory cards, a sensor strip with 5 key metrics, and quick action buttons.
- **Advisory Detail Screen:** Detailed view of an advisory with severity badges, supporting sensor readings, and mock action buttons (Approve/Decline).
- **Scan Screen:** UI for capturing a leaf photo (via camera or gallery) and simulating an AI analysis to return a crop health result.
- **History Screen:** Chronological mock history of past alerts.
- **Settings Screen:** Language toggle (English / Hindi), Edge API URL configuration, and a working connection tester for `GET /health`.

## Next Steps
- Translate UI strings to Hindi and wire up the localization toggle.
- Create `HttpFarmStateRepository` to replace the mock repository.
- Connect to the real Edge API (`http://localhost:3001` or edge device IP) when Workstream 05 is live.
- Wire the image upload to the vision models (Workstream 02).

## Getting Started

1. Ensure you have Flutter installed (version 3.13.2+).
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```
