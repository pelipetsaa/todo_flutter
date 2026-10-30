# ToDo — Flutter client

A Flutter client for the ToDo backend from [ToDoList](../ToDoList) (Kotlin Multiplatform + Ktor).
It has the same features, screens and REST contract as the Compose Multiplatform clients there:

- Sign up / sign in with email and password, or with Google (native ID token, verified on the server).
- Todo list for **Today**, **This week** and **This month**; each row shows time, date, title and status.
- Detail screen to create, edit and delete a todo (date and time pickers, status `To do / In progress / Done`).
- Pull-to-refresh, inline validation, snackbar errors, transparent access token refresh.
- English and Russian UI.

## Architecture

The layers mirror the KMP modules of ToDoList:

```
lib/
  core/          API routes and JSON DTOs                   ← ToDoList core
  domain/        models, validation, period ranges,         ← app/domain
                 repository interfaces, use cases (pure Dart)
  data/          Dio client, token refresh, retries,        ← app/data
                 secure token storage, repositories
  presentation/  MVI view models, screens, navigation       ← app/shared
  di/            build config and the composition root
```

**MVI.** Each screen is a contract (State / Intent / Effect / Mutation), a pure reducer, a view model built on
`MviViewModel` (a `ChangeNotifier` with an effects stream), a stateless `XxxScreen(state, onIntent)` and an
`XxxRoute` that wires the view model and handles effects. Unlike Compose, Flutter shows dialogs imperatively, so the
date/time pickers and the delete confirmation are effects rather than a `dialog` field in the state.

**Session.** `TodoApp` is the auth gate: it opens on the screen that matches the stored session and resets the
back stack whenever the session changes — sign-in, logout, or a refresh token rejected by the server.

| Concern | Choice |
|---------|--------|
| Networking | Dio; bearer token with one shared refresh on 401; only GETs retried on 502/503/504 |
| Secure storage | flutter_secure_storage (Keychain / encrypted preferences) |
| Google sign-in | google_sign_in 7 (Credential Manager on Android, GoogleSignIn SDK on iOS) |
| State | own `MviViewModel` on `ChangeNotifier`, equatable states |

## Running

Start the backend from ToDoList (PostgreSQL in Docker plus the Ktor server on port 8080):

```bash
cd ../ToDoList && docker compose up -d && ./gradlew :server:run
```

Then run the app. Builds pick their backend by build type:

| Build | Backend | Android package / iOS bundle ID | Name |
|-------|---------|---------------------------------|------|
| Debug (`flutter run`) | Local server: `10.0.2.2:8080` from the Android emulator, `localhost:8080` from the iOS simulator | `com.pelypets.todo.todo_flutter.debug` / `com.pelypets.todo.todoFlutter.debug` | ToDo Debug |
| Release (GitHub releases) | `https://todolist-server-zyck.onrender.com` | `com.pelypets.todo.todo_flutter` / `com.pelypets.todo.todoFlutter` | ToDo |

Debug and release builds have different IDs, so both can be installed on one device.

```bash
flutter run                      # emulator or simulator
tool/run_on_device.sh            # a connected phone, still against the local server
```

`tool/run_on_device.sh` picks the first connected phone (or the device ID you pass). On Android it runs
`adb reverse tcp:8080 tcp:8080`, so the phone reaches the server as `localhost:8080` over USB; on an iPhone it uses
this computer's Wi-Fi address, so both must be on the same network (iOS asks for local network access once). Debug
builds allow plain HTTP to any host; release builds use HTTPS only.

### Configuration (`--dart-define`)

| Define | Default | Purpose |
|--------|---------|---------|
| `API_BASE_URL` | local server in debug, `https://todolist-server-zyck.onrender.com` in release | Backend address; release builds refuse anything but `https://` |
| `GOOGLE_SERVER_CLIENT_ID` | ToDoList's web client | Web OAuth client; the ID token audience on Android |
| `GOOGLE_IOS_CLIENT_ID` | empty | iOS OAuth client |

