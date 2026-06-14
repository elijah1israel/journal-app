/// App-wide configuration.
class ApiConfig {
  /// Base URL of the Trade Journal API. The Django backend exposes the
  /// REST surface under `/api/`.
  ///
  /// Override at run-time for local dev, e.g. on the Android emulator:
  ///   flutter run --dart-define=JOURNAL_API=http://10.0.2.2:8000/api
  static const String baseUrl = String.fromEnvironment(
    'JOURNAL_API',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
}
