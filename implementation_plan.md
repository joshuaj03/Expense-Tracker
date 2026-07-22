# Finara v0.2 — Feature Enhancement Plan

## Summary

16 feature requests organized into 4 phases. This plan transforms the alpha into a fully refined personal finance app.

---

## Phase A — Core UX Fixes (Priority: Highest)

These changes fix the transaction entry experience and app navigation structure.

---

### A1. Transaction Entry Overhaul

#### [MODIFY] [add_transaction_screen.dart](file:///c:/Users/joshu/OneDrive/Documents/Coding/Expense%20Tracker/finara/lib/features/transactions/presentation/screens/add_transaction_screen.dart)

**Req #1 — Category & Account Dropdowns:**
- Replace horizontal chip lists with **tap-to-open bottom sheet selectors**
- Category selector: shows categorized grid in a modal bottom sheet with search
- Account selector: shows account list in a modal bottom sheet with account icons & balances
- Both show the currently selected item as a compact tile with dropdown arrow

**Req #2 — Date/Time below Keypad:**
- Move date & time picker buttons to a fixed row **below the numeric keypad**, above the safe area
- Layout order: Amount display → Category/Account selectors → Notes → *(scroll ends)* → Keypad → Date/Time row

**Req #3 — Enhanced Notes Section:**
- Replace single-line TextField with a **multi-line, resizable TextBox** (min 3 lines visible)
- Add a `+` button in the notes field that toggles **Itemized List Mode**:
  - Shows a table with columns: **SL** (auto-numbered), **Item** (text), **Qty** (number), **Price** (number)
  - Each row auto-calculates `Qty × Price`
  - Total row at bottom auto-sums all prices
  - Total auto-fills the amount field
  - User can add/remove rows with `+`/`−` buttons
- When not in list mode, notes remain a free-text box

