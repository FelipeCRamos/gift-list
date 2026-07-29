import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/repositories/storage_repository.dart';
import '../images/image_compression.dart';
import 'gl_network_image.dart';

/// Picks an image, compresses it, uploads it via [StorageRepository], and
/// reports the resulting URL through [onChanged] (null when removed). Shows a
/// live preview and handles the busy/error states internally.
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
  final ImagePicker _picker = ImagePicker();
  String? _url;
  bool _busy = false;

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
    setState(() => _busy = true);
    try {
      final Uint8List raw = await file.readAsBytes();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload the image.')),
      );
    }
  }

  void _remove() {
    setState(() => _url = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            GlNetworkImage(
              url: _url,
              height: widget.height,
              width: double.infinity,
            ),
            if (_busy)
              const Positioned.fill(
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
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
