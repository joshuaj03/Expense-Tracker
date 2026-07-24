# Finara — Functional & Technical Requirements
### Derived from MyMoney (Play Store) + Personal Customization Requests
Version 1.0 — Living document, update as scope evolves

---

## 0. Document Purpose

This document translates the product vision (see `plan.md`) into concrete,
buildable requirements. Every requirement below is traceable to either:
- **[MM]** — a MyMoney behavior being replicated/improved
- **[NEW]** — a feature the user requested that MyMoney doesn't have
- **[FIX]** — a MyMoney limitation being explicitly corrected

Each requirement has an ID (e.g. `TXN-01`) for reference in tickets/PRs.

---

## 1. Add/Edit Transaction Screen

### 1.1 Category & Account Selectors — `TXN-01` `[FIX]`
- Tapping the **Account** field or **Category** field must NOT navigate to a
  new full screen (MyMoney's current behavior via a modal that still feels
  like a page). Instead:
  - Opens a **bottom sheet** (draggable, ~70% height, expandable to full)
  - Grid of category icons+labels (matches MyMoney's grid layout, improved
    with search bar pinned at top + recently-used row)
  - Account list shows icon, name, and current balance (like MyMoney's
    "Select an account" screen) but as a bottom sheet, not full navigation
  - Single tap selects and auto-dismisses the sheet
  - Sheet includes an "+ Add new category/account" affordance at the bottom
- Selected value renders inline in the field (icon + name), replacing the
  placeholder "Account"/"Category" label.

### 1.2 Date & Time Placement — `TXN-02` `[FIX]`
- Date and time pickers are currently inline text at the very bottom of the
  screen in MyMoney, below the numpad — but they scroll with content.
- **Requirement:** Date & time row must be **pinned/fixed** at the bottom of
  the screen, directly below the calculator-numpad, always visible without
  scrolling, across all transaction types (Income/Expense/Transfer).
- Tapping date opens the calendar picker (as in MyMoney); tapping time opens
  the clock dial picker (as in MyMoney) — visual style modernized per design
  system but interaction pattern kept since it works well.

### 1.3 Notes Section — `TXN-03` `[NEW]`
- Replace MyMoney's plain single-line-feeling notes box with a **larger,
  resizable text area** (min 4 lines visible, auto-expands up to a max, then
  internally scrolls) — optimized for pasting/reading lists or long text.
- **Itemized list mode** (toggle via a `+` icon inside/above the notes box):
  - Switches the notes box into a **structured line-item table**:
    | Sl. No. (auto) | Item | Qty | Price |
  - "Add row" button appends a new line; Sl. No. auto-increments.
  - Each row's Qty × Price computed live; a **running Sum** shown at the
    bottom of the table.
  - A "Use this total" action lets the user push the computed sum into the
    main transaction amount field (with confirmation if amount already set).
  - User can toggle back to free-text notes; if switching away, the itemized
    data is preserved (serialized) and restored if they toggle back — stored
    as structured JSON in the transaction's `noteItems` field, with a
    plain-text render fallback for display in lists/search.

### 1.4 Split Payment/Transaction — `TXN-04` `[NEW]`
- Add a **"Split this transaction"** toggle/checkbox in the entry form.
- When enabled, reveal:
  - **Number of people** stepper (`+`/`−` counter, default 2, min 2)
  - Per-person name input (optional, free text or select from saved
    "People" list used by the Lending/Borrowing and Split Expense modules)
  - Two supported split modes, user picks one:
    1. **Equal split** — total ÷ number of people, all shares equal
    2. **Custom share** — user manually enters either:
       - their own contribution amount, OR
       - their own share as a percentage
       - remaining amount/percentage auto-distributed equally among others
         (with manual override per person allowed in an expandable list)
  - The transaction saved to the user's own account records **only their own
    individual share/contribution** as the actual ledger amount (so account
    balances stay accurate) — full split detail is retained and linked into
    the **Split Expense module** (`SplitGroup`/`SplitExpense` entities from
    plan.md $4) for tracking who owes what.
  - This directly bridges quick transaction entry with the dedicated Split
    Expense tracker rather than being two disconnected features.

