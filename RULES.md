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
- All the apk must be stored in the folder build/app/apks/.
- **Naming**: The apps name now is Finara, so the apk names should be Finara_vx.x.x.x like that.

## 6. App Versioning & Release Lifecycle

- Follow **Semantic Versioning (SemVer)** using the format:
  `MAJOR.MINOR.PATCH-PRERELEASE.BUILD+BUILD_NUMBER`

- The Flutter app version must be maintained in `pubspec.yaml`, for example:
  `version: 0.1.0-alpha.1+1`

- Version stages:

  * **Alpha:** `0.x.x-alpha.N` — Active development. Features, UI, database structure, and architecture may change significantly.
  * **Beta:** `0.x.x-beta.N` — Major planned features are implemented and the app is ready for broader testing. Development should primarily focus on stabilization, bug fixes, UX improvements, and performance.
  * **Release Candidate:** `1.0.0-rc.N` — Feature-complete build considered suitable for production unless blocking issues are discovered.
  * **Production:** `1.0.0` and above — Stable public releases.

- Version number rules:

  * Increment `PATCH` for bug fixes and small corrections.
  * Increment `MINOR` for new backward-compatible features or meaningful feature milestones.
  * Increment `MAJOR` for major/breaking changes after the first production release.
  * Increment the prerelease number (`alpha.N`, `beta.N`, `rc.N`) for successive builds within the same development stage.
  * The Flutter build number after `+` must **always increase** and must never be reused or reset.

- Do **not** automatically transition the project from Alpha → Beta, Beta → RC, or RC → Production.

- A release-stage transition requires explicit developer approval.

- Do **not** automatically increment `MAJOR` or `MINOR` versions unless the scope of the change clearly requires it or the developer explicitly requests it.

- For normal development changes, fixes, and iterations, increment the appropriate prerelease/build number.

- Current development baseline:
  `0.1.0-alpha.1+1`

- Whenever preparing a build or release:

  1. Determine whether the change is a fix, feature, milestone, or release-stage transition.
  2. Update the version in `pubspec.yaml` accordingly.
  3. Ensure the build number is greater than every previously released build number.
  4. Preserve version history and never downgrade or reuse a previously published version/build number.
  5. Include the resulting version number in release notes or build summaries.

## Git & GitHub Workflow

### Branch Strategy

* `main` is the stable/releasable branch and must not be used for normal development.
* `develop` is the primary active-development branch.
* Never commit feature development directly to `main`.
* Create temporary branches from `develop` for isolated work.

Use the following branch naming convention:

* `feature/<name>` — new functionality
* `fix/<name>` — bug fixes
* `ui/<name>` — UI/UX changes
* `refactor/<name>` — internal code restructuring
* `perf/<name>` — performance improvements
* `docs/<name>` — documentation changes
* `chore/<name>` — tooling, dependencies, configuration, or maintenance

Examples:

`feature/credit-card-reminders`
`fix/csv-import-crash`
`ui/add-transaction-screen`
`refactor/sqlite-service`

### Commit Convention

Use Conventional Commit-style messages:

`type(scope): concise description`

Preferred commit types:

* `feat` — new functionality
* `fix` — bug fix
* `ui` — UI/UX changes
* `refactor` — code restructuring without changing intended behavior
* `perf` — performance improvement
* `test` — test additions or modifications
* `docs` — documentation
* `chore` — dependencies, configuration, build system, or maintenance

Examples:

`feat(transaction): add category selection popup`

`fix(csv): handle invalid imported transaction dates`

`ui(transaction): move date and time below calculator`

`refactor(database): extract SQLite repository`

### Commit Rules

* Each commit should represent one logical change.
* Keep commits small enough to understand and safely revert.
* Do not combine unrelated changes into a single commit.
* Do not use vague messages such as `update`, `changes`, `fix stuff`, or `final`.
* Do not commit code that is known to be broken unless explicitly creating a work-in-progress checkpoint.
* Never commit secrets, API keys, credentials, signing keys, `.env` contents, generated build artifacts, or other sensitive files.
* Verify `.gitignore` before committing newly generated or sensitive files.

### AI Agent Git Safety

* Never push, merge, rebase, force-push, delete branches, create releases, or modify Git tags without explicit developer approval.
* Never use `git push --force` or destructive Git operations unless explicitly instructed.
* The agent may inspect Git status, diffs, branches, and history when needed.
* Before proposing a commit, review the diff and ensure only intended files are included.
* The agent may recommend an appropriate branch name and commit message based on the work performed.
* Do not automatically commit after every file modification.
* A commit should only be created when the current logical unit of work is complete and the developer has requested or approved the commit.

### Merging

Normal development flow:

`develop → temporary branch → develop`

Stable release flow:

`develop → main`

Before merging into `develop`:

* Ensure the feature/fix is complete.
* Run relevant tests and static analysis.
* Ensure the application builds successfully where practical.
* Review the diff for unintended changes.

After a temporary branch has been successfully merged, it may be deleted.

### Releases & Tags

Stable development milestones merged into `main` should be tagged using the app version:

`v0.1.0-alpha.1`
`v0.8.0-beta.1`
`v1.0.0-rc.1`
`v1.0.0`

The Git tag must correspond to the version declared in `pubspec.yaml`.

Do not create, move, or delete release tags without explicit developer approval.

Release-stage transitions (Alpha → Beta → RC → Production) always require explicit developer approval.
