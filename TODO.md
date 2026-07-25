# Finara Project TODO List

This document tracks all remaining tasks, features, and technical goals for the Finara app based on the original requirements and recent discussions.

## 1. Data Migration & Cloud Backup (Immediate Next)
- [ ] **MyMoney Import:** Upload and restore the `.mbak` file from the MyMoney app to migrate all existing records, custom categories, budgets, and historical analytics seamlessly into Finara.
- [ ] **Google Drive Sync:** Integrate Google Sign-In to seamlessly backup and restore the SQLite database to/from Google Drive. Ensures data is safe against uninstalls or factory resets.

## 2. Core Tab Polishing
- [ ] **Dashboard:** General UI refinements and bug fixes.
- [ ] **Analytics:** Deeper category insights, visualizations, and fixes.
- [ ] **Budgets:** Refine UI, rollover mechanics, and visual progress tracking.
- [ ] **Settings:** Add **Global Currency Selection** (INR, USD, EUR, etc.) and other user preferences.

## 3. Smart Record Creation
- [ ] **OCR / Physical Bill Scanning:** Add a camera button near the '+' button to capture a receipt and auto-populate a draft record.
- [ ] **QR Code Scanner:** Scan merchant UPI QR codes to extract merchant name and amount, create a draft record, and seamlessly redirect to Android's UPI app selection intent.
- [ ] **Automated SMS Tracking:** Automatically parse incoming bank SMS to create draft records. Drafts remain pending until reviewed, modified, and approved by the user.

## 4. Loan Management (B2)
- [ ] **Loan Dashboard:** Summarize total interest paid vs. remaining principal.
- [ ] **Payoff Algorithm:** Add an algorithm estimating payoff time based on historical payments.

## 5. Split Expenses & Lending
- [ ] **Split Transactions:** Add a toggle to split a transaction among multiple people (equal split or custom percentages/amounts) right from the Add Transaction screen.
- [ ] **Lending/Borrowing Tracker:** Dedicated section to track "who owes what," maintain running per-person balances, and handle settle-up workflows.

## 6. Advanced Transaction Entry
- [ ] **Itemized Receipts (Notes):** Add a toggle in the transaction notes to switch to a structured table (Sl. No., Item, Qty, Price) that auto-calculates the sum and pushes it to the total amount.
- [ ] **Category Recommendations:** Auto-suggest categories as the user types the amount or notes based on historical patterns or bundled merchant keyword mapping (e.g., typing "Zomato" auto-suggests "Food").

## 7. Advanced Future Features (Phase 2+)
- [ ] **Voice Typing Entry:** Parse spoken natural language into a structured transaction.
- [ ] **On-device AI (SLM):** A conversational assistant to answer questions like "How much did I spend on food last month?" and provide personalized financial coaching.