### 1.5 Category Recommendations — `SUGGEST-01` `[NEW]` (see $13 below)
- While entering a transaction, as soon as **amount + account** (and
  optionally a note/merchant name) are set, show a **suggested category
  chip row** above the category field — see $13 for the recommendation
  engine details.

---

## 2. Account Management

### 2.1 Basic Account CRUD — `ACC-01` `[MM]`
- Create/edit/archive/delete accounts: name, icon, color, initial balance,
  currency (kept from MyMoney's "Edit account" modal, redesigned).
- **Editable at any time** post-creation (`ACC-05` `[NEW]` — see $7).

### 2.2 Credit Card Account Type — `ACC-02` `[NEW]`
When account type = **Credit Card**, the creation flow must additionally ask:
- **Credit Limit** (amount)
- **Billing cycle / statement generation date** (day of month)
- **Payment due date** (day of month, or "N days after statement date")
- Optional: **APR/interest rate**, **rewards rate %**
- System then auto-generates monthly `CreditCardStatement` records and:
  - Sends a **reminder notification** N days before due date (default 3,
    user-configurable)
  - Sends a **second reminder** on the due date itself if unpaid
  - Displays **utilization %** on the account card (green <30%, amber 30–70%,
    red >70%) to discourage over-utilization and encourage timely payoff
  - Tracks **payment history** per statement (paid on time / late / partial)

### 2.3 Loan Account Type — `ACC-03` `[NEW]`
When account type = **Loan** (covers both loans taken and loans given), ask:
- **Principal amount**
- **Monthly/annual interest rate (%)**
- **Tenure** (optional, for EMI calculation) or open-ended (interest-only
  tracking without fixed schedule)
- Loan type: Home / Personal / Car / Personal-lent / Personal-borrowed / Other

**Payment entry for loans** must let the user specify per payment:
- **Interest portion paid** (recorded as a real expense — affects analytics)
- **Principal portion paid** (recorded as balance reduction — excluded from
  analytics, since it's debt paydown, not spending — same rule as loan
  disbursement transfers, per plan.md $6)
- User can enter a single payment and split it manually between the two, or
  use "Auto-calculate from amortization schedule" if a tenure/EMI was set.
- Outstanding principal balance updates live after each payment.
- Amortization schedule (from plan.md $5.2.2) auto-generates if tenure is
  provided; otherwise the loan behaves as a simple running-balance ledger.

### 2.3.1 Loan reminders — `ACC-03b` `[NEW]`
- If EMI/due date is known, send payment reminders similarly to credit cards.

---

## 3. Category Management

### 3.1 Custom Icons — `CAT-01` `[MM]` `[NEW enhancement]`
- Existing MyMoney-style icon grid (Baby, Beauty, Bills, Car, etc.) retained
  as default set.
- User can create custom categories with:
  - Icon from built-in library, OR
  - Emoji, OR
  - **Custom uploaded image**, OR
  - **Auto-fetched brand/logo icon** (see $5 below)
- Full CRUD: add, edit (rename/re-icon/re-color), delete, reorder, and merge
  categories (merge = reassign all transactions from category A into B, then
  delete A).

### 3.2 Editable Anytime — `CAT-02` `[NEW]` (see $7)

---

## 4. Split Payment / Split Expense Module

(Ties into `TXN-04`.) Full standalone tracker (per plan.md $5.2.4):
- Groups of people, running per-person balances
- Settle-up flow, repayment history
- Optional deep-link to UPI app for settlement (see Phase 2, $Q below)

---

## 5. Icon Sourcing / Auto-Fetch — `ICON-01` `[NEW]`

**Goal:** For accounts like "Amazon Pay ICICI Credit Card," auto-fetch a
recognizable card/brand icon instead of a generic credit-card glyph.

**Approach (phased):**
1. **Bundled brand icon pack** — ship a curated set of common Indian bank/
   card/UPI-app logos (ICICI, HDFC, SBI, Axis, Kotak, Amazon Pay, Google Pay,
   PhonePe, Paytm, RuPay/Visa/Mastercard network marks) so most users get
   auto-matched icons **offline, instantly**, with zero network dependency
   or licensing risk from live scraping.
2. **Fuzzy name matching** — when the user types the account name, run a
   fuzzy string match ("amazon pay icici" → tokens: amazon, icici) against
   the bundled icon pack metadata to auto-suggest the best icon match live
   as they type, similar to how banking apps auto-detect card networks from
   BIN ranges.
3. **Online fallback (optional, user-triggered only)** — a "Search icon
   online" button that queries a logo API (e.g. Clearbit Logo API, Brandfetch,
   or a self-hosted curated icon CDN) for a brand/domain match, shown as a
   picker grid for the user to confirm before applying. Never auto-applies
   a fetched icon without user confirmation (avoids wrong/inappropriate
   logos being silently attached).
