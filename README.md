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

Then run the app; debug builds talk to the local server (`10.0.2.2:8080` from the Android emulator,
`localhost:8080` from the iOS simulator):

```bash
flutter run
```

### Configuration (`--dart-define`)

| Define | Default | Purpose |
|--------|---------|---------|
| `API_BASE_URL` | local server in debug, `https://todolist-server-zyck.onrender.com` in release | Backend address; release builds refuse anything but `https://` |
| `GOOGLE_SERVER_CLIENT_ID` | empty | Web OAuth client; the ID token audience on Android |
| `GOOGLE_IOS_CLIENT_ID` | empty | iOS OAuth client |

Cleartext HTTP is allowed only for local hosts: a debug-only network security config on Android and
`NSAllowsLocalNetworking` on iOS.

### Enabling Google sign-in

Without the client IDs the "Continue with Google" button shows an error; email sign-in keeps working.
The OAuth clients of ToDoList are registered for its own package and bundle ID, so this app needs its own:

1. In Google Cloud Console (the project of the ToDoList server) create an **Android** client for package
   `com.pelypets.todo.todo_flutter` with your debug SHA-1, and an **iOS** client for bundle ID
   `com.pelypets.todo.todoFlutter`.
2. Add the new iOS client ID to the server's `GOOGLE_CLIENT_IDS`.
3. iOS: add the reversed iOS client ID as a URL scheme (`CFBundleURLTypes`) in `ios/Runner/Info.plist`.
4. Run with
   `--dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id> --dart-define=GOOGLE_IOS_CLIENT_ID=<ios client id>`.

## Tests

```bash
flutter analyze
flutter test
```

| Folder | What is covered |
|--------|-----------------|
| `test/domain` | Period boundaries (week start, month and year changes), validation, use cases |
| `test/data` | Requests and mapping through a fake HTTP adapter, HTTP → domain error mapping, transparent token refresh (shared by concurrent requests), session end on a rejected refresh, retries of reads only |
| `test/presentation` | Reducers and view models of every screen, widget tests of the sign-in and todo list screens, the auth gate |

## CI/CD

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs on every push to `main` and every pull request:

- **quality** (Linux): `dart format` check, `flutter analyze`, tests with a coverage summary.
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
