# Finara — Personal Finance Operating System
### Product & Engineering Plan (Flutter, Android-first)

---

## 1. Vision

Finara is not an expense logger — it's a **Personal Finance Operating System**.
It should feel like Arc Browser meets Apple Wallet meets Linear: fast, quiet,
confident. Every screen answers one of three questions instantly:
**"Where do I stand? Where is my money going? What should I do next?"**

Benchmark app: MyMoney (reference screenshots analyzed — see §11 "Learnings from MyMoney").

---

## 2. Design System

### 2.1 Visual Language
- **Theme:** Dark-first (default), full light mode parity, system-follow option.
- **Style:** Minimal + glassmorphism used *sparingly* — reserve frosted/acrylic
  blur for: bottom nav, modal sheets, the balance hero card, and floating
  action bar. Everything else stays flat/solid for legibility and battery.
- **Elevation:** Soft, low-opacity shadows (never harsh drop shadows). Rounded
  corners 16–24dp on cards, 12dp on chips/buttons, full-round on FAB/avatars.
- **Motion:** 150–250ms curves (easeOutCubic), shared-axis transitions between
  tabs, hero animation for transaction → detail, spring physics on
  swipe-to-delete/categorize.
- **Typography:** Manrope (display/headers) + Inter (body/numbers). Tabular
  figures for all currency values so columns align.
- **Color system:**
  - Neutral base: near-black `#0B0B0F` (dark) / `#FAFAFA` (light)
  - Accent gradient: violet→cyan (brand), used only for primary CTA + hero card
  - Semantic: green (income/positive), red/coral (expense/negative), amber
    (warnings/budget-near-limit), blue (transfers/neutral)
  - Category colors: 24-color curated palette, auto-assigned but user-overridable
- **Iconography:** Custom rounded-line icon set (not emoji-style like MyMoney).
  Each category = icon + color + optional custom image/emoji override.

### 2.2 Core Components (build as a shared `design_system` package)
- `GlassCard`, `SoftCard`, `BalanceHero`, `AmountText` (auto color + sign),
  `CategoryChip`, `AccountTile`, `BudgetProgressBar` (gradient fill, over-budget
  state), `TrendSparkline`, `DonutChart`, `BarChart` (Fl_chart wrapper),
  `SegmentedControl` (Income/Expense/Transfer), `NumericKeypad` (custom, not OS
  keyboard, with calculator +/−/×/÷ like MyMoney but redesigned),
  `BottomSheetScaffold`, `EmptyState`, `SkeletonLoader`.

---

## 3. Tech Stack & Architecture

### 3.1 Stack

|
 Layer            
|
 Choice                                                        
|
|
------------------
|
----------------------------------------------------------------
|
|
 Framework        
|
 Flutter (stable channel), Android first, iOS-ready structure   
|
|
 Language         
|
 Dart (null-safe, strict lints)                                 
|
|
 State Mgmt       
|
 Riverpod 2.x (code-gen) — chosen over Bloc for less boilerplate 
|
|
 DI               
|
 Riverpod providers (no separate get_it needed)                 
|
|
 Local DB         
|
 Drift (SQLite) — type-safe, reactive streams, migrations       
|
|
 Navigation       
|
 go_router                                                       
|
|
 Charts           
|
 fl_chart                                                        
|
|
 Backup format    
|
 Custom 
`.finara`
 (encrypted JSON+SQLite blob, zip)              
|
|
 Cloud sync (opt) 
|
 Firebase (Auth + Firestore) OR Supabase — pick Supabase for     
|
|
|
 portability/self-host option; end-to-end AES encryption before 
|
|
|
 upload regardless of backend                                   
|
|
 OCR              
|
 google_mlkit_text_recognition (on-device, offline)              
|
|
 Voice entry      
|
 speech_to_text + on-device intent parser (regex/NLP hybrid)     
|
|
 AI insights      
|
 On-device heuristics first (rules engine); optional cloud LLM   
|
|
|
 call (user opt-in) for natural-language summaries               
|
|
 Notifications    
|
 flutter_local_notifications + WorkManager for reminders         
|
|
 Testing          
|
 flutter_test, mocktail, golden_toolkit, integration_test        
|
|
 CI               
|
 GitHub Actions (analyze, test, build APK)                       
|

### 3.2 Architecture: Clean Architecture + MVVM, modular by feature

