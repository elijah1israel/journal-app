# Wickbook · Claude notes

Flutter mobile companion for the Trade Journal platform. Rides the
same Django backend as the React `trade-journal-frontend` (`/api/`
routes, JWT auth) — this client is just the mobile-shaped slice.

## Layout

```
lib/
  config.dart           Base URL (override with --dart-define=WICKBOOK_API=...)
  main.dart             Splash → login/register → home shell
  theme/app_theme.dart  Brand palette + Material 3 theme
  state/app_state.dart  Single ChangeNotifier covering the whole session
  services/             dio clients: auth, trades, strategies
                        + token_storage (flutter_secure_storage)
  models/               Wire-shaped value types (auth_user, trade, strategy)
  screens/              splash, login, register, home_shell, dashboard,
                        trades, trade_form, calendar, strategies, profile
  widgets/ui.dart       PrimaryButton, StatusPill, EmptyState, formatPnl
```

The architecture is a deliberate port of `pable-mobile` — single
`ChangeNotifier`, dio with transparent JWT refresh, secure-storage for
tokens, custom scrollable bottom-nav in the home shell. Anyone hopping
between the two apps should land on identical idioms.

## Bottom navigation

`HomeShell` (lib/screens/home_shell.dart) hosts every top-level screen
behind a horizontally-scrollable bottom nav (`_ScrollableBottomNav`),
copied beat-for-beat from Pable. The five tabs are:

1. **Dashboard** — stat tiles + recent trades
2. **Trades** — filterable journal list, FAB to log a new trade
3. **Calendar** — month grid tinted by daily P&L; tap a day to drill in
4. **Strategies** — list + bottom-sheet editor
5. **Profile** — user card + sign-out

Tabs live in an `IndexedStack` so each tab's scroll position is
preserved across switches. The nav row scrolls horizontally, so adding
Performance / Signals later just slots in without squeezing labels.

## Order of operations

1. `bootstrap` reads the saved JWT pair from secure storage and pulls
   `/traders/me/` + the first page of trades/strategies.
2. `login` / `register` do the same after a fresh sign-in. Register
   immediately logs in with the credentials it just used so the user
   lands on the shell, not on a "now sign in" screen.
3. The trade form POSTs / PATCHes; the backend computes P&L, R:R, and
   status server-side — the client only ever sends the inputs.
4. The calendar buckets closed trades by `exit_date` (local time) and
   tints each day cell by the signed sum of its P&L. Open trades don't
   show — they have no realised P&L yet.

## Local dev

Platform folders (`android/`, `ios/`) are intentionally not committed.
On a fresh clone:

```bash
flutter create .                                                # bootstrap platforms
flutter pub get
flutter run --dart-define=WICKBOOK_API=http://10.0.2.2:8000/api   # Android emulator
flutter test                                                    # model round-trip tests
flutter analyze                                                 # must stay clean
```

## CI

`.github/workflows/build-apk.yml` mirrors Pable's workflow: regenerates
the Android scaffold inside the runner, patches the manifest to add
INTERNET in release builds and rename the launcher to "Wickbook",
generates launcher icons from `assets/icon/icon.png`, runs
`flutter analyze` + `flutter test`, then builds release split-per-ABI
+ universal APKs and uploads them as workflow artifacts. No deploy
step yet — sideload from the artifact for now.

## Branding

Charcoal ink (`#0E1116`) + bullish emerald (`#00D964`) + bearish red
(`#FF3B47`) on soft white (`#FBFBF9`). The brand mark is a stylised
**morning star** three-candle reversal pattern; those same green and
red are reused as the P&L tint via `AppColors.pnl(value)` so the logo
and every chart cell speak the same colour language.

The colour constants live in `theme/app_theme.dart` under `AppColors`;
the emerald is keyed `teal*` to match the Pable widget helpers so the
shared widget code (PrimaryButton, StatusPill, FilterChip) ports
without renames.

- `assets/branding/wickbook-icon.svg` — square morning-star app icon;
  shown on splash + auth.
- `assets/branding/wickbook-logo-light.svg` — horizontal logo (dark
  wordmark) for light surfaces.
- `assets/branding/wickbook-logo-dark.svg` — horizontal logo (white
  wordmark) for dark surfaces / overlays.
- `assets/icon/icon.png`, `icon_foreground.png` — fed to
  `flutter_launcher_icons`; CI regenerates the Android launcher icon
  on every build. Adaptive background is `#0E1116` to match the brand.

The Dart package name has to be lowercase (`wickbook`), so the
workflow patches `android/app/src/main/AndroidManifest.xml` after
`flutter create` to set `android:label="Wickbook"` and inject the
INTERNET permission into the release manifest (`flutter create` only
adds it to the debug + profile manifests).

## Conventions

- Errors come from the API as DRF detail strings; `api_client.dart`
  wraps them in `ApiException`. Surface them in red snackbars via
  `showAppSnack(context, e.message, error: true)`.
- Don't reach for shared_preferences here — `flutter_secure_storage`
  is the only persistence layer (just the JWT pair).
- Server is authoritative for derived fields (P&L, P&L %, R:R,
  `status`, `exit_price`). Never recompute them client-side; the
  form sends inputs only.
- Use `AppColors.pnl(value)` to tint a number green / red / grey by
  sign — every P&L surface should use it so the colour cue is
  consistent.
