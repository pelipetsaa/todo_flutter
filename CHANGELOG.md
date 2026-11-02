# Changelog

User-visible changes. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions are the `v*` tags that trigger the release workflow.

## Unreleased

### Added
- Debug builds have their own package / bundle ID (`.debug`) and name "ToDo Debug", so they can be installed next to
  the release app.
- `tool/run_on_device.sh` runs a debug build on a connected phone against the local server (`adb reverse` on Android,
  the computer's Wi-Fi address on iPhone); Android debug builds allow plain HTTP to any host for this.

- Password managers can fill the sign-in and sign-up forms and offer to save the credentials.

### Changed
- The tokens are stored as one secure value, so a pair is never saved half-updated; the two values of 1.0.1 are moved
  over on the first launch.
- A reinstalled iOS app starts signed out instead of reusing the previous install's Keychain tokens. Updating from
  1.0.1 on iOS signs the user out once.
- GitHub Actions are pinned to commit SHAs.

### Fixed
- The "To do" status badge had no background in the light theme; it is grey again, as in the ToDoList apps.
- Log out is instant: it no longer waits up to a minute for a sleeping server to revoke the refresh token.
- A token refresh that cannot reach the server reports "No connection" instead of "Session expired", and saving or
  deleting a todo shows that error instead of silently stopping.
- Saving a todo that was deleted elsewhere closes the editor with an error; deleting one closes it.
- A failing Keychain / Keystore no longer breaks sign-in, sign-out or app start.
- Debug logs no longer contain the access token.
- Google sign-in no longer keeps spinning after an unexpected plugin error.
- Requests under `/api/v1/auth` are recognised when `API_BASE_URL` contains a path.

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
