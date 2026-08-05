import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

/// In-memory cache for decoded base64 image bytes to guarantee instant 0ms rendering
final Map<String, Uint8List> _b64MemoryCache = {};

Uint8List? _getDecodedBytes(String rawUrl) {
  if (_b64MemoryCache.containsKey(rawUrl)) {
    return _b64MemoryCache[rawUrl];
  }
  try {
    String cleanB64 = rawUrl;
    if (rawUrl.startsWith('data:image')) {
      final commaIndex = rawUrl.indexOf(',');
      if (commaIndex != -1) {
        cleanB64 = rawUrl.substring(commaIndex + 1);
      }
    }
    final bytes = base64Decode(cleanB64);
    _b64MemoryCache[rawUrl] = bytes;
    return bytes;
  } catch (_) {
    return null;
  }
}

/// Helper widget to select an image from Camera or Gallery
class AppImagePickerBox extends StatelessWidget {
  const AppImagePickerBox({
    super.key,
    required this.base64Image,
    required this.onImagePicked,
    required this.onImageRemoved,
  });

  final String? base64Image;
  final ValueChanged<String> onImagePicked;
  final VoidCallback onImageRemoved;

  Future<void> _pick(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        // Cache immediately
        _b64MemoryCache[base64Str] = bytes;
        onImagePicked(base64Str);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showChoice(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Material Photo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _pick(ImageSource.camera);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.camera_alt_rounded,
                            size: 32, color: AppColors.gold),
                        SizedBox(height: 8),
                        Text('Take Photo',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _pick(ImageSource.gallery);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.dark.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.photo_library_rounded,
                            size: 32, color: AppColors.dark),
                        SizedBox(height: 8),
                        Text('Choose Gallery',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = base64Image != null && base64Image!.isNotEmpty;

    if (hasImage) {
      return Stack(
        children: [
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: AppImageDisplay(
                imageUrl: base64Image,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black.withValues(alpha: 0.6),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, size: 18, color: Colors.white),
                onPressed: onImageRemoved,
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _showChoice(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.dark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.edit, size: 14, color: AppColors.cream),
                    SizedBox(width: 4),
                    Text(
                      'Change',
                      style: TextStyle(
                          color: AppColors.cream,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => _showChoice(context),
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.4),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, size: 30, color: AppColors.gold),
            SizedBox(height: 6),
            Text(
              'Add Material Photo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.dark,
              ),
            ),
            Text(
              'Tap to select from Gallery or Camera',
              style: TextStyle(fontSize: 11, color: AppColors.textMid),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fast, flicker-free Image display widget (Base64 data URI, HTTP URL, or fallback placeholder icon)
class AppImageDisplay extends StatelessWidget {
  const AppImageDisplay({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.inventory_2_rounded,
    this.iconColor = AppColors.gold,
  });

  final String? imageUrl;
  final BoxFit fit;
  final IconData placeholderIcon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Icon(placeholderIcon, color: iconColor);
    }

    final url = imageUrl!.trim();

    // ── Base64 / Data URI ──────────────────────────────────────────────────
    if (url.startsWith('data:image') || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      final bytes = _getDecodedBytes(url);
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Icon(placeholderIcon, color: iconColor),
        );
      }
      return Icon(placeholderIcon, color: iconColor);
    }

    // ── Network HTTP / HTTPS ─────────────────────────────────────────────────
    return Image.network(
      url,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Icon(placeholderIcon, color: iconColor),
    );
  }
}
