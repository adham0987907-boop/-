import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../models/vault_file.dart';
import '../services/vault_service.dart';

class ViewerScreen extends StatefulWidget {
  final VaultFile file;
  final List<VaultFile> allFiles;
  final int index;

  const ViewerScreen({
    super.key,
    required this.file,
    required this.allFiles,
    required this.index,
  });

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _pageController = PageController(initialPage: widget.index);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleUI() => setState(() => _showUI = !_showUI);

  @override
  Widget build(BuildContext context) {
    final file = widget.allFiles[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Content
          GestureDetector(
            onTap: _toggleUI,
            child: file.isImage
                ? _buildImageGallery()
                : _VideoViewer(file: file),
          ),

          // Top bar
          AnimatedOpacity(
            opacity: _showUI ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        file.name,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () => _showOptions(context, file),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom info bar
          if (_showUI)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      file.sizeFormatted,
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    Text(
                      '${_currentIndex + 1} / ${widget.allFiles.length}',
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return PhotoViewGallery.builder(
      pageController: _pageController,
      itemCount: widget.allFiles.length,
      onPageChanged: (i) => setState(() => _currentIndex = i),
      builder: (context, index) {
        final f = widget.allFiles[index];
        return PhotoViewGalleryPageOptions(
          imageProvider: FileImage(File(f.vaultPath)),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white38, size: 64),
          ),
        );
      },
      backgroundDecoration: const BoxDecoration(color: Colors.black),
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
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.greenAccent),
              title: const Text('استعادة للجهاز', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await VaultService.instance.restoreFile(file);
                if (mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('حذف نهائي', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await VaultService.instance.deleteFile(file);
                if (mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Video Player ────────────────────────────────────────────────────────────

class _VideoViewer extends StatefulWidget {
  final VaultFile file;
  const _VideoViewer({required this.file});

  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.file(File(widget.file.vaultPath));
    await _videoController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFF6C63FF),
        handleColor: const Color(0xFF6C63FF),
        bufferedColor: Colors.white24,
        backgroundColor: Colors.white12,
      ),
    );
    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(child: Chewie(controller: _chewieController!));
  }
}
