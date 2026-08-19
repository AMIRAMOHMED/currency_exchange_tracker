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
| 4 | App empty at midnight — API fine. | Phone on Aug 17, API `latest` still Aug 16; old code looked up phone today (missing) and fetched phone yesterday (= same API date twice). | **Fixed.** Read `date` from `latest` → fetch that minus 1 → sort API dates for rate/change. Not the phone clock. |

**Midnight bug (brief):** Phone rolled to a new day before the API did — home looked for a date that wasn't in the response. Fix: anchor on `latest`'s date, fetch the day before, stop matching with the device clock.

---

## Module 2 — Details & 7-day chart

Tap a row → header from list, chart from 7 daily files for that code.

**Chart / offline bug (brief):** Offline chart stuck at 2 days because home only saves today + yesterday, and the first history fetch used the phone date — one 404 killed all 7 requests. Fix: on tap, show Hive first, then fetch only the missing days for that currency (anchor = newest cached date from home).

| # | What I asked | Model output | Decision |
|---|---|---|---|
| 1 | Why 7 network calls? Can I fetch USD only? | API serves full `egp.json` per day; extract one code. No single-currency URL. | **Rejected** “USD-only storage.” **Accepted** lazy load — chart fetch only on tap. |
| 2 | Repo should return 7 days for one code, not 7 days × 5 codes. | `getHistory` on repo; repo got bloated. | **Edited, then reversed.** Split `CurrencyHistoryRepository` + Hive box keyed by code. Only the opened chart goes offline. |
| 3 | Offline chart shows 2 days not 7 — USD sometimes 7, GBP 2. Debug it. | First guess: stale memory cache or prefetch 7 days on home. | **Rejected** home prefetch and `_WeekPlan` refactor — too heavy, not the real issue. |
| 4 | After clearing cache, every currency shows 2 days. Keep details fast. | Root cause: `Future.wait` on 7 device dates; API `latest` is often yesterday → 404 aborts all. | **Fixed.** Read Hive (2 days from home) → yield chart → `getRatesForDates` for missing days only (~5 calls). Skip 404s per date. Anchor = newest local date (user always comes from home). |

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
| 2 | Plugin + banner only; leave repos alone. | Also suggested auto-refresh, `isCached` on list, two banner types. | **Edited.** Global strip for no internet only. Stale rates got their own notice later (see below). |
| 3 | Global Cubit + app-level banner. | `ConnectivityService` → `ConnectivityCubit` → `ConnectivityBanner` in `MaterialApp.builder`. | **Accepted.** Repos unchanged. Android got `INTERNET` + `ACCESS_NETWORK_STATE`; iOS left alone per plugin docs. |
| 4 | Remove dead code and comment noise. | Trimmed unused fields/methods in service; stripped long comments. | **Accepted.** Small files don't need essay comments. |
| 5 | Offline card on details felt wrong — said "You're offline" but I only had yesterday's rates. | `OfflineStatusBanner` + `isCached`; duplicate date on the right. | **Edited.** `StaleDataNotice`: show when `date` ≠ today, pass `date` only, home + details. Dropped `isCached`. Clock icon + "Rates from {date}" — top strip still covers no internet. |

**Stale notice (brief):**  
**Problem:** Details-only card said "You're offline" and used `isCached`, even when I was online with yesterday's API rates.  
**Why:** `isCached` tracked where data came from, not whether it's today's file — wrong trigger, and it duplicated the top no-internet strip.  
**Fix:** `StaleDataNotice` on home + details when `date` ≠ today; `date` only, dropped `isCached`, clock icon + "Rates from {date}" — connectivity strip still owns real offline.

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

## Architecture refactor

Notes from a long chat — single table, streams, domain cleanup, refresh bug.

