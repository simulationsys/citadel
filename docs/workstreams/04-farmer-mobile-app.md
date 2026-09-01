# Workstream 04 — Farmer mobile app

## Context

The farmer experience is the practical endpoint of Citadel. It needs to reduce a complex sensor/AI system to clear choices in a few seconds, including when connectivity is weak. It is not an analytics console; it is an action surface for the person at the field.

## Phase 1 MVP outcome

The app shows the latest field condition and the most urgent advisory, allows a farmer to capture or select a crop image, and displays the returned diagnosis/pest result in straightforward language. A farmer can view whether irrigation is recommended and, if the team includes a control flow, approve or decline that request.

`apps/farmer-app/` contains an Expo/React Native starter. It deliberately begins with static cards so the field experience can be shaped before every backend endpoint is final.

## Scope

- Farmer-focused information hierarchy: urgent action first, supporting readings second, history only where it is useful.
- Offline and local-network experience: cached latest state, clear stale-data indication, and graceful recovery after reconnection.
- Image capture/selection and feedback while local model analysis is running.
- Alert presentation for disease, pest, irrigation, heat, and flood conditions.
- Language, icons, colour, and readability choices appropriate for the intended users and demo language.
- Actuation approval/user acknowledgement flow if used, without implying irrigation was performed when it was only recommended.

## Interfaces

The app consumes the edge API’s farm-state/advisory representation and may later consume an image-analysis endpoint. It should rely on the common advisory fields—`title`, `severity`, `message`, and `action`—rather than hard-coding a separate rule system in the UI.

The app needs to report only a small set of interaction events to the backend, such as photo submission, alert acknowledgement, and irrigation approval. The exact offline store and request strategy can remain adaptable.

## Practical MVP evidence

- The home screen remains useful with no internet connection after it has received a local farm state.
- A low-moisture alert and a risk alert are distinguishable and understandable at a glance.
- A sample leaf image can travel through the selected result path and receive a clear response.

## Design space still open

Navigation style, chosen language(s), accessibility detail, offline data approach, user identity model, and the degree of manual vs automatic pump control remain open. The key measure is whether a farmer can understand what to do next.
