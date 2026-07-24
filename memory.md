# Finara Project State & Handover Summary

## 🎯 Goal
Building "Finara"—a personalized, offline-first Expense Tracker & Budgeting app. It is heavily inspired by the "MyMoney" Android app, but tailored with custom features (itemized transactions, advanced loan tracking, budget carry-forward, and custom account icons) specifically for the user.

## ✅ What We've Completed
- **Core Architecture:** Established the project using Flutter, Riverpod, Drift (SQLite), and GoRouter.
- **Native `.mbak` Import:** Successfully reversed the MyMoney `.mbak` encryption. Implemented a native Dart decryption and import flow using PBKDF2 with AES-CBC.
- **Phase A (Core UX & Tracking):**
  - Navigation restructure.
  - Transaction entry overhaul (custom numpad, category/account picker bottom sheets).
  - **Itemized Lists vs. Notes:** Built logic to save multi-item transactions and text notes separately, stored seamlessly in Drift via JSON.
  - **Records Tab Revamp:** Implemented complex timeframe toggles (Daily, Weekly, Monthly 1/3/6, Yearly) with nested summaries.
  - Summary and Transaction Detail popups with UI wrapping/overflow protections.
  - Budget persistence, remaining amounts, and tip displays.
  - Category and account editing improvements.

## 📍 Current Exact State
We just successfully finished building out and debugging the **Transactions & Records Module**. The UI gracefully handles long account names, explicitly separates itemized lines from the raw text notes in the database, and provides analytical summaries per timeframe.

We are now ready to tackle Phase B!

## 🚀 Pending Tasks (Up Next)
**Phase B: Advanced Financial Tracking**
1. **B1: Credit Card Management** 
   - Tracking billing cycles, grace periods, statement generation, and due dates.
2. **B2: Loan Management**
   - Summarizing total interest paid, remaining principal, and an algorithm estimating payoff time based on historical payments.
3. **Advanced Analytics**
   - Deeper category insights / recommendations.
4. **Data Sync & Backup**
   - CSV / Google Drive Sync.

## ⚠️ Key Technical Decisions & Constraints
- **APK Naming Scheme:** User prefers final APKs to be placed in `C:\Coding\Expense Tracker\app` following the format `Finara_vx.xx_build_prod.apk` (or `beta`).
- **Offline First:** All data is stored via Drift SQLite locally.
- **Logging Strategy:** The user prefers on-device testing. We rely on the in-app **Talker UI** for debugging rather than tethered `adb logcat`.
- **UI Constraints:** Avoid overflow errors by using `Flexible`/`Expanded` with `maxLines: 2` and `TextOverflow.ellipsis` on long data fields like account names.
