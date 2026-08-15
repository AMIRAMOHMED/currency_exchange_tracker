# AI usage log

Tool: **Cursor** (agent chat). I used it for scaffolding, API design, and the presentation layer. I still made the architecture calls — what to keep, what to cut, and how the UI should behave.

Format: **prompt → what the model returned → I accepted / edited / rejected, and why.**

Only meaningful prompts are listed. Small follow-ups (“fix that lint”) are skipped.

---

## Shared / core

Errors, Dio, GetIt, `main`. Everything else sits on this.

| # | Prompt (short) | Model returned | My call |
|---|---|---|---|
| 1 | Clean Architecture + Dio + Hive CE. Start with `core/errors/` and folders. Then: core/domain/data only, empty presentation. | `AppFailure`, `Result`, Dio mapper, `RestErrorParser.safeCall`, Dio client, GetIt, Hive adapters. | **Edited.** Kept `safeCall` (no raw exceptions out of data). Dropped pass-through use cases and fields the UI never shows. |
| 2 | Use my Equatable `Success` / `Failure`, not `fold` / `isSuccess`. | First a fat `Result`, then my sealed pair. | **Accepted** my shape. I want `switch` at the call site. |
| 3 | Write this log; look up how people write AI usage notes. | First draft of this file. | **Edited.** Split by module so presentation could be filled later. |

---

## Module 1 — Exchange rates list

Home: 5 pairs, latest + yesterday, daily change, green/red.

| # | Prompt (short) | Model returned | My call |
|---|---|---|---|
| 1 | Domain felt overengineered. Unused UI data out. Compare before overwrite. | Big domain first (`CurrencyEntity`, extra use cases). After pushback: `DayRates`, `Currency`, `GetCurrenciesUseCase`, one Hive box. | **Edited, then accepted the thin version.** Two repo calls in the use case: `getLatest` + `getByDate(yesterday)`. Change = today − yesterday. |
| 2 | Green if EGP stronger, red if weaker. Then: one flag only. | `isEgpStronger` + `isEgpWeaker`, then only `isEgpStronger`. | **Accepted** one flag. UI will branch true/false. |
| 3 | Yesterday — how? | Yesterday = day before the **API** date, not the phone clock. | **Accepted.** Avoids a wrong day if the API is still on “yesterday.” |

---

## Module 2 — Detail & 7-day chart

Tap one currency. Header from the list row. Chart = 7 dates, extract that code.

| # | Prompt (short) | Model returned | My call |
|---|---|---|---|
| 1 | Why 7 fetches? Can I download USD only? | Task: 7 historical URLs, each file has all currencies, take one for the line. No USD-only URL. | **Rejected** “store USD only.” **Accepted** lazy load: no chart fetch until tap. |
| 2 | Ask the repo for 7 days of USD, not 7 days of 5 currencies. | `getHistory` on the repo, then a fat repo. | **Edited then later reversed.** First: repo = one day. Then: only the tapped chart is offline. Separate `CurrencyHistoryRepository` + Hive box keyed by code. |

---

## Module 3 — Offline cache

Persist last fetched rates. Offline → cache + last updated. Back online → refresh.

| # | Prompt (short) | Model returned | My call |
|---|---|---|---|
| 1 | Filter to 5 currencies before cache. | Filter + invert in `DayRatesModel.fromJson`. | **Accepted.** HTTP is still full `egp.json`. We only keep 5 numbers per day. |
| 2 | Don’t rewrite Hive if data is the same. One box. | `put` by date. Skip write if Equatable match. Drop keys older than 14 days. | **Accepted.** `getLatest` = network first. `getByDate` = cache first (a published day does not change). |
| 3 | Save a day when the user actually loads it. | Same write path on successful fetch. | **Edited.** Home still saves 2 days × 5 rates. Chart does **not** write those extra days into the rates box. |
| 4 | Offline after USD tap, then EUR — should EUR chart load? | Yes, same 7 Hive days have all 5 rates. | **Rejected.** Task: persist last fetched rates for the **list**. A chart is offline only if **that pair** was opened. Other pairs show offline. |

---

## Presentation — UI build (static screen)

