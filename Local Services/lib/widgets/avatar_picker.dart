import 'dart:io';

import 'package:flutter/material.dart';

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    required this.file,
    required this.networkUrl,
    required this.onTap,
    this.size = 104,
    super.key,
  });

  /// Local file just picked from the gallery (takes precedence over network).
  final File? file;

  /// Existing avatar URL fetched from the database.
  final String? networkUrl;

  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hasNetwork = networkUrl != null && networkUrl!.isNotEmpty;

    DecorationImage? image;
    if (file != null) {
      image = DecorationImage(image: FileImage(file!), fit: BoxFit.cover);
    } else if (hasNetwork) {
      image = DecorationImage(
        image: NetworkImage(networkUrl!),
        fit: BoxFit.cover,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              shape: BoxShape.circle,
              image: image,
            ),
            alignment: Alignment.center,
            child: image == null
                ? Icon(Icons.person_outline, color: primary, size: size * 0.45)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
