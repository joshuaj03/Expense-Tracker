# Feature Details: Global Icon Rendering & Search System

## What the feature/module/part is
This feature enhances the application's icon system by replacing hardcoded emoji rendering with a dynamic rendering engine capable of displaying network-fetched PNGs and SVGs alongside standard emojis. It also introduces live icon searching via external APIs (Iconify and Clearbit) when creating accounts and categories.

## What it does
- **Dynamic Icon Rendering:** Reads an icon string from the database and determines its format:
  - If it starts with `http` and ends with `.svg`, it renders it using `SvgPicture.network`.
  - If it starts with `http` (but not `.svg`), it renders it using `CachedNetworkImage` (e.g. for Clearbit PNGs).
  - Otherwise, it falls back to rendering the string as a standard emoji using the `Text` widget.
- **Icon Search:**
  - **Categories:** Uses `https://api.iconify.design/search?query=...` to let users search for SVG icons across various icon sets.
  - **Accounts:** Uses Clearbit to fetch company logos based on domain (e.g., `amazon.in`, `hdfcbank.com`).
- **Global Integration:** The dynamic rendering logic is applied across the entire app, ensuring icons display consistently in picker sheets, lists, dashboards, analytics, and budgets.

## What changes we made
1. **Added Dependencies:** Added `flutter_svg` and `cached_network_image` to `pubspec.yaml`.
2. **Account Creation:** Updated `add_account_screen.dart` to use `CachedNetworkImage` for fetching company logos and saving the URL to the database.
3. **Category Creation:** Refactored `add_category_dialog.dart` to include an Iconify search field and render SVGs, saving the `.svg` URL.
4. **Widespread UI Updates:** Replaced direct `Text(icon)` rendering with our dynamic Builder widget in:
   - `add_transaction_screen.dart`
   - `transactions_screen.dart`
   - `transaction_detail_dialog.dart`
   - `category_picker_sheet.dart`
   - `account_picker_sheet.dart`
   - `categories_screen.dart`
   - `analytics_screen.dart`
   - `budgets_screen.dart`
   - `accounts_screen.dart`
   - `dashboard_screen.dart`

## What's left to build
- **Unified Icon Widget:** We currently duplicate the dynamic Builder logic across many files. It should be extracted into a shared widget (e.g., `AppIcon(iconUrl: ...)`).
- **Default/Generic Accounts Search:** Currently, the account search mostly relies on Clearbit domains. It might be helpful to also provide an Iconify fallback for generic accounts (like "Cash" or "Wallet").
- **Offline Support:** `SvgPicture.network` doesn't currently cache SVGs for offline use. We need to implement a mechanism to cache these SVGs (e.g., using `flutter_cache_manager` directly) so icons load when the device is offline.

## Needs fix
- The duplicate code across multiple files makes maintaining the icon rendering logic cumbersome. We need to refactor it into a single `AppIcon` widget.
- Error states (e.g., when the network fails) currently fallback to a hardcoded generic emoji (`📌` or `🏦`). This should be standardized.

## Known bugs
- `SvgPicture.network` will throw an exception or fail silently if the network request fails and the SVG isn't cached by default.

## Doubts remaining or clarification required
- **Icon Storage Strategy:** Should we download and save SVGs/PNGs locally to the device instead of relying on URL links? This would permanently fix offline support and prevent broken links if Iconify/Clearbit goes down.
- **Icon Sizing:** Should we enforce a strict aspect ratio for all external icons to prevent layout shifting? Clearbit sometimes returns rectangular logos instead of square ones.
