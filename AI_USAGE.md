# AI usage log

**Tool:** Cursor (agent chat)  
**Scope:** scaffolding, API design, presentation layer — I still chose what to keep, cut, and ship.

Each row: **what I asked → what the model did → my decision (accepted / edited / rejected) and why.**  
Small fixes (“fix lint”) are skipped. This is a judgment log, not a chat transcript — reviewers should see *why* I agreed or pushed back, not every message I typed.

---

## Core setup

Errors, Dio, Hive CE, GetIt, `main.dart`.

| # | What I asked | Model output | Decision |
|---|---|---|---|
| 1 | Clean Architecture + Dio + Hive. Start with `core/errors/`, then domain/data only. | `AppFailure`, `Result`, Dio client, `safeCall`, GetIt, Hive adapters. | **Edited.** Kept `safeCall` so data layer never throws raw exceptions. Dropped unused fields and pass-through use cases. |
| 2 | Use my Equatable `Success` / `Failure` — no `fold` / `isSuccess`. | Switched to my sealed pair after a heavier first pass. | **Accepted.** `switch` at call sites reads cleaner. |
| 3 | Write this log; check how others document AI use. | First version of this file; updated as each module landed. | **Edited** each time — same table format, focus on decisions not prompts. |

---

## Module 1 — Home list (5 currencies)

Latest rate + yesterday, daily change, green/red.

| # | What I asked | Model output | Decision |
|---|---|---|---|
| 1 | Domain is overbuilt. Strip what the UI doesn't need. Compare before overwrite. | Fat domain first, then thin: `DayRates`, `Currency`, `GetCurrenciesUseCase`, one Hive box. | **Edited → accepted.** Use case calls `getLatest` + `getByDate(yesterday)`. Change = today − yesterday. |
| 2 | Green when EGP is stronger, red when weaker. Then: one flag only. | Two flags, then `isEgpStronger` alone. | **Accepted.** UI branches on true/false. |
| 3 | How is “yesterday” defined? | Day before the **API** date, not device clock. | **Accepted.** Correct when the API is still serving yesterday's file. |

---

## Module 2 — Details & 7-day chart

Tap a row → header from list, chart from 7 daily files for that code.

| # | What I asked | Model output | Decision |
|---|---|---|---|
| 1 | Why 7 network calls? Can I fetch USD only? | API serves full `egp.json` per day; extract one code. No single-currency URL. | **Rejected** “USD-only storage.” **Accepted** lazy load — chart fetch only on tap. |
| 2 | Repo should return 7 days for one code, not 7 days × 5 codes. | `getHistory` on repo; repo got bloated. | **Edited, then reversed.** Split `CurrencyHistoryRepository` + Hive box keyed by code. Only the opened chart goes offline. |

---

## Module 3 — Offline cache

Save last fetched rates. Offline → show cache + last updated.

| # | What I asked | Model output | Decision |
|---|---|---|---|
| 1 | Keep only 5 currencies before writing to Hive. | Filter in `DayRatesModel.fromJson`. | **Accepted.** HTTP is still full JSON; cache holds 5 rates per day. |
| 2 | Don't rewrite Hive if nothing changed. One box. | Skip `put` on Equatable match. Trim keys older than 14 days. | **Accepted.** `getLatest` = network first. `getByDate` = cache first. |
| 3 | Save when user loads data. | Same write path on success. | **Edited.** Home saves 2 days × 5 rates. Chart days don't pollute the rates box. |
| 4 | Offline after opening USD — should EUR chart work from cache? | Yes — same 7 Hive days have all 5 codes. | **Rejected.** Task says list is offline; each chart is offline only if **that pair** was opened before. |

---

## Presentation — Static UI (before BLoC)

Built from design images. No state management yet.

| # | What I asked | Model output | Decision |
|---|---|---|---|
| 1 | Home UI from 3 images. Theme → shared widgets → screen. Responsive, no magic pixels. | `app_colors/typography/spacing/theme`, `CurrencyCard`, `ChangeIndicator`, `SummaryInfoCard`, `CurrencyRatesScreen`. | **Accepted** structure. **Edited:** skipped extra markdown guides; fixed `CardTheme` → `CardThemeData`. |
| 2 | Zero change → no arrow, use brand color. | `ChangeIndicator` hides arrow, uses Primary 500 for flat days. | **Accepted.** JPY at 0.00 no longer shows a fake red arrow. |
| 3 | Details screen + `fl_chart`. 7-day line chart, mock data, extract widgets. | `DetailsScreen`, `SevenDayCurrencyChart`, header/banner widgets. Had wrong time-range tabs at first. | **Accepted** modular split. **Edited:** Mon–Sun labels not hourly; no `$` on Y-axis; dropped fake 1D–1Y tabs. |
| 4 | Fix chart axis — weekdays only, “Past 7 Days” header. | Removed `TimeRangeSelector`; added `ChartWeekSectionHeader`. | **Accepted.** Tabs didn't match a fixed 7-day chart. |

---

## Module 4 — Connectivity banner

Show when the device loses network. Don't change how repos fetch.