Cleartext HTTP is allowed only for local hosts: a debug-only network security config on Android and
`NSAllowsLocalNetworking` on iOS.

### Enabling Google sign-in

Android builds send ToDoList's web OAuth client as the ID token audience (the server already accepts it). Google
only issues the token when an **Android** OAuth client in the same Google Cloud project matches the app's package and
signing certificate; until then the button shows an error and email sign-in keeps working. The reason is logged:
`adb logcat -s flutter` shows `Google sign-in failed: clientConfigurationError: ...`.

In Google Cloud Console → APIs & Services → Credentials (the ToDoList project) create an Android OAuth client per
package and signing certificate:

| Builds | SHA-1 |
|--------|-------|
| GitHub releases (the ToDoList upload key) | `3A:81:D0:10:F6:9C:B3:EE:19:83:E7:C6:2C:31:42:87:8E:9B:4D:78` |
| Local debug builds (package `com.pelypets.todo.todo_flutter.debug`) | `keytool -list -v -keystore ~/.android/debug.keystore -storepass android` |
| Google Play | the app signing key SHA-1 from Play Console → App integrity |

iOS needs its own client as well, since ToDoList's is registered for another bundle ID:

1. Create an **iOS** client for bundle ID `com.pelypets.todo.todoFlutter` and add its ID to the server's
   `GOOGLE_CLIENT_IDS`.
2. Add the reversed client ID as a URL scheme (`CFBundleURLTypes`) in `ios/Runner/Info.plist`.
3. Build with `--dart-define=GOOGLE_IOS_CLIENT_ID=<ios client id>`.

## Tests

```bash
flutter analyze
flutter test

# End-to-end: the client against a running ToDoList server (see "Running")
E2E_BASE_URL=http://localhost:8080 flutter test test/e2e
```

| Folder | What is covered |
|--------|-----------------|
| `test/core` | JSON contract with the server: ISO instants (with microseconds), statuses, auth bodies, error responses |
| `test/domain` | Period boundaries (week start, month and year changes, DST days, other zones), validation, use cases |
| `test/data` | Requests and mapping through a fake HTTP adapter, HTTP → domain error mapping, transparent token refresh (shared by concurrent requests), session end on a rejected refresh, retries of reads only |
| `test/presentation` | Reducers and view models of every screen, widget tests of the sign-in and todo list screens, the auth gate |
| `test/e2e` | Sign-up, todo CRUD, sign-out and server validation through the real HTTP stack; skipped without `E2E_BASE_URL` |

Date and time logic takes a `TimeZone` (`lib/domain/time`): the app uses the device's, tests a fixed IANA zone
(`test/support/time_zones.dart`), so results do not depend on the machine running them.

## CI/CD

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs on every push to `main` and every pull request:

- **quality** (Linux): `dart format` check, `flutter analyze`, tests with a coverage summary.
- **e2e** (Linux): checks out [ToDoList](https://github.com/pelipetsaa/ToDoList), starts its server with PostgreSQL and
  runs `test/e2e` against it.
- **android** (Linux): debug APK (uploaded as an artifact) and a release build, so R8 problems show up before a release.
- **ios** (macOS): release build without code signing.

Pushing a `v*` tag runs [`.github/workflows/release.yml`](.github/workflows/release.yml): it builds a signed APK and
App Bundle (version from the tag, build number from the run) and publishes a GitHub release with the APK.
Optional steps run once their secrets are set:

| Secret | Used for |
|--------|----------|
| `ANDROID_KEYSTORE_BASE64` | Upload keystore, `base64 -i release.jks` — **required** for a release |
| `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | Keystore credentials |
| `PLAY_SERVICE_ACCOUNT_JSON` | Upload to Google Play (track from the `PLAY_TRACK` variable, `internal` by default) |
| `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_P8`, `APPLE_TEAM_ID` | iOS archive and TestFlight upload |

Create a keystore once with
`keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`.
Locally, release builds without these variables are signed with the debug key.

[Dependabot](.github/dependabot.yml) opens weekly pull requests for pub packages and GitHub Actions.
