import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/csv_import_result.dart';
import '../services/api_client.dart';
import '../services/trade_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Bottom-sheet flow for syncing trades from a broker CSV. Mirrors the
/// React `ImportCsvModal` — column hints, file picker, upload phase,
/// success summary with Added/Updated/Skipped counters, and a row-level
/// error list when the server rejects the file.
class CsvImportSheet extends StatefulWidget {
  const CsvImportSheet({super.key});

  static const List<String> requiredColumns = [
    'Ticket ID', 'Open Time', 'Open Price', 'Close Time', 'Close Price',
    'Profit', 'Lots', 'Symbol', 'Type', 'SL', 'TP',
  ];
  static const List<String> optionalColumns = [
    'Commission', 'Swap', 'Pips', 'Volume',
  ];

  static Future<CsvImportResult?> show(BuildContext context) {
    return showModalBottomSheet<CsvImportResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CsvImportSheet(),
    );
  }

  @override
  State<CsvImportSheet> createState() => _CsvImportSheetState();
}

enum _Phase { idle, uploading, done }

class _CsvImportSheetState extends State<CsvImportSheet> {
  PlatformFile? _file;
  _Phase _phase = _Phase.idle;
  CsvImportResult? _result;
  String? _error;
  List<String> _rowErrors = const [];

  Future<void> _pickFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: false, // we send the path to dio's MultipartFile.fromFile
    );
    if (picked == null || picked.files.isEmpty) return;
    setState(() {
      _file = picked.files.first;
      _error = null;
      _rowErrors = const [];
    });
  }

  Future<void> _submit() async {
    final file = _file;
    if (file == null || file.path == null) return;
    setState(() {
      _phase = _Phase.uploading;
      _error = null;
      _rowErrors = const [];
    });
    try {
      final result = await context.read<AppState>().importTradesCsv(
            path: file.path!,
            filename: file.name,
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _phase = _Phase.done;
      });
    } on CsvImportException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _rowErrors = e.errors;
        _phase = _Phase.idle;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _phase = _Phase.idle;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Import failed. Check the file and try again.';
        _phase = _Phase.idle;
      });
    }
  }

  void _dismiss() {
    if (_phase == _Phase.uploading) return;
    Navigator.of(context).pop(_result);
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return PopScope(
      canPop: _phase != _Phase.uploading,
      child: Padding(
        padding: EdgeInsets.only(bottom: insets),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Handle(),
                if (_phase == _Phase.uploading) const _ProgressBar(),
                _Header(onClose: _dismiss, disabled: _phase == _Phase.uploading),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: _phase == _Phase.done && _result != null
                        ? _SuccessView(result: _result!)
                        : _PickerView(
                            file: _file,
                            error: _error,
                            rowErrors: _rowErrors,
                            onPick: _pickFile,
                          ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.bg,
                    border: Border(
                        top: BorderSide(color: AppColors.borderSoft)),
                  ),
                  child: _phase == _Phase.done
                      ? PrimaryButton(
                          label: 'Done',
                          icon: Icons.check,
                          onPressed: _dismiss,
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _phase == _Phase.uploading
                                    ? null
                                    : _dismiss,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  foregroundColor: AppColors.gray500,
                                  side: const BorderSide(
                                      color: AppColors.border),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                child: const Text('Cancel',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: PrimaryButton(
                                label: _phase == _Phase.uploading
                                    ? 'Syncing…'
                                    : 'Sync trades',
                                icon: Icons.cloud_upload_outlined,
                                loading: _phase == _Phase.uploading,
                                onPressed: _file == null ? null : _submit,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 2,
      child: LinearProgressIndicator(
        backgroundColor: AppColors.surface,
        valueColor: AlwaysStoppedAnimation(AppColors.teal),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose, required this.disabled});
  final VoidCallback onClose;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Import broker CSV',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gray900)),
                const SizedBox(height: 2),
                const Text('MT4 / MT5 export · Syncs by Ticket ID',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.gray500)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: disabled ? null : onClose,
            icon: const Icon(Icons.close, color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}

class _PickerView extends StatelessWidget {
  const _PickerView({
    required this.file,
    required this.error,
    required this.rowErrors,
    required this.onPick,
  });

  final PlatformFile? file;
  final String? error;
  final List<String> rowErrors;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _InfoCard(),
        const SizedBox(height: 16),
        const _ColumnsBlock(),
        const SizedBox(height: 18),
        const _MiniLabel('CSV file'),
        const SizedBox(height: 8),
        _FileDropTarget(file: file, onTap: onPick),
        if (error != null) ...[
          const SizedBox(height: 14),
          _ErrorBlock(message: error!, rows: rowErrors),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  static const _bullets = [
    'New tickets are added',
    'Open trades get updated with the latest prices & close info',
    'Closed trades are left untouched',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How sync works',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gray900)),
          const SizedBox(height: 6),
          for (final b in _bullets)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5, right: 8),
                    child: Icon(Icons.circle,
                        size: 4, color: AppColors.gray500),
                  ),
                  Expanded(
                    child: Text(b,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.gray500)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ColumnsBlock extends StatelessWidget {
  const _ColumnsBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MiniLabel('Required columns'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final c in CsvImportSheet.requiredColumns)
              _ColumnChip(label: c, tone: _ChipTone.required),
          ],
        ),
        const SizedBox(height: 14),
        const _MiniLabel('Optional columns'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final c in CsvImportSheet.optionalColumns)
              _ColumnChip(label: c, tone: _ChipTone.optional),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Dates accept YYYY.MM.DD HH:MM:SS or YYYY-MM-DD HH:MM:SS. Close '
          'Time may be "Currently Running" for open positions.',
          style: TextStyle(
              fontSize: 11.5, color: AppColors.gray500, height: 1.45),
        ),
      ],
    );
  }
}

enum _ChipTone { required, optional }

class _ColumnChip extends StatelessWidget {
  const _ColumnChip({required this.label, required this.tone});
  final String label;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final isRequired = tone == _ChipTone.required;
    final bg = isRequired ? AppColors.teal50 : AppColors.bg;
    final fg = isRequired ? AppColors.teal : AppColors.gray500;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: isRequired ? Colors.transparent : AppColors.border),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: fg)),
    );
  }
}

