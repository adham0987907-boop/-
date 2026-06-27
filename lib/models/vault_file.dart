import 'dart:io';

enum FileType { image, video, document, audio, other }

class VaultFile {
  final String id;
  final String name;
  final String vaultPath;     // path inside hidden vault folder
  final String originalPath;  // original path before hiding
  final FileType type;
  final int sizeBytes;
  final DateTime addedAt;

  VaultFile({
    required this.id,
    required this.name,
    required this.vaultPath,
    required this.originalPath,
    required this.type,
    required this.sizeBytes,
    required this.addedAt,
  });

  File get file => File(vaultPath);

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  bool get isImage => type == FileType.image;
  bool get isVideo => type == FileType.video;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'vaultPath': vaultPath,
    'originalPath': originalPath,
    'type': type.index,
    'sizeBytes': sizeBytes,
    'addedAt': addedAt.toIso8601String(),
  };

  factory VaultFile.fromJson(Map<String, dynamic> json) => VaultFile(
    id: json['id'],
    name: json['name'],
    vaultPath: json['vaultPath'],
    originalPath: json['originalPath'],
    type: FileType.values[json['type']],
    sizeBytes: json['sizeBytes'],
    addedAt: DateTime.parse(json['addedAt']),
  );

  static FileType typeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    const images = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'];
    const videos = ['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv', 'webm', 'm4v'];
    const audio  = ['mp3', 'aac', 'wav', 'flac', 'm4a', 'ogg'];
    const docs   = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'];

    if (images.contains(ext)) return FileType.image;
    if (videos.contains(ext)) return FileType.video;
    if (audio.contains(ext))  return FileType.audio;
    if (docs.contains(ext))   return FileType.document;
    return FileType.other;
  }
}