4. Fetched/confirmed icons are cached locally so they're available offline
   afterward.
5. User can always override with manual icon/emoji/image upload.

---

## 6. Editable Everything — `EDIT-01` `[FIX]`

MyMoney allows editing accounts (seen in "Edit account" modal) but this must
extend consistently to:
- **Categories** — full edit ($3.2)
- **Accounts** — full edit ($2.1), including changing account *type*
  post-creation with data migration warnings if changing to/from Credit
  Card/Loan type
- **Budgets** — full edit anytime ($9)
- **Transactions/Records** — see $7 detail below

---

## 7. Record Editing & Detail View — `REC-01` `[NEW]`

- Tapping any transaction in the Records list opens a **detail view within
  the same screen** (bottom sheet expanding to near-full height, or an
  in-place expansion card — not a jarring full navigation push) showing:
  - All fields: type, amount, account, category, date/time, notes (rendered
    as formatted itemized list if applicable), split details if applicable,
    attached receipt image if any
- An **Edit** button switches the same view into edit mode (reuses the
  Add-Transaction form pre-filled) with **Save**/**Cancel** actions.
- Delete action available with an **Undo snackbar** (per plan.md $13
  suggestion) rather than a blocking confirm dialog.
- Supports the same account/category bottom-sheet pickers as new entry ($1.1).

---

## 8. Budget Management — `BUD-01` `[FIX]`

- **Persistent by default:** A budget limit set for a category is NOT scoped
  to a single month only (fixing MyMoney's current per-month "not budgeted
  this month" reset behavior). Once set, it **carries forward automatically**
  to all future months until the user changes or removes it.
- User can, at any time:
  - **Add** a new category to the active budget set
  - **Remove** a category from budgeting (stops applying going forward;
    historical months keep their recorded limit for accurate past reporting)
  - **Modify** the limit amount for any category (change applies from the
    month of edit onward; past months retain the limit that was active then,
    so historical "budget vs actual" reporting stays accurate)
- **Rollover option retained per-category** (MyMoney's Carry Over toggle) —
  unused budget can roll into next month if enabled.
- **Remaining amount shown per category** — `BUD-02` `[NEW]`:
  - Each budgeted category row shows: limit, spent so far, and
    **remaining usable amount** (limit − spent, or limit + rollover − spent),
    with a progress bar (green → amber → red as it approaches/exceeds).
- **Tips & advice** — `BUD-03` `[NEW]`:
  - Contextual micro-tips surfaced on the Budget screen, e.g.:
    - "You've used 90% of your Clothing budget with 10 days left in the
      month."
    - "You consistently underspend your Grocery budget by ~₹800 — consider
      reallocating it to your Emergency Fund goal."
  - Powered by the on-device AI/rules engine (plan.md $7).

---

## 9. Balance Visibility — `PRIV-01` `[NEW]`

- An **eye icon** next to the Total Balance (dashboard hero card) toggles
  between showing the real figure and a masked state (`₹••••••`).
- State persists across app restarts (stored in local prefs) until toggled
  back.
- Applies to: dashboard hero balance, and optionally per-account balances
  (secondary toggle or inherits the global state — recommend a single global
  toggle for simplicity, with a settings option to also mask per-account
  figures).

---

## 10. Navigation Structure — `NAV-01` `[FIX]`

**Bottom navigation bar (5 items, user-approved layout):**
1. **Home** (Dashboard)
2. **Records** (Transaction list, matches MyMoney's Records tab)
3. **Analytics** (renamed from "Analysis")
4. **Accounts** *(new addition to bottom bar, was previously a 4th tab already
   in MyMoney — kept here)*
5. **Budgets** *(elevated to bottom bar from what was previously accessible
   via a tab — now a primary nav item)*

**Categories tab removed from bottom bar** — folded into: (a) accessible from
the category picker sheet during transaction entry, and (b) a dedicated
"Manage Categories" entry inside the side drawer, since it's a
configuration/management task rather than daily-use navigation.

**Side Drawer (hamburger icon, top-left, 3 horizontal lines):**
- Manage Categories
- Settings & Preferences
- Backup & Restore ($11)
- Net Worth / Investments / Subscriptions / Savings Goals / Lending &
  Borrowing / Credit Cards / Loans (advanced modules — accessed here to keep
  bottom bar uncluttered, per plan.md $5.2)
- Help / Feedback / About / Pro (if a paid tier exists)

---

## 11. Backup & Restore — `BACKUP-01` `[NEW/FIX]`

### 11.1 Local Backup
- **Export as CSV** — a full data export (all transactions + accounts +
  categories + budgets) as a structured CSV, saved to device storage,
  shareable via Android share sheet.
- **Native encrypted backup** (`.finara` file, per plan.md $5.1) remains
  available for true restore-anything-including-settings use cases; CSV is
  the primary "portable/inspectable" format per this request.

### 11.2 Google Drive / Google Account Sync
- **Google Sign-In** integration (`google_sign_in` package + Drive API scope
  `drive.appdata` or `drive.file`).
- **Backup to Drive:** on-demand button + optional **auto-backup schedule**
  (daily/weekly) that uploads the latest CSV/encrypted snapshot to the user's
  Google Drive (app-specific folder, not visible/cluttering their main Drive
  unless user opts for a visible folder).
- **Restore from Drive:** authenticate → list available backup files by
  date → select → preview record count/date range → confirm → import.
- **Restore from local file:** file picker (Android Storage Access
  Framework) to select a `.csv` or `.finara` file from device storage.
- **Goal:** user never loses data on uninstall/factory reset as long as they
  signed in to Google at least once and a backup exists.

### 11.3 CSV Import Mapping — `BACKUP-02` `[NEW]`
- User will supply a **sample CSV** (from their current MyMoney export/usage)
  — once provided, this section will be finalized with:
  - Exact column headers expected
  - Field-by-field mapping to Finara's schema (`Transaction`, `Account`,
    `Category` tables per plan.md $4)
  - Handling rules for: date format parsing, currency symbol stripping,
    duplicate detection (match on date+amount+account+note hash to avoid
    double-import), unmapped/unknown category auto-creation
  - A **column-mapping UI** (if headers don't exactly match) so the import
    isn't rigid to one exact CSV shape — user can map "My CSV column X" →
    "Finara field Y" manually for one-off imports from other sources too.
- **Action item:** ⚠️ Placeholder — finalize this subsection once the sample
  CSV is shared.

---

## 12. Category Recommendations — `SUGGEST-01` `[NEW]` (detailed)

- **Trigger:** as soon as user enters an amount and/or note/merchant text
  during transaction entry.
- **Recommendation sources (in priority order):**
  1. **Merchant/note keyword match** — if note contains known merchant
     names/keywords (e.g. "Zomato," "Swiggy" → Food; "Uber," "Ola" → Long
     Travel/Transport) using a bundled keyword-to-category dictionary
     (extensible/user-editable).
  2. **Historical pattern match** — same amount range + same account used
     previously → suggest the most frequently used category for that
     combination.
  3. **UPI QR/deep-link payee name** (Phase 2, ties to `QR-01`) — if the
     transaction was initiated from a scanned UPI QR or link, the payee name
     (`pn` param) feeds into keyword matching automatically.
- Suggestions rendered as up to 3 tappable chips above/near the category
  field; tapping one instantly selects that category (still editable via
  the normal picker sheet).
- Engine improves over time per-user (weights recent/frequent choices higher)
  — fully on-device, no cloud dependency required for this feature.

---

## 13. Non-Functional / Cross-Cutting Requirements

- **NFR-01:** All bottom-sheet pickers ($1.1) must support keyboard-avoiding
  behavior and be dismissible via swipe-down or scrim tap.
- **NFR-02:** Notes itemized-list mode ($1.3) values must be included in
  full-text search (`SEARCH-01`) so users can find a transaction by item
  name, not just the note string.
- **NFR-03:** All reminder notifications (credit card due, loan EMI, budget
  near-limit, subscription renewal) route through a single
  `NotificationScheduler` service to avoid duplicate/conflicting alarms, and
  respect Android's exact-alarm and battery-optimization constraints (use
  `WorkManager` + `AlarmManager` appropriately, request
  `SCHEDULE_EXACT_ALARM` only where truly needed).
- **NFR-04:** Google Drive backup must gracefully degrade to local-only mode
  if the user denies sign-in or is offline — app must never block core
  functionality on cloud availability.
- **NFR-05:** Split-transaction math ($1.4/$4) and loan interest/principal
  math ($2.3) must have dedicated unit tests given they directly affect
  account balance integrity.

---

## 14. Phase 2+ (Explicitly Deferred, Tracked Here for Continuity)

These remain as planned but are **not** part of the current requirements
build — listed here so scope isn't lost between documents:

- **OCR receipt capture** (`OCR-01`) — extract merchant/amount/date from a
  photographed physical bill/receipt, auto-fill transaction form.
- **Voice typing entry** (`VOICE-01`) — spoken transaction parsed into
  structured fields.
- **QR code scanning + UPI deep-link auto-populate** (`QR-01`) — scanning or
  opening a `upi://pay?...` link should parse:
  - `pa` (payee address/UPI ID)
  - `pn` (payee name → feeds category recommendation, $12)
  - `am` (amount → pre-fills amount field)
  - `cu` (currency)
  - `aid` (app-specific transaction reference, stored as external ref)
  - Then **redirect to the UPI app chooser** (Android intent) to complete
    the actual payment, and on return (or via manual confirmation), log the
    transaction in Finara pre-filled with the parsed data.
- **On-device SLM (small language model)** for deeper natural-language
  insights, financial Q&A ("how much did I spend on food last quarter?"),
  and personalized coaching beyond the rules-engine AI layer in plan.md $7.
- **Deeper analysis/recommendation engine** — the SLM would sit atop the
  rules-based Financial Health Score/insights system, not replace it,
  providing conversational summaries and richer forecasting.

---

## 15. Open Items Requiring Your Input

1. ⚠️ **Sample CSV** — please share it; $11.3 will be completed with exact
   field mapping once received.
2. Google Drive backup: should auto-backup be **on by default** after sign-in,
   or opt-in only?
3. For split transactions ($1.4), should "who owes what" reminders (push
   notifications to nudge settlement) be in scope for v1 or deferred with
   the rest of the Split Expense module polish?
4. Icon auto-fetch ($5): confirm you're fine with a **bundled offline pack +
   optional manual online search** approach rather than automatic live
   scraping (which has reliability/licensing/offline-support downsides).

## 15. currency selection
- there should be a setting in the settings window where i can switch between currencies like inr , dollar, pound, euro etc each with their own unique symbol like rupee symbol.