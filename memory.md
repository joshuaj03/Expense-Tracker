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

## 📍 Current Exact State
We have successfully built, tested, and polished the **Global Icon System Upgrade**. All areas of the application now properly render external SVG and PNG images, gracefully falling back to text-based emojis when necessary. We've fixed issues where SVGs were not rendering in list views (Categories, Accounts, Dashboards, Budgets, Analytics) and saved the `.svg` URL properly in the database.
The latest APK `Finara_v0.1.0-alpha.2_build_11.apk` has been built and delivered for the user's manual sanity check. This build includes the new "Delete All Data" feature in Settings.
We are moving iteratively through the remaining features on the `develop` branch.

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
7. **Split Expenses & Lending**
   - Split Transactions toggle (equal or custom) from the Add Transaction screen.
   - Dedicated Lending/Borrowing tracker for "who owes what" and settle-up workflows.
8. **Advanced Transaction Entry**
   - **Itemized Receipts (Notes):** Line-item mode (Item, Qty, Price) that auto-calculates totals.
   - **Category Recommendations:** Auto-suggest categories based on typing history or merchant keywords.
9. **Advanced Future Features (Phase 2+)**
   - **Voice Typing Entry:** Parse spoken language into a structured transaction.
   - **On-device AI (SLM):** Conversational assistant for financial Q&A and coaching.

## ⚠️ Key Technical Decisions & Constraints
- **Methodology:** We follow a strict "module/part/feature by feature" rule. First build, fix bugs and incomplete features, test (by providing an APK), fix if needed, then move to the next feature. We do not guess or hallucinate; we ask the user for clarification before proceeding.
- **APK Naming Scheme:** Final APKs follow a strict naming scheme, currently around `Finara_v0.1.0-alpha.2_build_x.apk`.
- **Offline First:** All data is stored via Drift SQLite locally.
- **UI Constraints:** Avoid overflow errors by using `Flexible`/`Expanded` with `maxLines: 2` and `TextOverflow.ellipsis` on long data fields like account names.
- **Git Branching:** Active development happens on the `develop` branch. The `main` branch is strictly reserved for stable releases.
