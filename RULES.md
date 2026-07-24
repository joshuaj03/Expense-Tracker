# Finara Implementation Rules

This document outlines the strict guidelines that must be followed when contributing to the Expense Tracker (Finara) codebase. These rules ensure consistency, performance, and maintainability.

## 1. Architecture & Framework
- **Feature-First Architecture**: Follow the established `core/` and `features/` directory structure. Each feature should contain its own presentation, domain, and data layers where applicable.
- **Riverpod State Management**: Use Riverpod generators (`@riverpod` or `@Riverpod(keepAlive: true)`) for strongly-typed providers. Providers should be scoped to their feature directories. Avoid passing Providers down the widget tree; instead, read providers locally (using `ConsumerWidget` or `ConsumerStatefulWidget`).
- **Offline-First Data with Drift**: Drift is the single source of truth. All data writes should go directly to Drift. UI should update automatically by listening to reactive Drift streams (e.g., `watchAll()`), rather than manually updating state after a write.

## 2. Language & Code Quality
- **Strict Null-Safety**: Dart's sound null-safety must be respected. Do not use the `!` (bang) operator unless absolutely certain; prefer `??` or explicit null checks.
- **Immutability**: Use `final` and `const` keywords extensively. Classes, especially those managed by Riverpod or representing data models, should be immutable where possible.
- **Linting**: Strict adherence to `flutter_lints` (6.0.0). No warnings should be left unaddressed.
- **Naming Conventions**: 
  - Use `snake_case.dart` for all file names.
  - Use `PascalCase` for all classes, enums, and typedefs.
- **Widget Extraction**: Avoid deeply nested widget trees. Extract complex UI blocks into separate `StatelessWidget`s rather than helper methods to optimize rebuilds.

## 3. Database & Testing
- **Drift Generated Files**: Never directly modify the `.g.dart` or `.drift.dart` files. Always run `dart run build_runner build` (or `watch`) after changing Drift schema or Riverpod providers.
- **Database Migrations**: Drift schema upgrades must be meticulously managed. If modifying tables, increment the schema version and implement the correct migration logic in the database class.
- **SQL Usage**: Prefer Drift's type-safe query builders over raw SQL to maintain compile-time safety.
- **Widget Tests**: Mock Drift database connections and Riverpod providers. Use `ProviderScope` with `overrides` to provide mock dependencies for UI testing.
- **Unit Tests**: Ensure business logic (notably Riverpod Notifier classes) is fully tested independent of the UI. Use `mockito` or `mocktail` for dependency mocking.

## 4. Logging & Observability
- **Centralized Logger**: All logging must route through `AppLogger.instance` (from `logger.dart`), which wraps `Talker`. Do not use `print()` or `debugPrint()`.
- **Database Logging**: Every DAO mutation (INSERT, UPDATE, DELETE) must log the operation details (e.g. amount, IDs) and be wrapped in a try/catch that calls `log.error()`. Watch/query operations should log their invocation via `log.db()`.
- **UI & Navigation Logging**: Every user interaction (taps, picker selections) must call `log.ui()`. Screen transitions are handled automatically by the router observer, but custom dialogs/sheets should log their opening/closing.
- **Error Logging**: Always log errors with the exception and stack trace using `log.error()`.

## 5. APK Build
- **Naming**: All new apk build should have the same format like Finara_vx.xx_build_xxxx.apk and should be stored in the app folder. The xxxx after build should either alpha , beta or prod based on the stage of development.
- Never name it prod unless, I approve. Right now the project is in active development, since it is being built from scratch, it cant got to even go to beta, unless all the phases are built.