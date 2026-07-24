# Accounts Module Redesign

## What the feature/module/part is
This is a complete redesign and overhaul of the Accounts tab in Finara, focusing on how accounts are managed, tracked, and how their associated transactions are displayed.

## What it does
- Displays a unified view of all active financial accounts.
- Calculates dynamic summaries (Income, Expense, Net Balance) of active accounts based on a timeframe filter (Daily, Weekly, Monthly, Yearly).
- Provides options for users to Edit, Ignore (soft delete to exclude from analytics/balances without destroying history), and Hard Delete an account.
- Introduces an Account Detail Screen to view the specific transaction history for an individual account.
- Introduces Credit Card specific billing history summaries showing generated bills.

## What changes we made
- **Schema Updates**: Added `isIgnored` field to `AccountsTable` and `billAmount` to `CreditCardBillsTable` (incremented schema version to 4).
- **AccountsDao**: Implemented logic for `toggleIgnoreAccount` and `hardDeleteAccount` (which gracefully cleans up linked transactions). Modified queries like `watchTotalBalance` to filter out ignored accounts.
- **TransactionsDao**: Ensured that global tracking queries filter out transactions from ignored accounts.
- **Credit Card Service**: Updated the bill generation to calculate real `billAmount`s from expenses within the billing period.
- **UI Redesign**: Overhauled `accounts_screen.dart` with a cleaner sticky header, dynamic timeview summaries, and 3-dot action menus. Fixed scrolling overlap bugs in the sticky header for monthly toggles.
- **Account Detail Screen**: Created `account_detail_screen.dart` for granular view of individual account history and associated actions. Moved Credit Card bill history into an interactive bottom sheet popup with robust fallback displays for uncalculated amounts.

## What's left to build
- **Loan Management**: B2 phase needs to be built to summarize total interest paid, remaining principal, and an algorithm estimating payoff time based on historical payments.
- **Advanced Category Insights**: B3 phase for category recommendations and deeper analytics.
- **Data Export/Import**: C1 phase for CSV backup and restore matching the original MyMoney format.

## Needs fix
- Ensure exact logic for `undo` on transaction deletion in `TransactionDetailDialog` (currently a placeholder snippet).

## Known bugs
- None currently identified in this build.

## Doubts remaining or clarification required
- For Credit Cards, do we need manual adjustment tools for previous bills if the generated calculation doesn't match the bank statement perfectly (e.g. late fees or manual adjustments)?
- For Loan Accounts, what specific mathematical formula should we use to estimate payoff time (amortization vs simple interest estimate)?