| # | What I asked | Model output | Decision |
|---|---|---|---|
| 1 | One Hive table or two? API always returns full JSON per date. | Single `ExchangeRateModel` keyed by `date_currency`; repo computes daily change. | **Accepted.** Same shape for home + history, less duplication. |
| 2 | Home = 2 calls, chart = 7 — how to not waste time? | `Future.wait` in parallel. Home pulls 5 codes; history pulls 1 (per task). | **Accepted.** Can't filter at URL — extract after download. |
| 3 | Too many types: `CurrencyInfo`, `Currency`, presentation extension. | `SupportedCurrency` enum, rename to `CurrencyRate`, `fromApiJson` on data model. | **Accepted.** JSON parsing stays in data layer, not BLoC. |
| 4 | Refresh spinner stops early with cache-first streams. | Traced: refresh → `isRefreshing: true` → cache emit → `isRefreshing: false` → network updates silently. | **Fixed.** Refresh passes `forceRefresh: true` (skip cache yield) + separate refresh mapper in bloc. Load still cache-first. |
| 5 | Midnight / wrong yesterday. | Phone rolled before API `latest` date. | **Fixed earlier** — anchor on API date, not device clock. |
| 6 | Offline chart stuck at 2 days. | Home only had 2 days; one bad date in `Future.wait` broke the batch. | **Fixed earlier** — Hive first, fetch missing days only for that currency. |

**Single table (from chat):**  
I had `DayRatesModel` (one row per day, map of 5 rates) plus a separate history box per currency — same data, two shapes. AI suggested one normalized table: `date`, `currency`, `rate`, `updatedAt`, Hive key `2026-08-16_USD`. Home reads today + yesterday for 5 codes; chart reads last 7 rows for one code. Store the raw API rate, invert to EGP in `fromApiJson`. Deleted the old models and the second Hive box.

**Cache-first + refresh (from chat):**  
Repo stream yields cache first, then network — good for first open. On pull-to-refresh I set `isRefreshing: true`, but the cache emission came back as `MainSuccess(cached)` with `isRefreshing: false`, so the spinner stopped before the API finished. One `onData` handler treated both emissions the same. Fix: load keeps cache-then-network; refresh uses `forceRefresh` to skip the cache yield and a separate refresh mapper so `isRefreshing` only clears when network is done.

---

## Key decisions (mine, not the model's first answer)

| Area | Decision |
|---|---|
| **Data** | One Hive table (`ExchangeRateModel`). Home = 2 parallel API calls × 5 codes. Chart = lazy on tap, missing days only. Anchor on API/cached date, not phone clock. |
| **Domain** | `SupportedCurrency` enum + `CurrencyRate` for UI rows. JSON parsing on the data model (`fromApiJson`), not in the BLoC. |
| **UI** | Static screens first, then wire data. Zero change = teal, no arrow. 7-day chart, no fake intraday axis. |
| **Connectivity** | Plugin = top strip for no internet. Stale rates = `StaleDataNotice` when `date` ≠ today (not `isCached`). Repos still decide fetch via network + Hive. |
| **BLoC** | Real use cases, no mocks. Load vs refresh events. Refresh uses `forceRefresh` so cache doesn’t kill the spinner. Errors = `AppFailure` end-to-end. Streams for cache-first load only. |

---

Commit this file with the code — GitHub renders it and the history stays honest.

---

## Change display refactor (`ChangeIndicator`)

Aug 17 — one param for daily change; widget owns percent, color, arrow.

| # | What I asked | Model output | Decision |
|---|---|---|---|
| 1 | Pass one change param to `CurrencyCard`; widget handles the rest. Before coding? | Root cause: `?? 0` getters forced a third `hasChange` flag. Pass `currency.change`; `ChangeIndicator` derives percent from `rate`. | **Accepted** — discuss first, then implement. |
| 2 | Implement it. Delete `changePercent` and `hasChange`. | Single nullable `change` on domain; percent in UI; removed `Untitled` + `isEgpStronger`. | **Accepted.** |
| 3 | Product colors: green = EGP stronger, red = weaker. Keep `ChangeIndicator` small. | Colors were inverted at first. Fixed. Then over-named, then trimmed to ~47 lines. | **Edited** twice — colors, then verbosity. |
| 4 | `null` vs `0`? Red arrow up or down? Fintech norm? | `null` = no yesterday (`—`); `0` = flat. Red + ↑ is normal — arrow follows rate, color follows EGP. | **Accepted** — no further code changes. |

**Shipped:** `change` only on entity/cards; `ChangeIndicator(rate, dailyRateChange)`; green ↓ rate, red ↑ rate.

**Rejected:** whole `CurrencyRate` on card, stored `changePercent`, EGP-direction arrows.

---


First suite. Official Dart / Flutter / `bloc_test` / `mocktail` docs only. Behavior, not private methods.

