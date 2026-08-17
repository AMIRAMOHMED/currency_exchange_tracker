# Currency Exchange Tracker

A Flutter app that tracks five major currencies against the Egyptian Pound (EGP). Built as a mobile technical assessment — focused on clean architecture, offline support, and a polished UI.

**Currencies:** USD · EUR · GBP · SAR · JPY  
**Base:** EGP  
**API:** [currency-api.pages.dev](https://latest.currency-api.pages.dev/v1/currencies/egp.json) 

---

## Features

**Home — exchange rates list**
- Latest rate for each currency (how many EGP per 1 unit)
- Daily change vs yesterday — green when EGP strengthened, red when it weakened
- Pull-to-refresh
- Loading skeletons, error screen with retry, empty state

**Details — tap any currency**
- Current rate and daily change
- 7-day line chart (fetched lazily on open, not upfront)
- Chart shimmer while loading
- Pull-to-refresh

**Offline & resilience**
- Rates cached locally with Hive — app still works without internet
- Banner when there's no connection
- "Rates from {date}" notice when data isn't from today
- Cache-first on load, force-refresh on pull-to-refresh

---

## Screenshots

| Home | Details + 7-day chart |
|---|---|
| <img src="https://github.com/user-attachments/assets/ef342642-607d-4bca-bf22-3c9da548cc14" width="280" alt="Currency list" /> | <img src="https://github.com/user-attachments/assets/9388616a-986d-47d7-8eb9-2ac0a374b218" width="280" alt="7-day line chart" /> |

| Loading (home) | Loading (chart) |
|---|---|
| <img src="https://github.com/user-attachments/assets/dcad8f52-608a-4af3-a565-48dedc2d19be" width="280" alt="Skeleton placeholders on home" /> | <img src="https://github.com/user-attachments/assets/1eae6806-8870-4fcd-81f5-563fd417c759" width="280" alt="Chart shimmer on details" /> |

| No internet | Stale rates notice |
|---|---|
| <img src="https://github.com/user-attachments/assets/941df4f3-639c-4444-921c-e278b206195b" width="280" alt="No internet banner" /> | <img src="https://github.com/user-attachments/assets/242945c1-bdfc-4f31-b6ae-dd3e8d9a516a" width="280" alt="Notice when rates aren't from today" /> |

| Empty state |
|---|
| <img src="https://github.com/user-attachments/assets/90a59bb5-8c01-40d7-8ae6-e65926a19c20" width="280" alt="No chart data available" /> |

---

## Tech stack

| Layer | Tools |
|---|---|
| UI | Flutter, Material 3, Google Fonts |
| State | flutter_bloc |
| Network | Dio |
| Local storage | Hive CE |
| Charts | fl_chart |
| Connectivity | connectivity_plus |
| DI | get_it |
| Tests | flutter_test, bloc_test, mocktail |

---

## Architecture

Clean Architecture with three layers. Presentation talks to domain use cases only — no direct API or Hive calls from widgets.

```
presentation/   screens, blocs, widgets
features/currency/
  domain/       entities, repositories (interfaces), use cases
  data/         remote/local datasources, repository impls, models
core/           dio, errors, theme, DI, connectivity
```

**Data flow (simplified):**
- **Home** — 2 API calls (latest + yesterday) → compute daily change → cache in Hive
- **Chart** — opened on tap → show cached days first → fetch only missing dates for that currency
- **Offline** — repos fall back to Hive; UI shows banner + stale notice where needed

---

## Getting started

**Requirements:** Flutter SDK ^3.10.8, Android or iOS device/emulator

```bash
git clone <repo-url>
cd currency_exchange_tracker
flutter pub get
flutter run
```

**Run tests:**

```bash
flutter test
```

Tests cover repositories, blocs, and key widget flows.

---

## AI usage

This project used AI (Cursor) during development. Prompts, outputs, and what I accepted/edited/rejected are logged in [AI_USAGE.md](./AI_USAGE.md).

---

## Project structure

```
lib/
├── core/           errors, network, theme, DI
├── features/currency/
│   ├── domain/     CurrencyRate, use cases, repo contracts
│   └── data/       API, Hive, repository implementations
├── presentation/   screens, blocs, chart widget
├── shared/         reusable widgets (cards, banners, error views)
└── main.dart
```