| # | What I asked | Model output | Decision |
|---|---|---|---|
| 1 | Add `connectivity_plus` or is current offline flow enough? Search properly. | Audit: Hive fallback works, `NetworkFailure` handled, gaps in UX (no banner, no auto-refresh). | **Accepted** analysis. Still wanted a visible signal — didn't stop at "no plugin." |
| 2 | Plugin + banner only; leave repos alone. | Also suggested auto-refresh, `isCached` on list, two banner types. | **Edited.** I only wanted one global strip — no BLoC or screen changes. |
| 3 | Global Cubit + app-level banner. | `ConnectivityService` → `ConnectivityCubit` → `ConnectivityBanner` in `MaterialApp.builder`. | **Accepted.** Repos unchanged. Android got `INTERNET` + `ACCESS_NETWORK_STATE`; iOS left alone per plugin docs. |
| 4 | Remove dead code and comment noise. | Trimmed unused fields/methods in service; stripped long comments. | **Accepted.** Small files don't need essay comments. |

---

## Module 5 — BLoC + real data

Wire screens to real use cases. Loading, empty, error, pull-to-refresh. Longest session — several "simplify" and "why is refresh stuck?" rounds.

| # | What I asked | Model output | Decision |
|---|---|---|---|
| 1 | BLoC + Equatable for both screens. **Mock** use cases in `lib/domain/`. | Mock domain (`FetchMainDataUseCase`, `FetchDetailsDataUseCase`, fake models). Two blocs, 5 states each, Fetch/Refresh events. | **Rejected.** Real use cases already exist. Told it: presentation only, delete mocks, don't touch domain. |
| 2 | Use real use cases. Presentation layer only. | Deleted mocks. Wired `GetCurrenciesUseCase` / `GetCurrencyHistoryUseCase`. Shared `LoadingView`, `ErrorView`, `EmptyView`. | **Accepted.** Kept separate `event` / `state` / `bloc` files per screen. |
| 3 | Pull-to-refresh spinner never stops. | **Bug:** `Equatable` skips re-emit when data is unchanged → `stream.firstWhere` in `RefreshIndicator` waits forever. **Fix:** `isRefreshing: true/false` on success state. | **Accepted.** Also: no full `Loading` screen during refresh — list stays visible. |
| 4 | Explain the bug / I still don't get it. | Technical walkthrough, then plain analogy (waiter never says "done" if the plate looks identical). | **Accepted** for learning. No code change. |
| 5 | Simplify states, events, files. | Tried one file per bloc. | **Rejected.** Kept 3 files per bloc but fewer states — empty = success with empty list, not its own state. |
| 6 | Why `stream` in the bloc? Over-engineered. | Moved wait to UI `_refresh()`; removed `reload()` from blocs. | **Accepted.** Bloc toggles `isRefreshing`; screen awaits `!isRefreshing`. |
| 7 | Google: senior best practice for BLoC + pull-to-refresh? | Don't replace content with loading on refresh; flag on success; let `RefreshIndicator` own the Future. | **Accepted.** Matches what we fixed in #3. |
| 8 | Make details bloc match main bloc. | Removed leftover `reload()` from details. | **Accepted.** Both blocs symmetric now. |
| 9 | Delete unused code and redundant bits. | Cleanup pass; briefly broke build by removing a needed import, fixed it. | **Accepted.** Nothing dead left in presentation/connectivity. |
| 10 | Why both `isOffline` and `userMessage` for network errors? Refactor? | Duplication — message already describes network failure; flag only changed icon/title. Proposed: state holds `AppFailure`, widget checks type. | **Accepted.** One mapping point in `ErrorView`, not in every bloc. |
| 11 | Pass `AppFailure` through; reusable `ErrorView` + network factory. | `MainError(error)` / `DetailsError(error)`. `ErrorView` picks icon/title from `error is NetworkFailure`. `ErrorView.network(...)` factory. Refresh failure → restore `previousData`. | **Accepted.** Bloc line is now `Failure(:final error) => MainError(error)`. |
| 12 | Rewrite this log for the BLoC session. Human tone, brief, enough for reviewers. | Researched provenance patterns; rewrote this section. | **Edited** — you're reading it. |

**What shipped**

- Two blocs on real use cases; separate **load** vs **refresh** events
- `isRefreshing` on success + UI `stream.firstWhere` for `RefreshIndicator`
- Refresh error → keep last good data, don't flash error screen
- Errors carry `AppFailure`; `ErrorView` handles copy and visuals
- List loading: `CurrencyCardShimmer`; details: spinner / chart shimmer

**What I pushed back on**

- Mock domain when real repos already existed
- One mega-file per bloc
- `reload()` + stream logic inside blocs
- `isOffline` bool next to a message that already says "no internet"
- Full-screen loading replacing the list on pull-to-refresh

---

## Key decisions (mine, not the model's first answer)

| Area | Decision |
|---|---|
| **Data** | Home cache = 5 rates/day. Chart cache = one series per opened code. Chart fetch on tap only. |
| **UI** | Static screens first, then wire data. Zero change = teal, no arrow. 7-day chart, no fake intraday axis. |
| **Connectivity** | Plugin = banner only. Repos still decide offline via failed request + Hive. Global cubit, dumb screens. |
| **BLoC** | Real use cases, no mocks. Load vs refresh events. `isRefreshing` fixes Equatable refresh bug. Errors = `AppFailure` end-to-end. |

---

Commit this file with the code — GitHub renders it and the history stays honest.