| # | What I asked | Model output | Decision |
|---|---|---|---|
| 1 | Write tests from current docs. Blocs first, then repos. Mock boundaries only. Cover load/refresh, empty refresh, chart loading, cache vs remote. | `bloc_test` + mocktail suite under `test/presentation/bloc/` and `test/features/currency/data/`. | **Accepted** structure. Asked it to re-run everything. |
| 2 | Invent cases that *should* fail if the app is wrong — then fix the app the simple way and test those. | Mapped real bugs (spinner stuck, empty refresh wiping the list, duplicate Success) to tests, then patched production. | **Edited.** Kept the cases. Cut extra test helpers. |
| 3 | What does `seed: () => previous` mean in `bloc_test`, and why do some tests have it? | `seed` = start the bloc already in Success so refresh can run. Load tests start from the real initial state, so they don't need it. | **Accepted** for learning. No code change. |
| 4 | Rename the fixtures file. | Renamed to a name that matches the rest of `test/`. | **Accepted.** |

**What I pushed back on:** a heavy test framework, testing private methods, goldens.

---


UX problem: pull-to-refresh hits the API, the API is still yesterday's file, the stale banner stays, so people pull again.

| # | What I asked | Model output | Decision |
|---|---|---|---|
| 1 | Senior UX + architecture: user refreshes, still sees old-date rates, refreshes again. Fix it wisely. | Options: dialog, banner copy, snackbar + cooldown + “checked at”. | **Picked** snackbar + 2 min cooldown + timestamp. Not a blocking dialog. |
| 2 | Same idea, simpler, human-written. Don't invent a new layer. | First pass added an enum and extra types. | **Rejected** the extra enum. Cooldown lives on the bloc (`_lastRefreshAt`). One `RefreshSnackListener` reused on both screens. |
| 3 | Where should debounce live on mobile — Dio? Dart? Search it. Don't implement yet. | Articles: skip the *action* in the UI/bloc, not the HTTP client. Dio interceptors are for HTTP, not “user pulled too soon.” | **Accepted.** 2 min gate in the bloc. No Dio interceptor. |
| 4 | One listener widget or two? Stateless? Think first. | One generic `BlocListener` wrapping both screens. Widgets stay stateless. | **Accepted.** |
| 5 | On a real successful refresh, snackbar too? | Yes — “Rates updated”, or “latest rates are from {date}” if the file isn't today. | **Accepted.** |
| 6 | Why extend / mixin / `StateStreamable`? Read 2026 bloc docs. | Mixin `HasRefreshSnack` so one listener works for both states. `BlocBase` is enough; `StateStreamable` was extra. | **Edited.** Kept a tiny mixin. Dropped the heavier type. |
| 7 | Snackbar never shows. Device logs attached. | `listenWhen` / Equatable: snack didn't look “new,” so the listener skipped it. Timestamp on the snack record so each refresh is a new value. | **Accepted** the bugfix. |
| 8 | Offline still shows “Rates updated” / “Already up to date”. Bug. Details too. | Refresh was treating a cache/error path as success. Failure → “Couldn't refresh — check your connection.” Cooldown only after a real network success. | **Accepted.** Same snack path on home and details. |

**Shipped:** `RefreshSnackListener`, 2 min cooldown in both blocs, themed snack (check vs wifi-off), `lastCheckedAt` on success for “Checked at …”.

**Rejected:** refresh enum, Dio debounce, two copy-pasted listeners, showing “updated” when the call never reached the network.

---


I wrote the model a team-lead prompt: read data + repo + bloc + screens, then simplify. Same cases. Human-looking code.

| # | What I asked | Model output | Decision |
|---|---|---|---|
| 1 | Write me that prompt, then run it. Not only the git diff — whole remote + local stack. | Cleanup pass: names, duplicated snack mapping, dead branches. Behavior supposed to stay. | **Edited.** Kept simplifications that tests still covered. Reverted anything that grew the surface. |
| 2 | How does home fetch locally — latest, then subtract a day? | Yes: cache/API `latest` date, then the day before that. Not the phone clock. | **Accepted** as explanation. Matches the midnight fix earlier. |
| 3 | `/gstack-design-review` — which UX cases do we handle, what's missing? | Stale banner, no-internet strip, refresh snacks, chart loading. Gap was “refreshed but still yesterday” — already the snack work. | **Accepted** the review. No extra screens. |
| 4 | Should `StaleDataNotice` also show when offline? Don't edit. How to check with no new parameter? | Yes — it's about the *rate date*, not connectivity. `date != today` is enough. Top strip already owns “no internet.” | **Accepted.** Still one date check. |
| 5 | Drop `checkedAt:` and read it from the cubit so the screen doesn't hold `lastCheckedAt`? | Screen still needs the value from state. Bloc already has it. Passing `state.lastCheckedAt` into the widget is the simple version. | **Accepted.** Didn't hide it behind a new lookup. |
| 6 | Details screen is much longer than home. Simplify. | Split body/status widgets; same states as home. | **Edited.** Shorter, but details still owns header + chart + stale notice. |

