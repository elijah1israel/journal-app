# Journal

Flutter mobile companion for the **Trade Journal** platform — log trades,
track strategies, and keep an eye on running P&L from your phone.

Same backend as the React `trade-journal-frontend`: a Django REST API
served under `/api/`. JWT auth, same routes — this app just shows the
mobile-shaped half of the surface.

## Backend

This client talks to the Trade Journal Django API:

- `POST /api/auth/token/` — sign in
- `POST /api/auth/token/refresh/` — refresh access token
- `POST /api/traders/register/` — create account
- `GET /api/traders/me/` — current user
- `GET/POST /api/trades/` + `GET/PATCH/DELETE /api/trades/<id>/`
- `GET/POST /api/strategies/` + `GET/PATCH/DELETE /api/strategies/<id>/`

The base URL defaults to `http://10.0.2.2:8000/api` (Android emulator
loopback). Override at run-time with `--dart-define=JOURNAL_API=...`.

## Run

Platform folders (`android/`, `ios/`, etc.) are not committed; this
repo holds the cross-platform Dart source only. To bootstrap them
locally:

```bash
flutter create .                    # regenerate platform scaffolding
flutter pub get
flutter run                         # picks the connected device
```

Point at a local API during dev:

```bash
flutter run --dart-define=JOURNAL_API=http://10.0.2.2:8000/api   # Android emulator
flutter run --dart-define=JOURNAL_API=http://localhost:8000/api  # iOS simulator
```

Sanity-check before pushing:

```bash
flutter analyze     # must stay clean — CI fails on warnings
flutter test        # model round-trip tests
```

## Project layout

```
lib/
  config.dart                  API base URL (overridable via --dart-define)
  main.dart                    App + bootstrap routing
  theme/app_theme.dart         Brand palette + Material 3 theme
  state/app_state.dart         Single ChangeNotifier: auth → trades → strategies
  services/                    Dio clients (auth, trades, strategies)
                               + token_storage (flutter_secure_storage)
  models/                      JSON-shaped value types (auth_user, trade, strategy)
  screens/
    splash_screen.dart
    login_screen.dart / register_screen.dart
    home_shell.dart            Scrollable bottom nav + IndexedStack
    dashboard_screen.dart      Stat tiles + recent trades
    trades_screen.dart         Filterable journal list
    trade_form_screen.dart     Log / edit / delete a trade
    strategies_screen.dart     List + bottom-sheet editor
    profile_screen.dart        User card + sign-out
  widgets/ui.dart              Shared UI helpers (PrimaryButton, StatusPill,
                               EmptyState, formatPnl, formatPrice)
```

The architecture is intentionally a beat-for-beat port of the Pable
waiter app — same single-`ChangeNotifier` pattern, same Dio client
with transparent JWT refresh, same `flutter_secure_storage` for tokens,
same widget helpers, same `_ScrollableBottomNav` in the home shell —
so anyone hopping between the two apps lands on familiar code.

## CI

`.github/workflows/build-apk.yml` mirrors the Pable workflow: builds
release split-per-ABI + universal APKs on every push to `main`, runs
`flutter analyze` + `flutter test`, and uploads the APKs as workflow
artifacts. Platform folders are regenerated inside the workflow so
`android/` never has to live in this repo.

To install on a phone: open the workflow run, download the
`journal-release-vX.Y.Z` artifact, and sideload the universal APK.
