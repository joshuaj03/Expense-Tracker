# Finara — Personal Finance Operating System
### Product & Engineering Plan (Flutter, Android-first)

---

## 1. Vision
Finara is not an expense logger — it's a **Personal Finance Operating System**.
It should feel like Arc Browser meets Apple Wallet meets Linear: fast, quiet, confident. 
Benchmark app: **MyMoney—Track Expense & Budget** + highly personalized, advanced features.

---

## 2. Design System
- **Theme:** Dark-first (default), full light mode parity.
- **Style:** Minimal + glassmorphism used sparingly for overlays.
- **Typography:** Manrope (headers) + Inter (numbers, tabular figures).
- **Core Components:** Build as a shared `design_system` package.

---

## 3. Tech Stack & Architecture
- **Framework:** Flutter (Android first).
- **State Mgmt:** Riverpod 2.x (code-gen).
- **Local DB:** Drift (SQLite) — 100% offline-first.
- **Navigation:** go_router.
- **Architecture:** Clean Architecture + MVVM, Feature-First.
- **Rules:** Must strictly adhere to `RULES.md` and `finara-code-review` `SKILL.md`. Every feature must start with a `SPEC.md`.

---

## 4. Master Stories & Scenarios

### Epic 1: Navigation & Structure
- **Core Navigation**: Bottom navigation bar with Home, Analytics, Records, Budgets, Accounts.
- **Side Drawer**: Hamburger menu containing Manage Categories, Settings, Backup & Restore, Advanced Modules (Net Worth, Subscriptions, Loans).
- **Action Logs**: A "Logs" button in the side drawer to view comprehensive Talker-based logging of all operations (DB, UI, Nav, Lifecycle) for debugging/review.
- **Time-Based Summaries**: Pop-up toggles for Daily/Weekly/Monthly/Yearly record views on both the Records window and the Home window.

### Epic 2: Transaction Entry & Management
- **Bottom Sheet Selectors**: Tapping 'Account' or 'Category' opens a draggable bottom sheet (~70% height) with an "Add New" button.
- **Fixed Date & Time Picker**: Pinned to the bottom of the screen (below numpad) using modern calendar and clock dial pickers.
- **Advanced Notes**: Multi-line, expandable text area. Can toggle to a structured table (Sl. No, Item, Qty, Price) that auto-calculates a sum.
- **Split Transactions**: Split equally or custom among N people. Only the user's share is recorded to the main ledger.
- **Category Recommendations**: Smart suggestions based on merchant keywords in notes or historical patterns (same amount + account).
- **In-Place Editing**: Tapping a record expands it into a detail view with an "Edit" button. Delete uses an Undo snackbar.

### Epic 3: Account Management
- **Account CRUD**: Creation, modification, deletion, and archiving of standard accounts.
- **Credit Card Accounts**: Support Credit Limit, Statement Date, Due Date. Show utilization percentage ring. Schedule OS-level Push Notifications for due dates.
- **Loan Accounts**: Support Principal amount, Interest Rate, Tenure. Show a **Loan Summary** (Total interest paid, remaining principal, estimated time to close based on past velocity).

### Epic 4: Category & Icon Management
- **Custom Categories**: Support custom icons, emojis, or image uploads, and merging categories.
- **Smart Icon Sourcing**: Pre-bundle common Indian bank/wallet/app logos. Support highly specific card fronts (e.g., Amazon Pay ICICI card image) for easy identification.

### Epic 5: Budgeting & Analysis
- **Persistent Budgets**: Prompt the user to "Copy budget from last month?" to start fresh or carry over.
- **Budget Insights**: Display "Remaining Usable Amount" alongside spent and limit, with context-aware AI tips.

### Epic 6: Global Features & Settings
- **Privacy Mode**: Eye icon on the dashboard to mask total balances (e.g., `₹••••••`).
- **Currency Selection**: Setting to select global currency (INR, USD, EUR, etc.).
- **Export & Backup**: Export as `.csv` AND `.pdf`. Backup using `.bak` (or `.mbak`).
- **Restore**: Restore data natively from `.csv` or `.bak` files, seamlessly integrating it as normal records.

### Epic 7: Project Cleanup (Phase 1)
- **Architecture Fixes**: Run `finara-code-review` on existing codebase. Reorganize folders according to `RULES.md`. Refactor Riverpod providers to be local. Refactor Drift database connections to comply with offline-first rules.