**Req #4 — Split Payment Toggle:**
- Add a "Split Payment" switch/checkbox below the notes section
- When enabled, shows:
  - **Number of people** counter (with `+`/`−`)
  - **OR** explicit "My share" amount field (toggle between "Equal split" and "Custom share")
  - Calculates and displays: `Total: ₹X → My share: ₹Y`
  - The transaction is saved with the user's share amount
  - Store split metadata (total, people count, user's share) in a new `split_info` JSON field

#### [NEW] `lib/features/transactions/presentation/widgets/category_picker_sheet.dart`
- Modal bottom sheet with search + grid of category icons
- Groups by income/expense type
- Recent categories shown at top

#### [NEW] `lib/features/transactions/presentation/widgets/account_picker_sheet.dart`
- Modal bottom sheet listing accounts with icons, names, and balances

#### [NEW] `lib/features/transactions/presentation/widgets/itemized_notes.dart`
- The itemized list widget (SL, Item, Qty, Price table)

---

### A2. Navigation Restructure

#### [MODIFY] [app_router.dart](file:///c:/Users/joshu/OneDrive/Documents/Coding/Expense%20Tracker/finara/lib/core/navigation/app_router.dart)

**Req #15 — Bottom Nav + Drawer:**
- Bottom nav changes from **4 tabs** to **5 tabs**:
  - 🏠 Home | 📝 Records | 💳 Accounts | 📊 Budgets | 📈 Analytics
- **Settings moves to a side drawer** (hamburger icon `≡` in the app bar)
- Drawer contains: Settings, Backup & Restore, About, Sign Out

#### [NEW] `lib/core/navigation/app_drawer.dart`
- Side drawer widget with: Settings, Backup & Restore, About

---

### A3. Record Editing & Viewing

#### [MODIFY] [transactions_screen.dart](file:///c:/Users/joshu/OneDrive/Documents/Coding/Expense%20Tracker/finara/lib/features/transactions/presentation/screens/transactions_screen.dart)

**Req #8 — Edit & View records in-place:**
- Tapping a transaction opens an **expanded detail view** (bottom sheet or inline expansion) showing all fields
- "Edit" button opens the same `AddTransactionScreen` pre-filled with existing data
- Save updates the record in-place (not create + delete)

#### [MODIFY] [transactions_dao.dart](file:///c:/Users/joshu/OneDrive/Documents/Coding/Expense%20Tracker/finara/lib/core/database/daos/transactions_dao.dart)
- Add `updateTransaction()` method that reverses old balance changes and applies new ones

---

### A4. Balance Hide Toggle

#### [MODIFY] [dashboard_screen.dart](file:///c:/Users/joshu/OneDrive/Documents/Coding/Expense%20Tracker/finara/lib/features/dashboard/presentation/screens/dashboard_screen.dart)

**Req #10:**
- Add an **eye icon** (👁/🙈) button on the balance hero card
- When tapped, all amounts on the dashboard show `₹ ••••••` instead of actual values
- Persist state via SharedPreferences

---

### A5. Budget Persistence

#### [MODIFY] [budgets_dao.dart](file:///c:/Users/joshu/OneDrive/Documents/Coding/Expense%20Tracker/finara/lib/core/database/daos/budgets_dao.dart)

**Req #9 — Budgets carry forward:**
- When opening a new month, auto-clone budgets from the previous month if none exist for the current month
- User can add, remove, or modify budget limits anytime
- Budget edits apply from the current month forward (historical months stay unchanged)

#### [MODIFY] [budgets_screen.dart](file:///c:/Users/joshu/OneDrive/Documents/Coding/Expense%20Tracker/finara/lib/features/budgets/presentation/screens/budgets_screen.dart)

**Req #14 — Remaining amount + tips:**
- Each budget card shows: **Spent**, **Remaining**, **% used**
- Conditional tips: "You're on track! 👍", "Slow down — 80% used with 15 days left", "Over budget by ₹X ⚠️"
- Summary card at top: total budgeted, total spent, total remaining

---

### A6. Category & Account Modifications

**Req #7 — Edit existing categories/accounts:**
- Already partially implemented (accounts have edit screen)
- Add **edit dialog for categories** (tap category → edit name/icon/color)
- Add **long-press** to trigger edit on both accounts and categories in their list screens

---

## Phase B — Financial Features

---

### B1. Credit Card Management

#### [MODIFY] [add_account_screen.dart](file:///c:/Users/joshu/OneDrive/Documents/Coding/Expense%20Tracker/finara/lib/features/accounts/presentation/screens/add_account_screen.dart)

**Req #6 — Credit card fields:**
- When account type = "Credit Card", show additional fields:
  - **Credit limit** (₹ amount)
  - **Bill generation date** (day of month, 1–28)
  - **Payment due date** (day of month)
- Save these in new DB columns on the `accounts` table (or a linked `credit_cards` table)

#### [NEW] `lib/core/notifications/reminder_service.dart`
- Schedule local notifications:
  - 3 days before bill due date: "Credit card bill due in 3 days"
  - On due date: "Pay your credit card bill today to avoid penalty"

#### [MODIFY] Database schema
- Add `credit_limit`, `bill_gen_day`, `due_day` columns to `accounts` table

---

### B2. Loan Management

#### [NEW] `lib/features/loans/`

**Req #6 — Loan tracking:**
- Create loan with: **Name**, **Principal amount**, **Monthly interest %**, **Start date**
- Record payments split into: **Interest component** + **Principal component**
- Dashboard shows: Outstanding principal, total interest paid, remaining balance
- Each payment auto-calculates remaining principal

#### Schema additions:
```
Loans (id, name, principalAmount, interestRatePct, startDate, accountId)
LoanPayments (id, loanId, date, interestAmount, principalAmount, transactionId)
```

---

### B3. Category Recommendations

#### [NEW] `lib/core/utils/category_recommender.dart`

**Req #13:**
- When user starts typing a note or amount, suggest categories based on:
  - **Recent usage**: most frequently used categories
  - **Keyword matching**: "uber" → Transport, "swiggy" → Food & Dining
  - **Amount range**: small amounts (< ₹200) → Food/Transport, large → Rent/Shopping
- Show recommendations as chips above the category selector

---

### B4. Online Icon Fetching

**Req #5 — Fetch card/brand icons:**

> [!WARNING]
> This requires network access and an icon/logo API. For the alpha, I recommend:
> - Ship with a **curated set of 50+ icons** covering major banks, UPI apps, and card brands
> - Add a "search icons" feature that queries a free logo API (e.g., Clearbit Logo API or similar)
> - User can also pick from emoji or upload a custom image

---

## Phase C — Data & Sync

---

### C1. CSV Backup & Restore

#### [NEW] `lib/features/backup/`

**Req #11 & #16 — Backup/Restore:**
- **Export**: Generate CSV file with all transactions, accounts, categories, budgets
- **Import**: Parse CSV file and restore data with preview before commit
- CSV format will match your sample CSV fields (share the CSV and I'll match the schema)

#### [NEW] `lib/features/backup/presentation/screens/backup_screen.dart`
- Export to CSV (share/save to device)
- Import from CSV (file picker)
- Google Drive backup/restore (Phase C2)

---

### C2. Google Drive Integration

**Req #16 — Google Sign-in + Drive backup:**

> [!IMPORTANT]
> This requires:
> - `google_sign_in` package
> - `googleapis` package (for Drive API)
> - A Google Cloud project with OAuth credentials configured
> - SHA-1 fingerprint added to Firebase/Google Cloud Console
>
> **Do you have a Google Cloud project set up, or should I guide you through creating one?**

- Sign in with Google account
- Auto-backup to Google Drive (encrypted JSON/CSV)
- Restore from Google Drive with file picker
- Optional auto-backup on every transaction

---

## Phase D — Polish

- **Req #14 tips**: Financial tips engine (simple rule-based advice)
- Transaction detail view animations
- Drawer transitions and polish
- Itemized list export to notes text

---

## Open Questions

> [!IMPORTANT]
> **#1 — Sample CSV**: You mentioned sharing a sample CSV for import. Please share it so I can match the field mapping exactly.

> [!IMPORTANT]
> **#2 — Google Cloud Project**: For Google Drive backup, do you have a Google Cloud project with OAuth credentials? If not, I'll include setup instructions.

> [!IMPORTANT]
> **#3 — Loan Types**: Should loan tracking support both "Loans I've taken" (EMI payments) AND "Loans I've given" (tracking repayment from others)? The plan.md mentions both.

> [!IMPORTANT]
> **#4 — Split Payments**: When splitting, should it create separate transaction records for each person, or just record the user's share as a single transaction with split metadata?

> [!IMPORTANT]  
> **#5 — Icon Fetching**: For card icons (like "Amazon Pay ICICI"), acceptable to start with a curated icon pack of major Indian banks/cards and add online search later?

---

## Database Schema Changes

```diff
// accounts table additions
+ RealColumn get creditLimit => real().nullable()();
+ IntColumn get billGenDay => integer().nullable()();  
+ IntColumn get dueDay => integer().nullable()();

// transactions table additions  
+ TextColumn get splitInfo => text().withDefault(const Constant(''))(); // JSON

// New tables
+ Loans (id, name, principalAmount, interestRatePct, startDate, accountId)
+ LoanPayments (id, loanId, date, interestAmount, principalAmount, transactionId)
```

---

## Build Order

1. **A2** — Navigation restructure (drawer + 5-tab bottom nav) — *foundation for everything*
2. **A1** — Transaction entry overhaul (dropdowns, notes, split) — *most impactful UX fix*
3. **A3** — Record editing
4. **A4** — Balance hide toggle
5. **A5** — Budget persistence + tips
6. **A6** — Category/account editing
7. **B1** — Credit card management
8. **B2** — Loan management
9. **B3** — Category recommendations
10. **C1** — CSV backup/restore
11. **C2** — Google Drive (after you share Google Cloud credentials)
12. **B4** — Icon fetching
13. **D** — Polish

---

## Verification Plan

### After Each Phase
- `flutter analyze` — 0 errors
- Build and run on Android emulator/device
- Test the specific feature flow end-to-end

### Manual Testing
- Full transaction lifecycle: create → view → edit → delete
- Budget carry-forward across months
- CSV export → import round-trip
- Credit card reminder notification timing
