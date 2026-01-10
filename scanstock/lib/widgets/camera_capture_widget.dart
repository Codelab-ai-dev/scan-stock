import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraCaptureWidget extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;
  final Function(File) onImageCaptured;
  final VoidCallback? onImageRemoved;
  final double height;

  const CameraCaptureWidget({
    super.key,
    this.imageFile,
    this.imageUrl,
    required this.onImageCaptured,
    this.onImageRemoved,
    this.height = 150,
  });

  Future<void> _captureImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 80,
    );

    if (image != null) {
      onImageCaptured(File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imageFile != null || imageUrl != null;

    return GestureDetector(
      onTap: () => _captureImage(context),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[400]!,
            width: 1,
          ),
        ),
        child: hasImage ? _buildImagePreview() : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: 36,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 6),
        Text(
          'Toca para agregar foto',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageFile != null
              ? Image.file(
                  imageFile!,
                  fit: BoxFit.cover,
                )
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    );
                  },
                ),
        ),
        if (onImageRemoved != null)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onImageRemoved,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 6,
          right: 6,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}
