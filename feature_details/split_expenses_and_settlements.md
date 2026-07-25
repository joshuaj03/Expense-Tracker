# Feature: Split Expenses & Settlements

## What the feature/module/part is
This feature introduces the ability to split transaction amounts among multiple people (e.g., paying a restaurant bill for the group) and tracks the pending recoveries or debts. It introduces a new `SETTLE` transaction type designed explicitly for marking these pending splits and debts as paid.

## What it does
- **Split Logging:** When creating a transaction, the user can designate it as a "split" and specify either equal shares based on the number of people, or custom amounts. 
- **Pending Recoveries Tracking:** The app calculates the user's remaining unrecovered amount (the original amount paid minus the user's share, minus any amounts already settled). These are tracked on a dedicated "Pending Recoveries & Debts" screen accessible via the Accounts tab.
- **Settlement Transactions:** The user can create a `SETTLE` transaction (either receiving money back or paying someone back). These transactions automatically link to the original split/debt transaction and increment its `settledAmount`.
- **Accurate Ledger & Analytics:** The underlying account balance reflects the *full* amount immediately when the original transaction is made, ensuring the ledger is strictly accurate. However, the analytics engine and the transaction list view only count the `userShareAmount`, preventing the user's personal spending insights from being skewed by money spent on behalf of others.

## What changes we made
- **Database Schema Upgrades (Drift V5):** 
  - Added `isSplit`, `splitPeople`, `userShareAmount` to `Transactions` table.
  - Added `settledAmount`, `isFullySettled`, `isDebt`, and `settlementForTxnId` to the `Transactions` table to maintain explicit linkage between the original expense and the settlement payments.
  - Increment schema to V5 and implemented proper `onUpgrade` migration paths.
- **UI & Presentation:**
  - Added "Split Expense" toggle and interactive UI in `AddTransactionScreen` allowing for simple (number of people) or custom share inputs.
  - Added a new transaction action type: `SETTLE` alongside Income, Expense, and Transfer.
  - Created `PendingRecoveriesScreen` to list outstanding debts and splits with a visual progress bar.
  - Modified the transaction list items to display `userShareAmount` instead of the full amount.
  - Added "hide balance on press" interaction to the Accounts Screen summary area.
- **Data Layer (DAOs):**
  - Updated `TransactionsDao` to handle `SETTLE` type insertions and deletions, appropriately increasing/decreasing the parent transaction's `settledAmount` and updating the account balance accurately.

## What's left to build
- **Debt Transfer Toggle:** Implementation of the "Debt" checkbox inside the `TRANSFER` tab (to easily log when lending or borrowing money directly between accounts).
- **Auto-link Settlements:** When adding a general `SETTLE` transaction from the main UI, the user should be prompted to select *which* pending recovery/debt they are settling.

## Needs fix
- Ensure that if a user deletes a parent split transaction, all child `SETTLE` transactions are cascade-deleted or orphaned correctly to prevent balance desyncs.

## Known bugs
- None currently observed. (Recently fixed the database crash by properly implementing the V5 schema migration).

## Doubts remaining or clarification required
- Do we want to allow users to settle *partial* amounts across multiple accounts? (e.g., someone pays back $50 in Cash and $50 in Bank). The current data model supports this, but the UI might need to handle multi-account selection if done simultaneously.
