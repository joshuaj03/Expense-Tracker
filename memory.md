# Finara Project State & Handover Summary

## 🎯 Goal
Building "Finara"—a personalized, offline-first Expense Tracker & Budgeting app. It is heavily inspired by the "MyMoney" Android app, but tailored with custom features (itemized transactions, advanced loan tracking, budget carry-forward, and custom account icons) specifically for the user.

## ✅ What We've Completed
- **Core Architecture:** Established the project using Flutter, Riverpod, Drift (SQLite), and GoRouter.
- **Native `.mbak` Import:** Successfully reversed the MyMoney `.mbak` encryption. Implemented a native Dart decryption and import flow using PBKDF2 with AES-CBC.
- **Phase A (Core UX & Tracking):** Navigation restructure, transaction entry overhaul, itemized lists vs. notes, Records Tab revamp (daily/weekly/monthly/yearly timeframes), summary and transaction detail popups, budget persistence.
- **Accounts Module Redesign:** 
  - Added `isIgnored` to exclude specific accounts from global analytics without losing data.
  - Revamped `accounts_screen.dart` with time-based summary headers (Income, Expense, Total) and a clean 3-dot action menu.
  - Created a granular `account_detail_screen.dart` for specific account transaction histories.
  - Upgraded Drift database schema to v4 to support account exclusions and computed credit card `billAmount`.
- **Global Icon System Upgrade:**
  - Upgraded the hardcoded emoji system to dynamically support SVGs via Iconify API (`https://api.iconify.design/search?query=...`) and PNG logos via Clearbit API.
  - Implemented this unified dynamic rendering across the dashboard, categories list, accounts list, transaction logs, budgets, and analytics to give a cohesive modern look.
- **Data Management (Fresh Start):**
  - Added a strict "Delete All Data" function in Settings that clears user data but intelligently re-seeds the app with generic accounts and curated categories.
- **Split Expenses & Lending (Settle Module):**
  - Designed and implemented "Split Transaction" mode, supporting equally divided or custom amount splits among multiple people.
  - Added a dedicated "Pending Recoveries & Debts" tracker accessible directly from the Accounts Screen.
  - Created a new `SETTLE` transaction action for logging repayments.
  - *Recent Fixes:* Completely stabilized the Settle UI logic. Fixed a critical database companion logging bug that was preventing multi-record settlements from saving properly. Corrected "Lent" original amount math and polished the visual labeling across Pending Recoveries and Settle tabs. Verified color codes (Green = Recover, Red = Pay Back) and exclusion from analytics. 

## 📍 Current Exact State
We have successfully integrated and stabilized the **Split Expenses & Settlements** feature. The database handles deep linking between original debt transactions and their settlements perfectly, with accurate keypad distribution logic.
The latest APK `Finara_v0.1.0-alpha.4+15-update-2.apk` has been compiled and served.
We are moving iteratively through the remaining features on the `develop` branch, transitioning our focus to the next item on the pending task list: importing backups.

## 🚀 Pending Tasks (Up Next)
1. **Migration & Import (Immediate Next)**
   - Upload and restore the `.mbak` file from the MyMoney app to migrate all existing records, custom categories, budgets, and historical analytics seamlessly into Finara.
2. **Cloud Sync & Backup (Google Drive)**
   - Integrate Google Sign-In to seamlessly backup and restore the SQLite database to/from Google Drive. This ensures data is safe against uninstalls or factory resets.
3. **Dashboard, Analytics, Budgets & Settings Polishing**
   - General fixes, UI refinements, and feature additions across the core tabs.
4. **Smart Record Creation (OCR & QR)**
   - **OCR/Physical Bill:** Camera button near '+' to capture a bill and auto-populate a record.
   - **QR Code Scanner:** Scan merchant UPI QR codes to extract merchant name and amount, create a draft record, and seamlessly redirect to Android's UPI app selection intent.
5. **Automated SMS Tracking**
   - Automatically parse incoming bank SMS to create draft records. Drafts remain pending until reviewed, modified, and approved by the user.
6. **B2: Loan Management**
   - Fix and complete the loan section. Summarizing total interest paid, remaining principal, and an algorithm estimating payoff time based on historical payments.
7. **Advanced Transaction Entry**
   - **Itemized Receipts (Notes):** Line-item mode (Item, Qty, Price) that auto-calculates totals.
   - **Category Recommendations:** Auto-suggest categories based on typing history or merchant keywords.
8. **Advanced Future Features (Phase 2+)**
   - **Voice Typing Entry:** Parse spoken language into a structured transaction.
   - **On-device AI (SLM):** Conversational assistant for financial Q&A and coaching.

## ⚠️ Key Technical Decisions & Constraints
- **Methodology:** We follow a strict "module/part/feature by feature" rule. First build, fix bugs and incomplete features, test (by providing an APK), fix if needed, then move to the next feature. We do not guess or hallucinate; we ask the user for clarification before proceeding.
- **APK Naming Scheme:** Final APKs follow a strict naming scheme, currently around `Finara_v0.1.0-alpha.4_build_x.apk`.
- **Offline First:** All data is stored via Drift SQLite locally.
- **UI Constraints:** Avoid overflow errors by using `Flexible`/`Expanded` with `maxLines: 2` and `TextOverflow.ellipsis` on long data fields like account names.
- **Git Branching:** Active development happens on the `develop` branch. The `main` branch is strictly reserved for stable releases.