class _FileDropTarget extends StatelessWidget {
  const _FileDropTarget({required this.file, required this.onTap});
  final PlatformFile? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? AppColors.teal : AppColors.border,
            width: hasFile ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasFile ? AppColors.teal50 : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasFile ? Icons.description : Icons.upload_file_outlined,
                color: hasFile ? AppColors.teal : AppColors.gray500,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFile ? file!.name : 'Choose a CSV file',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasFile
                        ? '${(file!.size / 1024).toStringAsFixed(1)} KB · tap to swap'
                        : 'MT4 / MT5 export, UTF-8 encoded',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.gray500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray500),
          ],
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.rows});
  final String message;
  final List<String> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.danger, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(message,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.danger)),
              ),
            ],
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: rows.length.clamp(0, 30),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    rows[i],
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontFamily: 'monospace',
                      color: AppColors.gray700,
                    ),
                  ),
                ),
              ),
            ),
            if (rows.length > 30)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '…and ${rows.length - 30} more',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray500,
                      fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.result});
  final CsvImportResult result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.teal50,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.teal.withOpacity(0.5)),
            ),
            child:
                const Icon(Icons.check, color: AppColors.teal, size: 32),
          ),
          const SizedBox(height: 14),
          const Text('Sync complete',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gray900)),
          const SizedBox(height: 4),
          Text(
            '${result.totalInFile} ticket${result.totalInFile == 1 ? "" : "s"} processed',
            style:
                const TextStyle(fontSize: 12.5, color: AppColors.gray500),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                  child: _Stat(
                      label: 'Added',
                      value: result.created,
                      color: AppColors.success)),
              const SizedBox(width: 10),
              Expanded(
                  child: _Stat(
                      label: 'Updated',
                      value: result.updated,
                      color: AppColors.gray900)),
              const SizedBox(width: 10),
              Expanded(
                  child: _Stat(
                      label: 'Skipped',
                      value: result.skipped,
                      color: AppColors.gray500)),
            ],
          ),
          if (result.created == 0 &&
              result.updated == 0 &&
              result.skipped > 0)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                'All tickets already exist as closed trades — nothing to do.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.gray500,
                    height: 1.45),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value.toString(),
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.gray500)),
        ],
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.gray500));
}
