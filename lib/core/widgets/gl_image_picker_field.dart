import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart'
    show DropDoneDetails, DropTarget;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/repositories/storage_repository.dart';
import '../images/image_compression.dart';
import 'gl_network_image.dart';

/// Adds an image by tap-to-pick or by dragging a file from the computer,
/// compresses it, uploads it via [StorageRepository], and reports the resulting
/// URL through [onChanged] (null when removed). Shows a live preview and handles
/// the busy/error states internally.
class GlImagePickerField extends StatefulWidget {
  const GlImagePickerField({
    required this.pathPrefix,
    required this.onChanged,
    this.initialUrl,
    this.label = 'Photo',
    this.height = 160,
    super.key,
  });

  /// Storage path prefix for the upload (a timestamped filename is appended).
  final String pathPrefix;
  final ValueChanged<String?> onChanged;
  final String? initialUrl;
  final String label;
  final double height;

  @override
  State<GlImagePickerField> createState() => _GlImagePickerFieldState();
}

class _GlImagePickerFieldState extends State<GlImagePickerField> {
  static const List<String> _imageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
  ];

  final ImagePicker _picker = ImagePicker();
  String? _url;
  bool _busy = false;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _url = widget.initialUrl;
  }

  Future<void> _pick() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }
    await _upload(await file.readAsBytes());
  }

  Future<void> _onDrop(DropDoneDetails detail) async {
    setState(() => _dragging = false);
    if (detail.files.isEmpty) {
      return;
    }
    final XFile file = detail.files.first;
    if (!_looksLikeImage(file)) {
      _showError('Please drop an image file.');
      return;
    }
    await _upload(await file.readAsBytes());
  }

  Future<void> _upload(Uint8List raw) async {
    setState(() => _busy = true);
    try {
      final Uint8List compressed = compressImage(raw);
      if (!mounted) {
        return;
      }
      final StorageRepository storage = context.read<StorageRepository>();
      final path =
          '${widget.pathPrefix}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String url = await storage.uploadImage(path, compressed);
      if (!mounted) {
        return;
      }
      setState(() {
        _url = url;
        _busy = false;
      });
      widget.onChanged(url);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      _showError('Could not upload the image.');
    }
  }

  bool _looksLikeImage(XFile file) {
    final String? mime = file.mimeType;
    if (mime != null && mime.isNotEmpty) {
      return mime.startsWith('image/');
    }
    final String name = file.name.toLowerCase();
    return _imageExtensions.any(name.endsWith);
  }

  void _remove() {
    setState(() => _url = null);
    widget.onChanged(null);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        DropTarget(
          onDragEntered: (_) => setState(() => _dragging = true),
          onDragExited: (_) => setState(() => _dragging = false),
          onDragDone: _onDrop,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GlNetworkImage(
                url: _url,
                height: widget.height,
                width: double.infinity,
              ),
              if (_dragging)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.primary, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        'Drop image to upload',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_busy)
                const Positioned.fill(
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to choose, or drag an image here.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.outline),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.upload),
              label: Text(_url == null ? 'Add photo' : 'Replace'),
            ),
            if (_url != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: _busy ? null : _remove,
                child: const Text('Remove'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
