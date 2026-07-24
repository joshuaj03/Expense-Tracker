---
name: finara-code-review
description: Reviews a Flutter/Dart file or PR against the strict Finara project context and rules. Ensures offline-first Drift patterns, Riverpod state management, and Widget extraction rules are met.
---

# Finara Code Review

This skill performs a rigorous code review of any provided Dart file or pull request to ensure it complies with the `project-context.md` rules defined for the Expense Tracker.

## Prerequisites
- The target file(s) must be provided in the user's prompt.
- The user should indicate if they want fixes automatically applied or just a review report.

## Execution Steps

### 1. Context Loading
- Review the `project-context.md` file (or `RULES.md`) to refresh the strict rules regarding Drift, Riverpod, and Flutter UI extraction.

### 2. Code Analysis
Scan the provided code for the following exact requirements:
- **Riverpod**: Are providers localized? Are we passing providers down the tree instead of using ConsumerWidgets? Are we using `@riverpod`?
- **Drift**: Is there any direct `.g.dart` modification? Are writes going to Drift instead of local state clones?
- **Null-Safety**: Are there any dangerous `!` operators? 
- **Widgets**: Are widget trees deeply nested? (Recommend extraction to StatelessWidgets if nesting is > 4 levels deep).
- **Naming Conventions**: PascalCase for classes, snake_case for files.

### 3. Report Generation
Generate an artifact named `finara_code_review.md`. 
Include:
- A summary of compliance with `RULES.md`.
- Specific line-by-line feedback with code diffs to correct anti-patterns.
- A checklist of what needs to be fixed.

### 4. Auto-Fix (Optional)
If the user requested auto-fixes, use your codebase editing tools to apply the recommendations safely, running `dart format` and `dart run build_runner build` afterwards if Riverpod/Drift models were touched.
