import 'package:flutter/material.dart';
import '../models/vault_file.dart';
import '../services/vault_service.dart';

class FilesScreen extends StatelessWidget {
  final List<VaultFile> files;
  final VoidCallback onRefresh;

  const FilesScreen({
    super.key,
    required this.files,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('مفيش ملفات مخفية', style: TextStyle(color: Colors.white38, fontSize: 16)),
            SizedBox(height: 8),
            Text('اضغط + عشان تخفي ملفات', style: TextStyle(color: Colors.white24, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: files.length,
      itemBuilder: (context, i) {
        final file = files[i];
        return _FileListTile(
          file: file,
          onRestore: () async {
            await VaultService.instance.restoreFile(file);
            onRefresh();
          },
          onDelete: () async {
            final confirmed = await _confirmDelete(context);
            if (confirmed == true) {
              await VaultService.instance.deleteFile(file);
              onRefresh();
            }
          },
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('حذف نهائي', style: TextStyle(color: Colors.white)),
        content: const Text(
          'الملف هيتحذف نهائياً ومش هيرجع. متأكد؟',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لأ')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('احذف', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _FileListTile extends StatelessWidget {
  final VaultFile file;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _FileListTile({
    required this.file,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _typeColor(file.type).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_typeIcon(file.type), color: _typeColor(file.type), size: 24),
        ),
        title: Text(
          file.name,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${file.sizeFormatted} • ${_formatDate(file.addedAt)}',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white54),
          color: const Color(0xFF16213E),
          onSelected: (v) {
            if (v == 'restore') onRestore();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore, color: Colors.greenAccent, size: 18),
                  SizedBox(width: 8),
                  Text('استعادة', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  SizedBox(width: 8),
                  Text('حذف', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(FileType type) {
    switch (type) {
      case FileType.document: return Icons.description_outlined;
      case FileType.audio:    return Icons.audio_file_outlined;
      case FileType.other:    return Icons.insert_drive_file_outlined;
      default:                return Icons.insert_drive_file_outlined;
    }
  }

  Color _typeColor(FileType type) {
    switch (type) {
      case FileType.document: return Colors.blueAccent;
      case FileType.audio:    return Colors.purpleAccent;
      default:                return Colors.tealAccent;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'النهارده';
    if (diff.inDays == 1) return 'إمبارح';
    if (diff.inDays < 7)  return 'من ${diff.inDays} أيام';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}        return _FileListTile(
          file: file,
          onRestore: () async {
            await VaultService.instance.restoreFile(file);
            onRefresh();
          },
          onDelete: () async {
            final confirmed = await _confirmDelete(context);
            if (confirmed == true) {
              await VaultService.instance.deleteFile(file);
              onRefresh();
            }
          },
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('حذف نهائي', style: TextStyle(color: Colors.white)),
        content: const Text(
          'الملف هيتحذف نهائياً ومش هيرجع. متأكد؟',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لأ')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('احذف', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _FileListTile extends StatelessWidget {
  final VaultFile file;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _FileListTile({
    required this.file,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _typeColor(file.type).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_typeIcon(file.type), color: _typeColor(file.type), size: 24),
        ),
        title: Text(
          file.name,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${file.sizeFormatted} • ${_formatDate(file.addedAt)}',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white54),
          color: const Color(0xFF16213E),
          onSelected: (v) {
            if (v == 'restore') onRestore();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore, color: Colors.greenAccent, size: 18),
                  SizedBox(width: 8),
                  Text('استعادة', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  SizedBox(width: 8),
                  Text('حذف', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(FileType type) {
    switch (type) {
      case FileType.document: return Icons.description_outlined;
      case FileType.audio:    return Icons.audio_file_outlined;
      case FileType.other:    return Icons.insert_drive_file_outlined;
      default:                return Icons.insert_drive_file_outlined;
    }
  }

  Color _typeColor(FileType type) {
    switch (type) {
      case FileType.document: return Colors.blueAccent;
      case FileType.audio:    return Colors.purpleAccent;
      default:                return Colors.tealAccent;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'النهارده';
    if (diff.inDays == 1) return 'إمبارح';
    if (diff.inDays < 7)  return 'من ${diff.inDays} أيام';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