lib/
core/
design_system/
utils/ (formatters, currency, date)
database/ (drift schema, DAOs, migrations)
encryption/
sync/
ai_engine/ (rules-based insight generators)
navigation/ (go_router config)
features/
dashboard/
transactions/
accounts/
categories/
budgets/
analytics/
credit_cards/
loans/
lending_borrowing/
split_expenses/
net_worth/
savings_goals/
subscriptions/
investments/
recurring_detection/
search/
settings_backup/
onboarding/
each feature/
data/ -> models, DAOs, repositories (impl)
domain/ -> entities, repository interfaces, use cases
presentation/-> screens, widgets, view_models (Riverpod notifiers)


- **Repository pattern**: every feature exposes a `XRepository` interface in
  `domain/`, implemented in `data/` against Drift. ViewModels never touch DB
  directly.
- **Use cases** encapsulate business rules (e.g., `CalculateNetWorthUseCase`,
  `IsAnalyticsExcludedUseCase` — critical for the transfer/funding exclusion
  rule).
- **Offline-first**: Drift is source of truth. Sync layer is a thin outbox
  pattern (local write → queued → pushed when online), never blocks UI.

---

## 4. Data Model (Drift schema — high level)

Account (id, name, type[cash/bank/upi/wallet/credit_card/investment/loan],
icon, color, initialBalance, currentBalance, currency, archived)

Category (id, name, type[income/expense], icon, color, parentId?, isSystem)

Transaction (id, type[income/expense/transfer/funding/loan/adjustment],
accountId, toAccountId?, categoryId?, amount, currency,
date, time, note, tags[], attachmentPath?, isExcludedFromAnalytics,
recurringRuleId?, splitGroupId?, loanId?, cardId?)

Budget (id, categoryId, month, year, limitAmount, rollover:bool)

CreditCard (id, accountId, creditLimit, billingCycleDay, dueDay,
rewardsRatePct, apr)
CreditCardStatement (id, cardId, periodStart, periodEnd, totalDue, minDue, paidAmount)

Loan (id, name, principal, interestRatePct, tenureMonths, startDate,
emiAmount, type[home/personal/car/lent/borrowed])
LoanPayment (id, loanId, date, principalComponent, interestComponent, prepayment:bool)

LendBorrow (id, personName, direction[lent/borrowed], amount, date,
dueDate?, status[open/partial/settled], reminderEnabled)
LendBorrowRepayment (id, lendBorrowId, amount, date)

SplitGroup (id, name, members[], createdDate)
SplitExpense (id, groupId, transactionId, paidBy, splits: Map<member, amount>, settled)

SavingsGoal (id, name, targetAmount, targetDate, currentAmount, accountId?)

Subscription (id, name, amount, billingCycle[monthly/yearly/weekly], nextDueDate,
categoryId, accountId, reminderDaysBefore)

RecurringRule (id, pattern, categoryId, accountId, avgAmount, confidence,
detectedFrom: List<transactionId>, status[suggested/confirmed/ignored])

NetWorthSnapshot (id, date, totalAssets, totalLiabilities, netWorth)


**Key rule enforced at the use-case layer (not DB constraint alone):**
`Transaction.type in [transfer, funding, adjustment]` → automatically sets
`isExcludedFromAnalytics = true`, and analytics repository always filters on
this flag. This directly solves the MyMoney observation where transfers /
"Balance change" / "Grants" pollute Income vs Expense totals.

---

## 5. Feature Modules

### 5.1 Core (MVP — v1.0)
1. **Onboarding** — currency, starting accounts, optional biometric lock.
2. **Dashboard**
   - Glass hero card: Net worth / total balance, toggle "This Month" cash flow
   - Horizontal account carousel (swipeable cards, mini balances)
   - "Quick Add" FAB → bottom sheet with segmented Income/Expense/Transfer
   - Recent transactions (last 5, "see all" link)
   - Budget snapshot (top 3 categories nearing limit)
   - Trend sparkline (last 6 months spend)
3. **Fast Transaction Entry**
   - Types: Income, Expense, Transfer, Funding (family/gift — excluded),
     Loan disbursement/repayment, Balance Adjustment (excluded)
   - Custom numeric keypad w/ calculator ops (kept from MyMoney, redesigned)
   - Smart defaults: last used account/category pre-filled, recent categories
     shown as chips
   - Attach receipt photo inline
4. **Accounts** — CRUD, reorder, archive, per-account transaction history,
   icons for cash/bank/UPI/wallet/credit card/investment.
5. **Categories** — custom icon+color picker, income/expense split (mirrors
   MyMoney's Income/Expense categories screen but with search + drag reorder +
   subcategories).