---


| # | What I asked | Model output | Decision |
|---|---|---|---|
| 1 | Review changes and performance. Add a BlocObserver to see rebuilds with the *same* data. | Observer + temporary debug prints. Found: duplicate `Loading` emit, Success→Success with the same list still rebuilding. | **Accepted** the diagnosis. Debug prints were temporary. |
| 2 | After reproduce: what actually shipped (ignore debug)? | Skip `emit(Loading)` if already loading. `buildWhen` on home: don't rebuild if the currency list didn't change. | **Accepted.** List stays put while snack/`isRefreshing` flip. |
| 3 | Skipping Loading looks the same to me. Where does the second Loading come from? | First emit is mine; a second `LoadMain` (rebuild/provider) would emit Loading again and flash the shimmer. Guard = no-op if already `MainLoading`. | **Accepted** once I understood it. Same guard on details. |
| 4 | Screen `buildWhen` vs Equatable — I thought Equatable means the screen shouldn't check. Search 2026 bloc docs. Don't implement extra ideas yet. | Equatable stops *identical* states. Snack + `isRefreshing` make Success ≠ Success, so the list would still rebuild without `buildWhen`. Docs: `buildWhen` is for “rebuild the list or not.” | **Accepted.** Keep Equatable on state, `buildWhen` on the list. |
| 5 | Why is `lastCheckedAt` on the bloc — read Hive instead? Use it for debounce? Think, don't implement. | Debounce is “when did *this user* last pull,” not “when was the box written.” Hive date is the rate file. Keep `_lastRefreshAt` in memory. | **Accepted.** Left as-is. |
| 6 | Review the observer. Human-written or over-engineered? Then fix it. | First version compared “visible data” by hand (`_sameVisibleData`). That's the blocs' job. | **Edited.** Now debug-only: `debugPrint` the transition + errors. Wired in `main.dart` under `kDebugMode`. |

**Rejected:** keeping the fat observer after we already skip same-list rebuilds in `buildWhen`.

---


| # | What I asked | Model output | Decision |
|---|---|---|---|
| 1 | `StaleDataNotice` is used on both screens. Walk the steps — what's inside the widget vs outside? I think the show-logic is duplicated. | Outside: decide whether to insert it. Inside: clock icon + copy. Both screens copied the date≠today check. | **Accepted** the split. |
| 2 | Implement, same logic, no extra repeats. Read the data shape. | First refactor pulled refresh-bar concerns into the notice. | **Rejected / reverted.** Too clever, and it touched the refresh snack for no reason. |
| 3 | Simpler: `StaleDataNotice.shouldShow(currencies.first.date)` and delete the other checks. | Static `shouldShow(date)` — year/month/day vs now. Both screens call that, then build the widget. | **Accepted.** One rule, two call sites. |

**Shipped:** `shouldShow` on the widget; screens only pass `date` + optional `checkedAt`.

---


| # | What I asked | Model output | Decision |
|---|---|---|---|
| 1 | Verify all tests pass. | Ran the suite after the refresh / observer / stale-notice work. | **Accepted** if green; fixed anything the simplify pass broke. |
| 2 | Update this log from every chat yesterday + today. Search how people write AI usage logs. Human, brief, enough for a reviewer. | Looked up assignment-style logs (prompt → output → keep/edit/reject + why). Appended these sessions in the same table format. | **Edited** — this section. Skipped “run tests again,” log pastes, and push-only chats. |

How I treated the model this week: I used it to draft, then I cut types, revert over-builds, and keep product rules (date ≠ clock, snack ≠ success when offline, observer is debug only).

---

