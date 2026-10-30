# Changelog

User-visible changes. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions are the `v*` tags that trigger the release workflow.

## Unreleased

## 1.0.1 — 2026-10-30

### Fixed
- Google sign-in was switched off in release builds: they now send ToDoList's web OAuth client as the ID token
  audience. It works once an Android OAuth client for this package and signing key exists (see README).
- A failed Google sign-in logs its reason, can be retried after a failed initialization, and no longer leaves the
  button spinning on unexpected platform errors.

## 1.0.0 — 2026-10-30

First release: a Flutter client with the same features and REST contract as the ToDoList apps. Release builds talk
to the deployed server at `https://todolist-server-zyck.onrender.com`.

### Added
- Sign-up and sign-in with email and password; Google sign-in once OAuth clients for this app are configured.
- Todos for today, this week and this month; create, edit and delete with date, time and status.
- Transparent access token refresh, reads retried while the server restarts, English and Russian UI.
- The ToDoList app icon on Android (adaptive) and iOS.
- CI: format, analyze, unit and widget tests with coverage, an end-to-end test against a running ToDoList server,
  Android and iOS builds. Signed Android releases on `v*` tags, optional Google Play and TestFlight uploads;
  Dependabot for pub packages and GitHub Actions.