Built from 3 design images: palette, typography/spacing, and the “Currency Rates” mockup. **Presentation only** — no BLoC/Cubit/Provider; dummy data for now.

| # | Prompt (short) | Model returned | My call |
|---|---|---|---|
| 1 | Build the home UI from scratch from 3 images. Phase 1: `core/theme/` (colors, typography, spacing, `ThemeData`). Phase 2: reusable widgets in `shared/widgets/`. Phase 3: screen in `presentation/screens/`. No state management; static data. Responsive layout — no hardcoded pixel sizes. | **Phase 1:** `app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_theme.dart` from the palette and Inter type scale. **Phase 2:** `CurrencyCard`, `ChangeIndicator`, `SummaryInfoCard`. **Phase 3:** `CurrencyRatesScreen` with AppBar, summary card, 5 currency rows, disclaimer. Wired `main.dart` + `pubspec.yaml` (Inter fonts, `assets/flags/`). Also wrote setup docs and flag/font READMEs. | **Accepted** the folder split and widget extraction — matches how I wanted the presentation layer organized. **Edited:** I didn’t ask for all the extra markdown guides; I kept the code, skimmed the docs. **Edited:** `CardTheme` → `CardThemeData` after analyzer complained. **Not done yet:** Inter `.ttf` files and flag PNGs still need to be dropped in before the screen looks right on device. |
| 2 | If change is 0, no arrow — use blue or whatever color fits. | `ChangeIndicator`: when `changeValue == 0`, hide the arrow and color the text **Primary 500** (`#1FB8CB`) instead of red/green. | **Accepted.** Teal reads as “unchanged” and stays on-brand. JPY (`0.00`) no longer gets a misleading red down arrow. I might switch to gray later if teal feels too loud — easy one-line change. |
| 3 | Update `AI_USAGE.md` for this UI work too. Search how to write it; brief, human, but enough for reviewers to see my judgment. | Researched prompt-log / design-log patterns (problem → decision → trade-off, not a raw chat dump). Updated this file. | **Edited.** Merged into the existing log instead of a second file. Same table style as the backend entries. |
| 4 | Build Details screen from screenshot. `fl_chart ^1.2.0`. Chart = 7 days on X-axis, currency values on Y-axis. Presentation only, mock data. Extract chart + sub-widgets. Responsive (`AspectRatio`, flexible layout). Reuse theme and `ChangeIndicator`. | `DetailsScreen`, `SevenDayCurrencyChart`, header/offline banner/stats/disclaimer widgets. Added `fl_chart` dep. Wired list → details navigation. First pass still had `1D–1Y` tabs and X-axis behaved like time slots from the mockup. | **Accepted** modular split and chart styling (line, gradient, dot, grid, tooltip). **Edited:** chart override — 7 weekday labels, not hourly times. **Edited:** dropped `$` on Y-axis; plain decimals (`48.00`) fit EGP rates better. **Edited:** `CardTheme`-style fixes and `SideTitleWidget` for axis labels after analyzer / layout issues. |
| 5 | Fix chart X-axis and range labels. Replace time titles with Mon–Sun (or Day 1–7). Remove `1D, 1W, 1M, 3M, 1Y` tabs — use a “Past 7 Days” header instead. | Updated `SevenDayCurrencyChart` to only label whole indices 0–6 with Mon–Sun. Y-axis shows 4 clean grid steps. Deleted `TimeRangeSelector`; added `ChartWeekSectionHeader`. | **Accepted.** Tabs were misleading for a fixed 7-day chart. Header is clearer. Weekday labels auto from index so mock data stays simple. |

### What I kept from the AI output

- Theme tokens in one place — widgets reference `AppColors` / `AppTypography` / `AppSpacing`, not magic numbers.
- Compound widgets instead of one giant screen file (list + details).
- `SafeArea`, `LayoutBuilder`, `SingleChildScrollView`, `Expanded`, `AspectRatio` for responsiveness.

### What I pushed back on (implicitly, by scope)

