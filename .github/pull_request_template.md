## What and why

<!-- What changes for users or developers, and why. Link the issue if there is one. -->

## How it was checked

<!-- Tests added or run, manual checks on Android / iOS, E2E against a local server. -->

## Checklist

- [ ] `dart format .` and `flutter analyze` are clean
- [ ] Tests cover the change
- [ ] API change: DTOs in `lib/core/dto` match the ToDoList server, and `E2E_BASE_URL=http://localhost:8080 flutter test test/e2e` passes
- [ ] New user-visible text exists in English and Russian (`lib/presentation/ui/strings.dart`)
- [ ] `CHANGELOG.md` has an entry under **Unreleased** if users will notice the change
