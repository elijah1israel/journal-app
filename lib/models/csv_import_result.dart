/// Server response from `POST /api/trades/import_csv/`.
///
/// The endpoint syncs broker CSVs by Ticket ID:
///   - new tickets         → inserted   (counted as [created])
///   - existing & open     → updated    (counted as [updated])
///   - existing & closed   → skipped    (counted as [skipped])
class CsvImportResult {
  const CsvImportResult({
    required this.created,
    required this.updated,
    required this.skipped,
    required this.totalInFile,
  });

  final int created;
  final int updated;
  final int skipped;
  final int totalInFile;

  int get processed => created + updated + skipped;

  factory CsvImportResult.fromJson(Map<String, dynamic> json) =>
      CsvImportResult(
        created: (json['created'] as num?)?.toInt() ?? 0,
        updated: (json['updated'] as num?)?.toInt() ?? 0,
        skipped: (json['skipped'] as num?)?.toInt() ?? 0,
        totalInFile: (json['total_in_file'] as num?)?.toInt() ?? 0,
      );
}
