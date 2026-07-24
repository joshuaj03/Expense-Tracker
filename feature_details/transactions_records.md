# Transactions & Records Module

## 1. What the feature/module/part is
This module is the core transactional engine and history viewer for Finara. It encompasses the `Add Transaction` screen and the `Records` tab. It allows users to input their income, expenses, and transfers, and subsequently view them in an organized manner across different timeframes.

## 2. What it does
- **Recording Transactions**: Allows users to input financial transactions (expense, income, transfer) linking them to specific accounts and categories.
- **Itemized Lists & Notes**: Users can add specific line items (with quantities and prices) to a transaction, and also add a general text note. These are maintained separately.
- **Records Tab (View)**: Displays a comprehensive history of transactions organized by timeframes (Daily, Weekly, Monthly, Yearly).
- **Summaries**: Shows total income, expenses, and net amounts for the selected timeframe. A detailed breakdown (including pie charts) is available via a summary popup.
- **Quick Navigation**: Includes a "Current" button to jump immediately back to the present day/week/month/year.
- **Transaction Details**: Clicking on any record opens a modal popup displaying the full details of the transaction, including its category, associated accounts, itemized lists, and notes.

## 3. What changes we made
- **Timeframe Toggles**: Implemented the Daily, Weekly, Monthly (with 1/3/6 month sub-toggles), and Yearly views.
- **Summary Popup**: Added a "Summary" button that opens a popup with detailed charts and stats for the selected timeframe.
- **Itemized List Fixes**: Fixed a critical logic flaw where the itemized list was overwriting the raw `notes` column. Re-routed itemized entries to properly serialize to `itemizedListJson` and load back correctly during edit mode.
- **Header Revamp**: Replaced the redundant "Records" title with the app name "Finara" and moved the sidebar drawer menu button to this header.
- **Navigation Shortcuts**: Added a button near the timeframe selector to quickly reset the view to the current date.
- **UI Overflow Fixes**: Wrapped long account names (like "Amazon Pay ICICI Credit Card") in `Flexible` widgets in both the transaction lists and the details popup, allowing them to wrap to two lines without layout errors.
- **Popup Refinements**: Removed the explicit close button from the transaction detail modal, allowing users to close it seamlessly by tapping outside the box.

## 4. What's left to build
- Phase B Modules: Credit Card management (B1), Loan management (B2).
- Advanced Analytics: Deeper category insights or machine-learning based recommendations.
- CSV/Drive Sync: Exporting and backing up records.

## 5. Needs fix
- *None currently identified for this specific module.* The recent fixes addressed the known UI overflows and data saving issues.

## 6. Known bugs
- Old transactions created during the beta test with the buggy `_isItemized` logic will have their itemized list saved as a plain text string in the `note` field, and their `itemizedListJson` will be empty. (This only affects test data prior to version 0.0.22).

## 7. Doubts remaining or clarification required
- Should we provide a bulk-edit or multi-select delete option in the Records tab?
- When deleting an account or category that is linked to historical transactions, should we enforce a "soft delete" or reassign those transactions?
