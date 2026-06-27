import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/vault_file.dart';

class VaultService {
  VaultService._();
  static final VaultService instance = VaultService._();

  static const _secureStorage = FlutterSecureStorage();
  static const _pinKey = 'vault_pin';
  static const _filesKey = 'vault_files';
  static const _uuid = Uuid();

  late Directory _vaultDir;
  List<VaultFile> _files = [];

  List<VaultFile> get files => List.unmodifiable(_files);

  // ─── Init ────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();

    // Hidden folder — starts with dot so it won't show in media scanners
    _vaultDir = Directory('${appDir.path}/.vault_secure');
    if (!await _vaultDir.exists()) await _vaultDir.create(recursive: true);

    // Create .nomedia so Android gallery ignores the folder
    final noMedia = File('${_vaultDir.path}/.nomedia');
    if (!await noMedia.exists()) await noMedia.create();

    await _loadFileIndex();
  }

  // ─── PIN ─────────────────────────────────────────────────────────────────

  Future<bool> hasPinSet() async {
    final pin = await _secureStorage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    await _secureStorage.write(key: _pinKey, value: pin);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _secureStorage.read(key: _pinKey);
    return stored == pin;
  }

  Future<void> changePin(String newPin) async {
    await _secureStorage.write(key: _pinKey, value: newPin);
  }

  // ─── File Operations ─────────────────────────────────────────────────────

  /// Move a file INTO the vault (hides it from gallery)
  Future<VaultFile> hideFile(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) throw Exception('File not found: $sourcePath');

    final id = _uuid.v4();
    final originalName = sourcePath.split('/').last;
    // Rename with .vault extension so it won't open in other apps
    final destPath = '${_vaultDir.path}/$id.vault';

    await source.copy(destPath);
    await source.delete(); // remove from original location (gallery)

    final stat = await File(destPath).stat();
    final vaultFile = VaultFile(
      id: id,
      name: originalName,
      vaultPath: destPath,
      originalPath: sourcePath,
      type: VaultFile.typeFromPath(originalName),
      sizeBytes: stat.size,
      addedAt: DateTime.now(),
    );

    _files.add(vaultFile);
    await _saveFileIndex();
    return vaultFile;
  }

  /// Move a file OUT of the vault (restores it to gallery)
  Future<void> restoreFile(VaultFile vaultFile) async {
    final source = File(vaultFile.vaultPath);
    if (!await source.exists()) throw Exception('Vault file missing');

    // Restore to Downloads if original path no longer exists
    String destPath = vaultFile.originalPath;
    final destDir = Directory(destPath.substring(0, destPath.lastIndexOf('/')));
    if (!await destDir.exists()) {
      final downloads = Directory('/storage/emulated/0/Download');
      destPath = '${downloads.path}/${vaultFile.name}';
    }

    await source.copy(destPath);
    await source.delete();

    _files.removeWhere((f) => f.id == vaultFile.id);
    await _saveFileIndex();
  }

  /// Permanently delete from vault
  Future<void> deleteFile(VaultFile vaultFile) async {
    final file = File(vaultFile.vaultPath);
    if (await file.exists()) await file.delete();
    _files.removeWhere((f) => f.id == vaultFile.id);
    await _saveFileIndex();
  }

  // ─── Filter helpers ───────────────────────────────────────────────────────

  List<VaultFile> getByType(FileType type) =>
      _files.where((f) => f.type == type).toList();

  List<VaultFile> getImages() => getByType(FileType.image);
  List<VaultFile> getVideos() => getByType(FileType.video);

  int get totalSizeBytes =>
      _files.fold(0, (sum, f) => sum + f.sizeBytes);

  String get totalSizeFormatted {
    final bytes = totalSizeBytes;
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ─── Persistence ──────────────────────────────────────────────────────────

  Future<void> _saveFileIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_files.map((f) => f.toJson()).toList());
    await prefs.setString(_filesKey, json);
  }

  Future<void> _loadFileIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_filesKey);
    if (json == null) return;

    try {
      final list = jsonDecode(json) as List;
      _files = list.map((e) => VaultFile.fromJson(e)).toList();

      // Verify files still exist — clean up orphans
      _files = _files.where((f) => File(f.vaultPath).existsSync()).toList();
      await _saveFileIndex();
    } catch (_) {
      _files = [];
    }
  }
}
