# Finara - Memory & Context

## 1. Project Overview & Location
**Current Path:** `C:\Coding\Expense Tracker` (Moved out of OneDrive to prevent Android Gradle lock issues).
Finara is a Personal Finance Operating System built with Flutter for Android first. It aims to be fast, confident, and provide instant insights on money management. The benchmark app is MyMoney, but with a more modern, minimal, glassmorphic UI, and stricter analytics rules.

## 2. Architecture & Tech Stack
- **Framework:** Flutter (Android first)
- **Language:** Dart (null-safe)
- **State Management & DI:** Riverpod 2.x
- **Local Database:** Drift (SQLite) with reactive streams.
- **Navigation:** `go_router`
- **Architecture Pattern:** Clean Architecture + MVVM, feature-based modularity.
  - `core/` (database, design_system, navigation, utils)
  - `features/` (accounts, analytics, backup, budgets, categories, dashboard, search, settings, transactions)
- **Offline First:** Drift is the single source of truth.

## 3. Database Schema (Drift)
- **Accounts:** ID, name, type (cash, bank, upi, wallet, creditCard, investment), icon, color, initial/current balances, currency.
- **Categories:** ID, name, type (income, expense), icon, color, parent ID, isSystem.
- **Transactions:** ID, type (income, expense, transfer), account ID, to-account ID, category ID, amount, date, note, tags, isExcludedFromAnalytics.
- **Budgets:** ID, category ID, month, year, limitAmount, rollover.

## 4. Work Accomplished (Phase 0 & Phase 1 MVP)
*All tasks below have been fully implemented:*
- **Phase 0 (Foundation):** Flutter project scaffold, Drift database layer, Design system (theme, core widgets like `GlassCard`, `NumericKeypad`), Navigation shell (`go_router`), Utils (currency/date formatting).
- **Phase 1 (MVP Features):** Dashboard, Fast Transaction Entry, Accounts, Categories, Analytics (strict transfer exclusion), Budgets, Search, Settings, Backup export.

## 5. Finara v0.2 - Current Plan (From Implementation Plan & Task Tracker)
Based on the comprehensive v0.2 requirements, the next set of features is grouped into 4 phases:

**Phase A: Core UX Fixes & Database Migration**
- [ ] Drift schema migration (v2) for Credit Cards (limit, billing), Loans (principal, interest), and Split Payments.
- [ ] Navigation restructure (5-tab bottom nav + drawer)
- [ ] Transaction entry overhaul (dropdowns, itemized notes, split support)
- [ ] Record editing & viewing

**Phase B: Financial Features**
- [ ] Credit card management (limit, billing, reminders)
- [ ] Loan management (tracking principal vs interest)
- [ ] Budget persistence (effective date ranges rather than static month)

**Phase C: Data & Sync**
- [ ] CSV backup/restore (matching `export_22_07_26_832.csv` format)
- [ ] **Google Drive Backup Architecture:** 
  - Local-first design (SQLite remains primary).
  - Uses Google Sign-In and Google Drive API (`appDataFolder`).
  - Safe snapshotting, compression, and encryption of the `.sqlite` file.
  - No centralized developer backend. User-owned encrypted backup.
  - Clean architecture separation: `GoogleAuthService`, `GoogleDriveService`, `DatabaseBackupService`, `BackupEncryptionService`.

**Phase D: Polish**
- [ ] Final build & test

## 6. Open Questions & Blockers (Status Updates)
1. **OneDrive + Gradle Conflict:** *Resolved.* Project moved to `C:\Coding\Expense Tracker`.
2. **Sample CSV / Backup:** *Resolved.* The CSV has been analyzed for import.
3. **Google Cloud credentials:** *Pending user action.* Google Sign-In configuration (OAuth Client IDs) will be needed for Phase C.
4. **Loan types & Split payments:** *Resolved.* Explicit data models provided.
5. **Budgets History:** *Resolved.* We will use an `effectiveFromMonth` and `effectiveToMonth` range.

## 7. Next Steps & Action Plan
- **Current Status:** Waiting for the user to review and approve the **Implementation Plan**.
- Once approved, begin executing **Phase A: Database & Core Models Migration** (schemaVersion 2) inside the new project directory.
