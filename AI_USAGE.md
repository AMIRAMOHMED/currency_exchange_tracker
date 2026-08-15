# AI usage log

Tool: **Cursor** (agent chat). I used it for scaffolding and for talking through the API. I decided architecture, what to delete, and product rules. Only meaningful prompts are listed — not every “explain again.”

Format for each entry: **prompt → what it returned → I accepted / edited / rejected, and why.**

I will add rows under **Presentation** and **Tests** when I build those. Same file, same style, new commits so dates stay honest.

---

## Shared / core

Errors, Dio, GetIt, `main`. Not a task module, but everything sits on it.

| # | Prompt (short) | Model returned | My call |
|---|---|---|---|
| 1 | Clean Architecture + Dio + Hive CE. Start with `core/errors/` and folders. Then: core/domain/data only, empty presentation. | `AppFailure`, `Result`, Dio mapper, `RestErrorParser.safeCall`, Dio client, GetIt, Hive adapters. | **Edited.** Kept `safeCall` (no raw exceptions out of data). Dropped pass-through use cases and fields the UI never shows. |
| 2 | Use my Equatable `Success` / `Failure`, not `fold` / `isSuccess`. | First a fat `Result`, then my sealed pair. | **Accepted** my shape. I want `switch` at the call site. |
| 3 | Write this log; look up how people write AI usage notes. | First draft of this file. | **Edited.** Split by module so presentation can be filled later. |

---

## Module 1 — Exchange rates list

Home: 5 pairs, latest + yesterday, daily change, green/red.

| # | Prompt (short) | Model returned | My call |
|---|---|---|---|
| 1 | Domain felt overengineered. Unused UI data out. Compare before overwrite. | Big domain first (`CurrencyEntity`, extra use cases). After pushback: `DayRates`, `Currency`, `GetCurrenciesUseCase`, one Hive box. | **Edited, then accepted the thin version.** Two repo calls in the use case: `getLatest` + `getByDate(yesterday)`. Change = today − yesterday. |
| 2 | Green if EGP stronger, red if weaker. Then: one flag only. | `isEgpStronger` + `isEgpWeaker`, then only `isEgpStronger`. | **Accepted** one flag. UI will branch true/false. |
| 3 | Yesterday — how? | Yesterday = day before the **API** date, not the phone clock. | **Accepted.** Avoids a wrong day if the API is still on “yesterday.” |

*Pull-to-refresh, loading/error/empty — presentation. I’ll log those there.*

---

## Module 2 — Detail & 7-day chart

Tap one currency. Header from the list row. Chart = 7 dates, extract that code.

| # | Prompt (short) | Model returned | My call |
|---|---|---|---|
| 1 | Why 7 fetches? Can I download USD only? | Task: 7 historical URLs, each file has all currencies, take one for the line. No USD-only URL. | **Rejected** “store USD only.” **Accepted** lazy load: no chart fetch until tap. |
| 2 | Ask the repo for 7 days of USD, not 7 days of 5 currencies. | `getHistory` on the repo, then a fat repo. | **Edited then later reversed.** First: repo = one day. Then: only the tapped chart is offline. Separate `CurrencyHistoryRepository` + Hive box keyed by code. |


*Shimmer, detail UI, navigation — presentation.*

---

## Module 3 — Offline cache

Persist last fetched rates. Offline → cache + last updated. Back online → refresh.

| # | Prompt (short) | Model returned | My call |
|---|---|---|---|
| 1 | Filter to 5 currencies before cache. | Filter + invert in `DayRatesModel.fromJson`. | **Accepted.** HTTP is still full `egp.json`. We only keep 5 numbers per day. |
| 2 | Don’t rewrite Hive if data is the same. One box. | `put` by date. Skip write if Equatable match. Drop keys older than 14 days. | **Accepted.** `getLatest` = network first. `getByDate` = cache first (a published day does not change). |
| 3 | Save a day when the user actually loads it. | Same write path on successful fetch. | **Edited.** Home still saves 2 days × 5 rates. Chart does **not** write those extra days into the rates box. |
| 4 | Offline after USD tap, then EUR — should EUR chart load? | Yes, same 7 Hive days have all 5 rates. | **Rejected.** Task: persist last fetched rates for the **list**. A chart is offline only if **that pair** was opened. Other pairs show offline. |

*“Last updated” banner and auto-refresh — presentation + a connection cubit.*

---

## Presentation

Not built yet. I will add rows here (BLoC, list, detail, shimmer, pull-to-refresh, connectivity).

| # | Prompt (short) | Model returned | My call |
|---|---|---|---|
| — | — | — | — |

---

## Tests & other

Same: fill when I write tests or extra work.

| # | Prompt (short) | Model returned | My call |
|---|---|---|---|
| — | — | — | — |

---

## What I decided without taking the first AI answer

- Home Hive: 5 rates per day (offline list without opening details)  
- Chart Hive: one series per tapped code (other charts stay offline)  
- Chart on tap only; Dio still `egp.json`, then extract that code  

Commit this file with the code so GitHub can show it next to the history.
