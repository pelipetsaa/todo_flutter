# Changelog

User-visible changes. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions are the `v*` tags that trigger the release workflow.

## Unreleased

### Added
- The ToDoList app icon on Android (adaptive) and iOS.
- An end-to-end test of the client against a running ToDoList server, run in CI on every push.

### Changed
- Period boundaries, the default due time and the date/time fields use an injected time zone (the device's in the
  app), so DST and zone changes are covered by tests.

## 1.0.0 — 2026-10-30

First version: a Flutter client with the same features and REST contract as the ToDoList apps.

### Added
- Sign-up and sign-in with email and password, or Google once OAuth clients are configured.
- Todos for today, this week and this month; create, edit and delete with date, time and status.
- Transparent access token refresh; reads retried while the server restarts; English and Russian UI.
- CI: format, analyze, tests with coverage, Android and iOS builds. Signed Android releases on `v*` tags, optional
  Google Play and TestFlight uploads; Dependabot for pub packages and GitHub Actions.
