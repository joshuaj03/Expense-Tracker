# Feature: Delete All Data (Fresh Start)

## What the feature/module/part is
A new data management utility located in the **Settings** tab that allows the user to completely wipe all transaction, budget, and custom account/category data to start fresh.

## What it does
When triggered, it deletes all existing user data from the local Drift SQLite database (`transactions`, `creditCardBills`, `budgets`, `categories`, and `accounts` tables). It immediately re-seeds the database with three clean, generic default accounts (Cash, Card, Savings with 0 balances) and a strict, curated list of default income and expense categories. It also features a confirmation dialog to prevent accidental triggers.

## What changes we made
- **UI:** Added a "Delete all data" button to `settings_screen.dart` under the Data Management section, styled in red to indicate a destructive action.
- **UX:** Implemented `_showDeleteConfirmation` to display an `AlertDialog` warning the user that data will be permanently erased.
- **Database Logic:** Added the `clearAllData()` method to `app_database.dart` using a transaction to clear tables safely.
- **Data Seeding:** Created a hardcoded list of strict default categories (as requested by the user) and default generic accounts to ensure the app remains usable immediately after wiping.
- **Bug Fixes:**
  - Fixed a mojibake UI bug where the empty state icon for Recent Transactions rendered as `ðŸ“` instead of the proper emoji (`📄` or `📌`). Updated `tables.dart` and `dashboard_screen.dart` to use the correct emojis.
  - Re-ran `build_runner` to regenerate `app_database.g.dart` to ensure schema drift definitions reflected the fixed emoji.
  - Fixed a logic error where clearing data incorrectly re-imported the user's specific `myMoneyAccounts` (bringing back custom names and balances) instead of zero-balance generic default accounts.

## What's left to build
- Cloud Backup / Sync logic (Google Drive) so users can actually perform the recommended backup before deleting data.
- The `.mbak` backup import logic needs to be fully integrated into the UI so users can restore data if they wiped it by accident.

## Needs fix
- Ensure that the side-effects of wiping the database (like cached values in Riverpod providers) are properly invalidated or refreshed across the app without requiring a hard restart.

## Known bugs
- None reported directly with this specific flow at the moment.

## Doubts remaining or clarification required
- Do we need to offer an option to "Delete Transactions Only" while keeping all custom Accounts and Budgets intact in the future?