- No state management hook-up — intentional; BLoC comes when I wire the list to `GetCurrenciesUseCase`.
- Didn’t treat the long setup guides as deliverables — the code structure was the goal.
- Didn’t keep the mockup’s intraday X-axis or time-range pills — wrong for a weekly currency chart.

---

## Module 5 — BLoC wiring & real data

Wire static screens to use cases. Loading, error, empty, pull-to-refresh.

| # | Prompt (short) | Model returned | My call |
|---|---|---|---|
| 1 | Hook list + details to real repos. BLoC per screen. Loading / error / empty / refresh. | `MainScreenBloc` + `DetailsScreenBloc`, sealed states, use cases via GetIt. Shared `LoadingView`, `ErrorView`, `EmptyView`. | **Edited.** Split **load** vs **refresh** events — refresh keeps data on screen. First load uses `LoadingView`, not a full-screen skeleton. |
| 2 | Error handling — strings or failures? | Mapped `Result` → `MainError` / `DetailsError` with `AppFailure`; `ErrorView` reads `error.userMessage` and picks wifi icon for `NetworkFailure`. | **Accepted.** One failure type end-to-end, same as the data layer. |
| 3 | Refresh failed mid-session — wipe the screen? | On refresh error, re-emit previous success state so stale data stays visible. Full error screen only when there was nothing to show yet. | **Accepted.** Matches Module 3 offline behavior: cached rows beat a blank error. |
| 4 | Loading UI — spinner or skeleton? | First pass: full-screen `MainScreenShimmer` + `DetailsScreenShimmer` built from `ShimmerBox`. | **Rejected** full-screen shimmers — too much layout to maintain for two screens. **Edited:** kept `LoadingView` (spinner) for screen load. Added `shimmer` package + `ChartShimmerSkeleton` only — chart-shaped placeholder with axis labels and a wave path, because `fl_chart` can't render without real points. `ShimmerBox` stays as a small reusable block if I need it later. |
| 5 | Details: chart from repo, offline banner, empty chart. | Real `HistoryPoint` list → `SevenDayCurrencyChart`. `OfflineStatusBanner` when `currency.isCached`. `< 2` points → `EmptyView`. | **Accepted.** Header still comes from the list row; chart fetches on tap only (Module 2). |
| 6 | Keep BLoCs thin? | Screens dispatch events; blocs call one use case; `switch` on `Result` in a private `_toState`. No connectivity logic inside feature blocs. | **Accepted.** Connectivity stays in the global Cubit (Module 4). Feature blocs only care about fetch results. |

### What shipped

- List: `LoadMain` / `RefreshMainData` → `MainScreenBloc` → live rates + daily change
- Details: `LoadDetails` / `RefreshDetailsData` → 7-day chart from `GetCurrencyHistoryUseCase`
- `LoadingView` spinner on first load; `RefreshIndicator` on success; retry on hard error
- `ChartShimmerSkeleton` + `ShimmerBox` (`shimmer` package) — chart-area placeholder only
- Refresh failure → keep last good data instead of swapping to error view

### What I pushed back on

- One event with a `refresh` flag — harder to read than separate load/refresh types
- Full-screen list/details shimmer screens — deleted; spinner is enough for the list
- Replacing the whole screen with `LoadingView` on pull-to-refresh
- Putting `AppFailure` mapping inside widgets — stays in bloc + `ErrorView`

---

## Module 4 — Connectivity banner

Offline UX: show when the radio drops, without changing how repos fetch data.

