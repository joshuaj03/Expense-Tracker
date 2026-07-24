---
project_name: 'Finara'
user_name: 'Joshua'
date: '2026-07-23'
sections_completed:
  ['technology_stack', 'language_rules', 'framework_rules', 'testing_rules', 'quality_rules', 'workflow_rules', 'anti_patterns']
status: 'complete'
rule_count: 18
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

- **Flutter**: SDK 3.12.2
- **State Management & DI**: Riverpod (flutter_riverpod 2.6.1)
- **Local Database**: Drift (drift 2.27.0, sqlite3_flutter_libs 0.5.0)
- **Navigation**: go_router (14.0.0)
- **Charts**: fl_chart (0.70.0)
- **Notifications**: flutter_local_notifications (22.1.0) with timezone (0.11.1) (Requires core library desugaring in Android `build.gradle.kts`)
- **Logging**: talker_flutter (4.4.1), talker_riverpod_logger (4.4.1)
- **Other utilities**: google_fonts (6.2.1), intl (0.19.0), csv (8.0.0), file_picker (8.1.4), shared_preferences (2.2.3), uuid (4.4.0)

## Critical Implementation Rules

### Language-Specific Rules

- **Strict Null-Safety**: Dart's sound null-safety must be respected. Do not use the `!` (bang) operator unless absolutely certain; prefer `??` or explicit null checks.
- **Immutability**: Use `final` and `const` keywords extensively. Classes, especially those managed by Riverpod or representing data models, should be immutable where possible.

### Framework-Specific Rules

- **Feature-First Architecture**: Follow the established `core/` and `features/` directory structure. Each feature should contain its own presentation, domain, and data layers where applicable.
- **Riverpod State Management**: Use Riverpod generators (`@riverpod` or `@Riverpod(keepAlive: true)`) for strongly-typed providers. Providers should be scoped to their feature directories.
- **Offline-First Data with Drift**: Drift is the single source of truth. All data writes should go directly to Drift. UI should update automatically by listening to reactive Drift streams (e.g., `watchAll()`), rather than manually updating state after a write.
- **Database Migrations**: Drift schema upgrades must be meticulously managed. If modifying tables, increment the schema version and implement the correct migration logic in the database class.

### Testing Rules

- **Widget Tests**: Mock Drift database connections and Riverpod providers. Use `ProviderScope` with `overrides` to provide mock dependencies for UI testing.
- **Unit Tests**: Ensure business logic (notably Riverpod Notifier classes) is fully tested independent of the UI. Use `mockito` or `mocktail` for dependency mocking.

### Code Quality & Style Rules

- **Linting**: Strict adherence to `flutter_lints` (6.0.0). No warnings should be left unaddressed.
- **File Naming**: Use `snake_case.dart` for all file names.
- **Class Naming**: Use `PascalCase` for all classes, enums, and typedefs.
- **Widget Extraction**: Avoid deeply nested widget trees. Extract complex UI blocks into separate `StatelessWidget`s rather than helper methods to optimize rebuilds.

### Development Workflow Rules

- **Tasks**: Use the provided `task.md` document to track execution steps when implementing a large feature. Check off items as they are completed.
- **Plans**: Update `implementation_plan.md` or `plan.md` when architectural or feature-level decisions change.
- **Artifacts**: Store documentation or reports in `docs/` or `design-artifacts/` according to standard BMad practices.

### Critical Don't-Miss Rules

- **Do not modify Drift generated files**: Never directly modify the `.g.dart` or `.drift.dart` files. Always run `dart run build_runner build` (or `watch`) after changing Drift schema or Riverpod providers.
- **Do not write inline SQL unless necessary**: Prefer Drift's type-safe query builders over raw SQL to maintain compile-time safety.
- **Avoid passing Providers down the widget tree**: Instead of passing state manually via parameters, read the providers locally in the widget that needs them (using `ConsumerWidget` or `ConsumerStatefulWidget`).

### Logging & Observability Rules

- **Use Talker exclusively**: The app uses `Talker` via `AppLogger` (`core/utils/logger.dart`) for all logging. Do not use `print` or `debugPrint`.
- **Log EVERYTHING**: Every database mutation (INSERT, UPDATE, DELETE), navigation event, user interaction (taps, picker selections), backup operation, and app lifecycle event MUST be logged.
- **Use the right log type**: `AppLogger.instance` has specific methods like `.db()`, `.nav()`, `.ui()`, `.backup()`, and `.lifecycle()`. Use the correct one.
- **Exception logging**: Wrap all DAO mutations in try/catch and use `AppLogger.instance.error('Message', e, st)`.

---

## Usage Guidelines

**For AI Agents:**

- Read this file before implementing any code
- Follow ALL rules exactly as documented
- When in doubt, prefer the more restrictive option
- Update this file if new patterns emerge

**For Humans:**

- Keep this file lean and focused on agent needs
- Update when technology stack changes
- Review quarterly for outdated rules
- Remove rules that become obvious over time

Last Updated: 2026-07-23
