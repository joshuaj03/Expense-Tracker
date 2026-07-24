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

## 📍 Current Exact State
We have successfully built, tested, and polished the **Accounts Module Redesign**. The UI gracefully handles dynamic summaries and excluded accounts. The latest APK `Finara_v0.1.0-alpha.2_build_2.apk` has been built and delivered for the user's manual sanity check. 
We are moving iteratively through the remaining features.

## 🚀 Pending Tasks (Up Next)
1. **B2: Loan Management (Next Immediate Task)**
   - Summarizing total interest paid, remaining principal, and an algorithm estimating payoff time based on historical payments.
2. **B3: Advanced Analytics**
   - Deeper category insights and recommendations.
3. **C1: Data Sync & Backup**
   - CSV backup/restore matching the MyMoney format and Google Drive Sync.

## ⚠️ Key Technical Decisions & Constraints
- **Methodology:** We follow a strict "module/part/feature by feature" rule. First build, fix bugs and incomplete features, test (by providing an APK), fix if needed, then move to the next feature. We do not guess or hallucinate; we ask the user for clarification before proceeding.
- **APK Naming Scheme:** Final APKs follow a strict naming scheme, currently around `Finara_v0.1.0-alpha.2_build_x.apk`.
- **Offline First:** All data is stored via Drift SQLite locally.
- **UI Constraints:** Avoid overflow errors by using `Flexible`/`Expanded` with `maxLines: 2` and `TextOverflow.ellipsis` on long data fields like account names.