6. **Analytics**
   - Donut chart (category breakdown) — **filtered to real income/expense only**
   - Bar chart (monthly trend, income vs expense overlay)
   - Cash flow view (in vs out vs net, weekly/monthly/yearly toggle)
   - Category drill-down with per-transaction list
7. **Budgets** — per category, monthly, rollover toggle (like MyMoney's
   Carry Over), progress bars, forecast ("at this rate you'll exceed by ₹X").
8. **Global Search** — search transactions/notes/category/account, filters
   (date range, type, amount range, account, tag).
9. **Backup/Export/Import**
   - Local `.finara` encrypted backup (AES-256, passphrase-derived key)
   - CSV/XLSX export by date range (parity with MyMoney's export)
   - Restore flow with preview before commit

### 5.2 Advanced Modules (v1.x — phased)
1. **Credit Card Management**
   - Limit, utilization ring (green/amber/red), billing cycle + due date
   - Statement generation, min-due vs full-due, payment history
   - EMI conversion tracking, rewards points ledger
   - Push reminder N days before due date; utilization warning >30%/>70%
2. **Loan Management (bank-style)**
   - Amortization schedule generator (principal/interest split per EMI)
   - EMI simulator (change tenure/rate → recompute)
   - Prepayment analysis: interest saved, new payoff date
   - Supports both borrowed loans and loans the user has *lent*
3. **Lending & Borrowing Tracker**
   - Person-based ledger, partial repayments, due reminders, settlement
     history, "who owes me / who I owe" summary widget on dashboard
4. **Split Expenses (Splitwise-style)**
   - Groups, equal/custom/percentage split, running balance per member,
     settle-up flow, optional UPI deep-link for settlement
5. **Net Worth Tracker**
   - Assets (cash+bank+investments+property manual entry) minus liabilities
     (credit card debt+loans), historical snapshot chart
6. **Emergency Fund Tracker** — target (e.g. 6x monthly expense, auto-
   calculated from analytics), progress ring, contribution history
7. **Savings Goals** — multiple goals, linked account, progress, projected
   completion date based on contribution rate
8. **Investment Overview** — manual entry (stocks/MF/FD/gold), current value
   vs invested, simple XIRR-lite return estimate
9. **Subscription Tracker** — recurring bills, calendar view, total monthly
   subscription burn, cancel/renew reminders
10. **Receipt OCR** — capture receipt → ML Kit text recognition → auto-extract
    amount/merchant/date → pre-fill transaction form for confirmation
11. **Voice Expense Entry** — "spent 500 on groceries with UPI" → parsed into
    amount/category/account via on-device NLP intent parser
12. **Smart Recurring Detection** — background job scans transaction history
    for repeating amount+category+interval patterns → suggests "Mark as
    recurring?" → feeds Subscription/RecurringRule tables

---

## 6. Analytics Rules (enforced, non-negotiable)

- `Transfer`, `Funding` (from family/gifts), `Balance Adjustment`, and any
  category flagged as a "wash" (e.g. Grants used purely for internal
  bookkeeping) are **excluded** from Income/Expense analytics and Net
  Worth income calc — but remain fully visible in the Records/ledger view.
- Analytics engine only aggregates transactions where
  `type IN (income, expense)` **and** `isExcludedFromAnalytics == false`.
- Credit card EMI conversions and loan repayments split principal (excluded —
  it's a liability transfer) vs interest (included — it's a real expense).
- This directly fixes what MyMoney does *wrong*: its Income/Expense-so-far
  totals visibly include "Balance change," "Transfer," and "Awards" (cashback)
  line items, muddying the real picture.

---

## 7. AI / Intelligence Layer

Build as `core/ai_engine` — a rules engine first, LLM-optional second.

- **Financial Health Score** (0–100): composite of savings rate, budget
  adherence, credit utilization, debt-to-income, emergency fund coverage.
- **Spending Insights**: "You spent 22% more on Clothing this month than your
  6-month average."
- **Credit Utilization Warnings**: push notification when utilization crosses
  30%/50%/90% thresholds.
- **Budget Forecasting**: linear + weighted-recent-days projection of month-end
  spend per category.
- **Loan Optimization**: suggest prepayment amount that maximizes interest
  savings given surplus cash detected in accounts.
- **Savings Recommendations**: suggest emergency fund top-up or goal
  contribution when idle balance detected in low-yield accounts.
- **Educational Tips**: contextual micro-tips triggered by behavior (e.g.
  first time overspending a budget → tip on the 50/30/20 rule).
- All of the above run **on-device** using deterministic rules — no user data
  leaves the phone unless the user explicitly opts into a cloud "Ask Finara"
  natural-language assistant feature (v2+, clearly gated, requires consent
  screen explaining what's sent).

---

## 8. Security & Privacy

- Optional biometric/PIN app lock (unlike MyMoney where this is Pro-gated —
  make it free and default-on-prompt).
- All local DB fields for sensitive strings (notes, person names in lending
  tracker) can optionally be encrypted at rest with sqlcipher if user enables
  "Enhanced Privacy Mode."
- Cloud sync (if enabled) is end-to-end encrypted client-side before upload;
  server never sees plaintext.
- Screenshots blocked in app-switcher when app lock is active (FLAG_SECURE).

---

## 9. Suggested Roadmap (phased for Antigravity/Flutter build)

**Phase 0 — Foundation (1–2 wks)**
- Project scaffold, design system package, Drift schema, go_router nav shell,
  theming (dark/light), core widgets.

**Phase 1 — MVP Core (3–4 wks)**
- Accounts, Categories, Transaction entry (all types), Dashboard v1,
  Analytics v1 (with exclusion rules), Budgets, Search, Backup/Export.

**Phase 2 — Advanced Financial Modules (4–5 wks)**
- Credit Cards, Loans + amortization, Lending/Borrowing, Net Worth, Savings
  Goals, Emergency Fund, Subscriptions.

**Phase 3 — Smart Features (3–4 wks)**
- Split Expenses, Recurring Detection, Receipt OCR, Voice Entry.

**Phase 4 — Intelligence Layer (2–3 wks)**
- AI Engine (health score, insights, forecasts, warnings), notification
  system, educational tips.

**Phase 5 — Polish, Sync, Testing (2–3 wks)**
- Optional encrypted cloud sync, animations pass, accessibility pass,
  golden tests, integration tests, performance profiling, iOS build target
  validation (if pursued).

---

## 10. Testing Strategy

- **Unit tests**: use cases (esp. analytics-exclusion logic, amortization
  math, budget forecast math) — 100% coverage target on financial calculators.
- **Widget/golden tests**: design system components across dark/light.
- **Integration tests**: full add-transaction flow, backup/restore round-trip.
- **Manual QA checklist**: currency formatting edge cases, negative balances,
  multi-currency (if added), timezone/date-boundary transaction bugs.

---

## 11. Learnings from MyMoney (reference app analysis)

What to keep:
- Fast numeric-keypad-first entry with inline calculator (+/−/×/÷)
- Segmented Income/Expense/Transfer selector
- Per-category budget list with "not budgeted" empty state
- Monthly view-mode switcher (daily/weekly/monthly/3mo/6mo/yearly) — but make
  these all free, not Pro-gated
- CSV/XLSX export by date range, local `.mbak`-style backup file

What to fix/improve:
- Analytics currently blends transfers/adjustments/cashback into income &
  expense totals → Finara enforces strict exclusion (§6)
- Flat, dated visual design (plain list rows, no charts on dashboard, generic
  icons) → Finara's glass/gradient dashboard with sparklines and health score
- No credit card intelligence (utilization, due date reminders) despite having
  a credit card account type
- No loan amortization, no lending/borrowing tracker, no split expenses
- Passcode protection paywalled behind Pro — make security a free baseline
- No OCR/voice/recurring-detection — pure manual entry only

---

## 12. Open Decisions / Questions for You

1. Multi-currency support in v1, or single base currency (INR) only for now?
2. Cloud sync: build in v1 or defer entirely to v2 (recommend defer — ship
   offline-first MVP first)?
3. Should credit card & loan modules be a paid tier later, or all free
   (monetization model — one-time Pro unlock like MyMoney, or subscription,
   or free+optional donation)?
4. Voice entry: on-device only (privacy-first, less accurate) vs cloud STT
   (more accurate, needs network + consent)?

---

## 13. My Additional Suggestions (not in your original prompt)

- **Widget/home-screen widget** for quick balance glance + quick-add (Android
  App Widget) — big UX win MyMoney doesn't have.
- **"Undo" snackbar** on delete/archive actions instead of confirm dialogs —
  feels faster and more premium.
- **Tags** (cross-cutting, independent of category) — e.g. "business",
  "reimbursable" — lets users slice data beyond category/account.
- **Multi-select bulk actions** in transaction list (bulk categorize/delete/
  export selected).
- **Shareable monthly report card** — auto-generated image/PDF summary card
  (like Spotify Wrapped) for social sharing or personal archive — strong
  differentiator, cheap to build once analytics exist.
- **Accessibility from day 1**: font scaling, screen-reader labels on charts
  (data table fallback), color-blind safe palette option.