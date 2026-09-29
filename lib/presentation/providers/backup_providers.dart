import 'dart:convert';
import 'dart:typed_data';

import 'package:expense_tracker/data/backup_service.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.watch(transactionRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  );
});

// File dialogs used by backup/restore, behind an interface so tests can
// replace them.
abstract class BackupFiles {
  // Returns false if the user cancelled.
  Future<bool> save(String fileName, String contents);

  // Returns null if the user cancelled.
  Future<String?> pickText();
}

class FilePickerBackupFiles implements BackupFiles {
  const FilePickerBackupFiles();

  @override
  Future<bool> save(String fileName, String contents) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(contents)),
      mimeType: 'application/json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    return uri != null;
  }

  @override
  Future<String?> pickText() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    return utf8.decode(await file.readAsBytes());
  }
}

final backupFilesProvider = Provider<BackupFiles>(
  (ref) => const FilePickerBackupFiles(),
);
