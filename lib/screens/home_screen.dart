import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/vault_service.dart';
import '../models/vault_file.dart';
import 'gallery_screen.dart';
import 'files_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  bool _importing = false;

  final List<_TabItem> _tabs = const [
    _TabItem(icon: Icons.photo_library_outlined, label: 'صور'),
    _TabItem(icon: Icons.videocam_outlined, label: 'فيديوهات'),
    _TabItem(icon: Icons.folder_outlined, label: 'ملفات'),
  ];

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final vault = VaultService.instance;
    final fileCount = vault.files.length;
    final totalSize = vault.totalSizeFormatted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الخزنة الآمنة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'إضافة ملفات',
            onPressed: _importing ? null : _pickAndHideFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(
                  icon: Icons.insert_drive_file_outlined,
                  label: 'ملفات',
                  value: fileCount.toString(),
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                _StatChip(
                  icon: Icons.photo_outlined,
                  label: 'صور',
                  value: vault.getImages().length.toString(),
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                _StatChip(
                  icon: Icons.videocam_outlined,
                  label: 'فيديو',
                  value: vault.getVideos().length.toString(),
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                _StatChip(
                  icon: Icons.storage_outlined,
                  label: 'حجم',
                  value: totalSize,
                ),
              ],
            ),
          ),

          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final selected = _currentTab == i;
                return GestureDetector(
                  onTap: () => setState(() => _currentTab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _tabs[i].icon,
                          size: 18,
                          color: selected ? Colors.white : Colors.white54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _tabs[i].label,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.white54,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: _importing
          ? const FloatingActionButton(
              onPressed: null,
              child: CircularProgressIndicator(color: Colors.white),
            )
          : FloatingActionButton.extended(
              onPressed: _pickAndHideFiles,
              icon: const Icon(Icons.add),
              label: const Text('إخفاء ملفات'),
            ),
    );
  }

  Widget _buildContent() {
    switch (_currentTab) {
      case 0:
        return GalleryScreen(
          files: VaultService.instance.getImages(),
          onRefresh: _refresh,
        );
      case 1:
        return GalleryScreen(
          files: VaultService.instance.getVideos(),
          onRefresh: _refresh,
          isVideos: true,
        );
      case 2:
        return FilesScreen(
          files: VaultService.instance.files
              .where((f) =>
                  f.type != FileType.image && f.type != FileType.video)
              .toList(),
          onRefresh: _refresh,
        );
      default:
        return const SizedBox();
    }
  }

  Future<void> _pickAndHideFiles() async {
    // Request permissions
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('محتاج إذن للوصول للملفات')),
        );
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _importing = true);

    int success = 0;
    for (final file in result.files) {
      if (file.path == null) continue;
      try {
        await VaultService.instance.hideFile(file.path!);
        success++;
      } catch (e) {
        debugPrint('Failed to hide ${file.name}: $e');
      }
    }

    if (mounted) {
      setState(() => _importing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success > 0
                ? 'تم إخفاء $success ملف بنجاح ✓'
                : 'فشل إخفاء الملفات',
          ),
          backgroundColor:
              success > 0 ? Colors.green.shade700 : Colors.red.shade700,
        ),
      );
    }
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}
