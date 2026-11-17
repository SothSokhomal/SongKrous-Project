# SONGKROUS (សង្គ្រោះ)

Emergency help app for Phnom Penh — one-tap SOS calling, a map of nearby
hospitals, police and fire services, safety guidance, and official hotlines.
Bilingual (Khmer / English).

## Monorepo layout

| Path | Description |
| --- | --- |
| [`frontend/`](frontend/) | Flutter mobile app (iOS + Android) |
| [`backend/`](backend/) | Placeholder for the future API & open-data service |

## Frontend

```bash
cd frontend
flutter pub get
flutter run          # pick an iOS simulator / Android emulator
flutter analyze
flutter test
```

**Stack:** Flutter · Riverpod (state) · go_router (navigation) ·
flutter_map + OpenStreetMap (map) · geolocator (GPS) · url_launcher (calls) ·
google_fonts (Inter + Noto Sans Khmer).

**Structure** (`frontend/lib/`):

- `core/constants` — EN/KH strings, 14 Khans (with centres), facility seed data
- `core/state` — Riverpod state: user location / GPS, map category filter
- `core/theme` — Red / Blue / White design tokens and typography
- `core/router` — go_router routes + transitions
- `features/onboarding` — splash → onboarding → phone number → GPS permission
- `features/home` — SOS home, SOS direct call, outgoing call
- `features/map` — interactive map, search, Khan picker, category sheets
- `features/safety` — "What happened?" → "Tips to stay calm"
- `features/hotlines` — quick-dial + Khan directory
- `shared/widgets` — logo, floating bottom nav, curved onboarding header, etc.

## Testing the flow (simulator)

```bash
cd frontend && flutter run     # iOS Simulator or Android emulator
```

1. Splash → **Next** → Onboarding (try the `ភាសាខ្មែរ | English` pill) → **Next**
2. Phone number (optional — **Skip for now** works) → GPS dialog → *Allow While Using App*
   or *Don't Allow* (Home then offers a Khan selector via the GPS pill)
3. **Home**: *Copy Location* (→ "Copied ✓"), *View Map* → clean map; tap Medical / Police / Fire →
   map opens routed to the nearest facility of that category; the red call button on each card →
   SOS call screen
4. **Map** (progressive disclosure):
   - *State A* — opened from the bottom bar or *View Map*: only search, Khan pill, pins and the
     recenter button. Tap any pin (or a search result) to enter State B.
   - *State B* — a Grab-style sheet docked to the bottom edge, under the floating nav. It opens
     half-way (category tabs, "Nearby …" list closest-first), drags up to full height and down to a
     peek (`Nearby Hospitals (3)` + *Swipe up*); tap the handle to toggle. A route line is drawn to
     the nearest facility and the camera frames it above the sheet; a route pill rides above the
     sheet. Tap a row to re-route, the round button to call, **Start Route** for the simulated
     turn-by-turn banner (**Exit** closes it), **All** or ✕ to return to State A.
5. **SOS call**: tap the pulsing SOS (or the red number) → outgoing call; *Send Message* opens SMS
6. **Safety Tips**: pick a situation → *Show my safety tips*
7. **Hotlines**: 117 / 118 / 119 quick-dial; search the Khan list

On the iOS Simulator set a location in Phnom Penh (Features → Location → Custom) to see GPS
move the map; fixes outside Phnom Penh are ignored and the default location is used.
Calls/SMS only fully work on a real device.

## Before release — verify

- All facility data lives in `core/constants/phnom_penh_data.dart` and is **local mock data**
  (names, phones and coordinates come from the design brief; route waypoints are hand-placed, not
  real routing). Distances/ETAs are the brief's values at the default GPS and are recomputed along the
  route line from any other position. Replace with the backend + a routing service.
- The Calmette numbers (+855 23 426 948 / 23 724 891) and 117 / 118 / 119 come from the design brief —
  confirm against official sources. Other facilities fall back to the national numbers.
- Khan directory rows dial the national police line (117); per-Khan station numbers are missing.
- The street address on Home (`St. 598, …`) is a **demo string**; real GPS only moves the map and
  coordinates. Add reverse geocoding to show the actual address.
- Khmer copy was drafted without native review; safety/medical tips need professional review.
- Public OpenStreetMap tiles are for development only — use a proper tile provider in production.
- The "How are you feeling?" text is collected but not analysed (no AI triage yet).
