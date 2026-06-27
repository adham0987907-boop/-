import 'dart:io';
import 'package:flutter/material.dart';
import '../models/vault_file.dart';
import '../services/vault_service.dart';
import 'viewer_screen.dart';

class GalleryScreen extends StatelessWidget {
  final List<VaultFile> files;
  final VoidCallback onRefresh;
  final bool isVideos;

  const GalleryScreen({
    super.key,
    required this.files,
    required this.onRefresh,
    this.isVideos = false,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isVideos ? Icons.videocam_off_outlined : Icons.photo_outlined,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              isVideos ? 'مفيش فيديوهات مخفية' : 'مفيش صور مخفية',
              style: const TextStyle(color: Colors.white38, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'اضغط + عشان تخفي ملفات',
              style: TextStyle(color: Colors.white24, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: files.length,
      itemBuilder: (context, i) {
        final file = files[i];
        return _GridTile(
          file: file,
          onTap: () {
            Navigator.of(context)
                .push(MaterialPageRoute(
                  builder: (_) => ViewerScreen(file: file, allFiles: files, index: i),
                ))
                .then((_) => onRefresh());
          },
          onLongPress: () => _showOptions(context, file),
        );
      },
    );
  }

  void _showOptions(BuildContext context, VaultFile file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              file.name,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.greenAccent),
              title: const Text('استعادة للجهاز', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await VaultService.instance.restoreFile(file);
                onRefresh();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('حذف نهائي', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await _confirmDelete(context);
                if (confirmed == true) {
                  await VaultService.instance.deleteFile(file);
                  onRefresh();
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لأ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('احذف', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final VaultFile file;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _GridTile({
    required this.file,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            file.isImage
                ? Image.file(
                    File(file.vaultPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _ErrorTile(),
                  )
                : _VideoThumbnail(file: file),
            if (file.isVideo)
              const Positioned(
                bottom: 4,
                right: 4,
                child: Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  final VaultFile file;
  const _VideoThumbnail({required this.file});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F3460),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam, color: Colors.white54, size: 32),
          const SizedBox(height: 4),
          Text(
            file.name.length > 12 ? '${file.name.substring(0, 12)}...' : file.name,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F3460),
      child: const Icon(Icons.broken_image_outlined, color: Colors.white38),
    );
  }
}
