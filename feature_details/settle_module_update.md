# Feature Details: Settle (Lend/Borrow & Split Payment) Update

## What the feature/module/part is
This module handles the advanced transaction tracking for tracking Debts (Lend/Borrow) and Split Payments (Income/Expense), specifically focusing on the new `SETTLE` transaction action in the Add Transaction screen, and the Pending Recoveries overview.

## What it does
It allows users to log a new `Settle` transaction which acts as a repayment toward an existing debt or pending recovery. The UI dynamically filters the user's pending records into "Recover" (Lent or Split Payments) and "Pay Back" (Borrowed), allows selecting multiple records, and smartly distributes a global repayment amount among them using a custom numeric keypad.

## What changes we made
- **Corrected Record Filtering:** Recover tab explicitly pulls `isSplit` transactions (Lent/Split), while Pay Back tab explicitly pulls `isDebt` transactions (Borrowed).
- **Remaining Amount Fix:** Lend transfers (where `userShareAmount` is null) are now correctly calculated using the full `txn.amount` as the original debt, rather than 0.
- **Title and Labelling:** Removed the placeholder `Transaction #ID` titles in both Settle and Pending Recoveries lists, replacing them with accurate conditional labels (`Lent`, `Split Payment`, or `Borrowed`).
- **Transaction Details UI:** Added clear indicators in the Transaction Details popup for Debt-related records (`Debt • Lend`, `Debt • Borrow`, `Debt Payment • Recover / Pay Back`).
- **Database Crashing Bug:** Fixed a critical bug in `TransactionsDao.updateTransaction` where it attempted to log missing companion values during settlement updates, which caused the UI to silently fail to close and only settle the first of multiple selected records.
- **Analytics Visibility:** Allowed setting to hide or show Settle transactions from global analytics, explicitly using green (positive) and red (negative) formatting in the record list.

## What's left to build
- N/A for Settle mechanics. Next feature priority is Migration & Import.

## Needs fix
- Currently stable.

## Known bugs
- None discovered for Settle module so far.

## Doubts remaining or clarification required
- None.
