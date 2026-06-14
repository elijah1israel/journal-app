/// App-wide configuration.
class ApiConfig {
  /// Base URL of the Wickbook API (the Trade Journal Django backend).
  /// The REST surface lives under `/api/`.
  ///
  /// Override at run-time for local dev, e.g. on the Android emulator:
  ///   flutter run --dart-define=WICKBOOK_API=http://10.0.2.2:8000/api
  static const String baseUrl = String.fromEnvironment(
    'WICKBOOK_API',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
}