| # | Prompt (short) | Model returned | My call |
|---|---|---|---|
| 1 | Should I add `connectivity_plus`, or is the current offline flow enough? Search hard. | Full audit: Hive fallback in repos, `NetworkFailure` → `ErrorView`, `isCached` on details only. Said **don't** use the plugin to gate requests — interface up ≠ API reachable. Gaps: list screen hides stale data, no auto-refresh on reconnect, release Android missing `INTERNET`. | **Accepted** the analysis. Current repo flow stays the source of truth. I still wanted a visible offline signal, so I didn't stop at "no plugin." |
| 2 | I'll add the plugin + a banner when internet is lost; leave everything else as-is. | Agreed in principle, but pushed back: banner should also respect `isCached`, auto-refresh on reconnect, and use two widgets (thin strip vs tall card). | **Edited.** I only wanted one global banner, not changes to list/details screens or other BLoCs. Ignored the auto-refresh and list-screen `isCached` banner for now. |
| 3 | What does "strip" mean? | ASCII mockup: thin top bar ("No internet connection") vs existing `OfflineStatusBanner` card with date + refresh. | **Accepted** the distinction. Picked the thin strip for connectivity, kept the card on details for cached data. |
| 4 | Thin strip + reuse card on list (recommended option). | Started building: service, strip, touched `MainScreenBloc` and list screen. | **Rejected** that wiring. Told it: global Cubit above `MaterialApp`, banner in app shell only — **no other BLoC, no screen changes.** |
| 5 | Global Cubit + app-level banner only. | Reverted screen/BLoC edits. Added `ConnectivityService`, `ConnectivityCubit`, `ConnectivityBanner` in `MaterialApp.builder`. Registered service in GetIt; `start()` before first frame. | **Accepted** the shape. Matches what I asked for. |
| 6 | Add release permissions for iOS and Android; read the package docs. | Read `connectivity_plus` README + plugin manifest. Android: `INTERNET` (app) + `ACCESS_NETWORK_STATE` (plugin). iOS: nothing — `NWPathMonitor`, no plist keys. | **Accepted** Android permissions in main manifest. **Accepted** leaving iOS plist alone — adding fake keys would be wrong. |
| 7 | Delete unused code in `ConnectivityService`. | Removed `dispose()`, unused `Connectivity?` constructor param, `_subscription` field (only existed for dispose). | **Accepted.** Service is a app-lifetime singleton; no need to cancel. |
| 8 | Clean comments on all connectivity files. | Stripped doc blocks and inline notes from service, cubit, banner, injection, Android manifest. | **Accepted.** Code is small enough to read without the essay comments. |
| 9 | Write this log entry for the connectivity work. Googled how people write AI usage logs first. | Researched: log **judgment** (kept / edited / rejected + why), not every chat line. Brief entries tied to deliverables. | **Edited** into this section. Same table style as the rest of the file. |

### What shipped

- `connectivity_plus` — UI signal only, never gates Dio calls
- `ConnectivityService` → `ConnectivityCubit` → `ConnectivityBanner` (app-wide teal bar)
- Repos unchanged: network fail → Hive fallback, same as Module 3
- Android release: `INTERNET` + `ACCESS_NETWORK_STATE`
- Details screen still uses `OfflineStatusBanner` when `currency.isCached`

### What I pushed back on

- Using connectivity status to skip API calls or pick cache
- Wiring banner into `MainScreenBloc` or list/details screens
- Auto-refresh on reconnect (would need BLoC changes I didn't want)
- `isCached` banner on the home list (same reason)
- iOS plist entries the plugin docs don't require
- Long architecture comments in every connectivity file

---

## Tests & other

| # | Prompt (short) | Model returned | My call |
|---|---|---|---|
| — | — | — | — |

---

## Decisions I made without taking the first AI answer

**Backend**

- Home Hive: 5 rates per day (offline list without opening details)
- Chart Hive: one series per tapped code (other charts stay offline)
- Chart on tap only; Dio still `egp.json`, then extract that code

**Presentation**

- Static UI first, real data later
- Zero change = no arrow, Primary 500 (not red/green)
- Positive/negative still green/red with arrows
- Details chart = always 7 days; no fake intraday axis
- “Past 7 Days” header instead of time-range tabs

**Connectivity**

- Plugin for banner only; offline data still decided by failed requests + Hive
- Global `ConnectivityCubit` + `MaterialApp.builder` banner — screens stay dumb
- Thin connectivity bar app-wide; tall cached-data card stays on details only

**BLoC / state**

- Separate load vs refresh events; `LoadingView` on first load, not full-screen shimmer
- Shimmer scoped to chart placeholder only (`ChartShimmerSkeleton`)
- Errors carry `AppFailure`; refresh failure keeps previous success data
- Feature blocs fetch only — no connectivity coupling

Commit this file with the code so GitHub renders it and the history stays honest.
